# EasyOpenVPN
EasyOpenVPN is a bash script designed to setup an OpenVPN on a Debian-based machine.

#About OpenVPN
OpenVPN is an open-source software application that allows connection from point-to-point or site-to-site using a secure connection. It implements VPN techniques to create the secure connection needed. It uses a custom protocol that utilizes key exchange(SSL[Secure Sockets Layer]/TSL[Transport Layer Security]).
OpenVPN allows for peer authentication. That is, when connecting to another location, some sort of verification must happen. This is basically the pre-shared key that was generated when the OpenVPN server was setup.
A normal VPN client can be used to connect to the OpenVPN as long it has the client information needed by the server to authenticate. 

#Platform Specifications
OpenVPN can be installed on a Windows distribution or a Linux distribution but for the purpose of this script we created it for CentOS7/Debian Linux distributions.

# Usage
Download script to any dir <br>
Run script as root <br>
Follow terminal instructions <br>
Done!

#Development Status
No future updates, only fixes

# Copyright and License
Copyright [2015] [Beesham/HunterIT]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
