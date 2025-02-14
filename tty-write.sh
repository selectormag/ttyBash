#!/bin/bash

# Allows a user to freewrite as long as he likes with then option to save the output to a file

source ./tty-common

printf "%s" "${BASHPID}" > /dev/shm/"${TTYNAME}"-action.pid

### FUNCTION DECLARATIONS ###

# None at this time

ttyinit

absorb "Write as long as you wish. Type ${TERMCH} to finish." > "${TTY}"

TMPFILE=$(mktemp ./files/ttymail.XXXXX)

while [[ "${COMPLETE}" != 'TRUE' ]]; do
	read LINE < "${TTY}"
	debugprint "Raw line is ${LINE}"
	LINE=$(chartoascii "${LINE}")
	TERMCHK=$(echo "${LINE}" | grep "${TERMCH}")
	        if [[ -n "${TERMCHK}" ]]; then
		COMPLETE='TRUE'
		debugprint "${TERMCH} found; end of message"
	fi
	echo "${LINE}" >> "${TMPFILE}"
	debugprint "Line: ${LINE}"
done

# Ask if the file should be saved

absorb "Do you wish to save? (Y/N): " > "${TTY}"
read -p SAVE

if [[ "${SAVE}" == "Y" ]]; then
	absorb "Specify filename: "
	read -p FILENAME > "${TTY}"
	mv -v "${TMPFILE}" >> "./files/${FILENAME}"
	printf "Saved.\n" > "${TTY}"
fi

ttyuninit
