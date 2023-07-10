#!/bin/bash
#---INPUT ARGS
#Possible input values: enable | disable
action=${1}

#---THIS SCRIPT'S PID
mypid=${BASHPID}

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
ACTIVE="active" #WLN_ACTIVE
DELETED="deleted"
INSERTED="inserted"
DISABLED="disabled" #WLN_DISABLED
ENABLED="enabled"   #WLN_ENABLED
ENABLE="enable" #WLN_ENABLE
DISABLE="disable"   #WLN_DISABLE
ISACTIVE="is-active"    #WLN_ISACTIVE
ISENABLED="is-enabled"  #WLN_ISENABLED
STATE_UP="up"    #WLN_UP
STATE_DOWN="down"    #WLN_DOWN
STATE_UNKNOWN="unknown"     #WLN_UNKNOWN

#---COUNTER CONSTANTS
CONN_RETRY_MAX=3   #WLN_CONN_RETRY_MAX
CONN_STATUS_CHECK_CTR_MAX=30 #WLN_CONN_STATUS_CHECK_CTR_MAX
IPADDR_CTR_MAX=3    #WLN_IPADDR_CTR_MAX
INTFSTATESET_RETRY_MAX=10  #WLN_INTFSTATESET_RETRY_MAX

#---ENVIRONMENT CONSTANTS
WLAN0="wlan0"   #WLN_WLAN0
WPA_SUPPLICANT="wpa_supplicant" #WLN_WPA_SUPPLICANT
WPA_SUPPLICANT_SRV="wpa_supplicant.service" #WLN_WPA_SUPPLICANT_SRV
WPA_SUPPLICANT_DAEMON_SRV="wpa_supplicant_daemon.service" #WLN_WPA_SUPPLICANT_DAEMON_SRV
WPA_WLAN0_CONF="wpa-wlan0.conf"   #WLN_WPA_WLAN0_CONF
WPA_WLAN0_LOG="wpa-wlan0.log"     #WLN_WPA_WLAN0_LOG
ETC_TIBBO_LOG_WLN_DIR="/etc/tibbo/log/wln"    #ETC_TIBBO_LOG_WLN_DIR
if [[ ! -d "${ETC_TIBBO_LOG_WLN_DIR}" ]]; then
    mkdir -p "${ETC_TIBBO_LOG_WLN_DIR}"
fi
ETC_TIBBO_NETPLAN_WLN_DIR="/etc/tibbo/netplan/wln"  #WLN_ETC_TIBBO_NETPLAN_WLN_DIR
if [[ ! -d "${ETC_TIBBO_NETPLAN_WLN_DIR}" ]]; then
    mkdir -p "${ETC_TIBBO_NETPLAN_WLN_DIR}"
fi
ETC_NETPLAN_DIR="/etc/netplan"  #WLN_ETC_NETPLAN_DIR
RUN_NETPLAN_DIR="/run/netplan"  #WLN_RUN_NETPLAN_DIR
WPA_SUPPLICANT_CONF_FPATH="/etc/wpa_supplicant.conf"    #WLN_WPA_SUPPLICANT_CONF_FPATH
WPA_SUPPLICANT_EXEC_FPATH="/sbin/wpa_supplicant"    #WLN_WPA_SUPPLICANT_EXEC_FPATH
WLN_WLAN_YAML_FPATH="/etc/netplan/wlan.yaml"    #WLN_WLAN_YAML_FPATH
WLN_WLAN_YAML_WPASUPPLICANT_FPATH="/etc/tibbo/netplan/wln/wlan.yaml.wpasupplicant"
WPA_WLAN0_CONF_FPATH="/run/netplan/wpa-wlan0.conf" #WLN_WPA_WLAN0_CONF_FPATH
WPA_WLAN0_LOG_FPATH="/etc/tibbo/log/wln/wpa-wlan0.log" #WLN_WPA_WLAN0_LOG_FPATH

#---PATTERN CONSTANTS
PATTERN_ACCESS_POINTS="access-points"   #WLN_PATTERN_ACCESS_POINTS
PATTERN_GLOBAL="global" #WLN_PATTERN_GLOBAL
PATTERN_GREP="grep" #WLN_PATTERN_GREP
PATTERN_INET="inet" #WLN_PATTERN_INET
PATTERN_INET6="inet6"   #WLN_PATTERN_INET6
PATTERN_SSID="ssid" #WLN_PATTERN_SSID
PATTERN_UP="UP"     #WLN_PATTERN_UP
PATTERN_DOWN="DOWN" #WLN_PATTERN_DOWN
PATTERN_WLAN0_CLTR_EVENT_CONNECTED="wlan0: CTRL-EVENT-CONNECTED" #WLN_PATTERN_WLAN0_CLTR_EVENT_CONNECTED

