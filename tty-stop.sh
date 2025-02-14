#!/bin/bash

# Stops all tty services as gracefully as possible (TODO: add more grace to this in the future)

TTYNAME="${1}"

# Get PIDs
#LOOPLISTENER=$(cat /dev/shm/"${TTYNAME}"-looplistener.pid)
FLDIGI=$(cat /dev/shm/"${TTYNAME}"-itty-main.pid)
SWITCHBOARD=$(cat /dev/shm/"${TTYNAME}"-switchboard.pid)
MAIN=$(cat /dev/shm/"${TTYNAME}"-main.pid)
OTHERS=$(cat /dev/shm/"${TTYNAME}"-action.pid)

#printf "Stopping loop listener..."
#kill "${LOOPLISTENER}"
#rm -f /dev/shm/tty-looplistener.pid
#echo " Stopped."
printf "Stopping fldigi process..."
kill "${FLDIGI}"
echo "Stopped."
printf "Stopping switchboard loop..."
kill "${SWITCHBOARD}"
rm -f /dev/shm/tty-switchboard.pid
echo " Stopped."
printf "Stopping main loop..."
kill "${MAIN}"
rm -f /dev/shm/tty-main.pid
echo " Stopped."

rm -f /dev/shm/*

echo "Cleaned up tmp files."

#printf "Stopping remaining TTY actions, if any..."
#kill "${OTHERS}"
rm -f /dev/shm/tty-action.pid
#echo " Stopped."
