#!/bin/bash

#This script generates openvpn client keys using the easy-rsa build-key tool and creates a single distributable .ovpn file with all of the necessary keys.
#This can be then distributed to users.


#Usage: generate_client.sh -n "<server name>"  -i "<interface>"

#Note: this defaults to AES-128-CBC which according to BSI recommendations of 2015 is still cryptographically secure see https://www.keylength.com/.

#########################
# The command line help #
#########################
display_help() {
    echo "Usage: $0 -c <client name>  -b <base config>"
    echo "Must be run as root."
    echo "   -c, --client-name           name of the client.  This will be used to generate key files and output .ovpn file."
    echo "   -b, --base-config           base client configuration file to be used to compile an output .ovpn for the client"
    echo "   -o, --output-directory      all keys are stored in /etc/openvpn/easy-rsa/keys if this parameter is provided the output .ovpn will be copied to the provided directory"
    echo "Example: sudo sh generate_client.sh -c client1 -o . -b base.conf"
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
      -b | --base-config)
          BASE_CONFIG="$2"
          shift 2
          ;;
      -c | --client-name)
          CLIENT_NAME="$2"
           shift 2
           ;;
      -o | --output-directory)
          OUTPUT_DIRECTORY="$2"
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

################################
# Root Check                   #
#                              #
################################
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

################################
# Validate and sanitize input  #
#                              #
################################
if [ -z "${CLIENT_NAME}" ]; then 
    >&2 echo  "Invalid Arguments: A client name must be provided with -c"
    exit 128; 
fi
#CLIENT_NAME="${CLIENT_NAME// /_}"#Remove white space
if [ -z "${BASE_CONFIG}" ]; then 
    >&2 echo  "Invalid Arguments: A base configuration file must be provided with -b"
    exit 128; 
fi

################################
# Build Client .ovpn file      #
# OpenVPN Server               #
################################
KEY_DIR=/etc/openvpn/easy-rsa/keys
OUTPUT_FILE=/etc/openvpn/easy-rsa/keys/$CLIENT_NAME.ovpn
echo
echo "Base Configuration: $BASE_CONFIG"
cat $BASE_CONFIG
echo

echo "Generating Keys..."
CWD=$(pwd)
cd /etc/openvpn/easy-rsa/
. /etc/openvpn/easy-rsa/vars
exec /etc/openvpn/easy-rsa/build-key $CLIENT_NAME 

cd CWD

echo "Compiling output .ovpn file: $OUTPUT_FILE"
cat $BASE_CONFIG >> $OUTPUT_FILE
echo '\n<ca>' >> $OUTPUT_FILE
cat $KEY_DIR/ca.crt >> $OUTPUT_FILE
echo '</ca>\n<cert>' >> $OUTPUT_FILE
cat $KEY_DIR/$CLIENT_NAME.crt >> $OUTPUT_FILE
echo '</cert>\n<key>' >> $OUTPUT_FILE
cat $KEY_DIR/$CLIENT_NAME.key >> $OUTPUT_FILE
echo '</key>\n<tls-auth>' >> $OUTPUT_FILE
cat /etc/openvpn/ta.key >> $OUTPUT_FILE
echo '</tls-auth>\n' >> $OUTPUT_FILE
echo 'key-direction 1' >> $OUTPUT_FILE;

echo "Client ovpn created: /etc/openvpn/easy-rsa/keys/$OUTPUT_FILE"

copy_client_certificate_to_output_dir() {
if [ -z ${OUTPUT_DIRECTORY+x} ]; then 
    echo "No output directory provided skipping copy."; 
  
else 
    echo "Output Directory set to: $OUTPUT_DIRECTORY";
    cp /etc/openvpn/easy-rsa/keys/$OUTPUT_FILE $OUTPUT_DIRECTORY
    #Set owner to whoever called this script
    chown $SUDO_USER $OUTPUT_DIRECTORY/$OUTPUT_FILE
fi
}