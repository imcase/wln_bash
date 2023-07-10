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

#---STRING CONSTANTS
EMPTYSTRING=""
COLON=":"
NOT_FOUND="<NOT FOUND>"

#---ACTION/REACTION CONSTANTS
ACTIVE="active"
CONNECTED="connected"
NOT_CONNECTED="not-connected"
DELETED="deleted"
INSERTED="inserted"
DISABLED="disabled"
ENABLED="enabled"
ENABLE="enable"
DISABLE="disable"
ISACTIVE="is-active"
ISENABLED="is-enabled"
STATE_UP="up"
STATE_DOWN="down"
STATE_UNKNOWN="unknown"

#---COUNTER CONSTANTS
CONN_RETRY_MAX=3
CONN_STATUS_CHECK_CTR_MAX=10
IPADDR_CTR_MAX=10
INTFSTATESET_RETRY_MAX=10

#---ENVIRONMENT CONSTANTS
WLAN0="wlan0"
WPA_SUPPLICANT="wpa_supplicant"
WPA_SUPPLICANT_SRV="wpa_supplicant.service"
WPA_SUPPLICANT_DAEMON_SRV="wpa_supplicant_daemon.service"
WPA_WLAN0_CONF="wpa-wlan0.conf"
WPA_WLAN0_LOG="wpa-wlan0.log"
ETC_TIBBO_LOG_WLN_DIR="/etc/tibbo/log/wln"
if [[ ! -d "${ETC_TIBBO_LOG_WLN_DIR}" ]]; then
    mkdir -p "${ETC_TIBBO_LOG_WLN_DIR}"
fi
ETC_TIBBO_NETPLAN_WLN_DIR="/etc/tibbo/netplan/wln"
if [[ ! -d "${ETC_TIBBO_NETPLAN_WLN_DIR}" ]]; then
    mkdir -p "${ETC_TIBBO_NETPLAN_WLN_DIR}"
fi
ETC_NETPLAN_DIR="/etc/netplan"
RUN_NETPLAN_DIR="/run/netplan"
WLAN_YAML_FPATH="/etc/netplan/wlan.yaml"
WLAN_YAML_WPASUPPLICANT_FPATH="/etc/tibbo/netplan/wln/wlan.yaml.wpasupplicant"
WPA_SUPPLICANT_CONF_FPATH="/etc/wpa_supplicant.conf"
WPA_SUPPLICANT_EXEC_FPATH="/sbin/wpa_supplicant"
WPA_WLAN0_CONF_FPATH="/run/netplan/wpa-wlan0.conf"
WPA_WLAN0_LOG_FPATH="/etc/tibbo/log/wln/wpa-wlan0.log"

#---PATTERN CONSTANTS
PATTERN_ACCESS_POINTS="access-points"
PATTERN_GLOBAL="global"
PATTERN_GREP="grep"
PATTERN_INET="inet"
PATTERN_INET6="inet6"
PATTERN_SSID="ssid"
PATTERN_UP="UP"
PATTERN_DOWN="DOWN"
PATTERN_WLAN0_CLTR_EVENT_CONNECTED="wlan0: CTRL-EVENT-CONNECTED"

#---PRINT CONSTANTS
PRINT_CONNECTED_TO="connected to"
PRINT_ASSIGNED_IPV4_ADDRESS="assigned ipv4 address"
PRINT_ASSIGNED_IPV6_ADDRESS="assigned ipv6 address"
PRINT_CLEAR_FILE="clear file"

PRINT_DONE="${FG_YELLOW}DONE${NOCOLOR}"
PRINT_FAILED="${FG_SOFLIGHTRED}FAILED${NOCOLOR}"
PRINT_NOT_FOUND="${FG_SOFLIGHTRED}${NOT_FOUND}${NOCOLOR}"
PRINT_STATUS="${FG_ORANGE}STATUS${NOCOLOR}"
PRINT_START="${FG_LIGHTGREEN}start${NOCOLOR}"
PRINT_STOP="${FG_SOFLIGHTRED}stop${NOCOLOR}"
PRINT_SUCCESSFUL="${FG_LIGHTGREEN}SUCCESSFUL${NOCOLOR}"



