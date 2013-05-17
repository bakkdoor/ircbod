module hello_bot;

import std.stdio;
import ircbod.client, ircbod.message;

void main(string[] args)
{
    IRCClient bot = new IRCClient("irc.freenode.net", 6667, "ircbod", null, ["#ircbod"]);

    bot.on(IRCMessage.Type.PRIV_MESSAGE, r"^hello (\S+)$", (msg, args) {
        msg.reply("Hello to you, too " ~ msg.nickname ~ "! You greeted: " ~ args[0]);
    });

    bot.on(IRCMessage.Type.JOIN, (msg) {
        writeln("User joined: ", msg.nickname);
        if(msg.nickname != bot.name)
            msg.reply("Welcome to the channel, " ~ msg.nickname);
    });

    bot.on(IRCMessage.Type.CHAN_MESSAGE, (msg) {
        writeln("got chan message: ", msg.text);
    });

    bot.on(IRCMessage.Type.PRIV_MESSAGE, (msg) {
        writeln("got private message: ", msg.text);
    });

    bot.run();
}

