#!/bin/bash
# Fetches SMS messages to print out on teletype
# TODO: If the script is interrupted, allow for it to pick up where it left off, meaning that if a message was retrieved but never actually printed (power outage, script killed, &c), it will print it before grabbing more messages. Right now it uses a random tmp file, so these rare cases would lose messages to the aether.

source tty-common

PREVTF='./tty-sms-lastcall.db'
MSGARCHIVE='./tty-sms-msgarchive.db'

#touch "${MSGARCHIVE}"

# Get the time that the last fetched message was sent
#if [[ -e "${PREVTF}" ]]; then
#	debugprint "Previous fetch time DB file exists. Checking time..."
#else
#	debugprint "This appears to be the first time this program has run, or you deleted the previous fetch time DB file. Creating..."
#	MTIME=$(TZ="GMT" date +"%Y-%m-%dT%H:%M:%SZ")
#	echo "${MTIME}" > "${PREVTF}"
#fi
#RAWPREVTIME=$(head -n 1 "${PREVTF}")
#debugprint "PREVTIME raw is ${RAWPREVTIME}"
#PREVTIME=$(TZ="GMT" date +"%Y-%m-%dT%H:%M:%SZ" --date '1 second ago '"${RAWPREVTIME}" | sed 's/T/\%20/;s/Z//')
#debugprint "PREVTIME translated is ${PREVTIME}"

# Fetch new messages, if any

#FOUTPUT=$(curl -s -X GET "https://api.catapult.inetwork.com/v1/users/${USERID}/messages?direction=in&fromDateTime=${PREVTIME}" -u "${TOKEN}":"${SECRET}" -H "Content-type: application/json" | jq '.[] | "\(.from)::\(.time)::\(.messageId)::\(.text)"' | tac)

FOUTPUT=$(curl -s -X GET "https://api.twilio.com/2010-04-01/Accounts/${TWIUSERID}/Messages.json?PageSize=5" -u "${TWIUSERID}":"${TWISECRET}" | jq '.messages[] | "\(.body)::\(.direction)::\(.from)::\(.uri)::\(.date_sent)"' | grep inbound)

debugprint "FOUTPUT is ${FOUTPUT}"

if [[ -z "${FOUTPUT}" ]]; then
	debugprint "No output from fetch request. Exiting."
	# Resume loop listener
	rm -vf /dev/shm/"${TTYNAME}".listlock
	exit 0
fi

# Turn on TTY/loop
#ttyctl "${TTYNAME}" on

TMPFILE=$(mktemp /dev/shm/ttysms.XXXXX)

