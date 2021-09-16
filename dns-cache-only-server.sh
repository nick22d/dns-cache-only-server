#!/bin/bash
### Description: This script configures a cache-only DNS server
### Written by: Nicholas Doropoulos
### Version: 1

#=========#
# MAIN BODY
#=========#

# Update the software repositories
apt-get update -y

# Install the bind service
apt-get install bind9 bind9utils -y

# Configure the network interface
ifconfig enp0s3 192.168.1.254 netmask 255.255.255.0

# Navigate into bind
cd /etc/bind/

# Populate the named.conf.options file
cat > /etc/bind/named.conf.options <<- "EOF"
acl "trusted" {

	192.168.1.0/24;

};

options {
	directory "/var/cache/bind";

	// If there is a firewall between you and nameservers you want
	// to talk to, you may need to fix the firewall to allow multiple
	// ports to talk.  See http://www.kb.cert.org/vuls/id/800113

	// If your ISP provided one or more IP addresses for stable 
	// nameservers, you probably want to use them as forwarders.  
	// Uncomment the following block, and insert the addresses replacing 
	// the all-0's placeholder.
	
	recursion yes;
	allow-query { localhost; trusted; };
	allow-query-cache { localhost; trusted; };
	allow-recursion { localhost; trusted; };
	
	forwarders {
	 	192.168.1.1;
	};

	//========================================================================
	// If BIND logs error messages about the root key being expired,
	// you will need to update your keys.  See https://www.isc.org/bind-keys
	//========================================================================
	
	forward only;
	//dnssec-validation auto;

	auth-nxdomain no;    # conform to RFC1035
};
EOF

# Populate the named.conf.local file
cat > /etc/bind/named.conf.local <<- "EOF"
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "intranet.local" {

	type forward;
	forward only;
	
	forwarders {
		
		192.168.1.100;
		192.168.1.101;
	
	};

};
EOF

# Verify the syntax of the named.conf file
named-checkconf -z /etc/bind/named.conf

# Restart the bind service for the changes to take effect
systemctl restart bind9
