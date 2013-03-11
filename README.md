friend-private-network
======================

Installed on a Raspberry Pi, it installs and configures OpenVPN, DHCP Server and a web application nginx/PHP based. It allows users to be linked to theirs friends LAN with multiple VPNs on a star networks topology.

Prerequisites
--------
- The Raspberry Pi network interface must be configured on a 192.168.N.0/24 network. N is the unique identifierwhich will be used on VPNs configuration. At this development level, its IP address must be 192.168.N.251.
- The Raspberry Pi's hostname is used to set the name of the VPN instance.
- Repositories shall be up-to-date (apt-get update)

Installation
-------
Execute the "install.sh" script.

Authorize a new client
-------
- Ask for its instance name.
- Execute the "genclient.sh" script (genclient.sh [instance name])
- Send to the client following files:
	- /etc/openvpn/easy-rsa/keys/ca.crt
	- /etc/openvpn/easy-rsa/keys/[instance name].crt
	- /etc/openvpn/easy-rsa/keys/[instance name].crt

Connect to a new server
-------
- Ask for its instance name and unique identifier.
- Get generated certificate and its authority certificate.
	- Move them in /etc/openvpn/[instance name]/
- Copy the "openvpn-client.conf" to /etc/openvpn/[instance name].conf
- Edit this file by replacing [ID], [HOSTNAME] and [MY_HOSTNAME] respectively by the server unique identifier, its instance name and your instance name.
- Restart the VPN daemon (service openvpn restart)
- Add the route with the following command: route add -net 192.168.N.0 netmask 255.255.255.0 gw 10.20.N.1
- Add theses IPTables rules (/etc/iptables/rules.v4) :
	- -A FORWARD -s 192.168.N.0/24 -j ACCEPT
	- -A POSTROUTING -s 192.168.N.0/24 -j MASQUERADE
- Restart iptables-persistent (service ipstart-persistent restart)
