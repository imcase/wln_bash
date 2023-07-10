#!/bin/bash
#---Input args
#Possible input values: enable | disable
action=${1}



#---COLORS CONSTANTS
NOCOLOR=$'\e[0m'

FG_ORANGE=$'\e[30;38;5;209m'
FG_LIGHTGREY=$'\e[30;38;5;246m'
FG_LIGHTGREEN=$'\e[30;38;5;71m'
FG_LIGHTBLUE=$'\e[30;38;5;45m'
FG_LIGHTRED=$'\e[1;31m'
FG_SOFLIGHTRED=$'\e[30;38;5;131m'
FG_YELLOW=$'\e[1;33m'

#---BOOLEAN CONSTANTS
ENABLE="enable"
DISABLE="disable"



#---ENVIRONMENT VARIABLES
autoresetconnect_sh="ntios-net-autoresetconnect.sh"
autoreconnectonboot_service="ntios-net-autoreconnectonboot.service"
autoreconnectonboot_runatlogin_dst_fpath="/etc/profile.d/ntios-net-autoreconnectonboot-runatlogin.sh"
autoreconnectonboot_runatlogin_src_fpath="/etc/tibbo/profile.d/net/ntios-net-autoreconnectonboot-runatlogin.sh"
reloadconnect_service="ntios-net-reloadconnect.service"
resetconnect_service="ntios-net-resetconnect.service"
yaml_fpath="/etc/netplan/*.yaml"
yaml_autoreconnect_fpath="/etc/tibbo/netplan/net/*.yaml.autoresetconnect"
yaml_org_fpath="/etc/tibbo/netplan/net/*.yaml.org"



#---PRINT VARIABLES
print_header=":-->${FG_ORANGE}STATUS${NOCOLOR}"
print_status_aborted="${FG_LIGHTBLUE}ABORTED${NOCOLOR} (Ignore)"
print_status_alreadydisabled="${FG_YELLOW}ALREADY DISABLED${NOCOLOR}"
print_status_disabled="${FG_SOFLIGHTRED}DISABLED${NOCOLOR}"
print_status_alreadyenabled="${FG_YELLOW}ALREADY ENABLED${NOCOLOR}"
print_status_enabled="${FG_LIGHTGREEN}ENABLED${NOCOLOR}"
print_status_executed="${FG_LIGHTBLUE}EXECUTED${NOCOLOR}"
print_status_alreadyexecuted="${FG_YELLOW}ALREADY EXECUTED${NOCOLOR}"
print_status_different="${FG_SOFLIGHTRED}DIFFERENT${NOCOLOR}"
print_status_done="${FG_LIGHTGREEN}DONE${NOCOLOR}"
print_status_identical="${FG_YELLOW}IDENTICAL${NOCOLOR}"
print_status_notfound="${FG_SOFLIGHTRED}NOT FOUND${NOCOLOR}"


#---SUBROUTINES
exit_if_files_are_same() {
    #Input args
    local file1=${1}
    local file2=${2}

    #Check if file exist
    if [[ ! -f "${file1}" ]] && [[ ! -f "${file2}" ]]; then
        echo -e "${print_header}: ${FG_LIGHTGREY}${autoresetconnect_sh}${NOCOLOR}: ${print_status_aborted}"

        exit
    elif [[ ! -f "${file1}" ]]; then
        echo -e "${print_header}: ${FG_LIGHTGREY}${autoresetconnect_sh}${NOCOLOR}: ${print_status_aborted}"

        exit
    elif [[ ! -f "${file2}" ]]; then
        echo -e "${print_header}: ${FG_LIGHTGREY}${autoresetconnect_sh}${NOCOLOR}: ${print_status_aborted}"

        exit
    fi

    #Remark:
    # Using this check, we can make sure that this script
    # ...is only excecuted if the content of 'file1' and
    # ...'file2' are not the same.
    diff_result=`diff "${file1}" "${file2}"`
    if [[ -z "${diff_result}" ]]; then
        echo -e "${print_header}: ${FG_LIGHTGREY}${autoresetconnect_sh}${NOCOLOR}: ${print_status_alreadyexecuted}"

        exit
    else
        echo -e "${print_header}: ${FG_LIGHTGREY}${autoresetconnect_sh}${NOCOLOR}: ${print_status_executed}"
    fi
}

