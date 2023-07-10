On the ltpp3-g2, an interface can be temporarily configured
with an ip/ipv6 address by using the following command:

1. IPv4:
sudo ifconfig eth1 1.2.0.1/24

2. IPv6:
sudo ifconfig eth1 inet6 add 1:2::1/64

NOTE: DO NOT execute 'netplan apply' afterwards!

3. FLUSH an interface with command:
sudo ip addr flush dev eth1

REMARK:
in the above steps 'eth1' can be replaced by any other interface-name (e.g. eth0, br0, wlan0)