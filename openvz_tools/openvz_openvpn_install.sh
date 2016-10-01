#!/bin/bash

#This script installs OpenVPN and patches if for an Ubuntu 16.04 LTS instance running in a OpenVZ container.
#run as root

sh ../openvpn_install.sh
sh vps_openvpn_patch.sh
