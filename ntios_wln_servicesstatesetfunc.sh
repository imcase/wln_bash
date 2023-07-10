#!/bin/bash
#---FUNCTIONS
WLN_Services_CheckIfEnabled_And_ThenStart_Handler() {
    #Define constants
    local PHASE_SERVICESSTATESETFUNC_WIFI_POWERSAVEOFF_TIMER_START=1
    local PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_START=10
    local PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_START=20
    local PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_START=30
    local PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_START=40
    local PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_START=50
    local PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_START=60
    local PHASE_SERVICESSTATESETFUNC_EXIT=100

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local phase="${PHASE_SERVICESSTATESETFUNC_WIFI_POWERSAVEOFF_TIMER_START}"
    local ret=${REJECTED}

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SERVICESSTATESETFUNC_WIFI_POWERSAVEOFF_TIMER_START}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Start "${WLN_WIFI_POWERSAVE_OFF_TIMER}" \
                        "${WLN_IW}" \
                        "${WLN_WIFI_POWERSAVE_OFF_TIMER_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"            
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_START}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_START}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Start "${WLN_WPA_SUPPLICANT_DAEMON_SRV}" \
                        "${WLN_WPASUPPLICANT}" \
                        "${WLN_WPA_SUPPLICANT_DAEMON_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_START}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_START}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Start "${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}" \
                        "${WLN_WPASUPPLICANT}" \
                        "${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_START}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_START}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Start "${WLN_DNSMASQ_SRV}" \
                        "${WLN_DNSMASQ}" \
                        "${WLN_DNSMASQ_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_START}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_START}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Start  "${WLN_IPTABLES_SRV}" \
                        "${WLN_IPTABLES}" \
                        "${WLN_IPTABLES_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"            
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_START}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_START}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Start  "${WLN_IP6TABLES_SRV}" \
                        "${WLN_IPTABLES}" \
                        "${WLN_IP6TABLES_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"            
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_START}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_START}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Start  "${WLN_HOSTAPD_NG_SRV}" \
                        "${WLN_HOSTAPD}" \
                        "${WLN_HOSTAPD_NG_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                ;;
            "${PHASE_SERVICESSTATESETFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