#---PRINT CONSTANTS
PRINT_CONNECTION_TO="Connection to"
PRINT_ASSIGNED_IPV4_ADDRESS="assigned ipv4 address"
PRINT_ASSIGNED_IPV6_ADDRESS="assigned ipv6 address"
PRINT_CLEAR_FILE="clear file"

PRINT_DONE="${FG_YELLOW}DONE${NOCOLOR}"
PRINT_FAILED="${FG_SOFLIGHTRED}FAILED${NOCOLOR}"
PRINT_NONE="${FG_LIGHTGREY}${NONE}${NOCOLOR}"
PRINT_STATUS="${FG_ORANGE}STATUS${NOCOLOR}"
PRINT_START="${FG_LIGHTGREEN}start${NOCOLOR}"
PRINT_STOP="${FG_SOFLIGHTRED}stop${NOCOLOR}"
PRINT_SUCCESSFUL="${FG_LIGHTGREEN}SUCCESSFUL${NOCOLOR}"

#---STRING CONSTANTS
EMPTYSTRING=""  #WLN_EMPTYSTRING
COLON=":"   #WLN_COLON
NONE="<none>"



#---VARIABLES
isconnected=false
netplan_generate_cmd="netplan generate"
wifi_ip_flush_cmd="ip addr flush dev ${WLAN0}"
wlan_yaml_backup_cmd="mv ${WLN_WLAN_YAML_FPATH} ${WLN_WLAN_YAML_WPASUPPLICANT_FPATH}"
wlan_yaml_restore_cmd="mv ${WLN_WLAN_YAML_WPASUPPLICANT_FPATH} ${WLN_WLAN_YAML_FPATH}"
wpa_supplicant_netplan_daemon_run_cmd="${WPA_SUPPLICANT_EXEC_FPATH} -B -c ${WPA_WLAN0_CONF_FPATH} -f ${WPA_WLAN0_LOG_FPATH} -i${WLAN0}"
wpa_wlan0_conf_remove_cmd="rm ${WPA_WLAN0_CONF_FPATH}"



