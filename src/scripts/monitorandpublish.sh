#!/bin/sh
#login to the SMA inverter and store the session
SESSION=`curl -s -X POST -d '{"right": "usr", "pass": "'$INVERTER_PW'"}' http://$INVERTER_HOST/dyn/login.json | jq -r .result.sid`
#get the data from the session
curl -s --data-binary '{"destDev":[]}' http://$INVERTER_HOST/dyn/getAllOnlValues.json?sid=$SESSION > /tmp/data.json
#logout
curl -s -X POST --data-binary '{}' http://$INVERTER_HOST/dyn/logout.json?sid=$SESSION >/dev/null

#publish to mqtt topic
#we are sending from file as we can't simply pass it on the commandline due to escaping of quotes etc.
mosquitto_pub -h $MQTT_HOST -f /tmp/data.json -t $MQTT_TOPIC

#clean-up the file
rm /tmp/data.json