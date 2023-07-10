#!/bin/bash
#---INPUT ARGS
PrintIsAllowed__in=${1}



#---CONSTANTS
POWER_OFF="off"
POWER_ON="on"
STATEGET_DOWN="DOWN"
STATEGET_UP="UP"
STATESET_DOWN="down"
STATESET_UP="up"



#---COLORS CONSTANTS
WLN_RESETCOLOR=$'\e[0m'
WLN_ORANGE=$'\e[30;38;5;209m'
WLN_LIGHTGREY=$'\e[30;38;5;246m'
WLN_LIGHTGREEN=$'\e[30;38;5;71m'
WLN_SOFLIGHTRED=$'\e[30;38;5;131m'



#---PHASE CONSTANTS
PHASE_WIFI_INTFSTATE=1
PHASE_WIFI_POWERSAVE_SET=10
PHASE_WIFI_POWERSAVE_GET=20
PHASE_EXIT=100



#---VARIABLES
phase=${PHASE_WIFI_INTFSTATE}
wifiName="wlan0"



#---SUBROUTINES
wifi_state_set() {
    #CONSTANTS
    local RETRY_CTR_MAX=10

    #VARIABLES
    local pid=0
    local retry_ctr=1

    #Check Wireless interface-state
    local isState=`ip link show dev ${wifiName} | grep -o "state.*" | cut -d" " -f2 2>&1`
    if [[ ${isState} == ${STATEGET_DOWN} ]]; then    #interface is down
        if [[ ${PrintIsAllowed__in} == true ]]; then
            echo -e ":-->${WLN_ORANGE}STATUS${WLN_RESETCOLOR}: ${WLN_LIGHTGREY}${wifiName}${WLN_RESETCOLOR} is ${WLN_LIGHTGREEN}${STATEGET_DOWN}${WLN_RESETCOLOR}"
        fi

        #Loop till retry_ctr < RETRY_CTR_MAX
        while [[ ${retry_ctr} -lt ${RETRY_CTR_MAX} ]]
        do
            #Print
            if [[ ${PrintIsAllowed__in} == true ]]; then
                echo -e ":-->${WLN_ORANGE}STATUS${WLN_RESETCOLOR}: Trying to bring ${WLN_LIGHTGREEN}${STATEGET_UP}${WLN_RESETCOLOR} ${WLN_LIGHTGREY}${wifiName}${WLN_RESETCOLOR} (${retry_ctr} out-of ${RETRY_CTR_MAX})"
            fi

            #Bring interface up
            ip link set dev ${wifiName} ${STATESET_UP} 2>&1 > /dev/null
            #Get PID
            pid=$!
            #Wait for process to finish
            wait ${pid}

            #Break loop if 'stdOutput' contains data (which means that Status has changed to UP)
            stdOutput=`ip link show dev ${wifiName} | grep -o "state.*" | cut -d" " -f2 2>&1`
            if [[ ${stdOutput} == ${STATEGET_UP} ]]; then    #data found
                break
            fi

            #error was found, retry_ctr again
            retry_ctr=$((retry_ctr + 1))
        done
    else
        stdOutput=${STATEGET_UP}
    fi

    #State has correctly changed to UP
    if [[ -z ${stdOutput} ]]; then
        if [[ ${PrintIsAllowed__in} == true ]]; then
            echo -e ":-->${WLN_ORANGE}STATUS${WLN_RESETCOLOR}: ${WLN_SOFLIGHTRED}Failed${WLN_RESETCOLOR} to bring ${WLN_LIGHTGREEN}${STATEGET_UP}${WLN_RESETCOLOR} ${WLN_LIGHTGREY}${wifiName}${WLN_RESETCOLOR} (${retry_ctr} out-of ${RETRY_CTR_MAX})"

            echo -e ":-->${WLN_ORANGE}STATUS${WLN_RESETCOLOR}: ${WLN_SOFLIGHTRED}Failed${WLN_RESETCOLOR} to set ${WLN_LIGHTGREY}${wifiName}${WLN_RESETCOLOR} Powersave to ${WLN_SOFLIGHTRED}${POWER_OFF}${WLN_RESETCOLOR}"
        fi

        phase=${PHASE_EXIT}
    else
        if [[ ${PrintIsAllowed__in} == true ]]; then
            echo -e ":-->${WLN_ORANGE}STATUS${WLN_RESETCOLOR}: ${WLN_LIGHTGREY}${wifiName}${WLN_RESETCOLOR} is ${WLN_LIGHTGREEN}${STATEGET_UP}${WLN_RESETCOLOR}"
        fi

        phase=${PHASE_WIFI_POWERSAVE_SET}
    fi
}

wifi_powersave_state_set() {
    #Set powersave-state to on
    iw dev ${wifiName} set power_save on
    #Set powersave-state to off
    iw dev ${wifiName} set power_save off

    phase=${PHASE_WIFI_POWERSAVE_GET}
}

wifi_powersave_state_get() {
    #Get Powersave-state
    local isPowersaveState=`iw dev ${wifiName} get power_save | grep -o "save.*" | cut -d" " -f2 2>&1`
    if [[ ${isPowersaveState} == ${POWER_ON} ]]; then
        if [[ ${PrintIsAllowed__in} == true ]]; then
            echo -e ":-->${WLN_ORANGE}STATUS${WLN_RESETCOLOR}: ${WLN_LIGHTGREY}${wifiName}${WLN_RESETCOLOR} Powersave is ${WLN_LIGHTGREEN}${POWER_ON}${WLN_RESETCOLOR}"
        fi
    else
        if [[ ${PrintIsAllowed__in} == true ]]; then
            echo -e ":-->${WLN_ORANGE}STATUS${WLN_RESETCOLOR}: ${WLN_LIGHTGREY}${wifiName}${WLN_RESETCOLOR} Powersave is ${WLN_SOFLIGHTRED}${POWER_OFF}${WLN_RESETCOLOR}"
        fi
    fi

    phase=${PHASE_EXIT}
}




#---MAIN SUBROUTINE
main__sub() {
    #Print empty line
    if [[ ${PrintIsAllowed__in} == true ]]; then
        echo -e "\r"
    fi

    #Go thru phases
    phase=${PHASE_WIFI_INTFSTATE}
    while true
    do
        case "${phase}" in
            ${PHASE_WIFI_INTFSTATE})
                wifi_state_set
                ;;
            ${PHASE_WIFI_POWERSAVE_SET})
                wifi_powersave_state_set
                ;;
            ${PHASE_WIFI_POWERSAVE_GET})
                wifi_powersave_state_get
                ;;
            ${PHASE_EXIT})
                break
                ;;
        esac
    done

    #Print empty line
    if [[ ${PrintIsAllowed__in} == true ]]; then
        echo -e "\r"
    fi
}



#---EXECUTE
main__sub
