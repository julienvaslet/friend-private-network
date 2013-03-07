friend-private-network
======================

Installed on a Raspberry Pi, it installs and configures OpenVPN, DHCP Server and a web application nginx/PHP based. It allows users to be linked to theirs friends LAN with multiple VPNs on a star networks topology.

Versions
--------
- 0.1 : Installation configures OpenVPN & DHCP Server and the Certificate Authority, new clients must be manually added by copying a template configuration file.
- 0.2 : Installation provides a web-interface which allows user to add/remove outgoing connections and authorize/revoke incoming connections.
- 0.3 : Web-inteface has an option to dynamically select unique identifier to avoid conflicts with other networks.
- 0.4 : Each client network is shared with neighbours in order to make easier the extension of the global network.
