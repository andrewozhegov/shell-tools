#!/bin/bash

CURRDIR="$(dirname `readlink -e "$0"`)"
WORKDIR=${1:-$CURRDIR}

exec &>"${WORKDIR}/words.log"
set -x

DB_DONE="${WORKDIR}/done.db"
DB_QUEUE="${WORKDIR}/queue.db"
TIMESPAN=300
INVOLVED_WORDS_N=10
PRIORITY_MAX=20

function get_from_line { echo $( awk 'NR == '$1' {print $'$2'}' "${DB}" ); }

function get_priority { echo `get_from_line $1 1`; }
function get_word     { echo `get_from_line $1 2`; }
function get_answer   { echo `get_from_line $1 3`; }

function set_priority
{
    local PRIORITY_N=`get_priority "$1"`
    sed -i ''$1's/'$PRIORITY_N'/'$2'/' "${DB}"
}

function ask_word
{
    WORD=`get_word $1`
    ANSW=`get_answer $1`

    [ `expr "$RANDOM" % 2` -eq 0 ] && read WORD ANSW <<<"$ANSW $WORD"
    [ "${ANSW}" == "$(kdialog --inputbox "Translate '$WORD':")" ] || {
        notify-send "Right answer is '${ANSW}'"
        return 1 
    }
}

function increase_priority
{
    local PRIORITY_N=`get_priority "$1"`
    set_priority "$1" "`expr $PRIORITY_N + $2`"
}

function words_count { echo `wc -l "$1" | awk '{print $1}'`; }

function add_from_queue
{
    [ `words_count "${DB_QUEUE}"` -eq 0 ] && return 1
    cat "${DB_QUEUE}" | awk 'NR == 1' >> ${DB}
    sed -i '1d' "${DB_QUEUE}"

    NEWLINE_N=`words_count "${DB}"`
    notify-send "New word '`get_word ${NEWLINE_N}`' transtaled as '`get_answer ${NEWLINE_N}`'"
}

function update_conf
{
    WEEK_DAY="$(date +%a | tr [:upper:] [:lower:])"
    DB="${WORKDIR}/words_${WEEK_DAY}.db"
    [ ! -f "${DB}" ] && touch "${DB}"

    while true ; do
        WORDS_COUNT="`words_count "${DB}"`"
        [ "$WORDS_COUNT" -ge "$INVOLVED_WORDS_N" ] && break
        add_from_queue || break
    done

    VALUES_SUM="$( cat "${DB}" | awk '{sum += $1} END {print sum}' )"
    sort -nr -k 1 -o "${DB}" "${DB}"
}

while true
do
    update_conf

    let "RAND = $RANDOM % $VALUES_SUM"
    [ "$RAND" -eq 0 ] && continue

    for ((N=1, PRIORITY_N=0, PRIORITY_FULL=0; N <= ${WORDS_COUNT}; N++)) ; do
        PRIORITY_N=`get_priority "$N"`
        [ "$PRIORITY_N" -gt "$PRIORITY_MAX" ] && set_priority "$N" "$PRIORITY_MAX"
        PRIORITY_FULL=`expr $PRIORITY_FULL + $PRIORITY_N`
        [ "$RAND" -le "$PRIORITY_FULL" ] && break
    done

    ask_word "$N" && {
        increase_priority "$N" "-1"
        [ "$PRIORITY_N" -eq 1 ] && {
            awk 'NR == '$N' {print $0}' "${DB}" >> "${DB_DONE}"
            sed -i ''$N'd' "${DB}"
        }
        sleep "$TIMESPAN"
    } || increase_priority "$N" "2"
done
