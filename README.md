# Network Guest Counter

A script to count clients on your network but omits persistent devices such as servers or routers.
This can be used as a public counter for your network, e.g. to indicate home many people are in the office.
Counted are devices that are in the network for less that a given amount of hours.

Put `count_guests.sh` somewhere on your gateway and call it every few minutes.

This cronjob entry for `/etc/crontab` will call the script every 5 minutes and write the number of guests to `/tmp/guests.txt`:

```
*/5 * * * * /usr/sbin/guest_counter.sh > /tmp/guests.txt
```

The script maintains a database in `/tmp/guest_counter.db` to track all devices.

## Options

Options can be set at the top of the script.

* `DEVICE_AGE_HOURS`  
  Count devices are on the network for less than n hours.  
  Default: 8

* `IF_NAME`  
  Network interface name. E.g. `eth0`.  
  Default: none

* `DEVICE_SOURCE`  
  Source for the list of devices on the network.  
  Default: `neigh`
  * `neigh` for using neighbor cache like ARP.
  * `nmap` to scan an entire network behind `IF_NAME`.
  * `dhcp` for reading a DHCP lease file.

## Notes

The script has to be run at least `DEVICE_AGE_HOURS` hours to be able to exclude servers and routers from being counted as guests.
