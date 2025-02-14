#!/bin/bash

# Receives ITTY text from an fldigi XMLRPC server and prints it out. If enabled, runs in the background of the main loop and automagically starts printing only if a new message is received. Stops printing when it detects that no signal has been received for MAXIDLE seconds

# TODO: Change fldigi IP address and port to variables, add process killer so that the correct fldigi-shell process gets 86'd when a message stops being received

source ./tty-common

# Check the receive file to see if anything new has been received; this loop is separate from the main loop because the main loop may take too long to respond and delay receiving an itty inbound message
CURRENT=$(stat -c %Y /dev/shm/"${TTYNAME}"-itty.rx)
LAST=$(cat /dev/shm/"${TTYNAME}"-itty-last.rx)

if [[ -z "${LAST}" ]]; then
	LAST=$(date +%s)
	printf "%s" "${LAST}" > /dev/shm/"${TTYNAME}"-itty-last.rx
fi

if [[ -z "${CURRENT}" ]]; then
	CURRENT=$(date +%s)
	touch /dev/shm/"${TTYNAME}"-itty.rx
fi

debugprint "CURRENT is ${CURRENT}, and LAST is ${LAST}."

if [ "${CURRENT}" -gt "${LAST}" ]; then

	# Something new showed up-- turn on teletype and start printing
	autocrlf off
	ttyinit
	# Send RX to current loop, watch for silence and disengage when rx has gone quiet
		
	debugprint "ITTY message inbound. Beginning transmission..."

	perl fldigi-shell -u "http://${ITTY_HOST}:${ITTY_PORT}/2/RPC2" -c polldata > "${TTY}" &
	FLDIGIPID=$(echo "${!}")
	SILENCE=0

	while [[ "${SILENCE}" -le 'MAXIDLE' ]]; do

		# Check for silence on RX
		RXTIME=$(stat -c %Y /dev/shm/"${TTYNAME}"-itty.rx)

		if [[ "${RXTIME}" -lt "${LASTTIME}" ]]; then
			# RX has been silent for a period of time; add counter
			((SILENCE++))
			debugprint "RX has been silent for ${SILENCE} seconds. (RXTIME is ${RXTIME}, LASTTIME is ${LASTTIME})."
		#######elif [[ -n "${TERMCHRX}" ]]; then
		     
		else
			# RX not currently silent-- ensure it's set to zero
			SILENCE=0
			debugprint "RX still in progress (RXTIME is ${RXTIME}, LASTTIME is ${LASTTIME}). SILENCE set to ${SILENCE}."
		fi

		# Set LASTTIME to current timestamp
		LASTTIME=$(date +%s)
		sleep 1
	done
				
	# Line has been idle for long enough that a new message isn't coming in-- SHOOT HER!
	debugprint "RX has been silent for ${SILENCE}, which is greater than or equal to the maximum idle setting of ${MAXIDLE}. Shutting down the TTY."
	# Clear the fldigi terminal so the previous crap doesn't get printed again
	perl fldigi-shell -u "http://${ITTY_HOST}:${ITTY_PORT}/2/RPC2" -c text.clear_rx

	# Finish him -- set the LAST variable for the next time this script is run and kill the intermediate fldigi process
	printf "%s" "${RXTIME}" > /dev/shm/"${TTYNAME}"-itty-last.rx
	kill "${FLDIGIPID}"
	ttyuninit
	autocrlf on

fi
