module ircbod.message;

import std.datetime;
import ircbod.client;

struct IRCMessage
{
    enum Type {
        MESSAGE,      // includes CHAN_MESSAGE & PIV_MESSAGE
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
        if(type == Type.PRIV_MESSAGE) {
            client.sendMessageToUser(message, nickname);
        } else {
            client.sendMessageToChannel(message, channel);
        }
    }
}
