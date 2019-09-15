#!/bin/bash

read ENCRYPTED

echo "The deciphered message is:"

printf "%s" "${ENCRYPTED}" | base64 -d | openssl rsautl -decrypt -inkey /home/teletype/.ssh/morsekob
