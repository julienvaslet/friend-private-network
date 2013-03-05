#!/bin/bash
version="0.1"
basedir=$(cd `dirname $0`; pwd)
hostname=$(hostname)

# Root user check
if [ $(whoami) != "root" ]
then
	echo "You need to run this script as root."
	echo "Exiting..."
	exit 1
fi

echo "Friend Private Network $version installer"
echo "Instance name will be the current hostname: $(hostname)"
read -p "Do you want to continue? (y/n) "

if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]
then
	# OpenVPN
	echo "OpenVPN installation..."
	apt-get install -y openvpn
	
	if [ $? -eq 0 ]
	then
		mkdir -p /etc/openvpn_tmp

		# Copy easy-rsa 2.0 files
		cp -R /usr/share/doc/openvpn/examples/easy-rsa/2.0 /etc/openvpn_tmp/easy-rsa

		# Patch scripts
		sed -i 's/--interact //g' /etc/openvpn_tmp/easy-rsa/build-key-server

		country="FR"
		province="Midi-Pyrénées"
		city="Toulouse"
		email="root@$hostname"

		echo "Please confirm the following certificate authority information: "
		
		read -p "Country [$country]: "
		if [ ! -z "$REPLY" ]
		then
			country="$REPLY"
		fi

		read -p "Province: [$province]: "
		if [ ! -z "$REPLY" ]
		then
			province="$REPLY"
		fi

		read -p "City [$city]: "
		if [ ! -z "$REPLY" ]
		then
			city="$REPLY"
		fi

		read -p "E-mail [$email]: "
		if [ ! -z "$REPLY" ]
		then
			email="$REPLY"
		fi

		# Update default values with ours
		sed -i "s/^\(export KEY_COUNTRY\).*/\1=\"$country\"/g" /etc/openvpn_tmp/easy-rsa/vars
		sed -i "s/^\(export KEY_PROVINCE\).*/\1=\"$province\"/g" /etc/openvpn_tmp/easy-rsa/vars
		sed -i "s/^\(export KEY_CITY\).*/\1=\"$city\"/g" /etc/openvpn_tmp/easy-rsa/vars
		sed -i "s/^\(export KEY_ORG\).*/\1=\"$hostname\"/g" /etc/openvpn_tmp/easy-rsa/vars
		sed -i "s/^\(export KEY_EMAIL\).*/\1=\"$email\"/g" /etc/openvpn_tmp/easy-rsa/vars
		sed -i "s/^\(export KEY_OU\).*/\1=\"$hostname\"/g" /etc/openvpn_tmp/easy-rsa/vars

		cd /etc/openvpn_tmp/easy-rsa
		source vars
		export KEY_NAME="$hostname"
		export KEY_CN="$hostname"
		./clean-all
		echo -e "\n\n\n\n\n\n\n\n" | ./build-ca
		echo
		./build-key-server $hostname
		./build-dh
		cd $basedir
	else
		echo "An error has occured."
		exit 3
	fi

	exit 0
else
	echo "Cancelling installation. Exiting..."
	exit 2
fi
