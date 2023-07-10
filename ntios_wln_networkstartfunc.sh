#!/bin/bash
#---CONSTANTS
PHASE_NETWORKSTARTFUNC_TASK_CHECK=1
PHASE_NETWORKSTARTFUNC_INTFSTATE_CHECK=2
PHASE_NETWORKSTARTFUNC_SERVICES_DISABLESTOP_HANDLER=3
PHASE_NETWORKSTARTFUNC_WEP_WPA_VALIDATION=4
PHASE_NETWORKSTARTFUNC_BSS_MODE_CHECK=5
PHASE_NETWORKSTARTFUNC_PHY_MODE_CHECK=6
PHASE_NETWORKSTARTFUNC_HW_MODE_SET=7
PHASE_NETWORKSTARTFUNC_SSID_CHECK=8
PHASE_NETWORKSTARTFUNC_SSID_ISVISIBLE_CHECK=9
PHASE_NETWORKSTARTFUNC_CHANNEL_CHECK=10
PHASE_NETWORKSTARTFUNC_DATABASE_UPDATE=12
PHASE_NETWORKSTARTFUNC_UFW_PORTS=13
PHASE_NETWORKSTARTFUNC_IPV46_FORWARDING=14
PHASE_NETWORKSTARTFUNC_SOFTWARE_INSTALL=20
PHASE_NETWORKSTARTFUNC_NETPLAN_HANDLER=30
PHASE_NETWORKSTARTFUNC_WIFIPOWERSAVEOFF_HANDLER=40
PHASE_NETWORKSTARTFUNC_DNSMASQ_HANDLER=50
PHASE_NETWORKSTARTFUNC_IPTABLES_HANDLER=60
PHASE_NETWORKSTARTFUNC_IP6TABLES_HANDLER=70
PHASE_NETWORKSTARTFUNC_HOSTAPD_HANDLER=80
PHASE_NETWORKSTARTFUNC_AUTORECONNECTONBOOT_HANDLER=400
PHASE_NETWORKSTARTFUNC_TASK_UPDATE=500
PHASE_NETWORKSTARTFUNC_EXIT=1000



