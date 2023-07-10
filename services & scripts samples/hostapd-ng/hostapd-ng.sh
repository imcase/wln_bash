#!/bin/bash
#---Input args
#Possible input values: enable | disable
action=${1}



#---COLORS CONSTANTS
NOCOLOR=$'\e[0m'
FG_LIGHTRED=$'\e[1;31m'
FG_ORANGE=$'\e[30;38;5;209m'
FG_LIGHTBLUE=$'\e[30;38;5;45m'
FG_LIGHTGREY=$'\e[30;38;5;246m'
FG_LIGHTGREEN=$'\e[30;38;5;71m'
FG_SOFLIGHTRED=$'\e[30;38;5;131m'
FG_YELLOW=$'\e[1;33m'

#---BOOLEAN CONSTANTS
ENABLE="enable"
DISABLE="disable"
ENABLED="enabled"

#---COUNTER CONSTANTS
HOSTAPD_NG_DAEMON_RUN_RETRY_MAX=3

#---ENVIRONMENT CONSTANTS
ETC_TIBBO_LOG_WLN_DIR="/etc/tibbo/log/wln"
if [[ ! -d "${ETC_TIBBO_LOG_WLN_DIR}" ]]; then
    mkdir -p "${ETC_TIBBO_LOG_WLN_DIR}"
fi

DNSMASQ_SERVICE="dnsmasq.service"
HOSTAPD="hostapd"
HOSTAPD_NG="hostapd-ng"
HOSTAPD_NG_SERVICE="hostapd-ng.service"
IPTABLES_SERVICE="iptables.service"
IP6TABLES_SERVICE="ip6tables.service"
WLAN_YAML="wlan.yaml"

#---INTERFACE CONSTANTS
BR0="br0"
ETH0="eth0"
ETH1="eth1"
WLAN0="wlan0"
AP_BRIF_LIST="${WLAN0} ${ETH0} ${ETH1}"
RT_BRIF_LIST="${WLAN0}"

#---PATTERN CONSTANTS
PATTERN_BRIDGES="bridges"
PATTERN_GREP="grep"
PATTERN_INTERFACES="interfaces"

#---PRINT CONSTANTS
PRINT_BRCTL_ADD_BRIDGE_INTERFACE="brctl> ${FG_LIGHTGREEN}add${NOCOLOR} bridge interface"
PRINT_BRCTL_DEL_BRIDGE_INTERFACE="brctl> ${FG_LIGHTGREEN}del${NOCOLOR} bridge interface"
PRINT_BR0="${FG_LIGHTGREY}${BR0}${NOCOLOR}"
PRINT_INTERFACE_BRING_UP="interface> bring ${FG_LIGHTGREEN}up${NOCOLOR}"
PRINT_INTERFACE_BRING_DOWN="interface> bring ${FG_SOFLIGHTRED}down${NOCOLOR}"
PRINT_NETPLAN_APPLY="netplan> ${FG_LIGHTGREY}apply${NOCOLOR}"
PRINT_WLAN_YAML_INSERT_INTO_LINE="${WLAN_YAML}> ${FG_LIGHTGREEN}insert${NOCOLOR} into line"
PRINT_WLAN_YAML_DELETE_LINE="${WLAN_YAML}> ${FG_SOFLIGHTRED}delete${NOCOLOR} line"
PRINT_WAIT_FOR_1_SEC="wait for ${FG_LIGHTGREY}1${NOCOLOR} sec"

PRINT_DONE="${FG_YELLOW}DONE${NOCOLOR}"
PRINT_FAILED="${FG_SOFLIGHTRED}FAILED${NOCOLOR}"
PRINT_NONE="${FG_LIGHTGREY}${NONE}${NOCOLOR}"
PRINT_STATUS="${FG_ORANGE}STATUS${NOCOLOR}"
PRINT_START="${FG_LIGHTGREEN}start${NOCOLOR}"
PRINT_STOP="${FG_SOFLIGHTRED}stop${NOCOLOR}"
PRINT_SUCCESSFUL="${FG_LIGHTGREEN}SUCCESSFUL${NOCOLOR}"

#---SED CONSTANTS
SED_SIXSPACES_ESCAPED="\ \ \ \ \ \ "



#---COUNTER VARIABLES
start_retry=0
tcounter_sec=1

#---PATH VARIABLES
hostapd_conf_fpath="/etc/hostapd/hostapd.conf"
hostapd_exec_fpath="/usr/sbin/hostapd"
hostapd_log_fpath="/etc/tibbo/log/wln/hostapd.log"
hostapd_pid_fpath="/run/hostapd.run"
wlan_yaml_fpath="/etc/netplan/wlan.yaml"