#---SUPPORT FUNCTIONS
Connection_Check_And_Data_Retrieval() {
    #Define constants
    local PHASE_SSID_CONNECTION_CHECK=1
    local PHASE_IPV4_RETRIEVE=10
    local PHASE_IPV6_RETRIEVE=20
    local PHASE_EXIT=100

    #Define variables
    local phase="${PHASE_SSID_CONNECTION_CHECK}"
    local grep_result="${EMPTYSTRING}"
    local ipv4_retrieved="${EMPTYSTRING}"
    local ipv6_retrieved="${EMPTYSTRING}"
    local netmaskv4_retrieved="${EMPTYSTRING}"
    local netmaskv6_retrieved="${EMPTYSTRING}"
    local ssid="${EMPTYSTRING}"
    local ctr=0

    #Initialize global variable
    isconnected=false

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SSID_CONNECTION_CHECK}")
                ctr=0

                while [[ ${ctr} -lt ${CONN_STATUS_CHECK_CTR_MAX} ]]
                do
                    #Check if connected
                    grep_result=$(sudo grep "${PATTERN_WLAN0_CLTR_EVENT_CONNECTED}" "${WPA_WLAN0_LOG_FPATH}")
                    if [[ -n "${grep_result}" ]]; then
                        #Update boolean
                        isconnected=true

                        #break loop
                        break
                    fi

                    #Sleep for 1 second
                    sleep 1

                    #Increment counter
                    ((ctr++))
                done

                #Get ssid
                ssid=$(grep "${PATTERN_SSID}" "${WPA_SUPPLICANT_CONF_FPATH}" | xargs | cut -d"=" -f2)

                #Print
                if [[ ${isconnected} == true ]]; then
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_CONNECTION_TO} ${FG_LIGHTGREY}${ssid}${NOCOLOR}: ${PRINT_SUCCESSFUL}"

                    phase="${PHASE_IPV4_RETRIEVE}"
                else
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_CONNECTION_TO} ${FG_LIGHTGREY}${ssid}${NOCOLOR}: ${PRINT_FAILED}"

                    phase="${PHASE_EXIT}"
                fi
                ;;
            "${PHASE_IPV4_RETRIEVE}")
                ctr=0

                while [[ ${ctr} -lt ${IPADDR_CTR_MAX} ]]
                do
                    #Retrieve IPv4-address
                    ipv4_retrieved=$(Ipaddr_Retrieve "${PATTERN_INET}" "${PATTERN_GLOBAL}")

                    if [[ -n "${ipv4_retrieved}" ]]; then
                        #Retrieve netmask
                        netmaskv4_retrieved=$(Netmask_Retrieve "${PATTERN_INET}" "${PATTERN_GLOBAL}")

                        #break loop
                        break
                    fi

                    #Sleep for 1 second
                    sleep 1

                    #Increment counter
                    ((ctr++))
                done

                #Print
                if [[ -n "${ipv4_retrieved}" ]]; then
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_ASSIGNED_IPV4_ADDRESS}: ${FG_LIGHTGREY}${ipv4_retrieved}${NOCOLOR}/${netmaskv4_retrieved}"
                else
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_ASSIGNED_IPV4_ADDRESS}: ${PRINT_NONE}"
                fi
                #Goto next-phase
                phase="${PHASE_IPV6_RETRIEVE}"
                ;;
            "${PHASE_IPV6_RETRIEVE}")
                ctr=0

                while [[ ${ctr} -lt ${IPADDR_CTR_MAX} ]]
                do
                    #Retrieve IPv4-address
                    ipv6_retrieved=$(Ipaddr_Retrieve "${PATTERN_INET6}" "${PATTERN_GLOBAL}")

                    if [[ -n "${ipv6_retrieved}" ]]; then
                        #Retrieve netmask
                        netmaskv6_retrieved=$(Netmask_Retrieve "${PATTERN_INET6}" "${PATTERN_GLOBAL}")

                        #break loop
                        break
                    fi

                    #Sleep for 1 second
                    sleep 1

                    #Increment counter
                    ((ctr++))
                done

                #Print
                if [[ -n "${ipv6_retrieved}" ]]; then
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_ASSIGNED_IPV6_ADDRESS}: ${FG_LIGHTGREY}${ipv6_retrieved}${NOCOLOR}/${netmaskv6_retrieved}"
                else
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_ASSIGNED_IPV6_ADDRESS}: ${PRINT_NONE}"
                fi

                #Goto next-phase
                phase="${PHASE_EXIT}"
                ;;
            "${PHASE_EXIT}")
                break
                ;;
        esac
    done
}
Ipaddr_Retrieve() {
    #Input args
    local ispattern1=${1}
    local ispattern2=${2}

    #Define variables
    local ipaddr="${EMPTYSTRING}"

    #Retrieve IP-address
    ipaddr=$(ip addr show ${WLAN0} | grep -w "${ispattern1}" | grep -w "${ispattern2}" | grep -o "${ispattern1}.*" | awk '{print $2}' | cut -d"/" -f1)

    #Output
    echo "${ipaddr}"

    return 0;
}
Netmask_Retrieve() {
    #Input args
    local ispattern1=${1}
    local ispattern2=${2}

    #Define variables
    local netmask="${EMPTYSTRING}"

    #Retrieve IP-address
    netmask=$(ip addr show ${WLAN0} | grep -w "${ispattern1}" | grep -w "${ispattern2}" | grep -o "${ispattern1}.*" | awk '{print $2}' | cut -d"/" -f2)

    #Output
    echo "${netmask}"

    return 0;
}

CmdExec() {
    #Input args
    local iscmd=${1}

    #Kill all wpa_supplicant daemons
    ${iscmd}; pid=$!; wait ${pid}; exitcode=$?

    #Print
    if [[ ${exitcode} -eq 0 ]]; then
        echo -e ":-->${PRINT_STATUS}: ${FG_LIGHTGREY}${iscmd}${NOCOLOR}: ${PRINT_DONE}"
    else
        echo -e ":-->${PRINT_STATUS}: ${FG_LIGHTGREY}${iscmd}${NOCOLOR}: ${PRINT_FAILED}"
    fi
}

