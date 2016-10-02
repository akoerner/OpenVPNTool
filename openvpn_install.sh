#!/bin/bash

#This script installs and configures OpenVPN with a basic configuration.  Tested on Ubuntu Server 16.04 LTS use on other distributions at your own risk.

#This script is basically an automation compilation of the following resources:
#https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-14-04
#https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-16-04
#http://www.tutorialspoint.com/articles/how-to-set-up-openvpn-on-ubuntu-16-04


#Note: this defaults to AES-128-CBC which according to BSI recommendations of 2015 is still cryptographically secure see https://www.keylength.com/.

#########################
# The command line help #
#########################
display_help() {
    echo
    echo "Basic Usage: $0 -n <server name>  -i <interface> -F"
    echo
    echo "MUST be run as root."
    echo
    echo "Required"
    echo "   -i, --interface                 interface to bind to e.g., eth0.  This is used to build the server.conf and for making ufw rules."
    echo "                                   Takes the interface identifier as argument."
    echo "Optional"
    echo "   -n, --server-name               name of the openvpn server.  This will be used to generate key files as well as build the server.conf."
    echo "                                   If no name is provided then the script will default to \"server\". Takes servername as argument."
    echo "   -F, --full-install              This enables a full install. All flags are executed -I, -B, -P, -U, -R and -S.  A full install entails installing" 
    echo "                                   openvpn via apt-get, building a server config, enabling port forwarding, inserting ufw rules,"
    echo "                                   restarting ufw(so the added rules take effect), building the certificate authority and generating keys,"
    echo "                                   and finally starting the openvpn service. Takes no arguments."
    echo "   -I, --install-openvpn           This simply installs openvpn and its dependencies via apt-get. Takes no arguments."
    echo "   -B, --build-server-config-file  This builds server config. Optionally, you can provide an output file with the -o flag otherwiseTakes no arguments."
    echo "                                   the output file defaults to: /etc/openvpn/server.conf."
    echo "   -o, --server-config-output-file Optional output file for the generated server config default is: /etc/openvpn/SERVERNAME.conf. Takes filename as argument."
    echo "   -P, --enable-packet-forwarding  Enables packet forwarding via sysctl. Takes no arguments."
    echo "   -U, --modify-ufw-rules          Modifies ufw for enabling packet forwarding and pass-through. Takes no arguments."
    echo "   -R, --reload-ufw                Reloads ufw so that modified rules take effect. Takes no arguments."
    echo "   -C, --build-ca                  Generates crypto keys via easy-rsa and builds the certificate authority."
    echo "   -S, --start-openvpn-server      Starts the openvpn system d service."
    echo "   -s, --silent-mode               If this flag is provided then the key generation will run without user interaction. All inputs"
    echo "                                   will be set to their default. Takes no arguments."
    echo "   -h                              help"
    echo
    echo "Example"
    echo
    echo "   sudo sh openvpn_install -n SomeServer -i eth0 -F"
    echo "                                   This does a full install setting the server name to SomeServer and binding to eth0"
    echo 
    # echo some stuff here for the -a or --add-options 
    exit 1
}

################################
# Default Parameters           #
#                              #
################################
KEY_DIRECTORY="/etc/openvpn/easy-rsa/keys/"
OPENVPN_DIRECTORY="/etc/openvpn/"
SERVER_NAME="server"
AES_CIPER="128"

INSTALL_OPENVPN=false
BUILD_SERVER_CONFIG_FILE=false
ENABLE_PACKET_FORWARDING=false
MODIFY_UFW_RULES=false
RELOAD_UFW=false
BUILD_CA=false
START_OPENVPN_SERVER=false
SILENT_MODE=true

