#!/bin/sh
# Run the main script every X seconds
#This will drift a tiny little bit, probably isn't that much of an issue
while :; do sleep $POLLING_INTERVAL & /SMA-Monitor/monitorandpublish.sh; wait; done