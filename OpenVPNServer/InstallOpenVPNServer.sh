#!/bin/bash

clear
echo "******************************************"
echo "*   Welcome to EasyOpenVPN Installer     *"
echo "*       by: Beesham and Kenneth          *"
echo "******************************************"
echo " "

#checks if user is running file as root
if [ "$(id -u)" != "0" ]; then
   echo "**This script must be run as root**" 1>&2
   echo "**Please log in as root then re-run script**"
   exit 1
fi

#Display Welcome Messages and Step by Step
echo "Hello, Welcome to EasyOpenVPN!, Sit back and relax during this setup!"
echo " "
echo "************ BASIC SETUP ****************"
echo "1) What is the IPv4 Address of the network interface you want to connect to?"
read -p "IPv4 Address: " IP
echo " "
echo "2) What port do you want OpenVPN on? (1194 is standard)"
read -p "Port: " PORT
echo " "
echo "3) Do you want to listen to port 53 as well?"
read -p "Port 53 (y/n): " OTHERPORT
echo ""
echo "4) Enable internal networking?"
read -p "Allow (y/n)? " INTERNAL
echo ""
echo "5) Enter Country Code (ex. CA, US)"
read -p "Code: " CONCODE
echo ""
echo "6) Enter Province/State (ex. Ontario)"
read -p "Prov/State: " PROVINCE
echo ""
echo "7) Enter City (ex. Toronto)"
read -p "City: " CITY
echo ""
echo "8) Enter Company Name (ex. Google)"
read -p "Name: " COMPANY
echo ""
echo "9) Enter EmailL"
read -p "Email: " EMAIL
echo ""
echo "10) What is your Client Name?"
read -p "Name: " NAME
echo ""
echo "GREAT!, we are done!, now we will install all the packages for you"

#Installing the Extra Packages for Enterprise Linux (EPEL) repository. 
#This is because OpenVPN isn't available in the default CentOS repositories. 
echo "Installing Extra Packages"
yum -y install epel-release


#Install OpenVPN. 
#We'll also install Easy RSA for generating our SSL key pairs, 
# which will secure our VPN connections.
echo "Installing OpenVPNServer and Easy RSA to generate SSL key pairs"
yum -y install openvpn easy-rsa -y

echo "Server Configuration Complete"


#Server is configured
#Generate keys and certificates.
#Easy RSA installs some scripts to generate these keys and certificates.
wget --no-check-certificate -O ~/easy-rsa.tar.gz https://github.com/OpenVPN/easy-rsa/archive/2.2.2.tar.gz
tar xzf ~/easy-rsa.tar.gz -C ~/
mkdir -p /etc/openvpn/easy-rsa/2.0/
cp ~/easy-rsa-2.2.2/easy-rsa/2.0/* /etc/openvpn/easy-rsa/2.0/
rm -rf ~/easy-rsa-2.2.2
rm -rf ~/easy-rsa.tar.gz


echo "Creating directory for keys and certificates"
mkdir -p /etc/openvpn/easy-rsa/keys

#Change Directory into the easy-rsa directory
cd /etc/openvpn/easy-rsa/2.0

#Make it more easier
cp -u -p openssl-1.0.0.cnf openssl.cnf

#Set to 2048 bit encyption
sed -i 's|export KEY_SIZE=1024|export KEY_SIZE=2048|' /etc/openvpn/easy-rsa/2.0/vars

#Set Country Code
sed -i 's|export KEY_COUNTRY="US"|export KEY_COUNTRY="$CONCODE"|' /etc/openvpn/easy-rsa/2.0/vars

#Set Province / State 
sed -i 's|export KEY_PROVINCE="CA"|export KEY_PROVINCE="$PROVINCE"|' /etc/openvpn/easy-rsa/2.0/vars

#Set City
sed -i 's|export KEY_CITY="SanFrancisco"|export KEY_CITY="$CITY"|' /etc/openvpn/easy-rsa/2.0/vars

#Set Org/Company
sed -i 's|export KEY_ORG="Fort-Funston"|export KEY_COUNTRY="$COMPANY"|' /etc/openvpn/easy-rsa/2.0/vars

#Set Admin Email
sed -i 's|export KEY_EMAIL="me@myhost.mydomain"|export KEY_COUNTRY="$EMAIL"|' /etc/openvpn/easy-rsa/2.0/vars

#Set Org Unit
sed -i 's|export KEY_OU="MyOrganizationalUnit"|export KEY_COUNTRY="$COMPANY"|' /etc/openvpn/easy-rsa/2.0/vars

#Create the PKI
. /etc/openvpn/easy-rsa/2.0/vars
. /etc/openvpn/easy-rsa/2.0/clean-all

export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --initca $*
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --server server

# Start creating the client keys
export KEY_CN="$CLIENT"
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" $NAME

# DH params
. /etc/openvpn/easy-rsa/2.0/build-dh

# Let's configure the server
cd /usr/share/doc/openvpn*/*ample*/sample-config-files
cp server.conf /etc/openvpn/
cd /etc/openvpn/easy-rsa/2.0/keys
cp ca.crt ca.key dh2048.pem server.crt server.key /etc/openvpn
cd /etc/openvpn/

# Set the server configuration
sed -i 's|dh dh1024.pem|dh dh2048.pem|' server.conf
sed -i 's|;push "redirect-gateway def1 bypass-dhcp"|push "redirect-gateway def1 bypass-dhcp"|' server.conf
sed -i "s|port 1194|port $PORT|" server.conf

#Setupt the DNS
grep -v '#' /etc/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read line; do
sed -i "/;push \"dhcp-option DNS 208.67.220.220\"/a\push \"dhcp-option DNS $line\"" server.conf
done

# Listen at port 53 too if user wants that
if [[ "$OTHERPORT" = 'y' ]]; then
		iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-port $PORT
		sed -i "1 a\iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-port $PORT" $RCLOCAL

fi

# Enable net.ipv4.ip_forward for the system
if ! grep -q "net.ipv4.ip_forward=1" "/etc/sysctl.conf"; then
		echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
fi

# Avoid an unneeded reboot
	echo 1 > /proc/sys/net/ipv4/ip_forward
	# Set iptables
	if [[ "$INTERNALNETWORK" = 'y' ]]; then
		iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
		sed -i "1 a\iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP" $RCLOCAL
	else
		iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to $IP
		sed -i "1 a\iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to $IP" $RCLOCAL
	fi
	
#Restart OpenVPN
if pidof systemd; then
	systemctl restart openvpn@server.service
	systemctl enable openvpn@server.service
else
	service openvpn restart
	chkconfig openvpn on
fi

#Test to see if you are in a NET Network
EXTERNALIP=$(wget -qO- ipv4.icanhazip.com)

#Test to see if the IP Matches, if not request it
if [[ "$IP" != "$EXTERNALIP" ]]; then
	echo ""
	echo "We have dected you're in a NAT, please type your external IP Address"
	echo ""
	read -p "External IP: " -e USEREXTERNALIP
	if [[ "$USEREXTERNALIP" != "" ]]; then
			IP=$USEREXTERNALIP
	fi
fi

sed -i "s|remote my-server-1 1194|remote $IP $PORT|" /usr/share/doc/openvpn*/*ample*/sample-config-files/client.conf
# Generate the client.ovpn
newclient "$NAME"
echo ""
echo "Finished!"
echo ""
echo "Your client config is available at ~/$NAME.ovpn"
echo "If you want to add more clients, you simply need to run this script another time!"
