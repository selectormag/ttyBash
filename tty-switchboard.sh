#!/bin/bash
# Watches for input from the manual switchboard and responds accordingly

source "${1}"
source tty-common

# Initialize GPIO pins
debugprint "Initializing switchboard..."
gpio -g mode "${CONTROLOUT1}" out && debugprint "Controlout1: ${CONTROLOUT1}"
gpio -g mode "${CONTROLOUT2}" out && debugprint "Controlout2: ${CONTROLOUT2}"
gpio -g mode "${CONTROLIN1}" in && debugprint "Controlin1: ${CONTROLIN1}"
gpio -g mode "${CONTROLIN2}" in && debugprint "Controlin2: ${CONTROLIN2}"
gpio -g write "${CONTROLOUT1}" 1
gpio -g write "${CONTROLOUT2}" 1

# Function to turn on a TTY
function ttyinit () {
	touch /dev/shm/"${1}".selected
	debugprint "${1} switch selected; added to queue."
}

# Switch board loop
debugprint "Initializing switchboard loop..."
EXIT='false'
trap 'EXIT=true' SIGUSR1

while [[ "${EXIT}" != "true" ]]; do
	LOOP1CTL=$(gpio -g read "${CONTROLIN1}")
	LOOP2CTL=$(gpio -g read "${CONTROLIN2}")

	CHKNUM=1
	while [[ "${LOOP1CTL}" -eq 1 && "${LOOP2CTL}" -eq 1 ]]; do
		# Both switches have been selected; hold and watch to ensure the user wishes to shut down
		debugprint "Shutdown signal potentially received. Checking to verify this is what the user wants. PASS ${CHKNUM}"
		if [[ "${CHKNUM}" -ge 10 ]]; then
			debugprint "The user has clearly specified to shut down. Doing so now."
			sudo shutdown now
			EXIT='true'
		fi
		((CHKNUM++))
		sleep 1
		LOOP1CTL=$(gpio -g read "${CONTROLIN1}")
		LOOP2CTL=$(gpio -g read "${CONTROLIN2}")
		if [ "${LOOP1CTL}" -eq 0 ] || [ "${LOOP2CTL}" -eq 0 ] ; then	
			debugprint "The user has released both switches and apparently wants to turn both TTYs on."
			ttyinit tty1 
			ttyinit tty2
			break
		fi
	done
	if [[ "${LOOP1CTL}" -eq 1 ]]; then
		# Switch to engage TTY1 selected; add request to queue
		ttyinit tty1
	elif [[ "${LOOP2CTL}" -eq 1 ]]; then
		# Switch to engage TTY2 selected; add request to queue
		ttyinit tty2
	else
		# Nothing to see here. Move along
		:
	fi	
done
