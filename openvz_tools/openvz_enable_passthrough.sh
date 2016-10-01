#!/bin/bash

#This script enables nat passthrough by inserting an iptables rule for openvpn running in an OpenVZ container.
#Usage run script as root

HOST=$(hostname -i)
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to-source $HOST