IntfStateGet() {
    #Define variables
    local intfstate="${EMPTYSTRING}"
    local intfstate_ucase="${EMPTYSTRING}"
    local intfstate_fpath="${EMPTYSTRING}"

    #Set interface-state fullpath
    intfstate_fpath="/sys/class/net/${WLAN0}/operstate"

    #Get interface-state from file
    if [[ -f "${intfstate_fpath}" ]]; then
        intfstate=$(cat "${intfstate_fpath}")
    else
        intfstate="${STATE_UNKNOWN}"
    fi

    #In case 'intfstate is still an Empty String',
    #...then get the interface-state via the 'ip' command.
    if [[ "${intfstate}" != "${STATE_UP}" ]] && [[ "${intfstate}" != "${STATE_DOWN}" ]]; then
        intfstate_ucase=$(ip a list "${WLAN0}" | grep -o "${PATTERN_UP}.*" | cut -d"," -f1)

        #Translate 'intfstate_alternative' to 'intfstate'
        if [[ "${intfstate_ucase}" == "${PATTERN_UP}" ]]; then
            intfstate="${STATE_UP}"
        else
            intfstate="${STATE_DOWN}"
        fi
    fi

    #Output
    echo "${intfstate}"

    return 0;
}
IntfStateSet() {
    #Define variables
    local cmd="${EMPTYSTRING}"
    local intfstateset_retry=0

    #Check if interface is already up
    if [[ $(IntfStateGet) == "${STATE_UP}" ]]; then
        return 0;
    fi

    #Bring interface up
    while [[ ${retry} -lt ${INTFSTATESET_RETRY_MAX} ]]
    do
        #If retry > 0, then bring interface down first
        if [[ ${retry} -gt 0 ]]; then
            cmd="ip link set dev ${WLAN0} down"
            CmdExec "${cmd}"
        fi

        #Bring interface up
        cmd="ip link set dev ${WLAN0} up"
        CmdExec "${cmd}"

        #Get interface-state
        if [[ $(IntfStateGet) == "${STATE_UP}" ]]; then
            break
        fi

        #Wait for 1 second
        sleep 1

        #Increment counter
        ((retry++))
    done
}

