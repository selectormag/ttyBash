#!/bin/bash
# Initializes all necessary processes and exits

echo "Initializing TTY services."

# Verify config file defined in command line parameters (TODO: Test to ensure there is a parameter, that the file exists, and that it contains all necessary definitions)
echo "Defined config file is ${1}"

source "${1}"

# Initialize switchboard loop
if [[ "${1}" == "./tty1-config" ]]; then
	./tty-switchboard.sh "${1}" >> "${2}" &
	echo "${!}" | tee > /dev/shm/"${TTYNAME}"-switchboard.pid
fi

# Initialize main watch loop
./tty-main.sh "${1}" >> "${2}" & 
echo "${!}" | tee > /dev/shm/"${TTYNAME}"-main.pid

echo "Informatica: 1 is ${1}, 2 is ${2}, 3 is ${3}"

# Initialize loop listener loop
#./tty-looplistener.sh "${1}" >> "${2}" &
#echo "${!}" > /dev/shm/"${TTYNAME}"-looplistener.pid

echo "Initialization finished."
