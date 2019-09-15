#!/bin/bash

# Converts ASCII to ITA2

INPUT="${1}"

#INPUT="The quick brown horse jumped over the laughing river"

UPPR="${INPUT^^}"

# Changes to FIGS, prints characters, and shifts back to LTRS whenever a FIGS character is detected
# Uses tr to replace all linefeeds with a backtick since sed struggles with linefeed detection
FIGLTR=$(printf "%s" "${UPPR}" | sed 's/[0-9\!\(\)?:;.,\x27\/"#\$&-]\+/\x1B&\x1F/g' | tr '\n' '`')
OUTPUT="${FIGLTR}"
# Sed commands as follows: E, [line feed - converts to LF and CR], A, [space], S, I, U, [carriage return], D, R, J, N, F, C, K, T, Z, L, W, H, Y, P, Q, O, B, G, M, Z, V
OUTPUT=$(printf "${FIGLTR}" | sed 's/E/\x01/g; s/`/\x02\x08/g; s/A/\x03/g; s/ /\x04/g; s/S/\x05/g; s/I/\x06/g; s/U/\x07/g; s/\r/\x08/g; s/D/\x09/g; s/R/\x0A/g; s/J/\x0B/g; s/N/\x0C/g; s/F/\x0D/g; s/C/\x0E/g; s/K/\x0F/g; s/T/\x10/g; s/Z/\x11/g; s/L/\x12/g; s/W/\x13/g; s/H/\x14/g; s/Y/\x15/g; s/P/\x16/g; s/Q/\x17/g; s/O/\x18/g; s/B/\x19/g; s/G/\x1A/g; s/M/\x1C/g; s/X/\x1D/g; s/V/\x1E/g; s/3/\x01/g; s/-/\x03/g; s/8/\x06/g; s/7/\x07/g; s/\$/\x09/g; s/4/\x0A/g; s/\x27/\x0B/g; s/,/\x0C/g; s/\!/\x0D/g; s/:/\x0E/g; s/(/\x0F/g; s/5/\x10/g; s/"/\x11/g; s/)/\x12/g; s/2/\x13/g; s/#/\x14/g; s/6/\x15/g; s/0/\x16/g; s/1/\x17/g; s/9/\x18/g; s/?/\x19/g; s/\&/\x1A/g; s/\./\x1C/g; s/\//\x1D/g; s/\;/\x1E/g; s/°//g')

printf "%s" "${OUTPUT}" > /dev/ttyUSB0
