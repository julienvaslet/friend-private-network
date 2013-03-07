#!/bin/bash
name="$1"

if [ -z "$name" ]
then
	echo "usage: $(basename $0) <client name>"
	exit 1
fi

cd /etc/openvpn/easy-rsa
source vars
export KEY_NAME="$name"
export KEY_CN="$name"
./build-key $name
