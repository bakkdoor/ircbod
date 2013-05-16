module ircbod.client;

import ircbod.socket, ircbod.message;
import std.regex, std.container, std.datetime, std.conv;

alias void delegate(IRCMessage message)                 MessageHandler;
alias void delegate(IRCMessage message, string[] args)  MessageHandlerWithArgs;

enum MessageType {
    MESSAGE,
    JOIN,
    PART,
    QUIT
}

class IRCClient
{
private:
    struct PatternMessageHandler {
        MessageHandler          callback;
        MessageHandlerWithArgs  callbackWithArgs;
        Regex!char              pattern;
    }

    IRCSocket                                   sock;
    string                                      nickname;
    string                                      password;
    string[]                                    channels;
    DList!PatternMessageHandler[MessageType]    handlers;

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

    void on(MessageType type, MessageHandler callback)
    {
        on(type, MATCHALL, callback);
    }

    void on(MessageType type, MessageHandlerWithArgs callback)
    {
        on(type, MATCHALL, callback);
    }

    void on(MessageType type, string pattern, MessageHandler callback)
    {
        on(type, regex(pattern), callback);
    }

    void on(MessageType type, string pattern, MessageHandlerWithArgs callback)
    {
        on(type, regex(pattern), callback);
    }

    void on(MessageType type, Regex!char regex, MessageHandler callback)
    {
        PatternMessageHandler handler = { callback, null, regex };
        if(type !in this.handlers) {
            this.handlers[type] = DList!PatternMessageHandler([handler]);
        } else {
            this.handlers[type].insertBack(handler);
        }
    }

    void on(MessageType type, Regex!char regex, MessageHandlerWithArgs callback)
    {
        PatternMessageHandler handler = { null, callback, regex };
        if(type !in this.handlers) {
            this.handlers[type] = DList!PatternMessageHandler([handler]);
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

    MessageType typeForString(string typeStr)
    {
        MessageType type;
        switch(typeStr) {
            case "JOIN":
                return MessageType.JOIN;
            case "PART":
                return MessageType.PART;
            case "QUIT":
                return MessageType.QUIT;
            default:
                return MessageType.MESSAGE;
        }
    }

    void processLine(string message)
    {
        if (auto matcher = match(message, r"^:(\S+)\!\S+ (JOIN|PART|QUIT) :?(\S+).*")) {
            auto user    = matcher.captures[1];
            auto typeStr = matcher.captures[2];
            auto channel = matcher.captures[3];
            auto time    = to!DateTime(Clock.currTime());
            IRCMessage ircMessage = {
                typeStr,
                user,
                channel,
                time,
                this
            };

            return handleMessage(typeForString(typeStr), ircMessage);
        }

        if (auto matcher = match(message, r"^:(\S+)\!\S+ PRIVMSG (\S+) :(.*)$")) {
            auto user    = matcher.captures[1];
            auto channel = matcher.captures[2];
            auto text    = matcher.captures[3];
            auto time    = to!DateTime(Clock.currTime());
            IRCMessage ircMessage = {
                text,
                user,
                channel,
                time,
                this
            };

            return handleMessage(MessageType.MESSAGE, ircMessage);
        }

        if (auto matcher = match(message, r"^PING (.+)$")) {
            auto server = matcher.captures[1];
            this.sock.pong(server);
        }
    }

    void handleMessage(MessageType type, IRCMessage message)
    {
        if(type in this.handlers) {
            foreach(PatternMessageHandler h; this.handlers[type]) {
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
