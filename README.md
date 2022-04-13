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
* To send the result to an MQTT broker, please `apt install mosquitto-clients`. Of course, you can also change the script to perform another action directly here. But remember that the script is executed every x minutes. In my case Homebridge takes care that an action is triggered only at the first detection of presence.

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

Once again, copy this list to a text editor an hit Enter after each pipe. Then write down the `client_database_id` of your friends that you want to be informed about when they come online.
