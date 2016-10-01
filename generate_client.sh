#!/bin/bash

#This script generates openvpn client keys using the easy-rsa build-key tool and creates a single distributable .ovpn file with all of the necessary keys.
#This can be then distributed to users.

KEY_DIR=/etc/openvpn/easy-rsa/keys

#########################
# The command line help #
#########################
display_help() {
    echo "Usage: $0 -c <client name>  -b <base config>"
    echo "Must be run as root."
    echo
    echo "Required"
    echo "   -c, --client-name           name of the client.  This will be used to generate key files and output .ovpn file. Takes the client name as an argument"
    echo "   -b, --base-config           base client configuration file to be used to compile an output .ovpn for the client. Takes the base config file as an argument."
    echo "   -o, --output-directory      All keys are stored in /etc/openvpn/easy-rsa/keys. If this parameter is provided the.  Takes the desired output directory as an argument."
    echo "                               output .ovpn will be copied to the directory and the ownership of the file will be changed " 
    echo "                               to whoever called sudo."
    echo "Optional"
    echo "   -s, --silent-mode                   If this flag is provided then the key generation will run without user interaction. All inputs"
    echo "                                       will be set to their default. Takes no arguments."
    echo "   -x, --skip-keygen                   Only the client ovpn file will be built with pre-existing keys if -O is not enabled. The key generation will be skipped. Takes no arguments."
    echo "                                       NOTE: This will fail if there are no keys already generated."
    echo "   -O, --skip-output-file-generation   Only the client keys will be generated provided -x is not enabled. The .ovpn output file generation will be skipped. Takes no arguments."
    echo
    echo "Example"
    echo "   sudo sh generate_client.sh -c client1 -o . -b base.conf"
    echo "   sudo sh generate_client.sh -c client1 -o . -b base.conf -s"
    echo
    echo "Note: This will fail if there is already a client with the provided name in the database"
    echo "All generated client keys as well as ovpn files are stored in: $KEY_DIR"
    exit 1
}

################################
# Check if parameters options  #
# are given on the command line#
################################
SILENT_MODE=false
SKIP_KEY_GENERATION=false
SKIP_OUTPUT_FILE_GENERATION=false

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
      -s | --silent-mode)
          SILENT_MODE=true
           shift 1
           ;;
      -x | --skip-key-generation)
          SKIP_KEY_GENERATION=true
           shift 1
           ;;
      -O | --skip-output-file-generation)
          SKIP_OUTPUT_FILE_GENERATION=true
           shift 1
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

OUTPUT_FILE=$CLIENT_NAME.ovpn
echo
echo "Base Configuration: $BASE_CONFIG"
cat $BASE_CONFIG
echo

if [ "$SKIP_KEY_GENERATION" = true ] ; then
  echo "Skipping key generation..."
else
  echo "Generating Keys..."
  CWD=$(pwd)
  cd /etc/openvpn/easy-rsa/
  . /etc/openvpn/easy-rsa/vars
  if [ "$SILENT_MODE" = true ] ; then
    ./pkitool $CLIENT_NAME
  else
    exec /etc/openvpn/easy-rsa/build-key $CLIENT_NAME 
  fi
  cd $CWD
fi
echo

if [ "$SKIP_OUTPUT_FILE_GENERATION" = true ] ; then
  echo "Skipping output file generation..."
else
  echo "Compiling output .ovpn file: $OUTPUT_FILE"
  cat $BASE_CONFIG >> $KEY_DIR/$OUTPUT_FILE
  echo '\n<ca>' >> $KEY_DIR/$OUTPUT_FILE
  cat $KEY_DIR/ca.crt >> $KEY_DIR/$OUTPUT_FILE
  echo '</ca>\n<cert>' >> $KEY_DIR/$OUTPUT_FILE
  cat $KEY_DIR/$CLIENT_NAME.crt >> $KEY_DIR/$OUTPUT_FILE
  echo '</cert>\n<key>' >> $KEY_DIR/$OUTPUT_FILE
  cat $KEY_DIR/$CLIENT_NAME.key >> $KEY_DIR/$OUTPUT_FILE
  echo '</key>\n<tls-auth>' >> $KEY_DIR/$OUTPUT_FILE
  cat /etc/openvpn/ta.key >> $KEY_DIR/$OUTPUT_FILE
  echo '</tls-auth>\n' >> $KEY_DIR/$OUTPUT_FILE
  echo 'key-direction 1' >> $KEY_DIR/$OUTPUT_FILE
  echo "Client ovpn created: $KEY_DIR/$OUTPUT_FILE"

  if [ -z ${OUTPUT_DIRECTORY+x} ]; then 
      echo "No output directory provided skipping copy."; 
  else 
      echo "Output Directory set to: $OUTPUT_DIRECTORY";
      echo "Copying /etc/openvpn/easy-rsa/keys/$OUTPUT_FILE to $OUTPUT_DIRECTORY/$OUTPUT_FILE"
      cp /etc/openvpn/easy-rsa/keys/$OUTPUT_FILE $OUTPUT_DIRECTORY
      #Set owner to whoever called this script
      echo "Setting ownership of $OUTPUT_DIRECTORY/$OUTPUT_FILE to $SUDO_USER:"
      chown $SUDO_USER $OUTPUT_DIRECTORY/$OUTPUT_FILE
  fi
fi
echo 