#---FUNCTIONS
WLN_networkstart() {
    #Input args
    local isssid=${1}             #Must provide
    local ischannel=${2}          #Must provide, could be set to 0 (= auto-select channel)
    local isbssmode=${3}          #optional
    local isssid_isvisible=${4}   #optional

    #Define variables
    local phase="${PHASE_NETWORKSTARTFUNC_TASK_CHECK}"
    local hw_mode="${WLN_HOSTAPD_HWMODE_G}"
    local ieee80211ac="${WLN_NUM_0}"
    local ieee80211n="${WLN_NUM_1}"
    local ieee80211d="${WLN_NUM_0}"
    local ieee80211h="${WLN_NUM_0}"
    local phymode="${PL_WLN_PHY_MODE_NULL}"
    local printmsg="${WLN_EMPTYSTRING}"
    local wlntask="${PL_WLN_NOT_ASSOCIATED}"
    local ret="${REJECTED}"



    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_NETWORKSTARTFUNC_TASK_CHECK}")
                #Retrieve data from database
                wlntask=$(WLN_intfstates_ctx_retrievedata \
                        "${WLN_INTFSTATES_CTX_DAT_FPATH}" \
                        "WLN_intfstates_ctx__associationstate")
                if [[ "${wlntask}" == "${PL_WLN_ASSOCIATED}" ]] || \
                        [[ "${wlntask}" == "${PL_WLN_OWN_NETWORK}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"

                    #Print
                    Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_TASK_CHECK}" \
                            "${wlntask}" \
                            "${WLN_NUM_1}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_INTFSTATE_CHECK}"

                    #Print
                    Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_TASK_CHECK}" \
                            "${wlntask}" \
                            "${WLN_NUM_2}"
                fi
                ;;
            "${PHASE_NETWORKSTARTFUNC_INTFSTATE_CHECK}")
                if [[ $(WLN_enabled) == "${NO}" ]]; then
                    if [[ $(WLN_enable) == "${REJECTED}" ]]; then
                        #Update output result
                        ret="${REJECTED}"

                        #Goto next-phase
                        phase="${PHASE_NETWORKSTARTFUNC_EXIT}"

                        #Print
                        Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_INTFSTATE_CHECK}" \
                                "${WLN_EMPTYSTRING}" \
                                "${WLN_NUM_1}"
                    else
                        #Goto next-phase
                        phase="${PHASE_NETWORKSTARTFUNC_SERVICES_DISABLESTOP_HANDLER}"

                        #Print
                        Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_INTFSTATE_CHECK}" \
                                "${WLN_EMPTYSTRING}" \
                                "${WLN_NUM_2}"
                    fi
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_SERVICES_DISABLESTOP_HANDLER}"

                    #Print
                    Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_INTFSTATE_CHECK}" \
                            "${WLN_EMPTYSTRING}" \
                            "${WLN_NUM_2}"
                fi
                ;;
            "${PHASE_NETWORKSTARTFUNC_SERVICES_DISABLESTOP_HANDLER}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_SERVICES_DISABLESTOP_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                if [[ $(WLN_Services_DisableStop_Handler) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_WEP_WPA_VALIDATION}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_SERVICES_DISABLESTOP_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_WEP_WPA_VALIDATION}")
                if [[ $(WLN_Wep_Wpa_Validation) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"

                    #Print
                    Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_WEP_WPA_VALIDATION}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_BSS_MODE_CHECK}"

                    #Print
                    Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_WEP_WPA_VALIDATION}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                fi
                ;;
            "${PHASE_NETWORKSTARTFUNC_BSS_MODE_CHECK}")
                #If 'isbssmode = PL_WLN_BSS_MODE_INFRASTRUCTURE', 
                #   then automatically set to default value 'isbssmode = PL_WLN_BSS_MODE_ROUTER'.
                if [[ "${isbssmode}" == "${PL_WLN_BSS_MODE_INFRASTRUCTURE}" ]]; then
                    isbssmode="${PL_WLN_BSS_MODE_ROUTER}"
                fi

                #Goto next-phase
                phase="${PHASE_NETWORKSTARTFUNC_PHY_MODE_CHECK}"

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_BSS_MODE_CHECK}" "${isbssmode}" "${WLN_NUM_1}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_PHY_MODE_CHECK}")
                #Retrieve 'phymode' from database
                phymode=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__phymode")

                #Check if 'phymode = PL_WLN_PHY_MODE_NULL'.
                if [[ "${phymode}" == "${PL_WLN_PHY_MODE_NULL}" ]]; then
                    phymode="${PL_WLN_PHY_MODE_2G}"
                fi

                #Goto next-phase
                phase="${PHASE_NETWORKSTARTFUNC_HW_MODE_SET}"

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_PHY_MODE_CHECK}" "${phymode}" "${WLN_NUM_1}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_HW_MODE_SET}")
                #Update hostapd variables
                case "${phymode}" in
                    "${PL_WLN_PHY_MODE_2G_LEGACY}")
                        hw_mode="${WLN_HOSTAPD_HWMODE_B}"
                        ieee80211ac=${WLN_NUM_0}
                        ieee80211n=${WLN_NUM_0}
                        ieee80211d=${WLN_NUM_0}
                        ieee80211h=${WLN_NUM_0}
                        ;;
                    "${PL_WLN_PHY_MODE_2G}")
                        hw_mode="${WLN_HOSTAPD_HWMODE_G}"
                        ieee80211ac=${WLN_NUM_0}
                        ieee80211n=${WLN_NUM_1}
                        ieee80211d=${WLN_NUM_0}
                        ieee80211h=${WLN_NUM_0}
                        ;;
                    "${PL_WLN_PHY_MODE_5G}")
                        hw_mode="${WLN_HOSTAPD_HWMODE_A}"
                        ieee80211ac=${WLN_NUM_1}
                        ieee80211n=${WLN_NUM_1}
                        ieee80211d=${WLN_NUM_1}
                        ieee80211h=${WLN_NUM_1}
                        ;;
                    *)
                        hw_mode="${WLN_HOSTAPD_HWMODE_G}"
                        ieee80211ac=${WLN_NUM_0}
                        ieee80211n=${WLN_NUM_1}
                        ieee80211d=${WLN_NUM_0}
                        ieee80211h=${WLN_NUM_0}
                        ;;
                esac

                #Goto next-phase
                phase="${PHASE_NETWORKSTARTFUNC_SSID_CHECK}"

                #Print
                printmsg="${hw_mode},${ieee80211ac},${ieee80211n},${ieee80211d},${ieee80211h}"
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_HW_MODE_SET}" "${printmsg}" "${WLN_NUM_1}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_SSID_CHECK}")
                #Check if 'isssid' is an <Empty String>
                if [[ "${isssid}" == "${WLN_EMPTYSTRING}" ]]; then
                    if [[ "${isbssmode}" == "${PL_WLN_BSS_MODE_ACCESSPOINT}" ]]; then
                        if [[ "${phymode}" == "${PL_WLN_PHY_MODE_2G_LEGACY}" ]]; then
                            isssid="${WLN_HOSTAPD_SSID_AP_B}"
                        elif [[ "${phymode}" == "${PL_WLN_PHY_MODE_2G}" ]]; then
                            isssid="${WLN_HOSTAPD_SSID_AP_GN}"
                        else    #phymode = PL_WLN_PHY_MODE_5G
                            isssid="${WLN_HOSTAPD_SSID_AP_AACN}"
                        fi
                    else    #isbssmode = PL_WLN_BSS_MODE_ROUTER
                        if [[ "${phymode}" == "${PL_WLN_PHY_MODE_2G_LEGACY}" ]]; then
                            isssid="${WLN_HOSTAPD_SSID_RT_B}"
                        elif [[ "${phymode}" == "${PL_WLN_PHY_MODE_2G}" ]]; then
                            isssid="${WLN_HOSTAPD_SSID_RT_GN}"
                        else    #phymode = PL_WLN_PHY_MODE_5G
                            isssid="${WLN_HOSTAPD_SSID_RT_AACN}"
                        fi
                    fi
                fi

                #Goto next-phase
                phase="${PHASE_NETWORKSTARTFUNC_SSID_ISVISIBLE_CHECK}"

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_SSID_CHECK}" "${isssid}" "${WLN_NUM_1}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_SSID_ISVISIBLE_CHECK}")
                #Check if 'isssid_isvisible = <Empty String>'
                #Remark:
                #   This condition will NOT be used in C++, because...
                #   ...an optional value will be set in the function.
                if [[ "${isssid_isvisible}" == "${WLN_EMPTYSTRING}" ]]; then
                    isssid_isvisible=true
                fi

                #Goto next-phase
                phase="${PHASE_NETWORKSTARTFUNC_CHANNEL_CHECK}"

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_SSID_ISVISIBLE_CHECK}" "${isssid_isvisible}" "${WLN_NUM_1}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_CHANNEL_CHECK}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_CHANNEL_CHECK}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Check if 'ischannel = <Empty String>'
                #Remark:
                #   This condition will NOT be used in C++, because...
                #   ...an optional value will be set in the function.
                if [[ ${ischannel} == ${WLN_EMPTYSTRING} ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Validate 'ischannel'
                    #Remark:
                    #   If the specified 'ischannel' is NOT supported in a certain country...
                    #   ...then the default ischannel (0) will be used instead.
                    #   When 'ischannel = 0', it basically means automatically set a ischannel.
                    ischannel=$(Channel_AutoSelect "${ischannel}" "${phymode}")

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_DATABASE_UPDATE}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_CHANNEL_CHECK}" "${ischannel}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_DATABASE_UPDATE}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_DATABASE_UPDATE}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Update database
                Networkstart_Intfstates_Ctx_Update "${isssid}" \
                        "${ischannel}" \
                        "${isbssmode}" \
                        "${phymode}" \
                        "${hw_mode}" \
                        "${ieee80211ac}" \
                        "${ieee80211n}" \
                        "${ieee80211d}" \
                        "${ieee80211h}" \
                        "${isssid_isvisible}"

                #Goto next-phase
                phase="${PHASE_NETWORKSTARTFUNC_UFW_PORTS}"

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_DATABASE_UPDATE}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_UFW_PORTS}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_UFW_PORTS}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                if [[ $(WLN_Ufw_Ports_Allow) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_IPV46_FORWARDING}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_UFW_PORTS}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_IPV46_FORWARDING}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_IPV46_FORWARDING}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                if [[ $(WLN_Ipv46_Forwarding_Enable) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_SOFTWARE_INSTALL}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_IPV46_FORWARDING}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_SOFTWARE_INSTALL}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_SOFTWARE_INSTALL}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                if [[ $(WLN_SoftwareInst_OnDemand_Handler "${isbssmode}") == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_NETPLAN_HANDLER}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_SOFTWARE_INSTALL}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_NETPLAN_HANDLER}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_NETPLAN_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup and Apply Netplan
                if [[ $(WLN_Netplan_Handler "${isbssmode}" "${WLN_WLAN_YAML_FPATH}" "false") == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_WIFIPOWERSAVEOFF_HANDLER}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_NETPLAN_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_WIFIPOWERSAVEOFF_HANDLER}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_WIFIPOWERSAVEOFF_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup dnsmasq and run service
                if [[ $(WLN_WifiPowerSave_Handler) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_DNSMASQ_HANDLER}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_WIFIPOWERSAVEOFF_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_DNSMASQ_HANDLER}")
                #Remark:
                #   Enabling/Starting dnsmasq.service should happen AFTER 
                #   ...enabling/starting 'hostapd-ng.service' because
                #   ...in 'hostapd-ng.sh' bridge 'br0' is added and brought up.
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_DNSMASQ_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup dnsmasq and run service
                if [[ $(WLN_Dnsmasq_Handler "${isbssmode}" "false") == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_IPTABLES_HANDLER}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_DNSMASQ_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_IPTABLES_HANDLER}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_IPTABLES_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup and run iptables service
                if [[ $(WLN_Ip46tables_Rules_Create "${WLN_IPTABLES}" \
                        "${WLN_IPTABLES_SRV}" \
                        "${WLN_IPTABLES_RULES_V4_ORG_FPATH}" \
                        "${WLN_IPTABLES_RULES_V4_FPATH}" \
                        "${WLN_IPTABLES_SERVICE_FPATH}" \
                        "${WLN_MOD_776}" \
                        "${WLN_INTFSTATES_CTX_DAT_FPATH}" \
                        "true") == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_IP6TABLES_HANDLER}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_IPTABLES_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_IP6TABLES_HANDLER}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_IP6TABLES_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup and run ip6tables service
                if [[ $(WLN_Ip46tables_Rules_Create "${WLN_IP6TABLES}" \
                        "${WLN_IP6TABLES_SRV}" \
                        "${WLN_IP6TABLES_RULES_V6_ORG_FPATH}" \
                        "${WLN_IP6TABLES_RULES_V6_FPATH}" \
                        "${WLN_IP6TABLES_SERVICE_FPATH}" \
                        "${WLN_MOD_776}" \
                        "${WLN_INTFSTATES_CTX_DAT_FPATH}" \
                        "true") == "${REJECTED}" ]]; then

                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_HOSTAPD_HANDLER}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_IP6TABLES_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_HOSTAPD_HANDLER}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_HOSTAPD_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup hostapd-ng and run service
                if [[ $(WLN_Hostapd_Handler "false") == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_AUTORECONNECTONBOOT_HANDLER}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_HOSTAPD_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_AUTORECONNECTONBOOT_HANDLER}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_AUTORECONNECTONBOOT_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup hostapd-ng and run service
                if [[ $(WLN_AutoReconnectOnBoot_Handler) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTARTFUNC_TASK_UPDATE}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_AUTORECONNECTONBOOT_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_TASK_UPDATE}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_TASK_UPDATE}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Update database
                WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" \
                        "WLN_intfstates_ctx__associationstate" \
                        "${PL_WLN_OWN_NETWORK}"

                #Update output result
                ret="${ACCEPTED}"

                #Goto next-phase
                phase="${PHASE_NETWORKSTARTFUNC_EXIT}"

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_TASK_UPDATE}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTARTFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}
Networkstart_Intfstates_Ctx_Update() {
    #Input args
    local isssid=${1}
    local ischannel=${2}
    local isbssmode=${3}
    local isphymode=${4}
    local ishw_mode=${5}
    local isieee80211ac=${6}
    local isieee80211n=${7}
    local isieee80211d=${8}
    local isieee80211h=${9}
    local isssid_isvisible=${10}



    #Write data to file
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__ssid" "${isssid}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__channel" "${ischannel}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__bssmode" "${isbssmode}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__phymode" "${isphymode}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__hwmode" "${ishw_mode}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__ieee80211ac" "${isieee80211ac}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__ieee80211n" "${isieee80211n}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__ieee80211d" "${isieee80211d}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__ieee80211h" "${isieee80211h}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__ssidisvisible" "${isssid_isvisible}"
}

