#!/bin/bash

# Fetches mail meant for teletype printing, parses it, and sends it to the teletype
# TODO: 
# Trap CTRL+C and perform cleanup functions
# Implement email index so a teletype operator can type in an index number to send a response rather than each recipient's email address and the subject
# 

source ./tty-common

printf "%s" "${BASHPID}" > /dev/shm/"${TTYNAME}"-action.pid

### FUNCTION DECLARATIONS ###

# Function for stripping everything outside of the message body
function stripbody () {
	# This assumes that the email body is separated from the garbage at the beginning and end of the raw file by blank lines
	declare IN=${*:-$(</dev/stdin)}
	printf "%s" "${IN}" | # Initial input
	sed '/./,$!d;s/--[a-zA-Z0-9_\-]\{15,\}//g;1,/^$/d' | # Removes any leading blank lines, strips out Outlook/Gmail delimiters, and removes content before first blank line
	tac | # Reverses lines so the next sed command will work
	sed '/./,$!d;1,/^$/d' | # Removes any leading blank lines, then removes everything before the first blank line (because of tac, this removes any TAILING blank lines and removes everything AFTER the LAST blank line)
	tac | # Reverses the line order back to normal
	egrep -vi "Content-Type: |Content-Transfer-Encoding: |Content-ID: " #Strips out unneeded MIME information
}

# Function for translating UTF8 characters encoded in a weird way to regular characters (some mail clients do this). This is in no way a comprehensive list as that would be ages long. These are the most likely to be used. If I come across other UTF8 characters encoded in weird ways more commonly, I may add them.
function weirdutf8 () {
	declare IN=${*:-$(</dev/stdin)}
	# Whitespace; more whitespace; yet more whitespace; hyphens; single-quotes; double-quotes; bullet points; another bullet point; single dot; double dot; ellipsis;
	printf "%s" "${IN}" | sed 's/=20/ /g;s/=E2=80=8./ /gI;s/=E2=80=A[8-9A-F]/ /gI;s/=E2=80=9[0-7]/\-/gI;s/=E2=80=9[8-9A-B]/\x27/gI;s/=E2=80=9[C-F]/"/gI;s/=E2=80=A[0-3]/\-/gI;s/=E2=80=A7/-/gI;s/=E2=80=A4/\./gI;s/=E2=80=A5/\.\./gI;s/=E2=80=A6/\.\.\./gI'
}

# Function for cleaning up message body
function cleanbody () {
	declare IN=${*:-$(</dev/stdin)}
	# Sed command as follows: removes lines starting with > (forwards/replies); removes "On ... wrote:" lines and everything below it as sometimes that can still get left behind; removes HTML and other XML-like tags; removes anything between brackets [ ] (some mail clients embed links and other non-TTY-friendly content between brackets); removes = (no space after) at line endings; removes plain =[space] at line endings (some mail clients do this)
	printf "%s" "${IN}" | sed '/^>/d;/On .\{31,\} wrote:/,$d;s/<[^>]\+>/ /g;s/\[[^>]\+\]//g;s/=$//g;s/= $//g' | weirdutf8
}

### NOW, FOR THE MAIN EVENT ###

# Download most recent message, if any
echo "Checking for new mail..."
fetchmail

# Verify there is a message waiting
MAILSIZE=$(du -b /var/mail/"${TTYUSER}" | awk '{print $1}')
if [[ "${MAILSIZE}" == 0 ]]; then
	debugprint "No messages waiting to be printed. Exiting."
	exit 0
fi

# Check to see if printer is being actively used; if so, go into wait loop until printer is free; if not, print message
#if [[ -f /dev/shm/"${TTYNAME}".inuse ]]; then
#        debugprint "Printer ${TTYNAME} is in active use. Waiting in line to print this message..."
#        INUSE='TRUE'
#        while [[ "${INUSE}" == "TRUE" ]]; do
#                if [[ ! -f /dev/shm/"${TTYNAME}".inuse ]]; then
#                        debugprint "Printer ${TTYNAME} is no longer in use. Printing message..."
#                        INUSE='FALSE'
#                        break
#                fi
#        done
#fi

# Pause loop listener
#touch /dev/shm/"${TTYNAME}".listlock