################################
# Check if parameters options  #
# are given on the command line#
################################
if [ $# -eq 0 ]; then
    display_help
fi

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
      -o | --server-config-output-file)
          SERVER_CONFIG_OUTPUT_FILE="${2:-/etc/openvpn/server.conf}"
           shift 2
           ;;
      -F | --full-install)
          INSTALL_OPENVPN=true
          BUILD_SERVER_CONFIG_FILE=true
          ENABLE_PACKET_FORWARDING=true
          MODIFY_UFW_RULES=true
          REENABLE_UFW=true
          BUILD_CA=true
          START_OPENVPN_SERVER=true
          shift 1
           ;;
      -I | --install-openvpn)
          INSTALL_OPENVPN=true
          shift 1
           ;;
      -B | --build-server-config-file)
          BUILD_SERVER_CONFIG_FILE=true
          shift 1
           ;;
      -P | --enable-packet-forwarding)
          ENABLE_PACKET_FORWARDING=true
          shift 1
           ;;
      -U | --modify-ufw-rules)
          MODIFY_UFW_RULES=true
          shift 1
           ;;
      -R | --reload-ufw)
          RELOAD_UFW=true
          shift 1
           ;;
      -C | --build-ca)
          BUILD_CA=true
          shift 1
           ;;
      -S | --start-openvpn-server)
          START_OPENVPN_SERVER=true
          shift 1
           ;;
      -s | --silent-mode)
          SILENT_MODE=true
          shift 1
           ;;
      --) # End of all options
          shift
          break
          ;;
      -*)
          echo "Error: Unknown option: $1" >&2
          display_help
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

if [ -z "${SERVER_CONFIG_OUTPUT_FILE}" ]; then 
    SERVER_CONFIG_OUTPUT_FILE=$OPENVPN_DIRECTORY/$SERVER_NAME.conf
fi

install_openvpn() {
echo "Hold onto your butts: Installing OpenVPN Server..."
#Update System
apt-get update

#Install Dependencies
apt-get install openvpn easy-rsa
service openvpn stop
}

build_server_config_file() {

if [ -z "${INTERFACE}" ]; then 
    >&2 echo  "Invalid Arguments: An interface to listen on must provided"
    exit 128; 
else
    LISTEN_ADDRESS=$(ifconfig $INTERFACE | awk -F ' *|:' '/inet addr/{print $4}')

fi

echo
echo "Building Configuration File Outputting to: $SERVER_CONFIG_OUTPUT_FILE"
echo "Setting server name to: $SERVER_NAME"
echo "Listen Interface set to: $INTERFACE"
echo "Setting server to listen on: $LISTEN_ADDRESS"
echo


#Copy example config to opevpn dir
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > $SERVER_CONFIG_OUTPUT_FILE

DH_PEM_FILE="${OPENVPN_DIRECTORY}dh2048.pem"
CA_CRT_FILE="${KEY_DIRECTORY}ca.crt"
CA_KEY_FILE="${KEY_DIRECTORY}ca.key"
SERVER_CRT_FILE="$KEY_DIRECTORY$SERVER_NAME.crt"
SERVER_KEY_FILE="$KEY_DIRECTORY$SERVER_NAME.key"
TA_KEY_FILE="${OPENVPN_DIRECTORY}ta.key"
CIPHER="AES-$AES_CIPER-CBC"

echo
echo "DH pem file: $DH_PEM_FILE"
echo "CA cert file: $CA_CRT_FILE"
echo "CA key file: $CA_KEY_FILE"
echo "Server crt file: $SERVER_CRT_FILE"
echo "Server key file: $SERVER_KEY_FILE"
echo "TA key file: $TA_KEY_FILE"
echo "Cipher: $CIPHER"
echo

#Modify example config
sed -i 's|;local a.b.c.d|local '$LISTEN_ADDRESS'|' $SERVER_CONFIG_OUTPUT_FILE
sed -i 's|dh dh1024.pem|dh '$DH_PEM_FILE'|' $SERVER_CONFIG_OUTPUT_FILE
sed -i 's|dh dh2048.pem|dh '$DH_PEM_FILE'|' $SERVER_CONFIG_OUTPUT_FILE
sed -i 's|ca ca.crt|ca '$CA_CRT_FILE'|' $SERVER_CONFIG_OUTPUT_FILE
sed -i 's|cert server.crt|cert '$SERVER_CRT_FILE'|' $SERVER_CONFIG_OUTPUT_FILE
sed -i 's|key server.key|key '$SERVER_KEY_FILE'|' $SERVER_CONFIG_OUTPUT_FILE
sed -i 's|;tls-auth ta.key|tls-auth '$TA_KEY_FILE'|' $SERVER_CONFIG_OUTPUT_FILE
sed -i 's|;cipher AES-128-CBC |cipher '$CIPHER'|' $SERVER_CONFIG_OUTPUT_FILE

#DNS Settings
sed -i 's|;push "redirect-gateway def1 bypass-dhcp"|push "redirect-gateway def1 bypass-dhcp"|' $SERVER_CONFIG_OUTPUT_FILE
sed -i 's|;push "dhcp-option DNS 208.67.222.222"|push "dhcp-option DNS 208.67.222.222"|' $SERVER_CONFIG_OUTPUT_FILE
sed -i 's|;push "dhcp-option DNS 208.67.220.220"|push "dhcp-option DNS 208.67.220.220"|' $SERVER_CONFIG_OUTPUT_FILE


sed -i 's|;user nobody|user nobody|' $SERVER_CONFIG_OUTPUT_FILE
sed -i 's|;group nogroup|group nogroup|' $SERVER_CONFIG_OUTPUT_FILE
}