# Parse each message and add to output if it has not yet been printed; not the most efficient loop, but it ensures all messages always get printed, and only once
while read -r LINE; do
	debugprint "LINE is ${LINE}"
	LINE=$(echo "${LINE}" | sed 's/^"//; s/"$//; s/\\n/ /g') # Remove quotes, newlines from output
	# Used to remove + for some reason: ;s/+//g
	FROM=$(echo "${LINE}" | awk -F "::" '{print $3}')
	STIME=$(echo "${LINE}" | awk -F "::" '{print $5}')
	MSGID=$(echo "${LINE}" | awk -F "::" '{print $4}')
	MSG=$(echo "${LINE}" | sed 's/\\"/"/g' | awk -F "::" '{print $1}' | chartotty)
	
	# Double check that this is an inbound message and not an outbound message that includes the word "inbound"
	DIRECTION=$(echo "${LINE}" | awk -F "::" '{print $2}')
	if [[ "${DIRECTION}" != "inbound" ]]; then 
		# Message is NOT inbound - skipping
		debugprint "Message is ${DIRECTION}-- will not print"
		continue
	fi

	debugprint "FROM is ${FROM}"
	debugprint "STIME is ${STIME}"
	debugprint "MSGID is ${MSGID}"
	debugprint "MSG is ${MSG}"

	# Verify whether this message has already been printed
	ISPRINTED=$(grep "${MSGID}" "${MSGARCHIVE}")

	debugprint "ISPRINTED is ${ISPRINTED}|"

	if [[ -n "${ISPRINTED}" ]]; then
		# Message has already been printed; ignore
		debugprint "Message id ${MSGID} has already been printed. Skipping."
		continue
	else
		debugprint "Message id ${MSGID} has not yet been printed. Adding to output..."
		
		# Format sent time to local computer time, human-friendly
		HTIME=$(date +"%Y-%m-%d %H:%M:%S %Z" --date "${STIME}")
		debugprint "HTIME is ${HTIME}"

		# Obfuscate phone number for privacy (useful in public settings)
		if [[ "${OBFUSCATE}" == 'TRUE' ]]; then
			FROM=$(echo "${FROM}" | sed -r 's/^(.{0})(.{7})/\1XXXXXXX/')
		fi

		# Add message to output
		echo "----------" >> "${TMPFILE}"
		echo "At ${HTIME}, ${FROM} said:" | fmt -usw "${WIDTH}" >> "${TMPFILE}"
		echo "${MSG}" | fmt -usw "${WIDTH}" >> "${TMPFILE}"
		# Add record of message printed to archive
		echo "${MSGID}::${HTIME}" >> "${MSGARCHIVE}"
		# Add time of last sent message to time log file, overwriting previous time
		#echo "${STIME}" > "${PREVTF}"
	fi
done <<< "${FOUTPUT}"

# If any, print out collected message(s)
SMSSIZE=$(du -b "${TMPFILE}" | awk '{print $1}')
if [[ "${SMSSIZE}" == 0 ]]; then
	debugprint "No messages waiting to be printed. Exiting."
	rm -vf "${TMPFILE}"
	exit 0
fi

ttyinit

# Turn on TTY/loop
#ttyctl "${TTYNAME}" on

# Check to see if printer is being actively used; if so, go into wait loop until printer is free; if not, print message
#if [[ -f /dev/shm/"${TTYNAME}".inuse ]]; then
#	debugprint "Printer ${TTYNAME} is in active use. Waiting in line to print this message..."
#	INUSE='TRUE'
#	while [[ "${INUSE}" == "TRUE" ]]; do
#		if [[ ! -f /dev/shm/"${TTYNAME}".inuse ]]; then
#			debugprint "Printer ${TTYNAME} is no longer in use. Printing message..."
#			INUSE='FALSE'
#			break
#		fi
#	done
#fi

# Print messages
#touch /dev/shm/"${TTYNAME}".inuse
bell "${SMSBELL}"
figs

if [[ "${USETG}" == "TRUE" ]]; then
	        # Send text to remote telegraph apparatus
		        cat "${TMPFILE}" | nc "${TGHOST}" "${TGPORT}" -w0 &
fi

sflow "${TMPFILE}"


# Cleanup
ttyuninit
rm -vf "${TMPFILE}"

# Clean up old message entries from the archive; anything older than 5 seconds older than the previously received message prior to this session is ancient history as far as we're concerned
#debugprint "STIME is ${STIME}"
#NUKTIME=$(date +%s --date '5 seconds ago '"${RAWPREVTIME}")
#cat "${MSGARCHIVE}" | while read LINE; do
#	OLDTIME=$(echo "${LINE}" | awk -F "::" '{print $2}')
#	MSGID=$(echo "${LINE}" | awk -F "::" '{print $1}')
#	OLDTIME=$(date +%s --date "${OLDTIME}")
#	debugprint "MSGID is ${MSGID}; NUKTIME is ${NUKTIME}; OLDTIME is ${OLDTIME}"
#	if [[ "${NUKTIME}" -gt "${OLDTIME}" ]]; then
#		debugprint "Message ID ${MSGID} is older than cutoff time. Deleting..."
#		sed -i "/${MSGID}/d" "${MSGARCHIVE}"
#	fi
#done

sleep 5
