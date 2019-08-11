#!/bin/sh

if [ -z "$LOCALE" ];
then
	LOCALE="en-US"
fi

# If this is the very first time we run, get the "dictionary" files
if [ ! -f /tmp/$LOCALE.json ];
then
	#we build this the first time in case of changes in firmware/translations/differences between inverters etc
	#adding --compressed as inverter by defaults sends content compressed for these files
	curl --compressed -s http://$INVERTER_HOST/data/ObjectMetadata_Istl.json > /tmp/ObjectMetadata_Istl.json
	curl --compressed -s http://$INVERTER_HOST/data/l10n/$LOCALE.json > /tmp/$LOCALE.json
	#get all the id's that we want translated
	jq -f /SMA-Monitor/keynames.jq /tmp/ObjectMetadata_Istl.json > /tmp/keynames.json
	#create dictionary
	jq --argfile dict /tmp/$LOCALE.json -f /SMA-Monitor/fillin.jq /tmp/keynames.json > /tmp/newdict.json
fi

#login to the SMA inverter and store the session
SESSION=`curl -s -X POST -d '{"right": "usr", "pass": "'$INVERTER_PW'"}' http://$INVERTER_HOST/dyn/login.json | jq -r .result.sid`
#get the data from the session
curl -s --data-binary '{"destDev":[]}' http://$INVERTER_HOST/dyn/getAllOnlValues.json?sid=$SESSION > /tmp/data.json
#logout
curl -s -X POST --data-binary '{}' http://$INVERTER_HOST/dyn/logout.json?sid=$SESSION >/dev/null

#"filter" the json file basically flattening all the paths and making it human readable
jq --argfile dict /tmp/newdict.json --argfile dict2 /tmp/$LOCALE.json -f /SMA-Monitor/filter.jq /tmp/data.json > /tmp/data-clean.json

#publish to mqtt topic
#we are sending from file as we can't simply pass it on the commandline due to escaping of quotes etc.
mosquitto_pub -h $MQTT_HOST -f /tmp/data-clean.json -t $MQTT_TOPIC

#clean-up the file
rm /tmp/data.json
rm /tmp/data-clean.json