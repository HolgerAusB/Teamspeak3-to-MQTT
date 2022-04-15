# Teamspeak3-to-MQTT
A script that detects if buddies are logged in on a Teamspeak3 server and sets their status to MQTT.

## Why
I wanted to be informed when one of my buddies is logged into my Teamspeak3 server, even if I am not sitting at the computer.

This script uses the telnet interface of a Teamspeak3 server to determine which users (clients) are currently online. It compares the client_database_id to see if my friends are online and sends the presence status to a mqtt-broker. Here you can then pick up the status via an existing Smarthome system and let for example a lamp blink.

## Prerequisites
* **You should host a Teamspeak3 server yourself or ask your hoster if you are allowed to run such a script on the telnet interface and with what minimum interval! You could be blocked otherwise!!!**
* You must be server admin of the Teamspeak server
* The script is a bash script for Linux. You should have basic knowledge in Linux and know how to use the Linux console.
* You need `expect` for the query over the telnet protocol. So you might need to install that. On Debian like systems just `apt install expect`
* You need to have access to a MQTT broker like 'mosquitto' local or somewhere else.
* To send the result to an MQTT broker, please `apt install mosquitto-clients`. Of course, you can also change the script to perform an other action directly here. But remember that the script is executed every x minutes. In my case Homebridge takes care that an action is triggered only at the first detection of presence.

## Preparation
The first thing you need to do is to collect and write down some data by hand. Start your Teamspeak3 client and connect to the server. You must be a server admin. In the menu select Tools>Server Query Login. Choose a name for the query user. After OK the system will tell you your password, write it down.

Now you have to start a telnet query on the Linux console. The default port for Telnet on Teamspeak servers is 10011. Even if the hoster sets up several virtual client servers on one machine, one telnet port is usually sufficient for all of them. If the port is not correct you have to ask your provider.

`telnet servername-or-ip 10011`

After the welcome message you must provide your query user credentials:

`login queryname secretpassword`

you should get an `error id=0 msg=ok` as an answer. Then you need to know which is your server ID:

`whoami`

which should give you a long list of parameters, your ID is `client_origin_server_id=xx`. Now you need to put this number to the next command:

`use 123`

Next command gives you a list of available Channels.

`channellist`

Copy this list and paste it into a text editor oder text file. After each pipe symbol `|` press enter to get a readable list, one channel per line. If you want to monitor only some of the channels you need their `cid`.

Last command gives you a list of logged in clients (the users). You need to do this, when yor buddies are online:

`clientlist`

Once again, copy this list to a text editor and hit Enter after each pipe. Then write down the `client_database_id` of your friends that you want to be informed about when they come online.

## Installation and configuration

Now place the script `ts3-to-mqtt.sh` from this repo to /usr/local/bin. Make it executable:

`sudo chmod +x /usr/local/bin/ts3-to-mqtt.sh`

Now copy the file `ts3-to-mqtt.conf` from this repo to `/etc/ts3-to-mqtt/` and open this with your editor to enter your configuration data.

Here are some additional hints about some of the parameters:

### mybuddies
This is an array, please keep the brackets () arround and do ___not___ set quotation marks arround the brackets. Multiple cid are seperated by spaces. e.g.:
```
mybuddies=(1234)                  # only one buddy
mybuddies=(1230 1231 1232 4433)   # multiple buddies
```
### channels
This one will be set as the middle part of a regular expression, so beware of the format, e.g. "(1200|1201)" will combined to the search pattern "cid=(1200|1201)".
```
channels=""                 # scan ALL channels
channels="1234"             # scan only one channel, id 1234
channels="(1234)"           # scan only one channel, id 1234
channels="(1201|1202|1300)" # scan given CIDs, seperate by pipe symbol
channels="99999"            # disable channel-scan, with an unused cid
```
### entree_cid
Some admins chose to have a single channel with low permissions for guests, while only the normal users have the right to move these guests to the real used channels. To be informed, when guests are waiting to be moved you can set the channals cid here. Set to an unused sid, if you dont want to use this feature. This one is part of a regular expression as in 'channels'.
```
entree_CID="1200"         # scan one channel for ANY users
entree_CID="(1200)"       # scan one channel for ANY users
entree_CID="(1200|1201)"  # scan two channels for ANY users
entree_CID="99999"        # disable entree-scan, with an unused cid
```
## Test the script
Use two console windows. In the first you subscribe to the mosquitto-broker to see, what the script is doing:

`mosquitto_sub -h localhost -p 1883 -F '%I \e[92m%t \e[96m%p\e[0m' -t ts3/#`

-F is just for coloring the output, you might need to adjust -t with your choosen topic and add more options like your credentials for mqtt if needed.

Now go to the second console window and start the script `ts3-to-mqtt.sh` and control on the other console window what happened. If you set your own client id the mybuddies you can controll if all the channels work. Change channel and start the script again. Logout in TS3 and start script again. test it when no others are online and with buddies online and maybe with guests.

## Set a cron job for automation
### **ONCE AGAIN: Beware that you testet everything well (last step) and have permissions from your hoster to run this bot before activating the cron job**

Copy the file `ts3-to-mqtt-cron` to your home-path, then you should check/edit on which hours the bot-script should run. Then you should replace all 'root' in the file by your normal user. There is no need to run the script as root user. After that, move this file to /etc/cron.d

## Legal
* Teamspeak is a trademark of TeamSpeak Systems, Inc.
* Homekit and Apple are trademarks of Apple Inc.
