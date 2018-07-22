#!/bin/sh

# This script tracks and counts clients on the network. Devices that turn out
# to be persistent, such as servers, will be omitted from being counted.

# Count devices that are less than 8 hours old
DEVICE_AGE_HOURS=8

# Timeout devices that are more than 12 hours old
DEVICE_TIMEOUT_HOURS=12

# Interface name, e.g. "eth0"
IF_NAME=""

# Device list source "neigh", "nmap" or "dhcp"
DEVICE_SOURCE="neigh"

###############################################################################

if [ $DEVICE_AGE_HOURS -ge $DEVICE_TIMEOUT_HOURS ]; then
  echo "$0: DEVICE_AGE_HOURS ($DEVICE_AGE_HOURS) must be lower or equal DEVICE_TIMEOUT_HOURS ($DEVICE_TIMEOUT_HOURS)" >&2
  exit 1
fi

# lines of "<dev_id> <first_seen> <last_seen>""
db_file="/tmp/guest_counter.db"
now=$(date +%s)
age=$((now - 60 * 60 * DEVICE_AGE_HOURS))
timeout=$((now - 60 * 60 * DEVICE_TIMEOUT_HOURS))
old_entries="$(cat $db_file 2> /dev/null)"
new_entries=""
dev_ids=""
count=0


case "$DEVICE_SOURCE" in
  "dhcp")
    # Fetch list of current MAC addresses from DHCP lease file
    dev_ids="$(cat /var/lib/dhcpd/dhcpd.leases | cut -s -d' ' -f2)"
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
  local multiple=$1
  local dev_id=$2
  local first_seen=${3:-$now}
  local last_seen=${4:-$now}

  if [ $multiple -ne 1 ]; then
    last_seen=$now
  fi

  # Only handle devices that did not timeout and the device id is as long as a MAC address
  if [ $last_seen -gt $timeout -a ${#dev_id} -eq 17 ]; then
    # Only count active devices that are younger than a certain age
    if [ $last_seen -eq $now -a $first_seen -gt $age ]; then
      count=$((count + 1))
    fi

    # Append entry
    new_entries+="$dev_id $first_seen $last_seen
"
  fi
}

# Split by newline
IFS="
"

for entry in $((echo "$dev_ids"; echo "$old_entries";) | sort -r | uniq -c -w 17)
do
  # Split by space
  IFS=" "

  handle_entry $entry
done

# Backup entries for next call
echo -n "$new_entries" > $db_file

echo $count

exit 0
