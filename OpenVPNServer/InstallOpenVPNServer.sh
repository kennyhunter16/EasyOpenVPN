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

OS=centos
#RCLOCAL='/etc/rc.d/rc.local'
#chmod +x /etc/rc.d/rc.local

#Display Welcome Messages and Step by Step
echo "Hello, Welcome to EasyOpenVPN!, Sit back and relax during this setup!"
echo " "
echo "************ BASIC SETUP ****************"
echo "1) What is the IPv4 Address of the network interface you want to connect to?"
read -p "IPv4 Address: "  IP
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

#Install all the Packages
yum install epel-release -y
yum install openvpn iptables openssl wget -y
wget --no-check-certificate -O ~/easy-rsa.tar.gz https://github.com/OpenVPN/easy-rsa/archive/2.2.2.tar.gz
tar xzf ~/easy-rsa.tar.gz -C ~/
mkdir -p /etc/openvpn/easy-rsa/2.0/
cp ~/easy-rsa-2.2.2/easy-rsa/2.0/* /etc/openvpn/easy-rsa/2.0/
rm -rf ~/easy-rsa-2.2.2
rm -rf ~/easy-rsa.tar.gz


#Make a New Client
newclient () {
	# Generates the client.ovpn
	cp /usr/share/doc/openvpn*/*ample*/sample-config-files/client.conf ~/$1.ovpn
	sed -i "/ca ca.crt/d" ~/$1.ovpn
	sed -i "/cert client.crt/d" ~/$1.ovpn
	sed -i "/key client.key/d" ~/$1.ovpn
	echo "<ca>" >> ~/$1.ovpn
	cat /etc/openvpn/easy-rsa/2.0/keys/ca.crt >> ~/$1.ovpn
	echo "</ca>" >> ~/$1.ovpn
	echo "<cert>" >> ~/$1.ovpn
	cat /etc/openvpn/easy-rsa/2.0/keys/$1.crt >> ~/$1.ovpn
	echo "</cert>" >> ~/$1.ovpn
	echo "<key>" >> ~/$1.ovpn
	cat /etc/openvpn/easy-rsa/2.0/keys/$1.key >> ~/$1.ovpn
	echo "</key>" >> ~/$1.ovpn
}


#Change Directory to Easy-RSA location
cd /etc/openvpn/easy-rsa/2.0/

#Remove Verison of OpenSSL to make it easier programming ;)
cp -u -p openssl-1.0.0.cnf openssl.cnf

#Change all the Vars Values

#Set to 2048 bit encyption
sed -i 's|export KEY_SIZE=1024|export KEY_SIZE=2048|' /etc/openvpn/easy-rsa/2.0/vars
#Set Country Code
sed -i 's|export KEY_COUNTRY="US"|export KEY_COUNTRY=$CONCODE|' /etc/openvpn/easy-rsa/2.0/vars
#Set Province / State 
sed -i 's|export KEY_PROVINCE="CA"|export KEY_PROVINCE=$PROVINCE|' /etc/openvpn/easy-rsa/2.0/vars
#Set City
sed -i 's|export KEY_CITY="SanFrancisco"|export KEY_CITY=$CITY|' /etc/openvpn/easy-rsa/2.0/vars
#Set Org/Company
#sed -i 's|export KEY_ORG="Fort-Funston"|export KEY_ORG=$COMPANY|' /etc/openvpn/easy-rsa/2.0/vars
#Set Admin Email
sed -i 's|export KEY_EMAIL="me@myhost.mydomain"|export KEY_EMAIL=$EMAIL|' /etc/openvpn/easy-rsa/2.0/vars

# Create the PKI
. /etc/openvpn/easy-rsa/2.0/vars
. /etc/openvpn/easy-rsa/2.0/clean-all

#We are going to use the Easy-RSA Script from GitHub. The only problem
#is this script needs to be updated in Build-ca changes format

export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --initca $*

# We are going to run the Build Key Server!
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --server server

#Now the client keys.
export KEY_CN="$NAME"
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" $NAME

# DH params
. /etc/openvpn/easy-rsa/2.0/build-dh

# Time to Confiugre the Server! 
cd /usr/share/doc/openvpn*/*ample*/sample-config-files

#Copy the Server conf to openVPN folder
cp server.conf /etc/openvpn/
cd /etc/openvpn/easy-rsa/2.0/keys
cp ca.crt ca.key dh2048.pem server.crt server.key /etc/openvpn
cd /etc/openvpn/

# Set the server configuration, sets the port here
sed -i 's|dh dh1024.pem|dh dh2048.pem|' server.conf
sed -i 's|;push "redirect-gateway def1 bypass-dhcp"|push "redirect-gateway def1 bypass-dhcp"|' server.conf
sed -i "s|port 1194|port $PORT|" server.conf

# Find the Server DNS and Set it :)
sed -i 's|;push "dhcp-option DNS 208.67.222.222"|push "dhcp-option DNS 208.67.222.222"|' server.conf
sed -i 's|;push "dhcp-option DNS 208.67.220.220"|push "dhcp-option DNS 208.67.220.220"|' server.conf

# Listen to Port 53 if the user wants
if [[ "$OTHERPORT" = 'y' ]]; then
		iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-port $PORT
		sed -i "1 a\iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-port $PORT" $RCLOCAL
fi
# Enable net.ipv4.ip_forward for the system
if ! grep -q "net.ipv4.ip_forward=1" "/etc/sysctl.conf"; then
			echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
fi

# Stop the Server from Rebooting
echo 1 > /proc/sys/net/ipv4/ip_forward

# Set the IP Tables
if [[ "$INTERNAL" = 'y' ]]; then
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

EXTERNALIP=$(wget -qO- ipv4.icanhazip.com)
if [[ "$IP" != "$EXTERNALIP" ]]; then
	echo ""
	echo "Looks like your server is behind a NAT!, What is your External IP?"
	echo ""
	read -p "External IP: " -e USEREXTERNALIP
	if [[ "$USEREXTERNALIP" != "" ]]; then
			IP=$USEREXTERNALIP
		fi
fi

sed -i "s|remote my-server-1 1194|remote $IP $PORT|" /usr/share/doc/openvpn*/*ample*/sample-config-files/client.conf


newclient "$NAME"
echo ""
echo "Finished!"
echo ""
echo "Your client config is available at ~/$NAME.ovpn"
echo "If you want to add more clients, you simply need to run this script another time!"

