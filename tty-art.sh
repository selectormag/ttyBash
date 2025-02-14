#!/bin/bash

# ITA2/Baudot-Murray printing
source ./tty-common
source "${1}"

#if [[ -n "${2}" ]]; then
	# This is being requested from the computer, not the loop

	
#fi

# Pause loop listener
touch /dev/shm/"${TTYNAME}".inuse

#asciiart -w 72 /home/teletype/Adobe-logo-1.png | grep -v "deprecated" |  tr '|' ' ' | tr '+' ' ' | tr '=' '"' | tr '~' ',' | tr 'o' '0' > /tmp/testingascii.tmp

ARTSEARCH=$(ls ./art/ | rmcr | grep -i "${2}")

debugprint "Art selection passed from loop listener is ${2}"
debugprint "ARTSEARCH is ${ARTSEARCH}|"

if [[ -z "${ARTSEARCH}" ]]; then
	ltrs
	echo "Art ${2} does not exist." > "${TTY}"
	sleep .5
	# Resume loop listener
	rm -vf /dev/shm/"${TTYNAME}".listlock
	# Reset TTY idle time
	touch /dev/shm/"${TTYNAME}".poweron
	#exit 1
else
	autocrlf off
	ltrs
	printf "\n\n\n" > "${TTY}"
	sflow "./art/${ARTSEARCH}"
	autocrlf on
	if [[ "${USEARTMSG}" == "TRUE" ]]; then
		# Only print the closing art message if so configured
		printf "\n\n" > "${TTY}"
		printf $(display_center "${ARTMSG}") > "${TTY}"
		printf "\n" > "${TTY}"
	fi
	printf "\n\n\n" > "${TTY}"
	bell "${ARTBELL}"
	sleep 1
fi

# Resume loop listener
rm -vf /dev/shm/"${TTYNAME}".inuse
