# Guest Counter

A script to count guests in your network. Exludes devices that are persistent like servers or routers.
This can be used as a public counter for your network, e.g. to indicate home many people are in the office. 

Put `count_guests.sh` somewhere on your gateway and call it every few minutes.

This cronjob entry will call the script every 5 minutes and write the number of guest to `/tmp/guests.txt`:

```
*/5 * * * * /usr/sbin/guests.sh | wc -l > /tmp/guests.txt
```

The script maintains a database in `/tmp/devices.txt` to track all devices.

Guest devices are not online for more than 8 hours straight.
Devices that has not been seen for 12 hours, will be removed from the database.