enable_packet_forwarding() {
echo
echo "Enabling Packet Forwarding..."
#Enable Packet Forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
sysctl -p
echo
}

modify_ufw_rules() {

if [ -z "${INTERFACE}" ]; then 
    >&2 echo  "Invalid Arguments: An interface to listen on must provided"
    exit 128; 
fi

if ! type ufw > /dev/null; then
    >&2 echo  "ufw command not found nothing to do."
    exit 126; 
fi

echo "Modifying ufw rules..."
#Make Firewall rule
ufw allow 1194/u
ufw allow proto tcp from any to any port 1194

echo "Changing ufw default forwarding policy from DROP to ACCEPT..."
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
echo "Inserting the following rules into /etc/ufw/before.rules:"
echo "$UFW_RULES"
echo


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
echo 
}

reload_ufw() {

if ! type ufw > /dev/null; then
    >&2 echo  "ufw command not found nothing to do."
    exit 126; 
fi
#Enable firewall
echo
echo "Reloading firewall via ufw for rules to take effect..."
ufw disable && ufw enable
ufw status verbose
}

build_ca() {

echo
echo "Building Certificate Authority"
echo "Setting server name to: $SERVER_NAME"
echo "Output directory: $KEY_DIRECTORY"
echo

#Build Certificate Authority
cp -r /usr/share/easy-rsa/ /etc/openvpn

mkdir $KEY_DIRECTORY

INSERT="export KEY_NAME=\"$SERVER_NAME\""
sed -i '70i '"$INSERT"'' /etc/openvpn/easy-rsa/vars

#Generate Diffie-Hellman parameters
echo "Generating Diffie-Hellman parameters"
echo "Output file: $DH_PEM_FILE"
rm "$DH_PEM_FILE"
openssl dhparam -out "$DH_PEM_FILE" 2048

echo "Generating TA key"
echo "Output file: $TA_KEY_FILE"
rm "$TA_KEY_FILE"
openvpn --genkey --secret "$TA_KEY_FILE"

cd /etc/openvpn/easy-rsa
. ./vars
./clean-all

if [ "$SILENT_MODE" = true ] ; then
  echo "Noninteractive mode enabled..."
  ./pkitool --initca
  ./pkitool --server $SERVER_NAME
else
  echo "Generating keys interactively..."
  ./build-ca 
  ./build-key-server $SERVER_NAME
fi


}

start_openvpn_server() {

if ! type openvpn > /dev/null; then
    >&2 echo  "openvpn not found nothing to do. Try installing it with the -I flag"
    exit 126; 
fi

echo
echo "Starting OpenVPN..."
echo
#Start Openvpn
echo "Starting Openvpn Server"
service openvpn stop $SERVER_NAME
service openvpn start $SERVER_NAME
service openvpn status $SERVER_NAME
echo

}



if [ "$INSTALL_OPENVPN" = true ] ; then
    install_openvpn
fi

if [ "$BUILD_SERVER_CONFIG_FILE" = true ] ; then
    build_server_config_file
fi

if [ "$ENABLE_PACKET_FORWARDING" = true ] ; then
   enable_packet_forwarding
fi

if [ "$MODIFY_UFW_RULES" = true ] ; then
   modify_ufw_rules
fi

if [ "$RELOAD_UFW" = true ] ; then
   reload_ufw
fi

if [ "$BUILD_CA" = true ] ; then
   build_ca
fi

if [ "$START_OPENVPN_SERVER" = true ] ; then
   start_openvpn_server
fi

