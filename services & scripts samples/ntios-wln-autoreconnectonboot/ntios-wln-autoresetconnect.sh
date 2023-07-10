#!/bin/bash 
#---Input args
action=${1}     #valid input values {enable|disable}
bssmode=${2}    #valid input values {infrastructure|accesspoint|router}



#---COLORS CONSTANTS
WLN_RESETCOLOR=$'\e[0m'
WLN_ORANGE=$'\e[30;38;5;209m'
WLN_LIGHTGREY=$'\e[30;38;5;246m'
WLN_LIGHTGREEN=$'\e[30;38;5;71m'
WLN_LIGHTBLUE=$'\e[30;38;5;45m'
WLN_LIGHTRED=$'\e[1;31m'
WLN_SOFLIGHTRED=$'\e[30;38;5;131m'
WLN_YELLOW=$'\e[1;33m'

#---BSSMODE CONSTANTS
WLN_SERVICE_INPUTARG_INFRASTRUCTURE="infrastructure"
WLN_SERVICE_INPUTARG_ACCESSPOINT="accesspoint"
WLN_SERVICE_INPUTARG_ROUTER="router"

#---ENVIRONMENT CONSTANTS
WLN_DNSMASQ_CONF_FPATH="/etc/dnsmasq.conf"
WLN_DNSMASQ_CONF_AUTORECONNECTONBOOT_FPATH="/etc/tibbo/dnsmasq/wln/dnsmasq.conf.autoreconnectonboot"
WLN_DNSMASQ_CONF_CURRENT_FPATH="/etc/tibbo/dnsmasq/wln/dnsmasq.conf.current"
WLN_HOSTAPD_CONF_FPATH="/etc/hostapd/hostapd.conf"
WLN_HOSTAPD_CONF_AUTORECONNECTONBOOT_FPATH="/etc/tibbo/hostapd/wln/hostapd.conf.autoreconnectonboot"
WLN_HOSTAPD_CONF_CURRENT_FPATH="/etc/tibbo/hostapd/wln/hostapd.conf.current"
WLN_HOSTAPD_NG_SERVICE_FPATH="/etc/systemd/system/hostapd-ng.service"
WLN_HOSTAPD_NG_SERVICE_AUTORECONNECTONBOOT_FPATH="/etc/tibbo/hostapd/wln/hostapd-ng.service.autoreconnectonboot"
WLN_HOSTAPD_NG_SERVICE_CURRENT_FPATH="/etc/tibbo/hostapd/wln/hostapd-ng.service.current"
WLN_IPTABLES_RULES_V4_FPATH="/etc/iptables/rules.v4"
WLN_IPTABLES_RULES_V4_AUTORECONNECTONBOOT_FPATH="/etc/tibbo/iptables/wln/rules.v4.autoreconnectonboot"
WLN_IPTABLES_RULES_V4_CURRENT_FPATH="/etc/tibbo/iptables/wln/rules.v4.current"
WLN_IP6TABLES_RULES_V6_FPATH="/etc/ip6tables/rules.v6"
WLN_IP6TABLES_RULES_V6_AUTORECONNECTONBOOT_FPATH="/etc/tibbo/ip6tables/wln/rules.v6.autoreconnectonboot"
WLN_IP6TABLES_RULES_V6_CURRENT_FPATH="/etc/tibbo/ip6tables/wln/rules.v6.current"
WLN_NTIOS_WLN_AUTORECONNECTONBOOT_LOG_FPATH="/etc/tibbo/log/wln/ntios-wln-autoreconnectonboot.log"
WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_SRC_FPATH="/etc/tibbo/profile.d/wln/ntios-wln-autoreconnectonboot-runatlogin.sh"
WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_DST_FPATH="/etc/profile.d/ntios-wln-autoreconnectonboot-runatlogin.sh"
WLN_NTIOS_WLN_RELOADCONNECT_SRV_FPATH="/etc/systemd/system/ntios-wln-reloadconnect.service"
WLN_NTIOS_WLN_RESETCONNECT_SRV_FPATH="/etc/systemd/system/ntios-wln-resetconnect.service"
WLN_WLAN_YAML_FPATH="/etc/netplan/wlan.yaml"
WLN_WLAN_YAML_AUTORECONNECTONBOOT_FPATH="/etc/tibbo/netplan/wln/wlan.yaml.autoreconnectonboot"
WLN_WLAN_YAML_CURRENT_FPATH="/etc/tibbo/netplan/wln/wlan.yaml.current"

