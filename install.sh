#!/bin/bash
basedir=$(cd `dirname $0`; pwd)
logfile="$basedir/install-$(date +%Y-%m-%d-%H-%M-%S).log"

# OpenVPN
echo "OpenVPN installation..."
sudo apt-get install -y openvpn > $logfile
echo $?