#---VARIABLES
hostapd_daemon_run_cmd="${hostapd_exec_fpath} -B -P ${hostapd_pid_fpath} -f ${hostapd_log_fpath} ${hostapd_conf_fpath}"
hostapd_daemon_pid_kill_cmd="kill -9 \$(cat ${hostapd_pid_fpath})"
hostapd_daemon_pspid_retrieve_cmd="ps axf | grep \"${hostapd_exec_fpath}\" | grep -v \"${PATTERN_GREP}\""
hostapd_daemon_proc_kill_cmd="pkill -9 ${HOSTAPD}"

dnsmasq_isenabled=$(systemctl is-enabled ${DNSMASQ_SERVICE})
iptables_isenabled=$(systemctl is-enabled ${IPTABLES_SERVICE})
ip6tables_isenabled=$(systemctl is-enabled ${IP6TABLES_SERVICE})
if [[ "${dnsmasq_isenabled}" == "${ENABLED}" ]] && \
        [[ "${iptables_isenabled}" == "${ENABLED}" ]] && \
        [[ "${ip6tables_isenabled}" == "${ENABLED}" ]]; then
    brif_list_spacedelimited="${RT_BRIF_LIST}"
else
    brif_list_spacedelimited="${AP_BRIF_LIST}"
fi
brif_list_arr=($(echo ${brif_list_spacedelimited}))
brif_list_commadelimited=$(sed 's/ /,/g' <<< ${brif_list_spacedelimited})
sed_netplan_interfaces_svstart="${SED_SIXSPACES_ESCAPED}${PATTERN_INTERFACES}: [${brif_list_commadelimited}]"
sed_netplan_interfaces_svstop="${SED_SIXSPACES_ESCAPED}${PATTERN_INTERFACES}: [${RT_BRIF_LIST}]"



#---FUNCTIONS
hostapd_cleanup_files() {
    if [[ -f "${hostapd_pid_fpath}" ]]; then
        rm "${hostapd_pid_fpath}"
    fi

    if [[ -f "${hostapd_log_fpath}" ]]; then
        rm "${hostapd_log_fpath}"
    fi
}

hostapd_start() {
    #Initialize
    start_retry=0

    #Start loop
    while [[ ${start_retry} -lt ${HOSTAPD_NG_DAEMON_RUN_RETRY_MAX} ]]
    do
        #Run hostapd-daemon
        eval ${hostapd_daemon_run_cmd}
        #Check if pid-file has been created
        if [[ -f "${hostapd_pid_fpath}" ]]; then
            break
        fi

        #Increment index
        ((start_retry++))
    done
}

hostapd_start_print() {
    #Define variables
    local print_status=""
    local hostapd_daemon_pid=0

    #Print empty-line
    echo -e "\r"

    #Get pid from file
    hostapd_daemon_pid=$(cat ${hostapd_pid_fpath})

    #Check hostapd-ng daemon was started successfully.
    print_status=":-->${PRINT_STATUS}: ${PRINT_START} ${FG_LIGHTGREY}${HOSTAPD_NG} -> PID (${NOCOLOR}${hostapd_daemon_pid}${FG_LIGHTGREY})${NOCOLOR}: "
    if [[ -f "${hostapd_pid_fpath}" ]]; then    #successful
        print_status+="${PRINT_SUCCESSFUL}"
    else    #is Not Empty String
        print_status+="${PRINT_FAILED}"

        #IMPORTANT: Stop hostapd-ng service
        systemctl stop ${HOSTAPD_NG_SERVICE}
    fi

    #Print
    echo -e "${print_status}"

    #Print empty-line
    echo -e "\r"
}

hostapd_stop() {
    #Kill deamon based on pid found in /run/hostapd-ng.pid
    if [[ -f "${hostapd_pid_fpath}" ]]; then
        eval ${hostapd_daemon_pid_kill_cmd}
    fi

    #Double-check if pid has been killed
    if [[ -n $(eval ${hostapd_daemon_pspid_retrieve_cmd}) ]]; then
        eval ${hostapd_daemon_proc_kill_cmd}
    fi
}
hostapd_stop_print() {
    #Define variables
    local print_status=""
    local hostapd_daemon_pid=0

    #Print empty-line
    echo -e "\r"

    #Get pid from file
    if [[ -f ${hostapd_pid_fpath} ]]; then
        hostapd_daemon_pid=$(cat ${hostapd_pid_fpath})

        #Check if pid was killed
        print_status=":-->${PRINT_STATUS}: ${PRINT_STOP} ${FG_LIGHTGREY}${HOSTAPD_NG} -> PID (${NOCOLOR}${hostapd_daemon_pid}${FG_LIGHTGREY})${NOCOLOR}: "
        if [[ -z $(eval ${hostapd_daemon_pspid_retrieve_cmd}) ]]; then    #is Empty String
            print_status+="${PRINT_SUCCESSFUL}"
        else    #is Not Empty String
            print_status+="${PRINT_FAILED}"
        fi

        #Print
        echo -e "${print_status}"

        #Print empty-line
        echo -e "\r"
    fi
}

