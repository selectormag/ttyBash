#!/bin/bash

TTY='/dev/ttyUSB0'

function sflow () {
        # Determine number of lines in given file
        NUMLINES=$(cat "${1}" | wc -l)
        # Process each line, one at a time
        LINENUM=1
        while [[ ${LINENUM} -le ${NUMLINES} ]]; do
                # Get line
                LINE=$(tail -n+"${LINENUM}" "${1}" | head -n1 | sed 's/%/ percent/g; s/\+/ plus/g; s/\@/ at /g; s/\*//g; s/=//g')
                # Determine length of line and calculate approximate wait time
                LENGTH=$(printf "%s" "${LINE}" | wc -m)
                WAITTIME=$(echo "${LENGTH} / 1 * .012" | bc)  # Timed this, and it is about the amount of characters a tty can print per second at 45 baud, targeted for full lines; I should make a formula to allow for various baud rates
                TOUTPUT=$(printf "%s\x02\x08" "${LINE}")
		./ita2conv.sh "${TOUTPUT}" # Send to loop
                #if [[ "${TGENABLED}" == "TRUE" ]]; then
                        # Sending received text to remote telegraph simultaneously as it's printed is enabled; establish connection and send, but don't block if connection is slow or cannot be established

                #fi
                echo "DEBUG: Line ${LINENUM}: ${TOUTPUT}"
                sleep "${WAITTIME}" # Wait approximate amount of time until sending next line so as to not overwhelm interface buffer; buffer seems to be able to hold 2.5 lines without ixon enabled, 6-8 lines with ixon enabled
                ((LINENUM++))
        done
	printf "\x02\x08" > /dev/ttyUSB0
}

FEEDCOUNT=1
INTERVAL=60
MAXFEED=5
while true; do
	if [[ "${FEEDCOUNT}" -eq 1 ]]; then
		# Print latest weather report
		OUTPUT=$(./tty-weather.sh)
	else
       		# Pull the oldest item from the top of the queue
       		OUTPUT=$(cat rss.queue | sed '/^$/q' | sed 's/Title: //g; s/Description: //g')
	fi
	printf "%s" "${OUTPUT}"
       	printf "%s" "${OUTPUT}" | fmt -usw 80 > /dev/shm/ita2.tmp
	sflow /dev/shm/ita2.tmp
	if [[ "${FEEDCOUNT}" -ne 1 ]]; then
       		sed -i '0,/^$/d' rss.queue
       		sed -i '1{/^$/d}' rss.queue
	fi
       	((FEEDCOUNT++))
       	if [[ "${FEEDCOUNT}" -ge "${MAXFEED}" ]]; then
	      FEEDCOUNT=1
       	fi
       sleep "${INTERVAL}"
done
