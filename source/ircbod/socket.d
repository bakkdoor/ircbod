module ircbod.socket;

import std.socket, std.socketstream, std.conv, std.string;
import core.vararg;

class IRCSocket
{
private:

    char[]         host;
    ushort         port;
    TcpSocket      sock;
    SocketStream   stream;

public:

    this(char[] host, ushort port = 6667)
    {
        this.host = host;
        this.port = port;
        this.sock = null;
    }

    bool connected() {
        return this.sock !is null;
    }

    bool connect()
    {
        this.sock   = new TcpSocket(new InternetAddress(this.host, this.port));
        this.stream = new SocketStream(this.sock);
        return true;
    }

    bool disconnect()
    {
        if (connected()) {
            this.sock.close();
            this.sock = null;
            return true;
        }
        return false;
    }

    void close()
    {
        disconnect();
    }

    bool reconnect()
    {
        disconnect();
        return connect();
    }

    string read()
    {
        return to!string(this.stream.readLine()).chomp();
    }

    private void write(string message)
    {
        std.stdio.writeln(">> " , message);
        this.stream.writeString(message ~ "\r\n");
    }

    void raw(string[] args)
    {
        auto last = args[$ - 1];
        if (last) {
            args[$ - 1] = ":" ~ last;
        }
        write(std.array.join(args, " "));
    }

    private void writeOptional(string command, string[] optional = [])
    {
        if(optional.length > 0) {
            command ~= " " ~ std.array.join(optional, " ");
        }
        write(command.strip());
    }

    void pass(string password)
    {
        write("PASS " ~ password);
    }

    void nick(string nickname)
    {
        write("NICK " ~ nickname);
    }

    void user(string username, uint mode, string unused, string realname)
    {
        write("USER " ~ std.array.join([username, to!string(mode), unused, ":" ~ realname], " "));
    }

    void oper(string name, string password)
    {
        write("OPER " ~ name ~ " " ~ password);
    }

    void mode(string channel, string[] modes)
    {
        write("MODE " ~ channel ~ " " ~ std.array.join(modes, " "));
    }

    void quit(string message = null)
    {
        raw(["QUIT", message]);
    }

    void join(string channel, string password = "")
    {
        writeOptional("JOIN " ~ channel, [password]);
    }

    void part(string channel, string message = "")
    {
        raw(["PART", channel, message]);
    }

    void topic(string channel, string topic = "")
    {
        raw(["TOPIC", channel, topic]);
    }

    void names(string[] channels)
    {
        if(channels.length > 0)
            write("NAMES " ~ std.array.join(channels, ","));
        else
            write("NAMES");
    }

    void list(string[] channels)
    {
        if(channels.length > 0)
            write("LIST " ~ std.array.join(channels, ","));
        else
            write("LIST");
    }

    void invite(string nickname, string channel)
    {
        write("INVITE " ~ nickname ~ " " ~ channel);
    }

    void kick(string channel, string nickname, string comment = null)
    {
        raw(["KICK", channel, nickname, comment]);
    }

    void privmsg(string target, string message)
    {
        write("PRIVMSG " ~ target ~ " :" ~ message);
    }

    void notice(string target, string message)
    {
        write("NOTICE " ~ target ~ " :" ~ message);
    }

    void motd(string target = null)
    {
        writeOptional("MOTD", [target]);
    }

    void stats(string[] params)
    {
        writeOptional("STATS", params);
    }

    void time(string target = null)
    {
        writeOptional("TIME", [target]);
    }

    void info(string target = null)
    {
        writeOptional("INFO", [target]);
    }

    void squery(string target, string message)
    {
        write("SQUERY " ~ target ~ " :" ~ message);
    }

    void who(string[] params)
    {
        writeOptional("WHO", params);
    }

    void whois(string[] params)
    {
        writeOptional("WHOIS", params);
    }

    void whowas(string[] params)
    {
        writeOptional("WHOWAS", params);
    }

    void kill(string user, string message)
    {
        write("KILL " ~ user ~ " :" ~ message);
    }

    void ping(string server)
    {
        write("PING " ~ server);
    }

    void pong(string server)
    {
        write("PONG " ~ server);
    }

    void away(string message = null)
    {
        raw(["AWAY", message]);
    }

    void users(string target = null)
    {
        writeOptional("USERS", [target]);
    }

    void userhost(string[] users)
    {
        write("USERHOST" ~ std.array.join(users, " "));
    }
}