bridge_addif_and_print() {
    #Define variables
    local printmsg=""
    local linenum=0
    local nextlinenum=0

    #Add bridge interface
    ip link add name ${BR0} type bridge
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_BRCTL_ADD_BRIDGE_INTERFACE} ${FG_LIGHTGREY}${BR0}${NOCOLOR}: ${PRINT_DONE}"

    #Bring bridge interface up
    ip link set dev ${BR0} up
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_INTERFACE_BRING_UP} ${FG_LIGHTGREY}${BR0}${NOCOLOR}: ${PRINT_DONE}"

    #Get 'linenum' matching the pattern 'PATTERN_INTERFACES'
    linenum=$(interfaces_linenum_get)
    if [[ ${linenum} -eq 0 ]]; then
        return 0;
    fi

    #Insert
    sed -i "${linenum}i ${sed_netplan_interfaces_svstart}" "${wlan_yaml_fpath}"
    #Get printable string of 'sed_netplan_interfaces_svstart'
    printmsg=$(echo "${sed_netplan_interfaces_svstart}" | sed 's/\\//g')
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_WLAN_YAML_INSERT_INTO_LINE} '${FG_LIGHTGREY}${linenum}${NOCOLOR}': ${FG_LIGHTGREY}${printmsg}${NOCOLOR}: ${PRINT_DONE}\n"

    #Get 'nextlinenum'
    nextlinenum=$(( linenum + 1 ))
    #Delete 'nextlinenum'
    sed -i "${nextlinenum}d" "${wlan_yaml_fpath}"
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_WLAN_YAML_DELETE_LINE} '${FG_LIGHTGREY}${nextlinenum}${NOCOLOR}': ${PRINT_DONE}\n"

    #Apply netplan
    netplan apply
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_NETPLAN_APPLY}: ${PRINT_DONE}\n"

    #Wait for 1 second
    sleep 1
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_WAIT_FOR_1_SEC}: ${PRINT_DONE}\n"

    #Print empty-line
    echo -e "\r"
}

bridge_delif_and_print() {
    #Define variables
    local printmsg=""
    local linenum=0
    local nextlinenum=0

    #Bring bridge interface down
    ip link set dev ${BR0} down
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_INTERFACE_BRING_DOWN} ${FG_LIGHTGREY}${BR0}${NOCOLOR}: ${PRINT_DONE}"

    #Delete bridge interface
    ip link del ${BR0}
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_BRCTL_DEL_BRIDGE_INTERFACE} ${FG_LIGHTGREY}${BR0}${NOCOLOR}: ${PRINT_DONE}"

    #Get 'linenum' matching the pattern 'PATTERN_INTERFACES'
    linenum=$(interfaces_linenum_get)
    if [[ ${linenum} -eq 0 ]]; then
        return 0;
    fi

    #Insert
    sed -i "${linenum}i ${sed_netplan_interfaces_svstop}" "${wlan_yaml_fpath}"
    #Get printable string of 'sed_netplan_interfaces_svstop'
    printmsg=$(echo "${sed_netplan_interfaces_svstop}" | sed 's/\\//g')
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_WLAN_YAML_INSERT_INTO_LINE} '${FG_LIGHTGREY}${linenum}${NOCOLOR}': ${FG_LIGHTGREY}${printmsg}${NOCOLOR}: ${PRINT_DONE}\n"

    #Get 'nextlinenum'
    nextlinenum=$(( linenum + 1 ))
    #Delete 'nextlinenum'
    sed -i "${nextlinenum}d" "${wlan_yaml_fpath}"
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_WLAN_YAML_DELETE_LINE} '${FG_LIGHTGREY}${nextlinenum}${NOCOLOR}': ${PRINT_DONE}\n"

    #Apply netplan
    netplan apply
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_NETPLAN_APPLY}: ${PRINT_DONE}\n"

    #Wait for 1 second
    sleep 1
    #Print
    echo -e ":-->${PRINT_STATUS}: ${PRINT_WAIT_FOR_1_SEC}: ${PRINT_DONE}\n"

    #Print empty-line
    echo -e "\r"
}

