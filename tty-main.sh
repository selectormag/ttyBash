#!/bin/bash
# Main ttybash program that ties everything else together

source ./tty-common
source "${1}"

# Main loop; watches for incoming messages/requests and responds accordingly
# TODO: Add way to catch exit request and gracefully do so

EXIT='false'
trap 'EXIT=true' SIGUSR1

if [[ "${USEITTY}" == 'TRUE' ]]; then
	debugprint "Initializing ITTY loop..."
	#./tty-itty-receive.sh ${1} > ./tty1.log &
	debugprint "Initializing background fldigi-shell text stream..."
	perl fldigi-shell -u "http://${ITTY_HOST}:${ITTY_PORT}/2/RPC2" -c text.clear_rx
	perl fldigi-shell -u "http://${ITTY_HOST}:${ITTY_PORT}/2/RPC2" -c poll > /dev/shm/"${TTYNAME}"-itty.rx &
	echo "${!}" > /dev/shm/"${TTYNAME}"-itty-main.pid
	debugprint "fldigi-shell stream initialized."
fi

debugprint "Initializing main loop..."

while [[ "${EXIT}" != "true" ]]; do
	# Check the queue for TTY selection
	INQUEUE=$(ls /dev/shm/"${TTYNAME}".selected 2> /dev/null)
	if [[ -n "${INQUEUE}" ]]; then
		debugprint "A request to manually use ${TTYNAME} has been submitted. Preparing..."
		rm -vf /dev/shm/"${TTYNAME}".selected
		ttyctl on
		./tty-looplistener.sh "${1}"
	fi

	# Check for email
	if [[ "${USEEMAIL}" == "TRUE" ]]; then
		./tty-email-fetch.sh "${1}"
	fi

	# Check for SMS
	if [[ "${USESMS}" == "TRUE" ]]; then
		debugprint "USESMS is ${USESMS}"
		./tty-sms-fetch.sh "${1}"
	fi

	# Check for ITTY
	if [[ "${USEITTY}" == 'TRUE' ]]; then
		./tty-itty-receive.sh "${1}"
	fi

	# Check for TCP
	# if tcp waiting file exists, remove wait file to allow connection

	# Check for RSS
	# ./tty-rss-fetch.sh "${1}"

	# Check for idleness
	ONTIME=$(ls --full-time /dev/shm/"${TTYNAME}".poweron 2> /dev/null | awk '{print $6 " " $7}')
	OTCHAR=$(echo "${ONTIME}" | wc -m)
	debugprint "ONtime is ${ONTIME}| and contains ${OTCHAR} characters."
	ONTIME=$(date +%s --date "${ONTIME}")
	debugprint "ONtime date is ${ONTIME}"
	CTIME=$(date +%s)
	debugprint "Ctime is ${CTIME}"
	IDLETIME=$((CTIME - ONTIME))
	if [[ "${OTCHAR}" -le 1 ]]; then
		debugprint "OTCHAR has a zero or one length value, meaning TTY has already been turned off."	
	elif [[ "${IDLETIME}" -ge "${MAXIDLE}" ]]; then
		# Loop has been running idle for too long; SHOOT 'ER!
		debugprint "TTY has been idle for ${IDLETIME} seconds, which is greater than max idle of ${MAXIDLE} seconds. Executing TTY shutdown..."
		ttyctl off
	fi

	# Throttle the loop to avoid hitting email provider, SMS provider, or RSS provider request limits
	sleep "${LOOPIDLE}"
done
