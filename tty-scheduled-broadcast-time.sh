#!/bin/bash

# Connects to an external fldigi server to broadcast RTTY/ITTY signals as scheduled for SPECIFIC TIMES

FLDIGI_HOST='192.168.76.13'
FLDIGI_PORT='7363'
# TODO: Create a parser that can determine if any of the scheduled messages will be entered in the past or if there is not enough time to print one message before executing another. Also check if any of the times are invalid and would never occur, e.g. 101:75

#source ./tty-common

#SCHEDPATH="${2}/"

SCHEDPATH="${1}/"

for FILE in "${SCHEDPATH}"*; do
	# Parse first line of file to get time delay (need to program something to check files for compliance before starting)
	echo "Getting timestamp of file ${FILE}..."
	TIMESTAMP=$(grep 'TIMESTAMP=' "${FILE}")
	TIMESTAMP=$(printf  %s "${TIMESTAMP}" | cut -d '=' -f 2)
	
	WAIT='TRUE'
	
	while [[ "${WAIT}" == 'TRUE' ]]; do
		CURTIME=$(date +"%H:%M")
		if [[ "${CURTIME}" == "${TIMESTAMP}" ]]; then
			WAIT='FALSE'
			echo "TIMESTAMP is ${TIMESTAMP}, which is equal to CURTIME ${CURTIME}. Time to execute scheduled message."
			break
		else
			echo "CURTIME is ${CURTIME} ($(date +'%H:%M:%S')). Waiting until time is ${TIMESTAMP}."
			sleep 60
		fi
	done

	TMPFILE=$(mktemp /dev/shm/itty-sched-bcast.XXXXX)
	TMPFILE2=$(mktemp /dev/shm/itty-sched-bcast.XXXXX)

	#Add date/time, blank lines to allow for
	printf "\n\n\n\nZCZC\n\n" > "${TMPFILE}"
	echo "TTBN Santa Tracker $(date +'%Y-%m-%d %H:%M %Z')" >> "${TMPFILE}"
	echo "-------" >> "${TMPFILE}"

	#Remove TIMEDELAY from file
	grep -v 'TIMESTAMP=' "${FILE}" > "${TMPFILE2}"

	#Format file to proper width
	fmt -usw 72 "${TMPFILE2}" >> "${TMPFILE}"

	# Add closing NNNN
	printf "\nNNNN\n" >> "${TMPFILE}"

	#Add EOF to file to trigger end of TX
	printf "\x04" >> "${TMPFILE}"

	# Run transmission
	echo "Activating TX mode..."
	perl fldigi-shell -u "http://${FLDIGI_HOST}:${FLDIGI_PORT}/2/RPC2" -c main.tx
	echo "Beginning transmission..."
	perl fldigi-shell -u "http://${FLDIGI_HOST}:${FLDIGI_PORT}/2/RPC2" -c send < "${TMPFILE}"
	echo "Starting up local printer..."
	cat "${TMPFILE}"
	TXWAIT=$(cat "${TMPFILE}" | wc -c)
	#SPACES=$(grep -o ' '  "${TMPFILE}" | wc -l)
	#TXWAIT=$(( TXWAIT + SPACES ))
	TXWAIT=$(echo "${TXWAIT}/5.45" | bc)
	echo "Waiting for transmission to finish. Sleeping for ${TXWAIT} seconds..."
	#
	sleep "${TXWAIT}"
	echo "TX finished. Returning to RX mode..."
	perl fldigi-shell -u "http://${FLDIGI_HOST}:${FLDIGI_PORT}/2/RPC2" -c main.rx
done

echo "Set of scheduled broadcasts complete. Terminating process."
