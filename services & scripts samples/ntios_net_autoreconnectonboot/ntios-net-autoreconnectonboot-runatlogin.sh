#!/bin/bash
mypid=$$
sudo systemctl start ntios-su-add@${mypid}

srv_input=\\\\x2Fbin\\\\x2Frm\\\\x20\\\\x2A
sudo systemctl start ntios-su-add@${srv_input}

srv_input=\\\\x2Fusr\\\\x2Fbin\\\\x2Fsystemctl\\\\x20\\\\x2A
sudo systemctl start ntios-su-add@${srv_input}

sudo systemctl start ntios-net-autoreconnectonboot.service

sudo rm /etc/profile.d/ntios-net-autoreconnectonboot-runatlogin.sh
