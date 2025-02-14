#!/bin/bash

	TMPFILE="${1}"
        TXWAIT=$(cat "${TMPFILE}" | wc -c)
        SPACES=$(grep -o ' '  "${TMPFILE}" | wc -l)
        FIGSCHARS=$(grep -o '[0-9]\|[$!?,.:;"'\''-()$&/]' | wc -l)
        TXWAIT=$(( TXWAIT + SPACES + FIGSCHARS ))
        TXWAIT=$(echo "${TXWAIT}/5.33" | bc)

	echo "Timewait is ${TXWAIT}"
