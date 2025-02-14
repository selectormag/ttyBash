#!/bin/bash

# Sends SMS message from teletype

source ./tty-common

# Pause loop listener, turn on TTY
#touch /dev/shm/"${TTYNAME}".inuse
#ttyinit

# Recipient prompt
# Loop to get recipients - keep adding more recipients until semicolon is not found at the end of the line

RECIPLIST=''
RECIPNUM=1
ISCOMPLETE='FALSE'

while [[ "${ISCOMPLETE}" != "TRUE" ]]; do
	ltrs

	# Print appropriate message depending on how many recipients we're adding
	if [[ "${RECIPNUM}" -eq 1 ]]; then
	       	ADDRPROMPT='Recipient number: '
	else
		ADDRPROMPT="Recipient ${RECIPNUM}: "
	fi

	absorb "${ADDRPROMPT}"
	read RECIPIENT < "${TTY}"
	RECIPIENT=$(chartoascii "${RECIPIENT}")
	debugprint "Recipient #${RECIPNUM}: ${RECIPIENT}"

	# If there is a semicolon at the end of the line, we want to add another email address
	if [[ "${RECIPIENT}" =~ ^.*\;$ ]]; then
		debugprint "Semicolon found at end of line. User wants to add another recipient, so we must loop again."
		ISCOMPLETE='FALSE'
	else
		debugprint "Semicolon not found at end of line. We're done adding recipients."
		ISCOMPLETE='TRUE'
	fi

	# Strip out anything that's not a number for now
	RECIPIENT=$(printf "%s" "${RECIPIENT}" | sed 's/[^0-9]//g')

	# Validate phone number; if good, move on. If bad, start this round over again.
	if [[ "${RECIPIENT}" =~ ^[0-9]{10}$ ]]; then
		debugprint "Number is valid: ${RECIPIENT}"
		RECIPLIST=$(printf "%s\n%s" "${RECIPLIST}" "${RECIPIENT}")
		((RECIPNUM++))
	else
		debugprint "Invalid number: ${RECIPIENT}"
		ltrs
		absorb 'Invalid number. '
		ISCOMPLETE='FALSE'
	fi
done

# Message body prompt
ltrs
MSGPROMPT="Enter message; type ${TERMCH} to send:"
absorb "${MSGPROMPT}"
printf "\n" > "${TTY}"
sleep .5
ltrs

# Get each line of message from loop, store it in temp file
#TMPFILE=$(mktemp /dev/shm/ttysms.XXXXX)
MSG=''
COMPLETE="FALSE"
while [[ "${COMPLETE}" != "TRUE" ]]; do
	read LINE < "${TTY}"
	LINE=$(chartoascii "${LINE}")
	TERMCHK=$(echo "${LINE}" | grep "${TERMCH}")
	if [[ -n "${TERMCHK}" ]]; then
		# LINE contains the sequence of characters that should terminate the SMS, so terminate this loop
		#LINE=$(echo "${LINE}" | sed "s/${TERMCH}//g") # This will remove term chars from the last line, normally commented out
		COMPLETE="TRUE"
		debugprint "${TERMCH} found; end of message"
	fi
	MSG=$(printf "%s %s" "${MSG}" "${LINE}")
	debugprint "MSG Line: ${LINE}"
done

# Send the SMS

printf "Sending..." > "${TTY}"
sleep 1 # For theatrics

# It would be more efficient to use sendMultiple call, but too late
echo "${RECIPLIST}" | while read RECIPIENT; do
	curl -s "https://api.twilio.com/2010-04-01/Accounts/${TWIUSERID}/Messages.json" --data-urlencode "Body=${MSG}" --data-urlencode "From=${TWIFROMNUM}" --data-urlencode "To=${RECIPIENT}" -u "${TWIUSERID}":"${TWISECRET}"
	# Would be good to validate the response here to ensure it actually sent instead of blindly trusting, but putting it off
done

absorb " Sent!"
printf "\n" > "${TTY}"
sleep .5

# Resume loop listener
#rm -vf /dev/shm/"${TTYNAME}".inuse
ttyuninit
