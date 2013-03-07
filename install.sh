#!/bin/bash
version="0.1"
basedir=$(cd `dirname $0`; pwd)

# Root user check
if [ $(whoami) != "root" ]
then
	echo "You need to run this script as root."
	echo "Exiting..."
	exit 1
fi

# Default values
hostname=$(hostname)
country="FR"
province="Midi-Pyrénées"
city="Toulouse"
email="root@$hostname"
uniqId=$(ifconfig | grep "192.168.[0-9]*.251" | sed 's/.*192\.168\.\([0-9]*\).*/\1/g')
install_dhcpd=0

# Unique identifier check
if [ "$uniqId" != "0" ]
then
	if [ -z "$uniqId" -o "$(expr $uniqId + 0 &> /dev/null; echo $?)" != "0" ]
	then
		echo "Your local IP address is not well configured."
		echo "It shall be 192.168.N.251, where N is your unique identifier."
		exit 1
	fi
fi

# Hostname check
if [ "$(hostname -a &> /dev/null; echo $?)" != "0" ]
then
	echo "Your hostname is not resolvable."
	echo "Please check your /etc/hosts file."
	exit 1
fi

echo "Friend Private Network $version installer"
echo "Instance name will be the current hostname: $(hostname)"
echo "Your unique identifier (based on ip configuration) is: $uniqId"
read -p "Do you want to continue? (y/n) "

if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]
then
	read -p "Do you want to configure a DHCP server? (y/n) "
	if [ "$REPLY" = "y" -o "$REPLY" = "Y" ]
	then
		install_dhcpd=0
	else
		install_dhcpd=1
	fi

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

	# OpenVPN
	echo "OpenVPN installation..."
	apt-get install -y openvpn
	
	if [ $? -eq 0 ]
	then
		# Copy easy-rsa 2.0 files
		cp -R /usr/share/doc/openvpn/examples/easy-rsa/2.0 /etc/openvpn/easy-rsa

		# Patch scripts
		sed -i 's/--interact //g' /etc/openvpn/easy-rsa/build-key
		sed -i 's/--interact //g' /etc/openvpn/easy-rsa/build-key-server

		# Update default values with ours
		sed -i "s/^\(export KEY_COUNTRY\).*/\1=\"$country\"/g" /etc/openvpn/easy-rsa/vars
		sed -i "s/^\(export KEY_PROVINCE\).*/\1=\"$province\"/g" /etc/openvpn/easy-rsa/vars
		sed -i "s/^\(export KEY_CITY\).*/\1=\"$city\"/g" /etc/openvpn/easy-rsa/vars
		sed -i "s/^\(export KEY_ORG\).*/\1=\"$hostname\"/g" /etc/openvpn/easy-rsa/vars
		sed -i "s/^\(export KEY_EMAIL\).*/\1=\"$email\"/g" /etc/openvpn/easy-rsa/vars
		sed -i "s/^\(export KEY_OU\).*/\1=\"$hostname\"/g" /etc/openvpn/easy-rsa/vars

		# Generate Certificate Authority & Server certificate
		cd /etc/openvpn/easy-rsa
		source vars
		export KEY_NAME="$hostname"
		export KEY_CN="$hostname"
		./clean-all
		echo -e "\n\n\n\n\n\n\n\n" | ./build-ca
		echo
		./build-key-server $hostname
		./build-dh
		cd $basedir

		# Generate OpenVPN Server configuration
		cp $basedir/openvpn-server.conf /etc/openvpn/$hostname.conf
		sed -i "s/\\[ID\\]/$uniqId/g" /etc/openvpn/$hostname.conf
		sed -i "s/\\[HOSTNAME\\]/$hostname/g" /etc/openvpn/$hostname.conf
		service openvpn restart
	else
		echo "An error has occured."
		exit 3
	fi

	# iptables-persistent
	apt-get install -y iptables-persistent
	if [ $? -eq 0 ]
	then
		# Configure iptables rules
		echo "Pushing iptables rules..."
		
		if [ -e "/etc/iptables/rules.v4" ]
		then
			timestamp=$(date +%s)
			echo "Current rules are saved to /etc/iptables/rules.v4.$timestamp"
			mv /etc/iptables/rules.v4 /etc/iptables/rules.v4.$timestamp
		fi
		
		cp $basedir/iptables.conf /etc/iptables/rules.v4
		sed -i "s/\\[ID\\]/$uniqId/g" /etc/iptables/rules.v4
		service iptables-persistent restart
	else
		echo "An error has occured."
		exit 4
	fi

	# System ip_forward option
	echo "IP forward activation..."
	sysctl -w net.ipv4.ip_forward=1

	# ISC DHCP Server
	if [ $install_dhcpd -eq 0 ]
	then
		apt-get install isc-dhcp-server
		if [ $? -eq 0 ]
		then
			if [ -e "/etc/dhcp/dhcpd.conf" ]
			then
				timestamp=$(date +%s)
				echo "Current DHCP server configuration is saved to /etc/dhcp/dhcpd.conf.$timestamp"
				mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.$timestamp
			fi

			cp $basedir/dhcpd.conf /etc/dhcp/dhcpd.conf
			sed -i "s/\\[ID\\]/$uniqId/g" /etc/dhcp/dhcpd.conf
			service isc-dhcp-server restart
		else
			echo "An error has occured."
			exit 5
		fi
	fi
	
	exit 0
else
	echo "Cancelling installation. Exiting..."
	exit 2
fi
