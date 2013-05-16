module ircbod.message;

import std.datetime;
import ircbod.client;

struct IRCMessage
{
    enum Type {
        CHAN_MESSAGE,
        PRIV_MESSAGE,
        JOIN,
        PART,
        QUIT
    }

    Type        type;
    string      text;
    string      nickname;
    string      channel;
    DateTime    time;
    IRCClient   client;

    void reply(string message)
    {
        if(this.type == Type.PRIV_MESSAGE) {
            this.client.sendMessageToUser(message, this.nickname);
        } else {
            this.client.sendMessageToChannel(message, this.channel);
        }
    }
}
