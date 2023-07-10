# sudo systemctl stop iptables.service
# sudo systemctl disable iptables.service

# sudo systemctl stop ip6tables.service
# sudo systemctl disable ip6tables.service

# sudo rm /etc/systemd/system/iptables.service
# sudo rm /etc/systemd/system/ip6tables.service

# sudo rm -rf /etc/iptables
# sudo rm -rf /etc/ip6tables

sudo rm -rf /etc/tibbo/dnsmasq
sudo rm -rf /etc/tibbo/firmware
sudo rm -rf /etc/tibbo/hostapd
sudo rm -rf /etc/tibbo/ip6tables
sudo rm -rf /etc/tibbo/iptables
sudo rm -rf /etc/tibbo/netplan/wln
sudo rm -rf /etc/tibbo/profile.d/wln