KillAllPids() {
    #Input args
    local ispattern=${1}
    local ispidexclude=${2}

    #Define variables
    local cmd="${EMPTYSTRING}"
    local pid_listarr=()
    local pid_listarritem="${EMPTYSTRING}"
    local pid_listarrlen=0

    #Get pids for the specified 'ispattern'
    pid_listarr=($(ps axf | grep "${ispattern}" | grep -v "${PATTERN_GREP}" | awk '{print $1}'))

    #Get array-length
    pid_listarrlen=${#pid_listarr[@]}
    if [[ ${pid_listarrlen} -eq 0 ]]; then
        return 0;
    fi

    #Cycle thru array
    for pid_listarritem in "${pid_listarr[@]}"
    do
        if [[ ${pid_listarritem} -ne ${ispidexclude} ]]; then
            cmd="kill -9 ${pid_listarritem}"

            CmdExec "${cmd}"
        fi
    done
}

WriteToFile() {
    #Input args
    local istargetfpath=${1}
    local isdata=${2}

    #Define variables
    local ret=false

    #Write to file
    echo -e "${isdata}" | tee "${istargetfpath}" >/dev/null; pid=$!; wait ${pid}; exitcode=$?

    #Print
    if [[ ${exitcode} -eq 0 ]]; then
        echo -e ":-->${PRINT_STATUS}: ${PRINT_CLEAR_FILE} ${FG_LIGHTGREY}${istargetfpath}${NOCOLOR}: ${PRINT_DONE}"
    else
        echo -e ":-->${PRINT_STATUS}: ${PRINT_CLEAR_FILE} ${FG_LIGHTGREY}${istargetfpath}${NOCOLOR}: ${PRINT_FAILED}"
    fi
}

Wpa_Supplicant_StopDisable(){
    #Define variables
    local cmd="${EMPTYSTRING}"

    #Check if service is-active
    if [[ $(systemctl is-active ${WPA_SUPPLICANT_SRV}) == "${ACTIVE}" ]]; then
        cmd="systemctl stop ${WPA_SUPPLICANT_SRV}"
        CmdExec "${cmd}"
    fi

    #Check if service is-enabled
    if [[ $(systemctl is-enabled ${WPA_SUPPLICANT_SRV}) == "${ENABLED}" ]]; then
        cmd="systemctl disable ${WPA_SUPPLICANT_SRV}"
        CmdExec "${cmd}"
    fi
}



#---MAIN FUNCTIONS
Start_Handler() {
    #Define constants
    local PHASE_WPA_SUPPLICANT_SERVICE_DISABLESTOP=1
    local PHASE_WPA_APPLICANT_PROCS_KILL_1STTIME=2
    local PHASE_IP_FLUSH_ALL=10
    local PHASE_WPA_WLAN0_LOG_CLEAR=20
    local PHASE_WLAN_YAML_MODIFY_ACCESS_POINTS_NAME=30
    local PHASE_INTFSTATE_CHECK_AND_SET=40
    local PHASE_NETPLAN_GENERATE=50
    local PHASE_WPA_APPLICANT_NETPLAN_DAEMON_START=60
    local PHASE_CONNECTION_STATUS_CHECK=70
    local PHASE_EXIT=100

    #Define variables
    local phase="${PHASE_WPA_SUPPLICANT_SERVICE_DISABLESTOP}"
    local ctr=0

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_WPA_SUPPLICANT_SERVICE_DISABLESTOP}")
                #Stop and Disable 'wpa_supplicant.service'
                Wpa_Supplicant_StopDisable

                #Goto next-phase
                phase="${PHASE_WPA_APPLICANT_PROCS_KILL_1STTIME}"
                ;;
            "${PHASE_WPA_APPLICANT_PROCS_KILL_1STTIME}")
                #Kill ALL wpa_supplicant daemons
                #   These daemons include:
                #   1. wpa_supplicant.service daemon
                #   2. initiated via command: /sbin/wpa_supplicant
                #   3. wpa_supplicant netplan daemon
                KillAllPids "${WPA_SUPPLICANT_CONF_FPATH}" "${mypid}"
                KillAllPids "${WPA_WLAN0_CONF_FPATH}" "${mypid}"

                #Goto next-phase
                phase="${PHASE_IP_FLUSH_ALL}"
                ;;
            "${PHASE_IP_FLUSH_ALL}")
                #Flush wifi-interface ip isdata
                CmdExec "${wifi_ip_flush_cmd}"

                #Goto next-phase
                phase="${PHASE_WPA_WLAN0_LOG_CLEAR}"
                ;;
            "${PHASE_WPA_WLAN0_LOG_CLEAR}")
                #Check if log-file is present
                if [[ -f ${WPA_WLAN0_LOG_FPATH} ]]; then
                    #Clear log-file content (do not remove file)
                    WriteToFile "${WPA_WLAN0_LOG_FPATH}" "${EMPTYSTRING}"
                fi

                #Goto next-phase
                phase="${PHASE_INTFSTATE_CHECK_AND_SET}"
                ;;
            "${PHASE_INTFSTATE_CHECK_AND_SET}")
                #Check and set interface-state
                IntfStateSet

                #Goto next-phase
                phase="${PHASE_NETPLAN_GENERATE}"
                ;;
            "${PHASE_NETPLAN_GENERATE}")
                #Execute netplan apply
                #IMPORTANT TO KNOW:
                #1. Everytime when changes are made to wlan.yaml,
                #   ...'netplan generate' MUST be executed to (re-)create
                #   ...the file 'wpa-wlan0.conf'.
                CmdExec "${netplan_generate_cmd}"

                #Goto next-phase
                phase="${PHASE_WPA_APPLICANT_NETPLAN_DAEMON_START}"
                ;;
            "${PHASE_WPA_APPLICANT_NETPLAN_DAEMON_START}")
                #Execute the wpa_supplicant netplan daemon,
                #...but now output messages to the specified log-file
                CmdExec "${wpa_supplicant_netplan_daemon_run_cmd}"

                #Goto next-phase
                phase="${PHASE_CONNECTION_STATUS_CHECK}"
                ;;
            "${PHASE_CONNECTION_STATUS_CHECK}")
                #Check SSID connection status
                #Retrieve IPv4 address/netmask
                #Retrieve IPv6 address/netmask
                Connection_Check_And_Data_Retrieval

                #Check if a connection is established to the specified SSID
                #Please note that 'isconnected' is a global variable.
                if [[ ${isconnected} == true ]]; then   #established
                    phase="${PHASE_EXIT}"
                else    #not established
                    if [[ ${ctr} == ${CONN_RETRY_MAX} ]]; then
                        phase="${PHASE_EXIT}"
                    else
                        #Increment counter
                        ((ctr++))

                        #Go back to the beginning of this loop
                        phase="${PHASE_WPA_SUPPLICANT_SERVICE_DISABLESTOP}"
                    fi
                fi
                ;;
            "${PHASE_EXIT}")
                break
                ;;
        esac
    done
}
Stop_Handler() {
    #Define variables
    #Kill ALL wpa_supplicant daemons
    #   These daemons could be:
    #   1. wpa_supplicant.service daemon
    #   2. initiated via command: /sbin/wpa_supplicant
    #   3. wpa_supplicant netplan daemon
    KillAllPids "${WPA_SUPPLICANT_CONF_FPATH}" "${mypid}"
    KillAllPids "${WPA_WLAN0_CONF_FPATH}" "${mypid}"
}



#---SELECT CASE
case "${action}" in
    "${ENABLE}")
        #Start subroutine in the BACKGROUND (&)
        Start_Handler
        ;;
    "${DISABLE}")
        Stop_Handler
        ;;
esac