#---OTHER CONSTANTS
WLN_EMPTYSTRING=""

#---PHASE CONSTANTS
PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_DISABLE=1
PHASE_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_HANDLER=10
PHASE_WLN_AUTORECONNECTONBOOT_NETPLAN_HANDLER=20
PHASE_WLN_AUTORECONNECTONBOOT_DNSMASQ_HANDLER=30
PHASE_WLN_AUTORECONNECTONBOOT_IPTABLES_HANDLER=40
PHASE_WLN_AUTORECONNECTONBOOT_IP6TABLES_HANDLER=50
PHASE_WLN_AUTORECONNECTONBOOT_HOSTAPD_HANDLER=60
PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE=70
PHASE_WLN_AUTORECONNECTONBOOT_EXIT=100

#---PRINT CONSTANTS
WLN_PRINTMSG_STATUS=":-->${WLN_ORANGE}STATUS${WLN_RESETCOLOR}"
WLN_PRINTMSG_DONE="${WLN_YELLOW}DONE${WLN_RESETCOLOR}"
WLN_PRINTMSG_FAILED="${WLN_SOFLIGHTRED}FAILED${WLN_RESETCOLOR}"
WLN_PRINTMSG_NOT="${WLN_SOFLIGHTRED}NOT${WLN_RESETCOLOR}"

#---SERVICES CONSTANTS
WLN_DNSMASQ_SRV="dnsmasq.service"
WLN_HOSTAPD_NG_SRV="hostapd-ng.service"
WLN_IPTABLES_SRV="iptables.service"
WLN_IP6TABLES_SRV="ip6tables.service"
WLN_WIFI_POWERSAVE_OFF_SRV="wifi-powersave-off.service"
WLN_WIFI_POWERSAVE_OFF_TIMER="wifi-powersave-off.timer"
WLN_WPA_SUPPLICANT_DAEMON_SRV="wpa_supplicant_daemon.service"
WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV="wpa_supplicant_netplan_daemon_kill.service"

#---STATES CONSTANTS
WLN_DISABLE="disable"
WLN_ENABLE="enable"
WLN_DISABLED="disabled"
WLN_ENABLED="enabled"



#---VARIABLES
phase="${WLN_EMPTYSTRING}"
timestamp=0
dnsmasq_current_timestamp_fpath="${WLN_DNSMASQ_CONF_CURRENT_FPATH}.${timestamp}"
hostapd_conf_current_timestamp_fpath="${WLN_HOSTAPD_CONF_CURRENT_FPATH}.${timestamp}"
rules_v4_current_timestamp_fpath="${WLN_IPTABLES_RULES_V4_CURRENT_FPATH}.${timestamp}"
rules_v6_current_timestamp_fpath="${WLN_IP6TABLES_RULES_V6_CURRENT_FPATH}.${timestamp}"
wlan_yaml_current_timestamp_fpath="${WLN_WLAN_YAML_CURRENT_FPATH}.${timestamp}"



#---FUNCTIONS
CheckIfFilesAreIdentical() {
    #Input args
    local isfpath1=${1}
    local isfpath2=${2}

    #Define variables
    local stdoutput=${WLN_EMPTYSTRING}
    local ret=false

    #Check if files are identical
    if cmp --silent -- "${isfpath1}" "${isfpath2}"; then
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}

FileExists() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local stdoutput=${WLN_EMPTYSTRING}
    local ret=false

    #Check if file exists
    if sudo test -f "${istargetfpath}"; then
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}

