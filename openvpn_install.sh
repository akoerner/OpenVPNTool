#!/bin/bash

#This script installs and configures OpenVPN with a basic configuration.  Tested on Ubuntu Server 16.04 LTS use on other distributions at your own risk.

#This script is basically an automation compilation of the following resources:
#https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-14-04
#https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-16-04
#http://www.tutorialspoint.com/articles/how-to-set-up-openvpn-on-ubuntu-16-04

#Usage: openvpn_install.sh -n "<server name>"  -i "<interface>"

#Note: this defaults to AES-128-CBC which according to BSI recommendations of 2015 is still cryptographically secure see https://www.keylength.com/.

#########################
# The command line help #
#########################
display_help() {
    echo "Usage: $0 -n <server name>  -i <interface>"
    echo "Must be run as root."
    echo "   -n, --server-name           name of the openvpn server.  This will be used to generate key files."
    echo "   -i, --interface             interface to bind to e.g., eth0"
    echo
    # echo some stuff here for the -a or --add-options 
    exit 1
}

################################
# Check if parameters options  #
# are given on the command line#
################################
while :
do
    case "$1" in

      -h | --help)
          display_help
          exit 0
          ;;
      -n | --server-name)
          SERVER_NAME="$2"
          shift 2
          ;;
      -i | --interface)
          INTERFACE="$2"
           shift 2
           ;;

      --) # End of all options
          shift
          break
          ;;
      -*)
          echo "Error: Unknown option: $1" >&2
          ## or call function display_help
          exit 1 
          ;;
      *)  # No more options
          break
          ;;
    esac
done

#Root check
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

################################
# Install/Configure            #
# OpenVPN Server               #
################################

echo "Hold onto your butts: Installing and configuring OpenVPN Server..."

LISTEN_ADDRESS=$(ip addr | grep inet | grep $INTERFACE | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
SERVER_CONFIG_FILE="/etc/openvpn/server.conf"

#Update System
apt-get update

#Install Dependencies
apt-get install openvpn easy-rsa
service openvpn stop

#Copy example config to opevpn dir
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > $SERVER_CONFIG_FILE

#Modify example config
sed -i 's|;local a.b.c.d|local '$LISTEN_ADDRESS'|' $SERVER_CONFIG_FILE
sed -i 's|dh dh1024.pem|dh /etc/openvpn/dh2048.pem|' $SERVER_CONFIG_FILE
sed -i 's|dh dh2048.pem|dh /etc/openvpn/dh2048.pem|' $SERVER_CONFIG_FILE
sed -i 's|ca ca.crt|ca /etc/openvpn/easy-rsa/keys/ca.crt|' $SERVER_CONFIG_FILE
sed -i 's|cert server.crt|cert /etc/openvpn/easy-rsa/keys/'$SERVER_NAME'.crt|' $SERVER_CONFIG_FILE
sed -i 's|key server.key|key /etc/openvpn/easy-rsa/keys/'$SERVER_NAME'.key|' $SERVER_CONFIG_FILE
sed -i 's|;tls-auth ta.key|tls-auth /etc/openvpn/ta.key|' $SERVER_CONFIG_FILE
sed -i 's|;cipher AES-128-CBC |cipher AES-128-CBC|' $SERVER_CONFIG_FILE

#DNS Settings
sed -i 's|;push "redirect-gateway def1 bypass-dhcp"|push "redirect-gateway def1 bypass-dhcp"|' $SERVER_CONFIG_FILE
sed -i 's|;push "dhcp-option DNS 208.67.222.222"|push "dhcp-option DNS 208.67.222.222"|' $SERVER_CONFIG_FILE
sed -i 's|;push "dhcp-option DNS 208.67.220.220"|push "dhcp-option DNS 208.67.220.220"|' $SERVER_CONFIG_FILE


sed -i 's|;user nobody|user nobody|' $SERVER_CONFIG_FILE
sed -i 's|;group nogroup|group nogroup|' $SERVER_CONFIG_FILE

#Enable Packet Forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
sysctl -p

#Make Firewall rule
ufw allow 1194/u
ufw allow proto tcp from any to any port 1194

sed -i 's|DEFAULT_FORWARD_POLICY="DROP"|DEFAULT_FORWARD_POLICY="ACCEPT"|'  /etc/default/ufw

UFW_RULES="
# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0] 
# Allow traffic from OpenVPN client
-A POSTROUTING -s 10.8.0.0/8 -o $INTERFACE -j MASQUERADE
COMMIT
# END OPENVPN RULES
"

if grep -q "OPENVPN" /etc/ufw/before.rules
then
    echo "ufw rules already exist skipping insert..."
else
    #Insert rules at line 10 of /etc/ufw/before.rules
    echo "ufw rules not found inserting..."
    head -n10 /etc/ufw/before.rules >> /etc/ufw/before.rules.bak
    echo "$UFW_RULES" >> /etc/ufw/before.rules.bak
    tail -n +10 /etc/ufw/before.rules >> /etc/ufw/before.rules.bak
    mv /etc/ufw/before.rules /etc/ufw/before.rules.default
    mv /etc/ufw/before.rules.bak /etc/ufw/before.rules

fi

#Enable firewall
echo "reenabling firewall via ufw for rules to take effect..."
ufw disable && ufw enable
ufw status verbose

#Build Certificate Authority
cp -r /usr/share/easy-rsa/ /etc/openvpn

mkdir /etc/openvpn/easy-rsa/keys

INSERT="export KEY_NAME=\"$SERVER_NAME\""
sed -i '70i '"$INSERT"'' /etc/openvpn/easy-rsa/vars

#Generate Diffie-Hellman parameters
rm /etc/openvpn/dh2048.pem
openssl dhparam -out /etc/openvpn/dh2048.pem 2048
rm /etc/openvpn/ta.key
openvpn --genkey --secret /etc/openvpn/ta.key

cd /etc/openvpn/easy-rsa
. ./vars
./clean-all
./build-ca
./build-key-server $SERVER_NAME

#Start Openvpn
echo "Starting Openvpn Server"
service openvpn stop
service openvpn start
service openvpn status

#Check openvpn port
echo "netstat openvpn port 1194:"
netstat -l | grep 1194

