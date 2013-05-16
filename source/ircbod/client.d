module ircbod.client;

import ircbod.socket, ircbod.message;
import std.regex, std.container, std.datetime, std.conv;

alias void delegate(IRCMessage message)                 MessageHandler;
alias void delegate(IRCMessage message, string[] args)  MessageHandlerWithArgs;

class IRCClient
{
private:
    struct PatternMessageHandler {
        MessageHandler          callback;
        MessageHandlerWithArgs  callbackWithArgs;
        Regex!char              pattern;
    }

    alias DList!PatternMessageHandler HandlerList;

    IRCSocket                       sock;
    string                          nickname;
    string                          password;
    string[]                        channels;
    HandlerList[IRCMessage.Type]    handlers;

    static Regex!char MATCHALL = regex(".*");

public:

    this(string server, ushort port, string nickname, string password = null, string[] channels = [])
    {
        this.sock     = new IRCSocket(server.dup, port);
        this.nickname = nickname;
        this.password = password;
        this.channels = channels;
    }

    string name() {
        return this.nickname;
    }

    void connect()
    {
        this.sock.connect();

        if (!this.sock.connected()) {
            throw new Exception("Could not connect to irc server!");
        }

        if (this.password) {
            this.sock.pass(this.password);
        }

        this.sock.nick(this.nickname);
        this.sock.user(this.nickname, 0, "*", "ircbod");

        foreach(c; this.channels) {
            this.sock.join(c);
        }
    }

    void disconnect()
    {
        this.sock.disconnect();
    }

    void reconnect()
    {
        this.sock.reconnect();
    }

    void on(IRCMessage.Type type, MessageHandler callback)
    {
        on(type, MATCHALL, callback);
    }

    void on(IRCMessage.Type type, MessageHandlerWithArgs callback)
    {
        on(type, MATCHALL, callback);
    }

    void on(IRCMessage.Type type, string pattern, MessageHandler callback)
    {
        on(type, regex(pattern), callback);
    }

    void on(IRCMessage.Type type, string pattern, MessageHandlerWithArgs callback)
    {
        on(type, regex(pattern), callback);
    }

    void on(IRCMessage.Type type, Regex!char regex, MessageHandler callback)
    {
        PatternMessageHandler handler = { callback, null, regex };
        if(type !in this.handlers) {
            this.handlers[type] = HandlerList([handler]);
        } else {
            this.handlers[type].insertBack(handler);
        }
    }

    void on(IRCMessage.Type type, Regex!char regex, MessageHandlerWithArgs callback)
    {
        PatternMessageHandler handler = { null, callback, regex };
        if(type !in this.handlers) {
            this.handlers[type] = HandlerList([handler]);
        } else {
            this.handlers[type].insertBack(handler);
        }
    }


    void run()
    {
        if(!this.sock.connected())
            connect();

        string line;
        while ((line = this.sock.read()).length > 0) {
            std.stdio.writeln(line);
            processLine(line);
        }

        this.sock.disconnect();
    }

    void sendMessageToChannel(string message, string channel)
    {
        this.sock.privmsg(channel, message);
    }

    void sendMessageToUser(string message, string nickname)
    {
        this.sock.privmsg(nickname, message);
    }

private:

    IRCMessage.Type typeForString(string typeStr)
    {
        IRCMessage.Type type;
        switch(typeStr) {
            case "JOIN":
                return IRCMessage.Type.JOIN;
            case "PART":
                return IRCMessage.Type.PART;
            case "QUIT":
                return IRCMessage.Type.QUIT;
            default:
                return IRCMessage.Type.CHAN_MESSAGE;
        }
    }

    void processLine(string message)
    {
        if (auto matcher = match(message, r"^:(\S+)\!\S+ (JOIN|PART|QUIT) :?(\S+).*")) {
            auto user    = matcher.captures[1];
            auto typeStr = matcher.captures[2];
            auto channel = matcher.captures[3];
            auto time    = to!DateTime(Clock.currTime());
            auto type    = typeForString(typeStr);
            IRCMessage ircMessage = {
                type,
                typeStr,
                user,
                channel,
                time,
                this
            };

            return handleMessage(ircMessage);
        }

        if (auto matcher = match(message, r"^:(\S+)\!\S+ PRIVMSG (\S+) :(.*)$")) {
            auto user    = matcher.captures[1];
            auto channel = matcher.captures[2];
            auto text    = matcher.captures[3];
            auto time    = to!DateTime(Clock.currTime());
            auto type    = channel[0] == '#' ? IRCMessage.Type.CHAN_MESSAGE : IRCMessage.Type.PRIV_MESSAGE;
            IRCMessage ircMessage = {
                type,
                text,
                user,
                channel,
                time,
                this
            };

            return handleMessage(ircMessage);
        }

        if (auto matcher = match(message, r"^PING (.+)$")) {
            auto server = matcher.captures[1];
            this.sock.pong(server);
        }
    }

    void handleMessage(IRCMessage message)
    {
        if(message.type in this.handlers) {
            foreach(PatternMessageHandler h; this.handlers[message.type]) {
                if(auto matcher = match(message.text, h.pattern)) {
                    string[] args = [];
                    foreach(string m; matcher.captures) {
                        args ~= m;
                    }
                    if(h.callback)
                        h.callback(message);
                    if(h.callbackWithArgs)
                        h.callbackWithArgs(message, args[1..$]);
                }
            }
        }
    }
}