#---VARIABLES
isconnected=false
netplan_apply_cmd="netplan apply"
wifi_ip_flush_cmd="ip addr flush dev ${WLAN0}"
wlan_yaml_remove_cmd="rm ${WLAN_YAML_FPATH}"
wpa_supplicant_netplan_daemon_run_cmd="${WPA_SUPPLICANT_EXEC_FPATH} -B -c ${WPA_WLAN0_CONF_FPATH} -f ${WPA_WLAN0_LOG_FPATH} -i${WLAN0}"
ret=false



#---SUPPORT FUNCTIONS
Connection_Check_And_Data_Retrieval() {
    #Define constants
    local PHASE_SSID_CONNECTION_CHECK=1
    local PHASE_IPV4_RETRIEVE=10
    local PHASE_IPV6_RETRIEVE=20
    local PHASE_EXIT=100

    #Define variables
    local phase="${PHASE_SSID_CONNECTION_CHECK}"
    local ctr=0
    local grep_result="${EMPTYSTRING}"
    local ipv4_retrieved="${EMPTYSTRING}"
    local ipv6_retrieved="${EMPTYSTRING}"
    local netmaskv4_retrieved="${EMPTYSTRING}"
    local netmaskv6_retrieved="${EMPTYSTRING}"
    local ssid="${EMPTYSTRING}"

    local connectedtossid=false
    local ipv4isfound=false
    local ipv6isfound=false

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
cat ${WPA_WLAN0_LOG_FPATH}
                    #Check if connected
                    grep_result=$(sudo grep "${PATTERN_WLAN0_CLTR_EVENT_CONNECTED}" "${WPA_WLAN0_LOG_FPATH}")
                    if [[ -n "${grep_result}" ]]; then
                        #Update boolean
                        connectedtossid=true

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
                if [[ ${connectedtossid} == true ]]; then
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_CONNECTED_TO} ${FG_LIGHTGREY}${ssid}${NOCOLOR}: ${PRINT_SUCCESSFUL}"

                    phase="${PHASE_IPV4_RETRIEVE}"
                else
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_CONNECTED_TO} ${FG_LIGHTGREY}${ssid}${NOCOLOR}: ${PRINT_FAILED}"

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
                        #Update boolean
                        ipv4isfound=true

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
                if [[ ${ipv4isfound} = true ]]; then
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_ASSIGNED_IPV4_ADDRESS}: ${FG_LIGHTGREY}${ipv4_retrieved}${NOCOLOR}/${netmaskv4_retrieved}"
                else
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_ASSIGNED_IPV4_ADDRESS}: ${PRINT_NOT_FOUND}"
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
                        #Update boolean
                        ipv6isfound=true

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
                if [[ ${ipv6isfound} = true ]]; then
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_ASSIGNED_IPV6_ADDRESS}: ${FG_LIGHTGREY}${ipv6_retrieved}${NOCOLOR}/${netmaskv6_retrieved}"
                else
                    echo -e ":-->${PRINT_STATUS}: ${PRINT_ASSIGNED_IPV6_ADDRESS}: ${PRINT_NOT_FOUND}"
                fi

                #Goto next-phase
                phase="${PHASE_EXIT}"
                ;;
            "${PHASE_EXIT}")
                #Determine 'isconnected'
                if [[ ${connectedtossid} == false ]]; then
                    isconnected=false
                else    #connectedtossid = true
                    if [[ ${ipv4isfound} == false ]] && [[ ${ipv6isfound} == false ]]; then
                        isconnected=false
                    else    #ipv4isfound = true and/or ipv6isfound = true
                        isconnected=true
                    fi
                fi

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
        ret=true

        echo -e ":-->${PRINT_STATUS}: ${FG_LIGHTGREY}${iscmd}${NOCOLOR}: ${PRINT_DONE}"
    else
        ret=false

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

    #Write to file
    echo -e "${isdata}" | tee "${istargetfpath}" >/dev/null; pid=$!; wait ${pid}; exitcode=$?

    #Print
    if [[ ${exitcode} -eq 0 ]]; then
        echo -e ":-->${PRINT_STATUS}: ${PRINT_CLEAR_FILE} ${FG_LIGHTGREY}${istargetfpath}${NOCOLOR}: ${PRINT_DONE}"
    else
        echo -e ":-->${PRINT_STATUS}: ${PRINT_CLEAR_FILE} ${FG_LIGHTGREY}${istargetfpath}${NOCOLOR}: ${PRINT_FAILED}"
    fi
}

