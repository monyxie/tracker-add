#!/bin/bash
# Get transmission credentials, if set
if [[ -n "$TRANSMISSION_USER" && -n "$TRANSMISSION_PASS" ]]; then
    auth="${TRANSMISSION_USER:-user}:${TRANSMISSION_PASS:-password}"
else
    auth=
fi
host=${TRANSMISSION_HOST:-192.168.1.168}
list_url=${TRACKER_URL:-https://gitee.com/harvey520/www.yaozuopan.top/raw/master/blacklist.txt}

add_trackers () {
    torrent_hash=$1
    tracker_list=$2
    echo -e "Adding trackers for \e[91m$torrent_name..."
    for tracker in $tracker_list ; do
        echo -ne "\e[93m*\e[0m ${tracker}..."
        if transmission-remote "$host" ${auth:+--auth="$auth"} --torrent "${torrent_hash}" -td "${tracker}" | grep -q 'success'; then
            echo -e '\e[92m done.'
            echo -en "\e[0m"
        else
            echo -e '\e[93m already added.'
            echo -en "\e[0m"
        fi
    done
}

# Get list of active torrents
ids=${1:-"$(transmission-remote "$host" ${auth:+--auth="$auth"} --list | tail -n +2 | grep -vE 'Seeding|Stopped|Finished' | grep '^ ' | awk '{ print $1 }')"}
# Get list of trackers
trackers=""
newline=$'\n'
for base_url in "${list_url}" ; do
    trackers="$trackers$newline$(curl -sL "${base_url}")"
done

# Remove empty lines
trackers=$(echo "$trackers" | grep -vE '^$')

for id in $ids ; do
    hash="$(transmission-remote "$host" ${auth:+--auth="$auth"}  --torrent "$id" --info | grep '^  Hash: ' | awk '{ print $2 }')"
    torrent_name="$(transmission-remote "$host" ${auth:+--auth="$auth"}  --torrent "$id" --info | grep '^  Name: ' |cut -c 9-)"
    add_trackers "$hash" "$trackers"
done
