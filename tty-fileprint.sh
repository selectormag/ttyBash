#!/bin/bash

# Basically a testing utility to print a file-- must be called from host comptuer command line, not from teletype (yet)

# Usage: tty-fileprint.sh <tty-config> <filepath>, e.g. ./tty-fileprint.sh tty1-config foo.bar

source ./tty-common

debugprint "Initiating file print..."
#autocrlf off
ttyinit
ltrs
sflow "${2}"
printf "\n\n\n\n" > "${TTY}"
ttyuninit
#autocrlf on
debugprint "Fileprint complete."
