#!/bin/bash

# Opens up a TCP port and allows external network devices to communicate with teletype

# Initialize -- parse for all config files and enable TCP com for each device that is enabled

# Initialize listener


stty -icanon && tcpserver -v -RHl0 -c "${TCPMAXCON}" "${TCPHOST}" "${TCPPORT}" ./tty-tcp-listen.sh &


