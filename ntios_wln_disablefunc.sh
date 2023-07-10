#!/bin/bash
#---FUNCTIONS
WLN_disable() {
    #----------------------------------------------------------------
    # NOTE:
    #   The 'original' TIOS 'disable()' function does not return any
    #   ...values. However, in this 'new' NTIOS version, this
    #   ...'disable()' function does return a value, which can
    #   ...be retrieved by the user if desired.
    #----------------------------------------------------------------

    #Define constants
    local PHASE_DISABLEFUNC_IP6TABLES_SERVICE_STOP=10
    local PHASE_DISABLEFUNC_IPTABLES_SERVICE_STOP=11
    local PHASE_DISABLEFUNC_HOSTAPD_NG_SERVICE_STOP=20
    local PHASE_DISABLEFUNC_DNSMASQ_SERVICE_STOP=30
    local PHASE_DISABLEFUNC_WPA_SUPPLICANT_SERVICE_DAEMON_STOP=40
    local PHASE_DISABLEFUNC_WPA_SUPPLICANT_SERVICE_STOP=41
    local PHASE_DISABLEFUNC_WIFI_POWERSAVEOFF_TIMER_STOP=50
    local PHASE_DISABLEFUNC_INTFSTATE_SET=60
    local PHASE_DISABLEFUNC_INTFSTATE_CHECK=61
    local PHASE_DISABLEFUNC_EXIT=100

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local phase="${PHASE_DISABLEFUNC_IP6TABLES_SERVICE_STOP}"
    local tty_curr="${WLN_DEV_TTYS0}"
    local retry=0
    local ret=${NO}

    #Get the current shell-terminal
    local tty_curr=$(tty)

    #Start phase
    while true
    do
        case "${phase}" in
            ${PHASE_DISABLEFUNC_IP6TABLES_SERVICE_STOP})
                #Stop service, but DO NOT DISABLE!
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop  "${WLN_IP6TABLES_SRV}" \
                        "${WLN_IPTABLES}" \
                        "${WLN_IP6TABLES_SERVICE_FPATH}") == false ]]; then
                    ret="${NO}"

                    phase="${PHASE_DISABLEFUNC_EXIT}"            
                else
                    phase="${PHASE_DISABLEFUNC_IPTABLES_SERVICE_STOP}"
                fi
                ;;
            ${PHASE_DISABLEFUNC_IPTABLES_SERVICE_STOP})
                #Stop service, but DO NOT DISABLE!
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop  "${WLN_IPTABLES_SRV}" \
                        "${WLN_IPTABLES}" \
                        "${WLN_IPTABLES_SERVICE_FPATH}") == false ]]; then
                    ret="${NO}"

                    phase="${PHASE_DISABLEFUNC_EXIT}"            
                else
                    phase="${PHASE_DISABLEFUNC_HOSTAPD_NG_SERVICE_STOP}"
                fi
                ;;
            ${PHASE_DISABLEFUNC_HOSTAPD_NG_SERVICE_STOP})
                #Stop service, but DO NOT DISABLE!
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop  "${WLN_HOSTAPD_NG_SRV}" \
                        "${WLN_HOSTAPD}" \
                        "${WLN_HOSTAPD_NG_SERVICE_FPATH}") == false ]]; then
                    ret="${NO}"

                    phase="${PHASE_DISABLEFUNC_EXIT}"
                else
                    phase="${PHASE_DISABLEFUNC_DNSMASQ_SERVICE_STOP}"
                fi
                ;;
            ${PHASE_DISABLEFUNC_DNSMASQ_SERVICE_STOP})
                #Stop service, but DO NOT DISABLE!
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop "${WLN_DNSMASQ_SRV}" \
                        "${WLN_DNSMASQ}" \
                        "${WLN_DNSMASQ_SERVICE_FPATH}") == false ]]; then
                    ret="${NO}"

                    phase="${PHASE_DISABLEFUNC_EXIT}"
                else
                    phase="${PHASE_DISABLEFUNC_WPA_SUPPLICANT_SERVICE_DAEMON_STOP}"
                fi
                ;;
            ${PHASE_DISABLEFUNC_WPA_SUPPLICANT_SERVICE_DAEMON_STOP})
                #Stop service, but DO NOT DISABLE!
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop "${WLN_WPA_SUPPLICANT_DAEMON_SRV}" \
                        "${WLN_WPASUPPLICANT}" \
                        "${WLN_WPA_SUPPLICANT_DAEMON_SERVICE_FPATH}") == false ]]; then
                    ret="${NO}"

                    phase="${PHASE_DISABLEFUNC_EXIT}"
                else
                    phase="${PHASE_DISABLEFUNC_WIFI_POWERSAVEOFF_TIMER_STOP}"
                fi
                ;;
            ${PHASE_DISABLEFUNC_WIFI_POWERSAVEOFF_TIMER_STOP})
                #Stop service, but DO NOT DISABLE!
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop "${WLN_WIFI_POWERSAVE_OFF_TIMER}" \
                        "${WLN_IW}" \
                        "${WLN_WIFI_POWERSAVE_OFF_TIMER_FPATH}") == false ]]; then
                    ret="${NO}"

                    phase="${PHASE_DISABLEFUNC_EXIT}"            
                else
                    phase="${PHASE_DISABLEFUNC_INTFSTATE_SET}"
                fi
                ;;
            ${PHASE_DISABLEFUNC_INTFSTATE_SET})
                #Only bring interface down if failed to bring interface-up the 1st time.
                #Remark:
                #   Bringing interface DOWN and then UP may cause issues
                #   ...when trying to START hostapd-ng.service.
                if [[ ${retry} -gt 0 ]]; then
                    cmd="ip link set dev ${WLN_WLAN0} ${WLN_UP}"
                    ret=$(CmdExec "${cmd}")
                fi

                #Bring interface up
                cmd="ip link set dev ${WLN_WLAN0} ${WLN_DOWN}"
                ret=$(CmdExec "${cmd}")

                #Goto next-phase
                phase="${PHASE_DISABLEFUNC_INTFSTATE_CHECK}"
                ;;
            ${PHASE_DISABLEFUNC_INTFSTATE_CHECK})
                if [[ $(GetInterfaceState "${WLN_WLAN0}") != "${WLN_DOWN}" ]]; then
                    #Check if the maximum number of retries have been reached.
                    if [[ ${retry} -eq ${WLN_INTFSTATESET_RETRY_MAX} ]]; then
                        #Update output value
                        ret="${NO}"

                        #Goto next-phase
                        phase="${PHASE_DISABLEFUNC_EXIT}"
                    else
                        #Wait for 1 sec
                        sleep 0.5

                        #Increment index by 1
                        ((retry++))

                        #Goto back-to-phase
                        phase="${PHASE_DISABLEFUNC_INTFSTATE_SET}"
                    fi
                else
                    #Update output value
                    ret="${YES}"

                    #Goto next-phase
                    phase=${PHASE_DISABLEFUNC_EXIT}
                fi
                ;;
            ${PHASE_DISABLEFUNC_EXIT})
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}
