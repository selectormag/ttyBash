#!/bin/bash

# Connects to an external fldigi server to broadcast RTTY/ITTY signals as scheduled

FLDIGI_HOST='192.168.76.13'
FLDIGI_PORT='7363'

#source ./tty-common

#SCHEDPATH="${2}/"

SCHEDPATH="${1}/"

for FILE in "${SCHEDPATH}"*; do
	# Parse first line of file to get time delay (need to program something to check files for compliance before starting)
	echo "Getting time delay of file ${FILE}..."
	TIMEDELAY=$(grep 'TIMEDELAY=' "${FILE}")
	TIMEDELAY=$(printf  %s "${TIMEDELAY}" | cut -d '=' -f 2)
	echo "TIMEDELAY is ${TIMEDELAY}. Waiting "${TIMEDELAY}" seconds..."
	sleep "${TIMEDELAY}"
	echo "Wait finished. Proceeding with broadcast."
	TMPFILE=/tmp/itty-bcast.tmp
	TMPFILE2=/tmp/itty-bcast2.tmp

	#Add date/time, blank lines to allow for
	printf "\n\n\n\n" > "${TMPFILE}"
	#echo "ZCZC" >> "${TMPFILE}"
	#echo $(date +"%Y-%m-%d %H:%M %Z") >> "${TMPFILE}"
	#echo "-------" >> "${TMPFILE}"

	#Remove TIMEDELAY from file
	grep -v 'TIMEDELAY=' "${FILE}" > "${TMPFILE2}"

	#Format file to proper width
	fmt -usw 72 "${TMPFILE2}" >> "${TMPFILE}"

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
	TXWAIT=$(echo "${TXWAIT}/5.35" | bc)
	echo "Waiting for transmission to finish. Sleeping for ${TXWAIT} seconds..."
	#
	sleep "${TXWAIT}"
	echo "TX finished. Returning to RX mode..."
	perl fldigi-shell -u "http://${FLDIGI_HOST}:${FLDIGI_PORT}/2/RPC2" -c main.rx
done

echo "Set of scheduled broadcasts complete. Terminating process."