CopyFile() {
    #Input args
    local issourcefpath=${1}
    local istargetfpath=${2}
    local isvalidatefpath=${3}

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local printmsg="${WLN_EMPTYSTRING}"
    local exitcode=0
    local pid=0

    #Check if 'issourcefpath' exists
    if [[ $(FileExists "${issourcefpath}") == true ]]; then
        #Check if 'issourcefpath' is identical to 'isvalidatefpath'
        #Remark:
        #   This check has been implemented to make sure that
        #       'istargetfpath' is not overwritten by 'issourcefpath'
        #       in case the contents of 'issourcefpath' is the same 
        #       as that of 'isvalidatefpath'.
        if [[ $(FileExists "${istargetfpath}") == true ]] && [[ -n ${isvalidatefpath} ]]; then
            #Check if 'issourcefpath = isvalidatefpath'.
            #If true, then exit function.
            if [[ $(CheckIfFilesAreIdentical "${issourcefpath}" "${isvalidatefpath}") == true ]]; then
                return 0;
            fi
        fi
        
        #Write to file
        cp "${issourcefpath}" "${istargetfpath}" >/dev/null; exitcode=$?; pid=$!; wait ${pid}

        #Print
        if [[ ${exitcode} -eq 0 ]]; then
            printmsg="${WLN_PRINTMSG_STATUS}: copy from '${WLN_LIGHTGREY}${issourcefpath}${WLN_RESETCOLOR}' "
                printmsg+="to '${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}': ${WLN_PRINTMSG_DONE}"
        else
            printmsg="${WLN_PRINTMSG_STATUS}: copy from '${WLN_LIGHTGREY}${issourcefpath}${WLN_RESETCOLOR}' "
                printmsg+="to '${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}': ${WLN_PRINTMSG_FAILED}"
        fi
    else
        printmsg="${WLN_PRINTMSG_STATUS}: copy from '${WLN_LIGHTGREY}${issourcefpath}${WLN_RESETCOLOR}' "
            printmsg+="to '${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}': ${WLN_PRINTMSG_NOT} exist"
    fi

    #Print
    echo -e "${printmsg}"
}

RemoveFile() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"

    #Remove 'wifi-powersave-off.service'
    if [[ $(FileExists "${istargetfpath}") == true ]]; then
        sudo rm "${istargetfpath}" >/dev/null; exitcode=$?; pid=$!; wait ${pid}

        if [[ ${exitcode} -eq 0 ]]; then
            printmsg="${WLN_PRINTMSG_STATUS}: Remove ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"
        else
            printmsg="${WLN_PRINTMSG_STATUS}: Remove ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"
        fi
    else
        printmsg="${WLN_PRINTMSG_STATUS}: file '${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}' "
        printmsg+="does ${WLN_PRINTMSG_NOT} exist (ignore)"
    fi

    #Print
    echo -e "${printmsg}"
}

systemctlDisableService() {
    #Input args
    local srv_name=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local exitcode=0
    local pid=0

    #Disable service
    if [[ $(SystemctlServiceIsEnabled "${srv_name}") == true ]]; then
        systemctl disable "${srv_name}" >/dev/null; exitcode=$?; pid=$!; wait ${pid}
    fi

    #Choose print-message
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Disable ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Disable ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"
    fi

    #Print
    echo -e "${printmsg}"
}

SystemctlEnableService() {
    #Input args
    local srv_name=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"


    #Enable service
    if [[ $(SystemctlServiceIsEnabled "${srv_name}") == false ]]; then
        systemctl enable "${srv_name}" >/dev/null; exitcode=$?; pid=$!; wait ${pid}
    fi

    #Choose print-message
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Enable ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Enable ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"
    fi

    #Print
    echo -e "${printmsg}"
}

SystemctlServiceIsEnabled() {
    #Input args
    local srv_name=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local srv_state="${WLN_DISABLED}"
    local pid=0
    local ret=false

    #Get service -state (enabled/disabled)
    srv_state=$(sudo systemctl is-enabled "${srv_name}" ; pid=$! ; wait ${pid})

    #Choose print-message
    if [[ "${srv_state}" == "${WLN_ENABLED}" ]]; then
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}



