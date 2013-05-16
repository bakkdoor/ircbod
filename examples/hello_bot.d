module main;

import std.stdio;
import ircbod.client;

void main(string[] args)
{
    IRCClient bot = new IRCClient("irc.freenode.net", 6667, "ircbod", null, ["#ircbod"]);

    bot.on(MessageType.MESSAGE, r"^!hello (\S+)$", (msg, args) {
        msg.reply("Hello to you, too, " ~ msg.nickname);
    });

    bot.on(MessageType.JOIN, (msg) {
        writeln("User joined: ", msg.nickname);
        if(msg.nickname != bot.name)
            msg.reply("Welcome to the channel, " ~ msg.nickname);
    });

    bot.run();
}

