#!/bin/bash

source ./tty-common

# Broadcast parameters are set in other config files; nothing to set up here. Just start broadcasting to specified fldigi server, which will in turn broadcast to the specified icecast/YouTube/whatever servers.

TMPFILE=$(mktemp /dev/shm/ttybcast.XXXXX)

# Need to wire this into the config file instead, but it will have to be hardwired for now
# Also need to write error handling, especially for if the SSH command returns negatively (times out, refused connection, bad creds, whatever)

debugprint "Initiating YouTube streaming service on remote machine..."
 
if ssh -v -o ConnectTimeout=10 -i "${BCASTKEY}" "${BCASTUSER}"@"${BCASTHOST}" "${REMOTE_BUTTPATH} > ttybcast.out 2>&1 < /dev/null & ${REMOTE_FLDIGIPATH} > ttybcast.out 2>&1 < /dev/null & ${REMOTE_FFMPEGPATH} -f avfoundation -framerate ${FRAMERATE} -i \"${VIDSTREAM}\" -vcodec libx264 -acodec aac -pix_fmt yuv420p -f flv rtmp://a.rtmp.youtube.com/live2/${YOUTUBEKEY} > tty-ytbcast.out 2>&1 < /dev/null &"; then
# Start streaming the rtty broadcast to YouTube
# https://apple.stackexchange.com/questions/166553/why-wont-video-from-ffmpeg-show-in-quicktime-imovie-or-quick-preview?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa

/usr/local/bin/ffmpeg -f avfoundation -framerate 30.000030 -i "default:0" -vcodec libx264 -acodec aac -pix_fmt yuv420p -f flv rtmp://a.rtmp.youtube.com/live2/69kz-4hka-91zz-aacc
	debugprint "SSH connection successful"
else
	debugprint "SSH connection not successful. Exiting." 
	absorb "ERROR with SSH connection"
	printf "\n" > "${TTY}"
	exit 1
fi

# Direct TTY stream to tmp file so multiple stream readers and pull from the file descriptor

#debugprint "Initializing temporary file descriptor..."

#"${TMPFILE}" < "${TTY}" &
#echo "${!}" | tee > /dev/shm/"${TTYNAME}"-bcast-tmp.pid

debugprint "Initializing remote fldigi transmitter..."
if perl fldigi-shell -u http://"${BCASTHOST}":"${FLDIGIPORT}"/RPC2 -c main.tx; then
	debugprint "fldigi command sueccessful"
else
	debugprint "fldigi command unsuccessful. Exiting."
	absorb "ERROR with fldigi connection"
	printf "\n" > "${TTY}"
	ssh if ssh -v -o ConnectTimeout=10 -i "${BCASTKEY}" "${BCASTUSER}"@"${BCASTHOST}" "pkill fldigi butt ffmpeg"
	exit 1
fi

debugprint "Initializing fldigi text stream..."
#Put tty into raw mode
stty -F "${TTY}"
cat "${TTY}" | tee "${TMPFILE}" | perl fldigi-shell -u http://"${BCASTHOST}":"${FLDIGIPORT}"/RPC2 -c sendchar &
#echo $(jobs -x echo %1 %2 %3) > /dev/shm/"${TTYNAME}"-bcast.pid
KILLLIST=$(jobs -x echo %1 %2 %3)
debugprint "PIDs that will be killed: ${KILLLIST}"

CONTINUE="FALSE"
while [[ "${CONTINUE}" == "FALSE" ]]; do

	TERMCHK=$(grep "${TERMCH}" "${TMPFILE}")

	if [[ -n "${TERMCHK}" ]]; then
		CONTINUE="TRUE"
		debugprint "Broadcast finished"
	else
		debugprint "Broadcast still ongoing. Will check again."
	fi

	sleep 5
done

debugprint "Cleaning up background processes, transmitter, and stream..."

#KILLLIST=$(cat /dev/shm/"${TTYNAME}"-bcast.pid | tr '\n' ' ')
kill "${KILLLIST}"
#rm -vf /dev/shm/"${TTYNAME}"-bcast.pid
perl fldigi-shell -u http://"${BCASTHOST}":"${FLDIGIPORT}"/RPC2 -c main.rx
# Reset tty from raw mode
source tty-common
rm -vf "${TMPFILE}"
ssh -v -o ConnectTimeout=10 -i "${BCASTKEY}" "${BCASTUSER}"@"${BCASTHOST}" "pkill fldigi butt ffmpeg"

debugprint "Cleanup finished."

