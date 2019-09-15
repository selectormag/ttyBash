#!/bin/bash
# Listens for information from tty loop and then sends an email. What fun.

source ./tty-common

### FUNCTIONS BLOCK

#function addrecip () {
#}

# Pause loop listener
#touch /dev/shm/"${TTYNAME}".inuse
ttyinit

# Recipient prompt

# Loop to get recipients - keep adding more recipients until semicolon is not found at the end of the line

RECIPLIST=''
RECIPNUM=1
ISCOMPLETE='FALSE'

while [[ "${ISCOMPLETE}" != "TRUE" ]]; do
	ltrs

	# Print appropriate message depending on how many recipients we're adding
	if [[ "${RECIPNUM}" -eq 1 ]]; then
	       	ADDRPROMPT='Recipient address: '
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

	# Strip out semicolon for now and translate any codes to ASCII chars
	RECIPIENT=$(printf "%s" "${RECIPIENT}" | sed 's/;//g')
	RECIPIENT=$(chartoascii "${RECIPIENT}")

	# Validate email address; if good, move on. If bad, start this round over again.
	if [[ "${RECIPIENT}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,63}$ ]]; then
		debugprint "Address is valid: ${RECIPIENT}"
		RECIPLIST=$(printf "%s" "${RECIPLIST}" && echo "${RECIPIENT}")
		((RECIPNUM++))
	else
		debugprint "Invalid address: ${RECIPIENT}"
		ltrs
		absorb 'Invalid address. '
		ISCOMPLETE='FALSE'
	fi
done

# Subject prompt
ltrs
SUBJPROMPT='Subject: '
absorb "${SUBJPROMPT}"
read SUBJECT < "${TTY}"
SUBJECT=$(chartoascii "${SUBJECT}")
debugprint "Subject: ${SUBJECT}"

# Message body prompt
ltrs
MSGPROMPT="Enter message; type ${TERMCH} to send:"
absorb "${MSGPROMPT}"
printf "\n" > "${TTY}"
sleep .5
ltrs

# Get each line of message from loop, store it in temp file
TMPFILE=$(mktemp /dev/shm/ttymail.XXXXX)
COMPLETE="FALSE"
while [[ "${COMPLETE}" != "TRUE" ]]; do
	read LINE < "${TTY}"
	LINE=$(chartoascii "${LINE}")
	TERMCHK=$(echo "${LINE}" | grep "${TERMCH}")
	if [[ -n "${TERMCHK}" ]]; then
		# LINE contains the sequence of characters that should terminate the email, so terminate this loop
		#LINE=$(echo "${LINE}" | sed "s/${TERMCH}//g") # This will remove term chars from the last line, normally commented out
		COMPLETE="TRUE"
		debugprint "${TERMCH} found; end of message"
	fi
	echo "${LINE}" >> "${TMPFILE}"
	debugprint "MSG Line: ${LINE}"
done

# Prepare to send the mail
ltrs
printf "Sending... " > "${TTY}"
sleep 1 # For theatrics

# Parse recipient list and divide each address by comma
RECIPIENT=$(printf "%s" "${RECIPLIST}" | tr '\n' ',')

echo "This is the command for sending the mail: cat ${TMPFILE} email -s ${SUBJECT} -n ${FROM} -f ${FROMADDR} -tls -r ${SMTPSRV} -p ${SMTP_PORT} -m login -u ${SMTPUSR} -i [PASSWORD] ${RECIPIENT}"

# Send
if cat "${TMPFILE}" | email -s "${SUBJECT}" -n "${FROM}" -f "${FROMADDR}" -tls -r "${SMTPSRV}" -p "${SMTP_PORT}" -m login -u "${SMTPUSR}" -i "${SMTP_PASS}" "${RECIPIENT}"; then
	absorb " Sent!"
	printf "\n" > "${TTY}"
	sleep .5
	rm -f "${TMPFILE}"
else
	absorb " ERROR: Problem sending. Check log."
	printf "\n" > "${TTY}"
	sleep .5
fi

#sleep 3

# Resume loop listener
#rm -vf /dev/shm/"${TTYNAME}".inuse
ttyuninit
