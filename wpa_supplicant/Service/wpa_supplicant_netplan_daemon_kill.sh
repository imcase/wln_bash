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

#---BOOLEANS CONSTANTS
ENABLE="enable"
DISABLE="disable"
START="start"
STOP="stop"

#---ENVIRONMENT CONSTANTS
WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV="wpa_supplicant_netplan_daemon_kill.service"
WPA_WLAN0_CONF_FPATH="/run/netplan/wpa-wlan0.conf"
WPA_WLAN0_LOG_FPATH="/etc/tibbo/log/wln/wpa-wlan0.log"

#---PATTERN CONSTANTS
PATTERN_GREP="grep"

#---PRINT CONSTANTS
PRINT_DONE="${FG_YELLOW}DONE${NOCOLOR}"
PRINT_FAILED="${FG_SOFLIGHTRED}FAILED${NOCOLOR}"
PRINT_STATUS="${FG_ORANGE}STATUS${NOCOLOR}"
PRINT_START="${FG_LIGHTGREEN}start${NOCOLOR}"
PRINT_STOP="${FG_SOFLIGHTRED}stop${NOCOLOR}"
PRINT_SUCCESSFUL="${FG_LIGHTGREEN}SUCCESSFUL${NOCOLOR}"
PRINT_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV="${FG_LIGHTGREY}${WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}${NOCOLOR}"

#---STRING CONSTANTS
EMPTYSTRING=""



#---SUPPORT FUNCTIONS
CmdExec() {
    #Input args
    local iscmd=${1}

    #Kill all wpa_supplicant daemons
    ${iscmd}; pid=$!; wait ${pid}; exitcode=$?

    #Print
    if [[ ${exitcode} -eq 0 ]]; then
        echo -e ":-->:${PRINT_STATUS}: ${FG_LIGHTGREY}${iscmd}${NOCOLOR}: ${PRINT_SUCCESSFUL}"
    else
        echo -e ":-->${PRINT_STATUS}: ${FG_LIGHTGREY}${iscmd}${NOCOLOR}: ${PRINT_FAILED}"
    fi
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
    #Note: the extra outer-bracket is to put the retrieved values in an array
    pid_listarr=($(ps axf | grep "${ispattern}" | grep -v "${PATTERN_GREP}" | grep -v "${WPA_WLAN0_LOG_FPATH}" | awk '{print $1}'))

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



#---MAIN FUNCTIONS
Start_Handler() {
    echo -e ":-->${PRINT_STATUS}: systemctl ${PRINT_START} ${PRINT_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}: ${PRINT_DONE}"

    KillAllPids "${WPA_WLAN0_CONF_FPATH}" "${mypid}"
}

Stop_Handler() {
    echo -e ":-->${PRINT_STATUS}: systemctl ${PRINT_STOP} ${PRINT_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}: ${PRINT_DONE}"
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
