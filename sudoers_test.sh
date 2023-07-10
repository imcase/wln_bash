#!/bin/bash

#---Define path variables
echo -e "\r"
echo "---Defining Varabiles (Filenames, Directories, Paths, Full-Paths)---"
echo -e "\r"
bin_dir=/bin
etc_dir=/etc
etc_default_dir=${etc_dir}/default
etc_profile_d_dir=${etc_dir}/profile.d
lib_dir=/lib
sbin_dir=/sbin
usr_dir=/usr
sbin_init_dir=${sbin_dir}/init
bin_systemctl_fpath=${bin_dir}/systemctl
usr_bin_dir=${usr_dir}/bin
usr_lib_dir=${usr_dir}/lib
usr_local_bin_dir=${usr_dir}/local/bin
etc_systemd_system_dir=${etc_dir}/systemd/system
etc_systemd_system_multi_user_target_wants_dir=${etc_systemd_system_dir}/multi-user.target.wants

systemd_fpath=${lib_dir}/systemd/systemd
localtime_dir=${etc_dir}/localtime
zoneinfo_dir=${usr_dir}/share/zoneinfo

passwd_fpath=${etc_dir}/passwd
sudo_fpath=${usr_bin_dir}/sudo

sshd_fpath=${etc_dir}/ssh/sshd_config
yaml_fpath=${etc_dir}/netplan/\*.yaml

# enable_eth1_before_login_service_filename="enable-eth1-before-login.service"
# enable_eth1_before_login_service_fpath=${etc_systemd_system_dir}/${enable_eth1_before_login_service_filename}
# enable_eth1_before_login_service_symlink_fpath=${etc_systemd_system_multi_user_target_wants_dir}/${enable_eth1_before_login_service_filename}

# daisychain_state_service_filename="daisychain_state.service"
# daisychain_state_service_fpath=${etc_systemd_system_dir}/${daisychain_state_service_filename}
# daisychain_state_service_symlink_fpath=${etc_systemd_system_multi_user_target_wants_dir}/${daisychain_state_service_filename}

create_chown_pwm_service_filename="create-chown-pwm.service"
create_chown_pwm_service_fpath=${etc_systemd_system_dir}/${create_chown_pwm_service_filename}
create_chown_pwm_service_symlink_fpath=${etc_systemd_system_multi_user_target_wants_dir}/${create_chown_pwm_service_filename}

one_time_exec_before_login_service_filename="one-time-exec-before-login.service"
one_time_exec_before_login_service_fpath=${etc_systemd_system_dir}/${one_time_exec_before_login_service_filename}
one_time_exec_before_login_service_symlink_fpath=${etc_systemd_system_multi_user_target_wants_dir}/${one_time_exec_before_login_service_filename}

enable_ufw_before_login_service_filename="enable-ufw-before-login.service"
enable_ufw_before_login_service_fpath=${etc_systemd_system_dir}/${enable_ufw_before_login_service_filename}
enable_ufw_before_login_service_symlink_fpath=${etc_systemd_system_multi_user_target_wants_dir}/${enable_ufw_before_login_service_filename}

environment_fpath=${etc_dir}/environment

arm_linux_gnueabihf_filename="arm-linux-gnueabihf"
arm_linux_gnueabihf_fpath=${usr_lib_dir}/${arm_linux_gnueabihf_filename}

wifipwrmgmt_sh_filename="wifipwrmgmt.sh"
wifipwrmgmt_sh_fpath=${usr_local_bin_dir}/${wifipwrmgmt_sh_filename}

wifipwrmgmt_run_sh_filename="wifipwrmgmt_run.sh"
wifipwrmgmt_run_sh_fpath=${etc_profile_d_dir}/${wifipwrmgmt_run_sh_filename}



username="ubuntu"


		echo "" | tee -a ${etc_dir}/sudoers
        echo "#---:MY ADDED SUDOERS:---" | tee -a ${etc_dir}/sudoers
		echo "${username} ALL=(ALL:ALL) ALL" | tee -a ${etc_dir}/sudoers
		echo "${username} ALL=(root) NOPASSWD: ${bin_systemctl_fpath} start ntios-su-add@*" | tee -a ${etc_dir}/sudoers