Wpa_Supplicant_Service_DisableStop() {
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

Wpa_Supplicant_Daemon_Service_DisableStop() {
    #Define variables
    local wpa_supplicant_daemon_srv_disable="systemctl disable ${WPA_SUPPLICANT_DAEMON_SRV}"
    local wpa_supplicant_daemon_srv_stop="systemctl stop ${WPA_SUPPLICANT_DAEMON_SRV}"

    #Execute commands
    CmdExec "${wpa_supplicant_daemon_srv_disable}"
    CmdExec "${wpa_supplicant_daemon_srv_stop}"
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
    local PHASE_NETPLAN_APPLY=50
    local PHASE_WPA_APPLICANT_NETPLAN_DAEMON_START=60
    local PHASE_CONNECTION_STATUS_CHECK=70
    local PHASE_CONNECTION_STATUS_WRITE_TO_FILE=80
    local PHASE_EXIT=100

    #Define variables
    local phase="${PHASE_WPA_SUPPLICANT_SERVICE_DISABLESTOP}"
    local connection_status="${NOT_CONNECTED}"
    local filecontent="${EMPTYSTRING}"
    local ctr=1

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_WPA_SUPPLICANT_SERVICE_DISABLESTOP}")
                #Reset variable
                ret=false

                #Stop and Disable 'wpa_supplicant.service'
                Wpa_Supplicant_Service_DisableStop

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
                phase="${PHASE_NETPLAN_APPLY}"
                ;;
            "${PHASE_NETPLAN_APPLY}")
                #Execute netplan apply
                #IMPORTANT TO KNOW:
                #1. Everytime when changes are made to wlan.yaml,
                #   ...'netplan apply' MUST be executed to (re-)create
                #   ...the file 'wpa-wlan0.conf'.
                #2. Do NOT use 'netplan generate'. Even though, 
                #   ...the file 'wpa-wlan0.conf' is generated, but still 
                #   ...it is required for that file to be applied once.
                #3. If file 'wpa-wlan0.conf' is NOT applied, then:
                #     a. connection to an SSID is possible, but...
                #     b. no ip address will be assigned.
                CmdExec "${netplan_apply_cmd}"

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
                #Check if 'wpa_supplicant_netplan_daemon_run_cmd' was executed successfully
                if [[ ${ret} == true ]]; then   #successful
                    #Check SSID connection status -> determine 'isconnected' {true|false}
                    #   Retrieve IPv4 address/netmask
                    #   Retrieve IPv6 address/netmask
                    Connection_Check_And_Data_Retrieval
                else    #failed
                    isconnected=false
                fi

                #Check if a connection is connected to the specified SSID
                #Please note that 'isconnected' is a global variable.
                if [[ ${isconnected} == true ]]; then   #connected
                    #Update status
                    connection_status="${CONNECTED}"

                    #Goto next-phase
                    phase="${PHASE_CONNECTION_STATUS_WRITE_TO_FILE}"
                else    #not connected
                    if [[ ${ctr} -eq ${CONN_RETRY_MAX} ]]; then
                        phase="${PHASE_CONNECTION_STATUS_WRITE_TO_FILE}"
                    else
                        #Increment counter
                        ((ctr++))

                        #Go back to the beginning of this loop
                        phase="${PHASE_WPA_SUPPLICANT_SERVICE_DISABLESTOP}"
                    fi

                    #Update status
                    connection_status="${NOT_CONNECTED}"
                fi
                ;;
            "${PHASE_CONNECTION_STATUS_WRITE_TO_FILE}")
                #Update filecontent
                filecontent="${WPA_SUPPLICANT_DAEMON_SRV}:${connection_status}"

                #Write to file
                WriteToFile "${WPA_WLAN0_LOG_FPATH}" "${filecontent}"

                #Goto next-phase
                phase="${PHASE_EXIT}"
                ;;
            "${PHASE_EXIT}")
                if [[ ${isconnected} == false ]]; then   #not connected
                    # CmdExec "${wlan_yaml_remove_cmd}"

                    Wpa_Supplicant_Daemon_Service_DisableStop
                fi

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