#---MAIN SUBROUTINE
append_timestamp_tofile_handler() {
    if [[ $(FileExists "${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_LOG_FPATH}") == true ]]; then
        timestamp=$(cat "${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_LOG_FPATH}")

        dnsmasq_current_timestamp_fpath="${WLN_DNSMASQ_CONF_CURRENT_FPATH}.${timestamp}"
        hostapd_conf_current_timestamp_fpath="${WLN_HOSTAPD_CONF_CURRENT_FPATH}.${timestamp}"
        hostapdng_service_current_timestamp_fpath="${WLN_HOSTAPD_NG_SERVICE_CURRENT_FPATH}.${timestamp}"
        rules_v4_current_timestamp_fpath="${WLN_IPTABLES_RULES_V4_CURRENT_FPATH}.${timestamp}"
        rules_v6_current_timestamp_fpath="${WLN_IP6TABLES_RULES_V6_CURRENT_FPATH}.${timestamp}"
        wlan_yaml_current_timestamp_fpath="${WLN_WLAN_YAML_CURRENT_FPATH}.${timestamp}"
    fi
}

enable_handler() {
    append_timestamp_tofile_handler

    phase="${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_DISABLE}"

    while true
    do
        case "${phase}" in
            "${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_DISABLE}")
                systemctlDisableService "${WLN_WPA_SUPPLICANT_DAEMON_SRV}"
                systemctlDisableService "${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}"
                systemctlDisableService "${WLN_DNSMASQ_SRV}"
                systemctlDisableService "${WLN_IPTABLES_SRV}"
                systemctlDisableService "${WLN_IP6TABLES_SRV}"
                systemctlDisableService "${WLN_HOSTAPD_NG_SRV}"
                systemctlDisableService "${WLN_WIFI_POWERSAVE_OFF_SRV}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_HANDLER}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_HANDLER}")
                RemoveFile "${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_DST_FPATH}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_NETPLAN_HANDLER}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_NETPLAN_HANDLER}")
                CopyFile "${WLN_WLAN_YAML_FPATH}" \
                        "${wlan_yaml_current_timestamp_fpath}" \
                        "${WLN_WLAN_YAML_AUTORECONNECTONBOOT_FPATH}"

                CopyFile "${WLN_WLAN_YAML_AUTORECONNECTONBOOT_FPATH}" \
                        "${WLN_WLAN_YAML_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}")
                CopyFile "${WLN_DNSMASQ_CONF_FPATH}" \
                        "${dnsmasq_current_timestamp_fpath}" \
                        "${WLN_DNSMASQ_CONF_AUTORECONNECTONBOOT_FPATH}"

                CopyFile "${WLN_DNSMASQ_CONF_AUTORECONNECTONBOOT_FPATH}" \
                        "${WLN_DNSMASQ_CONF_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_IPTABLES_HANDLER}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_IPTABLES_HANDLER}")
                CopyFile "${WLN_IPTABLES_RULES_V4_FPATH}" \
                        "${rules_v4_current_timestamp_fpath}" \
                        "${WLN_IPTABLES_RULES_V4_AUTORECONNECTONBOOT_FPATH}"

                CopyFile "${WLN_IPTABLES_RULES_V4_AUTORECONNECTONBOOT_FPATH}" \
                        "${WLN_IPTABLES_RULES_V4_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}")
                CopyFile "${WLN_IP6TABLES_RULES_V6_FPATH}" \
                        "${rules_v6_current_timestamp_fpath}" \
                        "${WLN_IP6TABLES_RULES_V6_AUTORECONNECTONBOOT_FPATH}"

                CopyFile "${WLN_IP6TABLES_RULES_V6_AUTORECONNECTONBOOT_FPATH}" \
                        "${WLN_IP6TABLES_RULES_V6_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}")
                CopyFile "${WLN_HOSTAPD_CONF_FPATH}" \
                        "${hostapd_conf_current_timestamp_fpath}" \
                        "${WLN_HOSTAPD_CONF_AUTORECONNECTONBOOT_FPATH}"

                CopyFile "${WLN_HOSTAPD_CONF_AUTORECONNECTONBOOT_FPATH}" \
                        "${WLN_HOSTAPD_CONF_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                #Persistent Overwrite
                CopyFile "${WLN_HOSTAPD_NG_SERVICE_FPATH}" \
                        "${hostapdng_service_current_timestamp_fpath}" \
                        "${WLN_EMPTYSTRING}"

                CopyFile "${WLN_HOSTAPD_NG_SERVICE_AUTORECONNECTONBOOT_FPATH}" \
                        "${WLN_HOSTAPD_NG_SERVICE_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE}")
                SystemctlEnableService "${WLN_DNSMASQ_SRV}"
                SystemctlEnableService "${WLN_IPTABLES_SRV}"
                SystemctlEnableService "${WLN_IP6TABLES_SRV}"
                SystemctlEnableService "${WLN_HOSTAPD_NG_SRV}"

                SystemctlEnableService "${WLN_WIFI_POWERSAVE_OFF_SRV}"
                SystemctlEnableService "${WLN_WIFI_POWERSAVE_OFF_TIMER}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_EXIT}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_EXIT}")
                break
                ;;
        esac
    done
}