# Create main tmp file
TMPFILE=$(mktemp /dev/shm/tty-mail-fetch.XXXXX)
# Add separation line header
echo "----------" > "${TMPFILE}"
# Parse out desired header information (from, date, subject)
cat /var/spool/mail/"${TTYUSER}" | egrep "From: |Date: |Subject: " | sed 's/<//g;s/>//g' | cleanbody | chartotty >> "${TMPFILE}"
echo >> "${TMPFILE}"

# Temp Lisalove stuff

#ISLOVE=$(grep "THIS MARRIAGE" "${TMPFILE}")

# Parse out message body; check whether it is base64-encoded
BASE64=$(cat /var/spool/mail/"${TTYUSER}" | sed '/--[a-zA-Z0-9_]\{15,\}/,$!d' | sed '1d;/--[a-zA-Z0-9_]\{15,\}/,$d' | grep -i "Content-Transfer-Encoding: base64")

# If base64-encoded, clean up garbage, decode message body, and send to tmpfile; else clean up garbage and send to tmpfile
CLEANTMP=$(mktemp /dev/shm/tty-mail-fetch-cleaner.XXXXX)
if [[ -n ${BASE64} ]]; then
	echo "Message body is encoded in base64. Cleaning up output and decoding..."
	cat /var/spool/mail/"${TTYUSER}" | stripbody | base64 -d | cleanbody | linepress > "${CLEANTMP}"
	#cat /var/spool/mail/"${TTYUSER}" | sed '/--[a-zA-Z0-9_\-]\{15,\}/,$!d' | sed '/Content-/d;1d;/--[a-zA-Z0-9_\-]\{15,\}/,$d' | base64 -d | sed '/^>/d;s/<[^>]\+>/ /g;s/\[[^>]\+\]//g;s///g' > "${CLEANTMP}"
	# Sed contortions as follows:
	# First: strips out headers before body
	# Second: Strips out Content-type and such that define the body; also strips out the beginning body delimiter; also strips out the b64-encoded garbage after the body, including attachments
	# [b64 decoding]
	# Third: Strips out lines starting with >, which are almost always forward/reply lines; also strips out HTML and other XML-like tags; also strips out anything between [ ] brackets; also strips out carriage returns
else
	echo "Message body is not encoded in base64. Cleaning up output..."
	cat /var/spool/mail/"${TTYUSER}" | stripbody | cleanbody | linepress > "${CLEANTMP}"
	#cat /var/spool/mail/"${TTYUSER}" | sed '/--[a-zA-Z0-9_\-]\{15,\}/,$!d' | sed '/Content-/d;1d;/--[a-zA-Z0-9_\-]\{15,\}/,$d;/^>/d;s/<[^>]\+>/ /g;s/\[[^>]\+\]//g;s///g;/^>/d' >> "${CLEANTMP}"
	# Sed contortions as follows:
	# First: strips out headers before body
	# Second: Strips out Content-type and such that define the body; also strips out the beginning body delimiter; also strips out the b64-encoded garbage after the body;also strips out lines starting with >, which are almost always forward/reply lines; also strips out HTML and other XML-like tags; also strips out anything between [ ] brackets; also strips out carriage returns
fi

# Clear email file so we're clean and ready for the next one to come in
> /var/spool/mail/"${TTYUSER}"

# Replace special characters for Baudot-Murray charset whilst removing superfluous line feeds with cat -s
MSG=$(cat -s "${CLEANTMP}" | chartotty)

# Format message to properly page width and save it to its final temp file
printf "%s" "${MSG}" | fmt -usw "${WIDTH}" >> "${TMPFILE}"

# Turn on TTY/loop
#ttyctl on

ttyinit

# Ensure the machines on the loop are in the corrcet shift
#printf "%s" "${FIGSCHAR}" > "${TTY}"
bell "${EMAILBELL}"
figs

# Print message out on teletype
#debugprint "THIS IS WHAT WAS SENT TO ${TTY}:"
#cat "${TMPFILE}"

# Take alternate course if certain email is received.
#if [[ -n "${ISLOVE}" ]]; then
#	        debugprint "Email is for Lisa! Taking alternate course of action."
#	cat ./art/ttylove > "${TMPFILE}"
#fi

if [[ "${USETG}" == "TRUE" ]]; then
	# Send text to remote telegraph apparatus, not including headers
	echo "${MSG}" | nc "${TGHOST}" "${TGPORT}" -w0 &
fi

sflow "${TMPFILE}"

sleep 5

# Cleanup
ttyuninit
rm -vf "${TMPFILE}" "${CLEANTMP}"

rm -vf /dev/shm/tty-action.pid
