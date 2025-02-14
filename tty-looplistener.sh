#!/bin/bash

# Listens for input from the loop and executes commands when one is received
# If no command is received for MAXIDLE seconds, cancel and go back to main loop
# When a command is received and processed successfilly, start over and wait for
# MAXIDLE seconds for another command, going back to main loop if none is 
# received. Repeat until a command is not received.

CONFIGFILE="${1}"

source ./tty-common

CONTINUE="FALSE"

debugprint "Configfile is ${1} - ${CONFIGFILE}, others are ${2} and ${3}"

while [[ "${CONTINUE}" == "FALSE" ]]; do
	#touch /dev/shm/"${TTYNAME}".inuse

	# Command prompt
	debugprint "Sending figs and absorbing $"
	figs
	absorb '$ '
	ltrs
	debugprint "Ready and listening for input on loop."
	# Wait X seconds for input (set in config-- same number of seconds as max idle time before TTY is shut off)
	read -t "${MAXIDLE}" LINE < "${TTY}"

	LINE=$(printf "%s" "${LINE}" | rmcr | rmlf)

	if [[ -n "${LINE}" ]]; then
		# If LINE is not null, try the following
		debugprint "Input received from ${TTYNAME}: ${LINE}|"
		if [[ "${LINE}" == " " ]]; then
			# It's just a blank space. Ignore.
			debugprint "LINE is an empty space. Moving on."
	        elif [[ "${LINE}" == *'SENDMAIL' ]]; then
	        	./tty-email-send.sh "${CONFIGFILE}"
			continue
	        elif [[ "${LINE}" == *'SENDSMS' ]]; then
	                ./tty-sms-send.sh "${CONFIGFILE}"
			continue
	        elif [[ "${LINE}" == *'ART'* ]]; then
	                ARTSEL=$(printf "%s" "${LINE}" | tr -s " " | cut -d " " -f 3)
			if [[ -z "${ARTSEL}" ]]; then
				ARTSEL=$(printf "%s" "${LINE}" | cut -d " " -f 2)
			fi
	        	./tty-art.sh "${CONFIGFILE}" "${ARTSEL}"
			continue
		elif [[ "${LINE}" == *'BROADCAST' ]]; then
			./tty-broadcast.sh "${CONFIGFILE}"
			continue
		elif [[ "${LINE}" == *'SSH' ]]; then
			./tty-ssh.sh "${CONFIGFILE}"
			continue
		elif [[ "${LINE}" == *'EXIT' ]]; then
			ttyctl "${TTYNAME}" off
		elif [[ "${LINE}" == *'WRITE' ]]; then
			./tty-write.sh "${CONFIGFILE}"
		elif [[ "${LINE}" == *'ITTY' ]]; then
			./tty-itty-receive.sh "${CONFIGFILE}"
		elif [[ "${LINE}" == *2* ]]; then
			bell 10
			./tty-fileprint.sh "${CONFIGFILE}" ./fooky.fooky
		else
	        	# Command from TTY didn't match any commands
	                debugprint "Command does not match existing commands."
			ltrs
			absorb "Command not found"
			printf "\n" > "${TTY}"
			sleep .5
	                continue
	        fi
	fi
	#rm -vf /dev/shm/"${TTYNAME}".inuse
	break
done
