# HAS_orangepilite2
Home Assistant Supervised auto-installation script for Orange Pi Lite 2

Tested on Armbian_community_26.2.0-trunk.592_Orangepilite2_trixie_current_6.18.18_minimal.

## Installation
1) Install the Armbian image and enable the Orange Pi.
2) When you first turn on your device, you will be asked to create a root password (you can also cancel the creation of a new user, leaving only root).
3) Log in as root.
4) Connect the Orange Pi to the internet (use armbian-config for Wi-Fi)
5) Update your system using these commands (the system will reboot automatically):
```bash
apt update && apt full-upgrade -y
reboot
```
6) After booting the system, log in as root.
7) Download and run the installation script **(during the execution of the script, the armbian-config interface will open. At this point, you need to reconnect the internet cable, or if you are using wifi, reconfigure your network connection)**.:
```bash
wget https://github.com/redn1ghtz/HAS_orangepilite2/blob/main/install_HAS.sh
chmod +x install_HAS.sh
./install_HAS.sh
```
8) Wait for 5-10 minutes or more, find out the IP address of the Orange Pi, and open the HA interface in your browser at **http://orangepi_ip:8123** (instead of orange_ip, enter the received IP address).
