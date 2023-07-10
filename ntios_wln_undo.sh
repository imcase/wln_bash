#Remove UFW ports
sudo ufw delete allow 53
sudo ufw delete allow 67
sudo ufw delete allow 68
sudo ufw delete allow 547
sudo ufw delete allow 5553

#Reset sysctl.conf
sudo sed -i 's/^net.ipv4.ip_forward=1/#net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sed -i 's/^net.ipv6.conf.all.forwarding=1/#net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf

#Stop & Disable Services
sudo systemctl stop hostapd.service
sudo systemctl disable hostapd.service
sudo systemctl stop hostapd-ng.service
sudo systemctl disable hostapd-ng.service
sudo systemctl stop ip6tables.service
sudo systemctl disable ip6tables.service
sudo systemctl stop iptables.service
sudo systemctl disable iptables.service
sudo systemctl stop dnsmasq.service
sudo systemctl disable dnsmasq.service
sudo systemctl stop wifi-powersave-off.service
sudo systemctl disable wifi-powersave-off.service
sudo systemctl stop wpa_supplicant_daemon.service
sudo systemctl disable wpa_supplicant_daemon.service
sudo systemctl stop wpa_supplicant_netplan_daemon_kill.service
sudo systemctl disable wpa_supplicant_netplan_daemon_kill.service

#Remove dirs
sudo rm -rf /etc/iptables

#Remove files
sudo rm /etc/systemd/system/iptables.service
sudo rm /etc/systemd/system/ip6tables.service
sudo rm /etc/systemd/system/wifi-powersave-off.service
sudo rm /etc/systemd/system/wifi-powersave-off.timer
sudo rm /usr/local/bin/wifi-powersave-off.sh
sudo rm /etc/systemd/system/hostapd-ng.service
sudo rm /usr/local/bin/hostapd-ng.sh
sudo rm /etc/systemd/system/hostapd-ng-autorecover.service
sudo rm /etc/systemd/system/hostapd-ng-autorecover.timer
sudo rm /usr/local/bin/hostapd-ng-autorecover.sh
sudo rm /usr/local/bin/ntios-wln-autoresetconnect.sh
sudo rm /etc/systemd/system/ntios-wln-autoresetconnect.service
sudo rm /usr/local/bin/wpa_supplicant_daemon.sh
sudo rm /etc/systemd/system/wpa_supplicant_daemon.service
sudo rm /usr/local/bin/wpa_supplicant_netplan_daemon_kill.sh
sudo rm /etc/systemd/system/wpa_supplicant_netplan_daemon_kill.service

# sudo rm /etc/dnsmasq.conf
# sudo rm /etc/wpa_supplicant.conf
sudo rm -rf /etc/hostapd
sudo rm -rf /etc/iptables
sudo rm -rf /etc/ip6tables
sudo rm -rf /etc/tibbo
sudo rm -rf /etc/wln

# #Run wpa_supplicant-daemon
# sudo wpa_supplicant -B -c /etc/wpa_supplicant.conf -iwlan0

#Set country-code to TW
sudo iw reg set TW

#Bring down br0
sudo ip link set dev br0 down
sudo ip link del br0

#Bring down wlan0
sudo ip link set dev wlan0 down

#Remove wlan.yaml
sudo rm /etc/netplan/wlan.yaml

#Rstore *.yaml
sudo cp /etc/netplan/*.yaml.bck /etc/netplan/*.yaml

#Apply netplan
sudo netplan apply

#Uninstall software
sudo apt -y remove --purge bridge-utils
sudo apt -y remove --purge dnsmasq
sudo apt -y remove --purge hostapd
sudo apt -y remove --purge iw
sudo apt -y remove --purge wireless-tools
sudo apt -y remove --purge wpasupplicant

sudo apt -y autoremove
