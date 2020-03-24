#!/bin/sh

DEVICE_N=${1:-4}

deviceID=0 ; while [ $deviceID -lt $DEVICE_N ]; do
    tmpfile="$(mktemp)"
    awk -v deviceID=$deviceID '{
        if (match($0,"graph_id")) $2="10"deviceID;
        if (match($0,"device_id")) $2="\""deviceID"\"";
        print $0;
        next;
    }' graph.config > "$tmpfile"
    mv "$tmpfile" './graph'$deviceID'.config'
    deviceID=$(( deviceID + 1 ))
done
