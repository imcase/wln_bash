#!/bin/bash
#---PATTERN CONSTANTS
PATTERN_ERROR1="nl80211: kernel reports: key not allowed"
PATTERN_ERROR2="Failed to set beacon parameters"

#---ENVIRONMENT VARIABLES
HOSTAPD_NG_SERVICE="hostapd-ng.service"
hostapd_log_fpath="/etc/tibbo/log/wln/hostapd.log"



#---SUBROUTINES
    autorecover_handler() {
    if [[ ! -f "${hostapd_log_fpath}" ]]; then
        exit
    fi
    #--------------------------------------------------------
    #Check whether one of the errors (specified 
    #   by 'PATTERN_ERROR1' and 'PATTERN_ERROR2') are found.
    # These errors are caused when the Wireless Interface 
    #   goes DOWN and then UP again. Because of that, the 
    #   SSID appears to be available for remote devices to 
    #   connect, but in reality this is not the case.
    # In order to fix the above mentioned issue, the 
    #   hostapd daemon has to be stopped and started.
    #--------------------------------------------------------
    #Define variables
    hostapd_pattern_error1_cmd="grep -F \"${PATTERN_ERROR1}\" ${hostapd_log_fpath}"
    hostapd_pattern_error2_cmd="grep -F \"${PATTERN_ERROR2}\" ${hostapd_log_fpath}"
    local error1_output=$(eval ${hostapd_pattern_error1_cmd})
    local error2_output=$(eval ${hostapd_pattern_error2_cmd})

    #Check if at least one variable contains data.
    #Remark:
    #   If one of the specified errors is found, then:
    #   1. kill hostapd-process
    #   2. start host
    if [[ -n "${error1_output}" ]]  && [[ -n "${error2_output}" ]]; then
        systemctl restart ${HOSTAPD_NG_SERVICE}
    fi

    #Empty file without removing file
    if [[ -f ${hostapd_log_fpath} ]]; then
        cat /dev/null > "${hostapd_log_fpath}"
    fi
}



#---EXECUTE SUBROUTINES
autorecover_handler
