module ircbod.message;

import std.datetime;
import ircbod.client;

struct IRCMessage
{
    string     text;
    string     nickname;
    string     channel;
    DateTime   time;
    IRCClient  client;

    void reply(string message)
    {
        if(this.channel[0] == '#') {
            this.client.sendMessageToChannel(message, this.channel);
        } else {
            this.client.sendMessageToUser(message, this.nickname);
        }
    }
}
