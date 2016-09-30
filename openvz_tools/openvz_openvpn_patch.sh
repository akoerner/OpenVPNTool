#!/bin/bash

#This is a patch that allows the openvpn service to run in an openvz container.  This script is specifically for Ubuntu 16.04 LTS.
#Run it at your own peral on other distros. In order for the system.d service you have to do this little post install patch to
#get the service to run.  Run the script as root to apply the patch.  
#More info at: http://askubuntu.com/questions/747023/systemd-fails-to-start-openvpn-in-lxd-managed-16-04-container

if [ "$1" == "-h" ]; then
  echo "Usage: run the script as root to apply the patch"
  exit 0
fi

#Root check
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#Begin Patch
echo "Applying Openvz openvpn service patch..."
sed -i 's|LimitNPROC=10|#LimitNPROC=10|' /lib/systemd/system/openvpn@.service
systemctl daemon-reload
service openvpn start
service openvpn status
#End Patch
