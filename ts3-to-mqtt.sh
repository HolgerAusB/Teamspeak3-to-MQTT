#! /bin/bash

# TeamSpeak3 To Mqtt - version 0.1.1
#
# Reads via the telnet port which users (clients) are online at
# a Teamspeak3 server and sets a mqtt topic for found buddies
#
# READ the manual at
# https://github.com/HolgerAusB/Teamspeak3-to-MQTT
#
# Script needs to have 'expect' and 'mosquitto-clients' installed
#################################################################
# NO WARRANTY - Use at YOUR OWN RISC - I am not a skilled coder !
#################################################################

# syntax:
#    ts3-to-mqtt.sh [/path/to/config.conf]
#
# if config-file from parameter is not found, script tries to
# find at  /etc/ts3-to-mqtt/ts3-to-mqtt.conf

###############################################################################
# don't change anything below that line, except you know, what you are doing! #
###############################################################################

# read configuration

if     [[ -e "$1" ]]
    then
	. "$1"
    elif [[ -e /etc/ts3-to-mqtt/ts3-to-mqtt.conf ]]
	then
	    . /etc/ts3-to-mqtt/ts3-to-mqtt.conf
	else
	    echo no config found
	    exit 10
fi

# build regex search patterns
chngrep="cid=$channels[^0-9]"
gstgrep="cid=$entree_CID[^0-9]"

# now reading clients=users via telnet by using 'expect'
VAR=$(
    expect -c "
        set timeout 20
	spawn telnet $server $port
	expect \"command.\"
	sleep .1;
	send \"login $username $password\\r\";
	sleep .1;
	send \"use $ts3serverid\\r\";
	sleep .1;
	send \"clientlist\\r\";
	sleep .1;
	expect -re \"(clid.*)\"
    " | grep clid | sed 's/\\p/_/g' | sed 's/|/\n/g' | grep -E "client_type=0"
)

memberchannels=$(echo $VAR | grep -E "$chngrep"  | grep -o -E 'client_database_id=[0-9]+' | grep -o -E '[0-9]+')
guestchannels=$(echo $VAR | grep -c -E "$gstgrep")

# check all defined buddies if they are in one of the watched channels
# and set their status to the mqtt-topic
for i in "${mybuddies[@]}"
do
    if [[ `echo $memberchannels | grep -c -E "(^|[^0-9])$i([^0-9]|$)"` -gt 0 ]]; then
    mosquitto_pub $mosq_param -t $mosq_topic/$i -m $mosq_online
    else
    mosquitto_pub $mosq_param -t $mosq_topic/$i -m $mosq_offline
    fi
done

# trigger the entree-topic if people waiting in guest-channel(s)
if [[ $guestchannels -gt 0 ]]; then
    mosquitto_pub $mosq_param -t $entree_topic -m $mosq_online
    # depending on how you process the mqtt data, you might want to activate the following two lines
    # sleep 10
    # mosquitto_pub $mosq_param -t $entree_topic -m $mosq_offline
fi