WLN_Services_CheckIfEnabled_And_ThenStop_Handler() {
    #Define constants
    local PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_STOP=1
    local PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_STOP=10
    local PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_STOP=20
    local PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_STOP=30
    local PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_STOP=40
    local PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_STOP=41
    local PHASE_SERVICESSTATESETFUNC_WIFI_POWERSAVEOFF_TIMER_STOP=50
    local PHASE_SERVICESSTATESETFUNC_EXIT=100

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local phase="${PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_STOP}"
    local ret=${REJECTED}

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_STOP}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop  "${WLN_HOSTAPD_NG_SRV}" \
                        "${WLN_HOSTAPD}" \
                        "${WLN_HOSTAPD_NG_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_STOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_STOP}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop  "${WLN_IP6TABLES_SRV}" \
                        "${WLN_IPTABLES}" \
                        "${WLN_IP6TABLES_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"            
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_STOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_STOP}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop  "${WLN_IPTABLES_SRV}" \
                        "${WLN_IPTABLES}" \
                        "${WLN_IPTABLES_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"            
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_STOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_STOP}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop "${WLN_DNSMASQ_SRV}" \
                        "${WLN_DNSMASQ}" \
                        "${WLN_DNSMASQ_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_STOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_STOP}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop "${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}" \
                        "${WLN_WPASUPPLICANT}" \
                        "${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_STOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_STOP}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop "${WLN_WPA_SUPPLICANT_DAEMON_SRV}" \
                        "${WLN_WPASUPPLICANT}" \
                        "${WLN_WPA_SUPPLICANT_DAEMON_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_WIFI_POWERSAVEOFF_TIMER_STOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_WIFI_POWERSAVEOFF_TIMER_STOP}")
                if [[ $(Service_CheckIf_IsEnabled_Then_Stop "${WLN_WIFI_POWERSAVE_OFF_TIMER}" \
                        "${WLN_IW}" \
                        "${WLN_WIFI_POWERSAVE_OFF_TIMER_FPATH}") == false ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                ;;
            "${PHASE_SERVICESSTATESETFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

WLN_Services_DisableStop_Handler() {
    #Define constants
    local PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP=1
    local PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_DISABLESTOP=10
    local PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_DISABLESTOP=20
    local PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_DISABLESTOP=30
    local PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP=40
    local PHASE_SERVICESSTATESETFUNC_WIFI_POWERSAVEOFF_TIMER_DISABLESTOP=50
    local PHASE_SERVICESSTATESETFUNC_EXIT=100

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local phase="${PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP}"
    local ret=${REJECTED}

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped  "${WLN_HOSTAPD_NG_SRV}" \
                        "${WLN_HOSTAPD}" \
                        "${WLN_HOSTAPD_NG_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped  "${WLN_IP6TABLES_SRV}" \
                        "${WLN_IPTABLES}" \
                        "${WLN_IP6TABLES_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"            
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped  "${WLN_IPTABLES_SRV}" \
                        "${WLN_IPTABLES}" \
                        "${WLN_IPTABLES_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"            
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_DNSMASQ_SRV}" \
                        "${WLN_DNSMASQ}" \
                        "${WLN_DNSMASQ_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP}")
                if [[ $(WpaSupplicant_StopDisable) == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_WIFI_POWERSAVEOFF_TIMER_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_WIFI_POWERSAVEOFF_TIMER_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_WIFI_POWERSAVE_OFF_TIMER}" \
                        "${WLN_IW}" \
                        "${WLN_WIFI_POWERSAVE_OFF_TIMER_FPATH}") == false ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                ;;
            "${PHASE_SERVICESSTATESETFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

WLN_Services_Disassociate_Handler() {
    #----------------------------------------------------------------
    # Disable & Stop all services except for 'wifi-poowersave-off.timer'
    #----------------------------------------------------------------

    #Define constants
    local PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP=1
    local PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_DISABLESTOP=10
    local PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_DISABLESTOP=20
    local PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_DISABLESTOP=30
    local PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP=40
    local PHASE_SERVICESSTATESETFUNC_EXIT=100

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local phase="${PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP}"
    local ret=${REJECTED}

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped  "${WLN_HOSTAPD_NG_SRV}" \
                        "${WLN_HOSTAPD}" \
                        "${WLN_HOSTAPD_NG_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped  "${WLN_IP6TABLES_SRV}" \
                        "${WLN_IPTABLES}" \
                        "${WLN_IP6TABLES_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"            
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped  "${WLN_IPTABLES_SRV}" \
                        "${WLN_IPTABLES}" \
                        "${WLN_IPTABLES_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"            
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_DNSMASQ_SRV}" \
                        "${WLN_DNSMASQ}" \
                        "${WLN_DNSMASQ_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP}")
                if [[ $(WpaSupplicant_StopDisable) == false ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                ;;
            "${PHASE_SERVICESSTATESETFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

WLN_Services_DisableStop_BasedOn_Bssmode_Handler() {
    #Input args
    local isbssmode=${1}

    #Define constants
    local PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP=1
    local PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_DISABLESTOP=10
    local PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_DISABLESTOP=20
    local PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_DISABLESTOP=30
    local PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP=40
    local PHASE_SERVICESSTATESETFUNC_WIFI_POWERSAVEOFF_TIMER_DISABLESTOP=50
    local PHASE_SERVICESSTATESETFUNC_EXIT=100

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local phase="${PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP}"
    local ret=${REJECTED}

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SERVICESSTATESETFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP}")
                if [[ "${isbssmode}" == "${PL_WLN_BSS_MODE_INFRASTRUCTURE}" ]]; then
                    if [[ $(Service_ShouldBe_Disabled_And_Stopped  "${WLN_HOSTAPD_NG_SRV}" \
                            "${WLN_HOSTAPD}" \
                            "${WLN_HOSTAPD_NG_SERVICE_FPATH}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                    else
                        phase="${PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_DISABLESTOP}"
                    fi
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_IP6TABLES_SERVICE_DISABLESTOP}")
                if [[ "${isbssmode}" == "${PL_WLN_BSS_MODE_INFRASTRUCTURE}" ]]; then
                    if [[ $(Service_ShouldBe_Disabled_And_Stopped  "${WLN_IP6TABLES_SRV}" \
                            "${WLN_IPTABLES}" \
                            "${WLN_IP6TABLES_SERVICE_FPATH}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"            
                    else
                        phase="${PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_DISABLESTOP}"
                    fi
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_IPTABLES_SERVICE_DISABLESTOP}")
                if [[ "${isbssmode}" == "${PL_WLN_BSS_MODE_INFRASTRUCTURE}" ]]; then
                    if [[ $(Service_ShouldBe_Disabled_And_Stopped  "${WLN_IPTABLES_SRV}" \
                            "${WLN_IPTABLES}" \
                            "${WLN_IPTABLES_SERVICE_FPATH}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"            
                    else
                        phase="${PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_DISABLESTOP}"
                    fi
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_DNSMASQ_SERVICE_DISABLESTOP}")
                if [[ "${isbssmode}" != "${PL_WLN_BSS_MODE_ROUTER}" ]]; then
                    if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_DNSMASQ_SRV}" \
                            "${WLN_DNSMASQ}" \
                            "${WLN_DNSMASQ_SERVICE_FPATH}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                    else
                        phase="${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP}"
                    fi
                else
                    phase="${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP}"
                fi
                ;;
            "${PHASE_SERVICESSTATESETFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP}")
                if [[ "${isbssmode}" != "${PL_WLN_BSS_MODE_INFRASTRUCTURE}" ]]; then
                    if [[ $(WpaSupplicant_StopDisable) == false ]]; then
                        ret="${REJECTED}"
                    else
                        ret="${ACCEPTED}"
                    fi
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_SERVICESSTATESETFUNC_EXIT}"
                ;;
            "${PHASE_SERVICESSTATESETFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}
