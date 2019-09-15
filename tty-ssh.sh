#!/bin/bash

# Interface between a teletype current loop and an SSH session
# Because who doesn't want to do sysadmin work on a ~90 year old
# machine with a charset that's all-caps plus change?

source ./tty-common

ttyinit

# Get connection info

while [[ "${ISGOOD}" != "TRUE" ]]; do
	ltrs
	absorb "Hostname/IP: "
	read REMHOST < "${TTY}"
	REMHOST=$(chartoascii "${REMHOST}")
	debugprint "REMHOST is ${REMHOST}"
	if [[ "${REMHOST}" == "EXIT" ]]; then
		debugprint "Exit has been requested. Exiting."
		exit 0
	fi

	debugprint "REMHOST2 is ${REMHOST}"

	CHKIP=$(echo "${REMHOST}" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
	debugprint "CHKIP is ${CHKIP}"

	if [[ -n "${CHKIP}" ]]; then
		debugprint "Input ${REMHOST} appears to be an IP address. Moving on."
		break
	else
		debugprint "Input ${REMHOST} does not appear to be an IP address; must be a hostname."
		CHKHOST=$(host "${REMHOST}" | grep "not found")
		if [[ -z "${CHKHOST}" ]]; then
			debugprint "Hostname ${REMHOST} resolves. Moving on."
			break
		else
			debugprint "Hostname ${REMHOST} does not resolve. Asking again."
			absorb "Host does not resolve or IP not recognized. "
		fi
	fi
done

absorb "Port: "
figs
read REMPORT < "${TTY}"
REMPORT=$(chartoascii "${REMPORT}")
ltrs
absorb "Username: "
read REMUSER < "${TTY}"
REMUSER=$(chartoascii "${REMUSER,,}")

#absorb "Use pubkey? (Y/*N) "
#read USEKEY < "${TTY}"

#if [[ "${USEKEY}" == "Y" || "${USEKEY}" == "YES" ]]; then
#	debugprint "Using public key."
#	absorb "Pubkey name: "
#	read KEYNAME < "${TTY}"
#	if [[ -f "${PUBKEYSPATH}/${KEYNAME}" ]]; then
#	       debugprint "Specified key ${KEYNAME} exists. Moving on."
#	       SSHCOMMAND="ssh -i ${PUBKEYSPATH}/${KEYNAME} ${REMUSER}@${REMHOST} -p ${REMPORT}"
#       else
#	       debugprint "Specified key ${KEYNAME} does NOT exist. Using password instead."
#	       absorb "Pubkey ${KEYNAME} does not exist. Password: "
#	       read REMPASS < "${TTY}"
#	       SSHCOMMAND="ssh ${REMUSER}@
#else
#	debugprint "Not using public key."
#	absorb "Password: "
#	read REMPASS < "${TTY}"

#fi
ltrs
absorb "Specify key: "
read KEYNAME < "${TTY}"
KEYNAME=$(chartoascii "${KEYNAME}")

if [[ -f "${PUBKEYSPATH}/${KEYNAME}" ]]; then
	debugprint "Specified key ${KEYNAME} exists. Moving on."
	SSHCOMMAND="ssh -i ${PUBKEYSPATH}/${KEYNAME} ${REMUSER}@${REMHOST} -p ${REMPORT}"
else
	debugprint "Specified key ${KEYNAME} does NOT exist."
	absorb "Key not found. Exiting."
	exit 1
fi

# Put some logic here to validate that a remote connection can be made

while [[ "${EXIT}" != "TRUE" ]]; do
	# Print prompt
	absorb "$) "
	ltrs
	debugprint "Ready and listening for input on commandline."
	read COMMAND < "${TTY}"
	COMMAND=$(printf "%s" | awk '{$1=$1};1' | rmcr | rmlf | chartoascii | sshize)
	if [[ "${COMMAND}" = " exit" ]]; then
		EXIT='TRUE'
		printf "\n" > "${TTY}"
		break
	fi
	# Execute command, capture output
	COMMRESPONSE=$(ssh -o "StrictHostKeyChecking no" -i "${PUBKEYSPATH}"/"${KEYNAME}" "${REMUSER}"@"${REMHOST}" -p "${REMPORT}" "${COMMAND}")
	debugprint "SSH output is ${COMMRESPONSE}"
	COMMRESPONSE=$(printf "%s" "${COMMRESPONSE}" | desshize | chartotty)
	absorb "${COMMRESPONSE}"
	printf "\n" > "${TTY}"
	sleep .5	
done

ttyuninit
