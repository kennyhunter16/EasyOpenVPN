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
read -p "Port 53 (y/n)" OTHERPORT
echo ""
echo "4) Enable internal networking?"
read -p "Allow (y/n)?" INTERNAL
echo ""
echo "5) What is your Client Name?"
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

#Configuring OpenVPNServer
echo "Configuring OpenVPNServer"
echo "Copying base configuration file"
cp server.conf /etc/openvpn

echo "Server Configuration Complete"
#Server is configured
#Generate keys and certificates.
#Easy RSA installs some scripts to generate these keys and certificates.

echo "Creating directory for keys and certificates"
mkdir -p /etc/openvpn/easy-rsa/keys

#Copying key and certificate generation scripts into directory.
echo "Copying keys and certificates to directory"
cp -rf /usr/share/easy-rsa/2.0/* /etc/openvpn/easy-rsa

#setup edit key_cn and other keys here to input to file before mv
#domain or subdomain that resolves to server
echo ***DONT LEAVE ANY OF THESE FIELDS BLANCK***
echo "Enter domain of your server >"
read KEY_CN
echo "Enter Country >"
read KEY_COUNTRY
echo "Enter Province >"	
read KEY_PROVINCE
echo "Enter City >"
read KEY_CITY
echo "Enter Organization >"
read KEY_ORG
echo "Enter EMAIL >"
read KEY_EMAIL
echo "Enter Community >"
read KEY_OU

chmod uo+w vars

vi vars -c '%s/export KEY_CN="CommonName"/export KEY_CN="$KEY_CN"/g' -c ':wq'
vi vars -c '%s/export KEY_COUNTRY="US"/export KEY_COUNTRY="$KEY_COUNTRY"/g' -c ':wq'


#mv vars /etc/openvpn/easy-rsa/
