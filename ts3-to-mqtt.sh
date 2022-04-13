#! /bin/bash
# TeamSpeak3 To Mqtt - version 20220413.1
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

# your TeamSpeak3-Server user MUST NOT be server admin credentials
# please use a 'query user'
server=localhost	#ts3 server name or ip
port=10011		#telnet port of ts3 server, standard: 1011
username=querybot	#query user, NOT admin
password=secret		#your query users password
ts3serverid=123		#your client_origin_server_id

# your friends goes here, you should put their names to comment line
# to not get confused some time later.
# use the client_database_id here, blank seperated array,
# don't remove brackets!
# e.g. my buddies: 1234=Tim 1250=Jane ...
mybuddies=(1234 1250 1666 13456 4001)

# which channels should be watched? use cid
# If you only want to check the Entrée-Channel, you can disable this
# by setting this to an unused CID like "(99999)" 
# e.g. my channels: 2900=Entrée 2901=Group1 2902=Group2 2917=Group3 2999=afk
channels="(2901|2902|2917)"

# If you have an Entrée-channel, where guests (with password) can join
# but can't move themselves to the real channels, put the channels ID here
# if you want to be informed of unknown guests waiting to get moved.
# To disable set this to an unused CID like "(99999)"
# Multiple channels seperated by Pipe: entree_CID="(2900|2901)"
entree_CID="(2900)"
entree_topic="ts3/entree"  #mqtt-topic for entrée-channel

# mosquitto command line, myabe you need to add username and password fields
mosq_param="-h localhost -p 1883"
# mosquitto base topic and message-text: 
mosq_topic="ts3"	# cid will added by script: ts3 => ts3/1234
mosq_online="true"	# mqtt message when buddy is online
mosq_offline="false"	# mqtt message when buddy is offline

###############################################################################
# don't change anything below that line, except you know, what you are doing! #
###############################################################################

chngrep="cid=$channels"
gstgrep="cid=$entree_CID"

# now reading clients=users via telnet by using 'expect'
VAR=$(
    expect -c "
	log_user 0
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
	log_user 1;
	expect -re \"(clid.*)\"
	sleep .1;
	set clidstring \$expect_out(1,string);
	sleep .1;
	send_user \"eot\";
	sleep .1
        " | grep clid | sed 's/\\p/_/g' | sed 's/|/\n/g' | grep -E "client_type=0"
    )

memberchannels=$(echo $VAR | grep -E "$chngrep"  | grep -o -E 'client_database_id=[0-9]+' | grep -o -E '[0-9]+')
guestchannels=$(echo $VAR | grep -c -E "$gstgrep")

# check all defined buddies if they are in one of the watched channels
# and set their status to the mqtt-topic
for i in "${mybuddies[@]}"
do
    if [[  "$VAR" =~ .*$i.* ]]; then
	mosquitto_pub $mosq_param -t $mosq_topic/$i -m $mosq_online
    else
	mosquitto_pub $mosq_param -t $mosq_topic/$i -m $mosq_offline
    fi
done

# trigger the entree-topic if people waiting in guest-channel(s)
if [[ $guestchannels -gt 0 ]]; then
    mosquitto_pub $mosq_param -t $entree_topic -m $mosq_online
    #sleep 10
    #mosquitto_pub $mosq_param -t $entree_topic -m $mosq_offline
fi
