#!/bin/sh

# This script tracks and counts clients on the network. Devices that turn out
# to be persistent, such as servers, will be omitted from being counted.

# Count devices that are less than 8 hours old
DEVICE_AGE_HOURS=8

# Interface name, e.g. "eth0"
IF_NAME=""

# Device list source "neigh", "nmap" or "dhcp"
DEVICE_SOURCE="neigh"

###############################################################################

if [ -z "$DEVICE_AGE_HOURS" ]; then
  echo "$0: DEVICE_AGE_HOURS is empty." >&2
  exit 1
fi

# lines of "<dev_id> <first_seen> <last_seen>""
db_file="/tmp/guest_counter.db"
now=$(date +%s)
age=$((now - 60 * 60 * DEVICE_AGE_HOURS))
old_entries="$(cat $db_file 2> /dev/null)"
new_entries=""
dev_ids=""
count=0
NL="
"

case "$DEVICE_SOURCE" in
  "dhcp")
    # Fetch list of current MAC addresses from DHCP lease file
    dev_ids="$(cat /var/lib/dhcpd/dhcpd.leases | awk '!/^(\$|#)/{printf("%17s\n", $2)}' | tr ' ' '_')"
    ;;
  "neigh")
    # Fetch list of current MAC addresses from neighbor list cache
    dev_ids="$(ip neigh show ${IF_NAME:+dev IF_NAME} | cut -s -d' ' -f5)"
    ;;
  "nmap")
    if [ -z "$IF_NAME" ]; then
      echo "$0 IF_NAME not set. Needed for nmap." >&2
      exit 1
    fi

    # Fetch list of current IP addresses via ping scan
    net=$(ip -4 a l dev $IF_NAME} | awk '/inet/{print($2)}')
    dev_ids=$(nmap -n -sn $net -oG - | awk '/Up$/{printf("%17s\n", $2)}' | tr ' ' '_')
    ;;
  *)
    echo "$0: DEVICE_SOURCE ($DEVICE_SOURCE) is invalid." >&2
    exit 1;
    ;;
esac

handle_entry() {
  local dev_id=$1
  local first_seen=${2:-$now}
  local last_seen=${3:-$now}

  IFS="$NL"
  for line in $old_entries; do
    if [ "$dev_id" = "${line:0:17}" ]; then
      last_seen=$now
      break
    fi
  done

  # Only handle present devices
  if [ ${#dev_id} -eq 17 -a $last_seen -eq $now ]; then
    # Only count active devices that are younger than a certain age
    if [ $first_seen -gt $age ]; then
      count=$((count + 1))
    fi

    # Append entry as line
    new_entries+="$dev_id $first_seen $last_seen$NL"
  fi
}

# Split by newline
IFS="$NL"
for entry in $((echo "$dev_ids"; echo "$old_entries";) | sort -r | uniq -w 17)
do
  # Split by space
  IFS=" "
  handle_entry $entry
done

# Backup entries for next call
echo -n "$new_entries" > $db_file

echo $count

exit 0
