#!/bin/bash

function status {
	oneg="$(onegate service show | grep undefined)"
	if [ -z "$oneg" ]; then
		feature=$1
		status="$2"
		onegate vm update $VMID --data "$feature"_STATUS="$status"
	else
		echo "Onegate is not configured"
	fi
}

function info {
	one="$(onegate service show | grep undefined)"
	if [ -z "$one" ]; then
		feature=$1
		#note="${2// /_}"
		note="$2"
		onegate vm update $VMID --data "$feature"_INFO="$note"
	else
		echo "Onegate is not configured"
	fi
}

function check {
	var="$1"
	feat=$2
	if [ "$var" = "text" ]; then
		echo ""
		onegate vm update $VMID --data "$feat"=" "
	else
		echo "$var"
	fi

}
