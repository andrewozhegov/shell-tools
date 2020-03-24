#!/bin/sh

DEVICE_N=${1:-4}
DATASET_SIZE=${2:-2226}

deviceID=0 ; while [ $deviceID -lt $DEVICE_N ]; do
    from=$(( ($DATASET_SIZE / $DEVICE_N) * $deviceID + 1 ))
    to=$(( ($DATASET_SIZE / $DEVICE_N) * ($deviceID + 1) ))
    tmpfile="$(mktemp)"
    awk -v deviceID=$deviceID -v from=$from -v to=$to '{
        if (!match($0,"selectImages")) {
            if (match($0,"graph_id")) $2="10"deviceID;
            if (match($0,"device_id")) $2="\""deviceID"\"";
            print $0;
            next;
        } else {
            print $0; getline;
            list=from;
            for (i=++from; i<=to; i++) {
                list=list","i
            };
            $2="\""list"\"";
            print $0
        }
    }' graph.config > "$tmpfile"
    mv "$tmpfile" './graph'$deviceID'.config'
    deviceID=$(( deviceID + 1 ))
done
