#!/bin/bash

# Parses RSS feeds and weather reporting and puts it all in queue for printing

PRINTNUM=1
RSSLIST='rss.list'
RSSQUEUE='rss.queue'
CHECKINT='600'

while read URL; do
	# Kick off all RSS feeds
	rsstail -d -n 100 -H -i "${CHECKINT}" -P -u "${URL}" >> "${RSSQUEUE}" &
done<"${RSSLIST}"

#while true; do
	# Check weather report using DarkSky API
#	./tty-weather.sh >> "${RSSQUEUE}" && echo "WEATHER TO RSS QUEUE"
#	sleep "${CHECKINT}"
#done

#while true; do
	# Pull the oldest item from the top of the queue
#	./ita2conv.sh $(cat "${RSSQUEUE}" | sed '/^$/q')
#	sed -i '0,/^$/d' "${RSSQUEUE}"
#	sleep "${PRINTINT}"
#done