timestamp_validate() {
    #Input args
    local istimestamp=${1}

    #Check 
}
disable_handler() {
    append_timestamp_tofile_handler

    phase="${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_DISABLE}"

    while true
    do
        case "${phase}" in
            "${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_DISABLE}")
                systemctlDisableService "${WLN_WPA_SUPPLICANT_DAEMON_SRV}"
                systemctlDisableService "${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}"
                systemctlDisableService "${WLN_DNSMASQ_SRV}"
                systemctlDisableService "${WLN_IPTABLES_SRV}"
                systemctlDisableService "${WLN_IP6TABLES_SRV}"
                systemctlDisableService "${WLN_HOSTAPD_NG_SRV}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_HANDLER}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_HANDLER}")
                CopyFile "${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_SRC_FPATH}" \
                        "${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_DST_FPATH}" \
                        "${WLN_EMPTYSTRING}"
                
                if [[ ${timestamp} -eq 0 ]]; then
                    phase="${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE}"
                else
                    phase="${PHASE_WLN_AUTORECONNECTONBOOT_NETPLAN_HANDLER}"
                fi
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_NETPLAN_HANDLER}")
                CopyFile "${wlan_yaml_current_timestamp_fpath}" \
                        "${WLN_WLAN_YAML_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}")
                CopyFile "${dnsmasq_current_timestamp_fpath}" \
                        "${WLN_DNSMASQ_CONF_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_IPTABLES_HANDLER}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_IPTABLES_HANDLER}")
                CopyFile "${rules_v4_current_timestamp_fpath}" \
                        "${WLN_IPTABLES_RULES_V4_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}")
                CopyFile "${rules_v6_current_timestamp_fpath}" \
                        "${WLN_IP6TABLES_RULES_V6_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}")
                CopyFile "${hostapd_conf_current_timestamp_fpath}" \
                        "${WLN_HOSTAPD_CONF_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                CopyFile "${hostapdng_service_current_timestamp_fpath}" \
                        "${WLN_HOSTAPD_NG_SERVICE_FPATH}" \
                        "${WLN_EMPTYSTRING}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE}")
                case "${bssmode}" in
                    "${WLN_SERVICE_INPUTARG_INFRASTRUCTURE}")
                        SystemctlEnableService "${WLN_WPA_SUPPLICANT_DAEMON_SRV}"
                        ;;
                    "${WLN_SERVICE_INPUTARG_ACCESSPOINT}")
                        SystemctlEnableService "${WLN_HOSTAPD_NG_SRV}"
                        ;;
                    "${WLN_SERVICE_INPUTARG_ROUTER}")
                        SystemctlEnableService "${WLN_DNSMASQ_SRV}"
                        SystemctlEnableService "${WLN_IPTABLES_SRV}"
                        SystemctlEnableService "${WLN_IP6TABLES_SRV}"
                        SystemctlEnableService "${WLN_HOSTAPD_NG_SRV}"
                        ;;
                esac

                SystemctlEnableService "${WLN_WIFI_POWERSAVE_OFF_SRV}"
                SystemctlEnableService "${WLN_WIFI_POWERSAVE_OFF_TIMER}"

                phase="${PHASE_WLN_AUTORECONNECTONBOOT_EXIT}"
                ;;
            "${PHASE_WLN_AUTORECONNECTONBOOT_EXIT}")
                break
                ;;
        esac
    done
}



#---SELECT CASE
case "${action}" in
    "${WLN_ENABLE}")
        enable_handler
        ;;
    "${WLN_DISABLE}")
        disable_handler
        ;;
esac