copy_org2yaml__sub() {
    if [[ -f "${yaml_org_fpath}" ]]; then
        cp "${yaml_org_fpath}" "${yaml_fpath}"

        echo -e "${print_header}: copy ${FG_LIGHTGREY}${yaml_org_fpath}${NOCOLOR} to ${FG_LIGHTGREY}${yaml_fpath}${NOCOLOR}: ${print_status_done}"
    fi
}

copy_yaml2org__sub() {
    if [[ -f "${yaml_fpath}" ]]; then
        cp "${yaml_fpath}" "${yaml_org_fpath}"

        echo -e "${print_header}: copy ${FG_LIGHTGREY}${yaml_fpath}${NOCOLOR} to ${FG_LIGHTGREY}${yaml_org_fpath}${NOCOLOR}: ${print_status_done}"
    fi
}

copy_autoreconnect2yaml_sub() {
    if [[ -f "${yaml_autoreconnect_fpath}" ]]; then
        cp "${yaml_autoreconnect_fpath}" "${yaml_fpath}"

        echo -e "${print_header}: copy ${FG_LIGHTGREY}${yaml_autoreconnect_fpath}${NOCOLOR} to ${FG_LIGHTGREY}${yaml_fpath}${NOCOLOR}: ${print_status_done}"
    fi
}

copy_autoreconnectonboot_runatlogin_src2dst() {
    if [[ -f "${autoreconnectonboot_runatlogin_src_fpath}" ]]; then
        cp "${autoreconnectonboot_runatlogin_src_fpath}" "${autoreconnectonboot_runatlogin_dst_fpath}"

        echo -e "${print_header}: copy ${FG_LIGHTGREY}${autoreconnectonboot_runatlogin_src_fpath}${NOCOLOR} to ${FG_LIGHTGREY}${autoreconnectonboot_runatlogin_src_fpath}${NOCOLOR}: ${print_status_done}"
    fi
}

remove_autoreconnectonboot_runatlogin_dst() {
    if [[ -f "${autoreconnectonboot_runatlogin_dst_fpath}" ]]; then
        rm "${autoreconnectonboot_runatlogin_dst_fpath}"

        echo -e "${print_header}: rm ${FG_LIGHTGREY}${autoreconnectonboot_runatlogin_dst_fpath}${NOCOLOR}: ${print_status_done}"
    fi    
}

netplan_apply__sub() {
    netplan apply &>/dev/null

    echo -e "${print_header}: netplan apply: ${print_status_done}"
}

systemctl_disable() {
    #Input args
    local softlinkfpath=${1}

    #Define variables
    local srv_name=$(basename "$softlinkfpath") 

    #Remove file (if present)
    if [[ -f "${softlinkfpath}" ]]; then
        rm "${softlinkfpath}"

        echo -e "${print_header}: service ${FG_LIGHTGREY}${srv_name}${NOCOLOR}: ${print_status_disabled}"
    else
        echo -e "${print_header}: service ${FG_LIGHTGREY}${srv_name}${NOCOLOR}: ${print_status_alreadydisabled}"
    fi
}
systemctl_enable() {
    #Input args
    local targetfpath=${1}
    local softlinkfpath=${2}

    #Define variables
    local srv_name=$(basename "$softlinkfpath") 

    #Create file (if missing)
    if [[ ! -f "${softlinkfpath}" ]]; then
        ln -s "${targetfpath}" "${softlinkfpath}"

        echo -e "${print_header}: file ${FG_LIGHTGREY}${softlinkfpath}${NOCOLOR}: ${print_status_enabled}"
    else
        echo -e "${print_header}: file ${FG_LIGHTGREY}${softlinkfpath}${NOCOLOR}: ${print_status_alreadyenabled}"
    fi
}



#---MAIN SUBROUTINE
enable_handler() {
    remove_autoreconnectonboot_runatlogin_dst

    exit_if_files_are_same "${yaml_fpath}" "${yaml_autoreconnect_fpath}"

    mkdir__sub

    copy_yaml2org__sub

    copy_autoreconnect2yaml_sub
}
disable_handler() {
    copy_autoreconnectonboot_runatlogin_src2dst

    exit_if_files_are_same "${yaml_fpath}" "${yaml_org_fpath}"

    mkdir__sub

    copy_org2yaml__sub
}



#---SELECT CASE
case "${action}" in
    "${ENABLE}")
        enable_handler
        ;;
    "${DISABLE}")
        disable_handler
        ;;
esac
