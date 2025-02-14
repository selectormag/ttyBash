#!/bin/bash

# Runs some test stuff through the TTY-USB adapter

source ./tty-common ttytest-config

OlFIGS="\x1E"
OlLTRS="\x1F"
OlAUTOCLI="\x16"

#TTY="/dev/ttyACM1"

while true; do
	echo -e "\n\n\n\n----------------------------------------------------\n"
	read -p "Press ENTER when ready for basic test."
	echo "Initiating basic test..."
	ttyinit
	ltrs
	echo "The quick brown fox jumps over the lazy dog 0123456789;:'\"()-&\!,." > "${TTY}"
	read -p "Press ENTER when ready to execute FIGS test."
	echo "Initiating FIGS test..."
	figs
	read -p "Press ENTER when ready to execute LTRS test."
	echo "Initiating LTRS test..."
	ltrs
	read -p "Press ENTER when ready for the TELETYPE MARCH"
	bell 3
	printf "." > "${TTY}"
	bell 1
	printf "." > "${TTY}"
	bell 1
	printf "." > "${TTY}"
        bell 3
        printf "." > "${TTY}"
        bell 1
        printf "." > "${TTY}"
        bell 1
	printf "." > "${TTY}"
        bell 3
        printf "." > "${TTY}"
        bell 1
        printf "." > "${TTY}"
        bell 1
        printf "." > "${TTY}"
        bell 1
        printf "." > "${TTY}"
	bell 2
	printf "." > "${TTY}"
	bell 2
	printf "........" > "${TTY}"
	bell 1
	printf "." > "${TTY}"
	bell 3
	printf "." > "${TTY}"
	bell 1
	printf "..." > "${TTY}"
	bell 1
	printf "." > "${TTY}"
	bell 1
	echo > "${TTY}"
	read -p "Press ENTER when ready for AUTOCLI test."
	echo "Initiating AUTOCLI test..."
	echo -e "${AUTOCFG}" > "${TTY}"
	read -t 3 < "${TTY}"
	read -t 3 RESULT < "${TTY}"
	if [[ -n "${RESULT}" ]]; then 
		echo "AUTOCLI test passed. Result: ${RESULT}"
		echo "exit" > "${TTY}"
	else
		echo "AUTOCLI test failed. No result."
	fi
	read -t 1 < "${TTY}"
	read -t 1 < "${TTY}"
	read -t 1 < "${TTY}"
	read -p "Press ENTER when ready for the receive test."
	echo "Initiating receive test..."
	echo "PLEASE TYPE A FEW THINGS TO TEST RECEIVE AND ENTER LF+CR:"
	read -t 45 RESULT2 < "${TTY}"
	echo "This is what you typed: ${RESULT2}"
	#read -p "Press ENTER when ready for send test."
	#echo "Initiating send test..."
	# Do manual crap here for Remington to play
	ttyuninit
	ttyctl off
	echo "TEST COMPLETE"
done