Networkstart_Debugprint() {
    #Input args
    local phase=${1}
    local printmsg_val=${2}
    local printmsg_num=${3}

    #Define constants
    local PRINTMSG_NETWORKSTART="${WLN_PRINTMSG_STATUS}: ${WLN_LIGHTGREY}Networkstart${WLN_RESETCOLOR}"

    #Define variables
    local printmsg="${PRINTMSG_NETWORKSTART}: "
    local printmsg_val1=$(echo "${printmsg_val}" | cut -d"," -f1)
    local printmsg_val2=$(echo "${printmsg_val}" | cut -d"," -f2)
    local printmsg_val3=$(echo "${printmsg_val}" | cut -d"," -f3)
    local printmsg_val4=$(echo "${printmsg_val}" | cut -d"," -f4)
    local printmsg_val5=$(echo "${printmsg_val}" | cut -d"," -f5)

    #Print
    case "${phase}" in
        "${PHASE_NETWORKSTARTFUNC_TASK_CHECK}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="TASK (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): "
                printmsg+="${WLN_PRINTMSG_REJECTED}" 
            else    #printmsg_num = WLN_NUM_2
                printmsg+="TASK (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): "
                printmsg+="${WLN_PRINTMSG_ACCEPTED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_INTFSTATE_CHECK}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="WIFI: ${WLN_PRINTMSG_DISABLED}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="WIFI: ${WLN_PRINTMSG_ENABLED}" 
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_SERVICES_DISABLESTOP_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="ALL SERVICES: ${WLN_PRINTMSG_DISABLESTOP}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="ALL SERVICES: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_WEP_WPA_VALIDATION}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="WEP & WPA VALIDATION: ${WLN_PRINTMSG_REJECTED}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="WEP & WPA VALIDATION: ${WLN_PRINTMSG_ACCEPTED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_BSS_MODE_CHECK}")
            printmsg+="WLN_BSS_MODE {"
            printmsg+="${WLN_LIGHTGREY}INFRA(${WLN_RESETCOLOR}0${WLN_LIGHTGREY})${WLN_RESETCOLOR}"
            printmsg+="|"
            printmsg+="${WLN_LIGHTGREY}AP(${WLN_RESETCOLOR}1${WLN_LIGHTGREY})${WLN_RESETCOLOR}"
            printmsg+="|"
            printmsg+="${WLN_LIGHTGREY}ROUTER(${WLN_RESETCOLOR}2${WLN_LIGHTGREY})${WLN_RESETCOLOR}"
            printmsg+="}: ${WLN_YELLOW}${printmsg_val1}${WLN_RESETCOLOR}"
            ;;
        "${PHASE_NETWORKSTARTFUNC_PHY_MODE_CHECK}")
            printmsg+="WLN_PHY_MODE {"
            printmsg+="${WLN_LIGHTGREY}2G-B(${WLN_RESETCOLOR}0${WLN_LIGHTGREY})${WLN_RESETCOLOR}"
            printmsg+="|"
            printmsg+="${WLN_LIGHTGREY}2G-GN(${WLN_RESETCOLOR}1${WLN_LIGHTGREY})${WLN_RESETCOLOR}"
            printmsg+="|"
            printmsg+="${WLN_LIGHTGREY}5G-AACN(${WLN_RESETCOLOR}2${WLN_LIGHTGREY})${WLN_RESETCOLOR}"
            printmsg+="}: ${WLN_YELLOW}${printmsg_val1}${WLN_RESETCOLOR}"
            ;;
        "${PHASE_NETWORKSTARTFUNC_HW_MODE_SET}")
            printmsg+="HOSTAPD <"
            printmsg+="${WLN_LIGHTGREY}hw_mode:${WLN_RESETCOLOR}${WLN_YELLOW}${printmsg_val1}${WLN_RESETCOLOR}"
            printmsg+=","
            printmsg+="${WLN_LIGHTGREY}ac:${WLN_RESETCOLOR}${WLN_YELLOW}${printmsg_val2}${WLN_RESETCOLOR}"
            printmsg+=","
            printmsg+="${WLN_LIGHTGREY}n:${WLN_RESETCOLOR}${WLN_YELLOW}${printmsg_val3}${WLN_RESETCOLOR}"
            printmsg+=","
            printmsg+="${WLN_LIGHTGREY}d:${WLN_RESETCOLOR}${WLN_YELLOW}${printmsg_val4}${WLN_RESETCOLOR}"
            printmsg+=","
            printmsg+="${WLN_LIGHTGREY}h:${WLN_RESETCOLOR}${WLN_YELLOW}${printmsg_val5}${WLN_RESETCOLOR}"
            printmsg+=">"
            ;;
        "${PHASE_NETWORKSTARTFUNC_SSID_CHECK}")
            printmsg+="SSID: ${WLN_YELLOW}${printmsg_val1}${WLN_RESETCOLOR}"
            ;;
        "${PHASE_NETWORKSTARTFUNC_SSID_ISVISIBLE_CHECK}")
            printmsg+="SSID_IS_VISIBLE: ${WLN_YELLOW}${printmsg_val1}${WLN_RESETCOLOR}"
            ;;
        "${PHASE_NETWORKSTARTFUNC_CHANNEL_CHECK}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="CHANNEL: ${WLN_PRINTMSG_VALIDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="CHANNEL: ${WLN_LIGHTGREY}channel${WLN_RESETCOLOR}:${WLN_YELLOW}${printmsg_val1}${WLN_RESETCOLOR}\n"
    
                printmsg+="${PRINTMSG_NETWORKSTART}: "
                printmsg+="CHANNEL: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_DATABASE_UPDATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="DATABASE: ${WLN_PRINTMSG_UPDATING}"
            else  #printmsg_num = WLN_NUM_2
                printmsg+="DATABASE: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_SOFTWARE_INSTALL}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="SOFTWARE INSTALL: ${WLN_PRINTMSG_INSTALLING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="SOFTWARE INSTALL: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_UFW_PORTS}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="UFW PORTS: ${WLN_PRINTMSG_UPDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="UFW PORTS: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_IPV46_FORWARDING}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="IPV4 & IPV6 FORWARDING: ${WLN_PRINTMSG_UPDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="IPV4 & IPV6 FORWARDING: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_NETPLAN_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="NETPLAN: ${WLN_PRINTMSG_UPDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="NETPLAN: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_WIFIPOWERSAVEOFF_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="WIFI-POWERSAVE-OFF: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="WIFI-POWERSAVE-OFF: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_DNSMASQ_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="DNSMASQ: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="DNSMASQ: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_IPTABLES_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="IPTABLES: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="IPTABLES: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_IP6TABLES_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="IP6TABLES: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="IP6TABLES: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_HOSTAPD_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="HOSTAPD: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="HOSTAPD: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_AUTORECONNECTONBOOT_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="AUTORECONNECTONBOOT: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="AUTORECONNECTONBOOT: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_TASK_UPDATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="DATABASE: ${WLN_PRINTMSG_UPDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="DATABASE: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTARTFUNC_EXIT}")
            break
            ;;
    esac

    #Print
    DebugPrint "${printmsg}"
}
