# Guest Counter

A script to count guests in your network. Excludes devices that are persistent like servers or routers.
This can be used as a public counter for your network, e.g. to indicate home many people are in the office. 

Put `count_guests.sh` somewhere on your gateway and call it every few minutes.

This cronjob entry for `/etc/crontab` will call the script every 5 minutes and write the number of guests to `/tmp/guests.txt`:

```
*/5 * * * * /usr/sbin/guest_counter.sh > /tmp/guests.txt
```

The script maintains a database in `/tmp/guest_counter.db` to track all devices.

## Options

Options can be set at the top of the script.

* `DEVICE_AGE_HOURS`  
  Count devices that are less than n hours old.  
  Default: 8

* `DEVICE_TIMEOUT_HOURS`  
  Timeout devices that are more than n hours old.  
  Default: 12

* `IF_NAME`  
  Interface name. E.g. `eth0`.  
  Default: 12

* `DEVICE_SOURCE`  
  Source for the list of devices on the network. `neigh` for neighbor cache like ARP. `nmap` for network scanning or `dhcp` for reading the DHCP lease file.  
  Default: nmap

## Notes

The script has to be run at least `DEVICE_AGE_HOURS` hours to be able to exclude servers and routers from being counted as guests.
