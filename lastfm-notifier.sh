#!/bin/bash

usage()
{
cat <<EOF
Usage: $0 <args>

Arguments:
    -u, --user         lastfm username
    -s, --scrobbles    scrobbles count to send notification (50000 as default)
    -m, --mp3          specify mp3 alert file

Example:
    $ $0 -u andrewozhegov -s 80000 -m ~/Documents/notify.mp3

EOF
}

APP_API_KEY="5e612db013450b4e282b84bd4ef3d9d7"
USER="andrewozhegov"
SCROBBLES="100000"

for arg in "$@" ; do
    case $arg in
        -h|--help)      usage; exit 0 ;;
        -u|--user)      shift; USER="$1"; shift ;;
        -s|--scrobbles) shift; SCROBBLES="$1"; shift ;;
        -m|--mp3)       shift; MP3="$1"; shift ;;
    esac
done

for pkg in mpg123 libnotify-bin curl jq ; do
    dpkg -s $pkg &>/dev/null ||
    echo "Package '$pkg' is required, but not found!"
done

while true
do
    current_count="$(
        curl -s "http://ws.audioscrobbler.com/2.0/?method=user.getinfo&user=$USER&api_key=$APP_API_KEY&format=json" | \
        jq -r '.user.playcount'
    )"

    [ -z "${current_count}" ] && continue

    echo "Scrobbles: ${current_count}"

    if [ "$current_count" -ne "${old_value:-0}" ]; then
        notify-send "Scrobbles: ${current_count}"
        old_value=$current_scrobbles_count
    fi


    sleep 60
done
