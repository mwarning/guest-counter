# Guest Counter

A script to count guests in your network. Excludes devices that are persistent like servers or routers.
This can be used as a public counter for your network, e.g. to indicate home many people are in the office. 

Put `count_guests.sh` somewhere on your gateway and call it every few minutes.

This cronjob entry for `/etc/crontab` will call the script every 5 minutes and write the number of guests to `/tmp/guests.txt`:

```
*/5 * * * * /usr/sbin/guest_counter.sh > /tmp/guests.txt
```

The script maintains a database in `/tmp/guest_counter.db` to track all devices.

Counted are devices that are online for less than 8 hours.
That is why you have to let the script run for that time to be able to exclude servers and routers from being counted as guests.
Devices that has not been seen for 12 hours, will be removed from the database entirely.
These values are configurable.
