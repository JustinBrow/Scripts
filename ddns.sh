#!/bin/sh
hostname='hostname.ddns.example.com'
password='password'
ip=$(wget -q 'https://ifconfig.me/ip' -O -)
echo "DDNS: Current IPv6 address is $ip" >> /var/log/messages
if [[ $ip =~ '(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))' ]]; then
   aaaa=$(nslookup $hostname 'ns1.he.net' | awk '/^Address: / { print $2 }')
   echo "DDNS: Current dynamic IPv6 address is $aaaa" >> /var/log/messages
   if [ $aaaa != $ip ]; then
      echo "DDNS: Current dynamic IPv6 address does not match current IPv6 address" >> /var/log/messages
      echo "DDNS: Changing dynamic IPv6 address from $aaaa to $ip" >> /var/log/messages
      wget --post-data "hostname=$hostname&password=$password&myip=$ip" 'https://dyn.dns.he.net/nic/update' -O - >> /var/log/messages
   else
      echo "DDNS: Current dynamic IPv6 address matches current IPv6 address" >> /var/log/messages
   fi
fi