interfaces_linenum_get() {
    #Define constants
    local PHASE_LINENUMS_GET=1
    local PHASE_BRIDGES_LINENUM_VALIDATE=10
    local PHASE_BR0_LINENUM_VALIDATE=20
    local PHASE_INTERFACES_LINENUM_VALIDATE=30
    local PHASE_EXIT=100

    #Define variables
    local phase="${PHASE_LINENUMS_GET}"
    local mytext="${WLN_EMPTYSTRING}"
    local br0_linenum=0
    local bridges_linenum=0
    local diff_linenum=0
    local interfaces_linenum=0

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_LINENUMS_GET}")
                #Get the line-numbers
                #Remark:
                #   The 'wlan.yaml' for ACCESSPOINT and ROUTER mode is designed
                #   ...to have the following inter-relationship between the line-numbers:
                #   bridges_linenum = based on the position in 'wlan.yaml' (e.g. 8)
                #   br0_linenum = bridges_linenum + 1 (e.g. 9)
                #   interfaces_linenum = br0_linenum + 1 (e.g. 10)
                bridges_linenum=$(grep -no "${PATTERN_BRIDGES}.*" "${wlan_yaml_fpath}" | cut -d":" -f1); exitcode=$?
                br0_linenum=$(grep -no "${BR0}.*" "${wlan_yaml_fpath}" | cut -d":" -f1); exitcode=$?
                interfaces_linenum=$(grep -no "${PATTERN_INTERFACES}.*" "${wlan_yaml_fpath}" | cut -d":" -f1); exitcode=$?

                #Goto next-phase
                phase="${PHASE_BRIDGES_LINENUM_VALIDATE}"
                ;;
            "${PHASE_BRIDGES_LINENUM_VALIDATE}")
                #Do not continue if 'bridges_linenum = <Empty String>'
                if [[ -z "${bridges_linenum}" ]]; then
                    #Set 'interfaces_linenum = 0'
                    interfaces_linenum=0

                    #Goto next-phase
                    phase="${PHASE_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_BR0_LINENUM_VALIDATE}"
                fi
                ;;
            "${PHASE_BR0_LINENUM_VALIDATE}")
                #Check if 'br0_linenum' is an Empty string or not.
                if [[ -z "${br0_linenum}" ]]; then
                    #Set 'interfaces_linenum = 0'
                    interfaces_linenum=0

                    #Goto next-phase
                    phase="${PHASE_EXIT}"
                else
                    #Check if 'diff_linenum = br0_linenum - bridges_linenum = 1'
                    diff_linenum=$((br0_linenum - bridges_linenum))
                    #Do not continue if 'diff_linenum != 1'
                    if [[ ${diff_linenum} -ne 1 ]]; then
                        #Set 'interfaces_linenum = 0'
                        interfaces_linenum=0

                        #Goto next-phase
                        phase="${PHASE_EXIT}"
                    else
                        #Goto next-phase
                        phase="${PHASE_INTERFACES_LINENUM_VALIDATE}"
                    fi
                fi
                ;;
            "${PHASE_INTERFACES_LINENUM_VALIDATE}")
                #Do not continue if 'interfaces_linenum = <Empty String>'
                if [[ -z "${interfaces_linenum}" ]]; then
                    #Set 'interfaces_linenum = 0'
                    interfaces_linenum=0
                else
                    #Check if 'diff_linenum = interfaces_linenum - br0_linenum = 1'
                    diff_linenum=$((interfaces_linenum - br0_linenum))
                    #Do not continue if 'diff_linenum != 1'
                    if [[ ${diff_linenum} -ne 1 ]]; then
                        #Set 'interfaces_linenum = 0'
                        interfaces_linenum=0
                    fi
                fi

                #Goto next-phase
                phase="${PHASE_EXIT}"
                ;;
            "${PHASE_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${interfaces_linenum}"

    return 0;
}



#---SUBROUTINES
stop_handler() {
    #Stop hostapd daemons
    hostapd_stop
    hostapd_stop_print

    #Unbridge interfaces
    bridge_delif_and_print

    #Cleanup files
    hostapd_cleanup_files
}

start_handler() {
    #Stop hostapd daemons (which were not killed last time)
    hostapd_stop
    hostapd_stop_print

    #Clean files (which were not cleaned up last time)
    hostapd_cleanup_files

    #Bridge interfaces
    bridge_addif_and_print

    #Initial start hostapd-daemon
    hostapd_start
    hostapd_start_print

    #If dnsmasq.service is enabled, then restart service.
    if [[ "${dnsmasq_isenabled}" == "${ENABLED}" ]]; then
        systemctl restart ${DNSMASQ_SERVICE}
    fi
}



#---Select case
case "${action}" in
    ${ENABLE})
        #Start subroutine in the BACKGROUND (&)
        start_handler
        ;;
    ${DISABLE})
        stop_handler
        ;;
esac
