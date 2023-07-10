#!/bin/bash
#---CONSTANTS
PHASE_ASSOCIATEFUNC_TASK_CHECK=1
PHASE_ASSOCIATEFUNC_INTFSTATE_CHECK=10
PHASE_ASSOCIATEFUNC_SERVICES_DISABLESTOP_HANDLER=20
PHASE_ASSOCIATEFUNC_WEP_WPA_VALIDATION=30
PHASE_ASSOCIATEFUNC_BSS_MODE_CHECK=40
PHASE_ASSOCIATEFUNC_SSID_CHECK=50
PHASE_ASSOCIATEFUNC_SSID_ISVISIBLE_CHECK=51
PHASE_ASSOCIATEFUNC_DATABASE_UPDATE=60
PHASE_ASSOCIATEFUNC_NETPLAN_HANDLER=70
PHASE_ASSOCIATEFUNC_WIFIPOWERSAVEOFF_HANDLER=80
# PHASE_ASSOCIATEFUNC_SOFTWARE_INSTALL=81
# PHASE_ASSOCIATEFUNC_DNSMASQ_DISABLESTOP=82
# PHASE_ASSOCIATEFUNC_HOSTAPD_DISABLESTOP=83
PHASE_ASSOCIATEFUNC_WPASUPPLICANT_HANDLER=90
PHASE_ASSOCIATEFUNC_AUTORECONNECTONBOOT_HANDLER=400
PHASE_ASSOCIATEFUNC_TASK_UPDATE=500
PHASE_ASSOCIATEFUNC_EXIT=1000

WLN_associate() {
    #Input args
    local isbssid=${1}            #Must provide (if not required, set to <Empty String> or 0.0.0.0.0.0)
    local isssid=${2}             #Must provide
    local ischannel=${3}          #Must provide (can be any value, will not be used)
    local isbssmode=${4}          #Must provide (is always PL_WLN_BSS_MODE_INFRASTRUCTURE)
    # local isssid_isvisible=${5}   #optional

    #Define variables
    local phase="${PHASE_ASSOCIATEFUNC_TASK_CHECK}"
    # local ssid_isvisible_is_set_automatically=false
    local wlntask="${PL_WLN_NOT_ASSOCIATED}"
    local ret="${REJECTED}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_ASSOCIATEFUNC_TASK_CHECK}")
                #Retrieve data from database
                wlntask=$(WLN_intfstates_ctx_retrievedata \
                        "${WLN_INTFSTATES_CTX_DAT_FPATH}" \
                        "WLN_intfstates_ctx__associationstate")
                if [[ "${wlntask}" == "${PL_WLN_ASSOCIATED}" ]] || \
                        [[ "${wlntask}" == "${PL_WLN_OWN_NETWORK}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_EXIT}"

                    #Print
                    Associate_Debugprint "${PHASE_ASSOCIATEFUNC_TASK_CHECK}" \
                            "${wlntask}" \
                            "${WLN_NUM_1}"
                else
                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_INTFSTATE_CHECK}"

                    #Print
                    Associate_Debugprint "${PHASE_ASSOCIATEFUNC_TASK_CHECK}" \
                            "${wlntask}" \
                            "${WLN_NUM_2}"
                fi
                ;;
            "${PHASE_ASSOCIATEFUNC_INTFSTATE_CHECK}")
                if [[ $(WLN_enabled) == "${NO}" ]]; then
                    if [[ $(WLN_enable) == "${REJECTED}" ]]; then
                        #Update output result
                        ret="${REJECTED}"

                        #Goto next-phase
                        phase="${PHASE_ASSOCIATEFUNC_EXIT}"

                        #Print
                        Associate_Debugprint "${PHASE_ASSOCIATEFUNC_INTFSTATE_CHECK}" \
                                "${WLN_EMPTYSTRING}" \
                                "${WLN_NUM_1}"
                    else
                        #Goto next-phase
                        phase="${PHASE_ASSOCIATEFUNC_SERVICES_DISABLESTOP_HANDLER}"

                        #Print
                        Associate_Debugprint "${PHASE_ASSOCIATEFUNC_INTFSTATE_CHECK}" \
                                "${WLN_EMPTYSTRING}" \
                                "${WLN_NUM_2}"
                    fi
                else
                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_SERVICES_DISABLESTOP_HANDLER}"

                    #Print
                    Associate_Debugprint "${PHASE_ASSOCIATEFUNC_INTFSTATE_CHECK}" \
                            "${WLN_EMPTYSTRING}" \
                            "${WLN_NUM_2}"
                fi
                ;;
            "${PHASE_ASSOCIATEFUNC_SERVICES_DISABLESTOP_HANDLER}")
                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_SERVICES_DISABLESTOP_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                if [[ $(WLN_Services_DisableStop_Handler) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_WEP_WPA_VALIDATION}"
                fi

                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_SERVICES_DISABLESTOP_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_ASSOCIATEFUNC_WEP_WPA_VALIDATION}")
                if [[ $(WLN_Wep_Wpa_Validation) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_EXIT}"

                    #Print
                    Associate_Debugprint "${PHASE_ASSOCIATEFUNC_WEP_WPA_VALIDATION}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"
                else
                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_BSS_MODE_CHECK}"

                    #Print
                    Associate_Debugprint "${PHASE_ASSOCIATEFUNC_WEP_WPA_VALIDATION}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                fi       
                ;;
            "${PHASE_ASSOCIATEFUNC_BSS_MODE_CHECK}")
                #Set 'isbssmode' to 'PL_WLN_BSS_MODE_INFRASTRUCTURE' (if not correct)
                if [[ "${isbssmode}" != "${PL_WLN_BSS_MODE_INFRASTRUCTURE}" ]]; then
                    isbssmode="${PL_WLN_BSS_MODE_INFRASTRUCTURE}"
                fi

                #Goto next-phase
                phase="${PHASE_ASSOCIATEFUNC_SSID_CHECK}"

                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_BSS_MODE_CHECK}" "${isbssmode}" "${WLN_NUM_1}"
                ;;
            "${PHASE_ASSOCIATEFUNC_SSID_CHECK}")
                #Check if 'isssid = <Empty String>'
                #Remark:
                #   This condition will NOT be used in C++, because...
                #   ...an optional value will be set in the function.
                if [[ "${isssid}" == "${WLN_EMPTYSTRING}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_EXIT}"

                    #Print
                    Associate_Debugprint "${PHASE_ASSOCIATEFUNC_SSID_CHECK}" \
                            "${isssid}" \
                            "${WLN_NUM_1}"
                else
                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_DATABASE_UPDATE}"

                    #Print
                    Associate_Debugprint "${PHASE_ASSOCIATEFUNC_SSID_CHECK}" \
                            "${isssid}" \
                            "${WLN_NUM_2}"
                fi
                ;;
            # "${PHASE_ASSOCIATEFUNC_SSID_ISVISIBLE_CHECK}")
            #     #Print
            #     Associate_Debugprint "${PHASE_ASSOCIATEFUNC_SSID_ISVISIBLE_CHECK}" "${isssid}" "${WLN_NUM_1}"

            #     #If 'isssid_isvisible' is NOT provided, then determine
            #     #...whether the 'isssid' is found in the 'scanned list'.
            #     if [[ "${isssid_isvisible}" == "${WLN_EMPTYSTRING}" ]]; then
            #         #Print
            #         Associate_Debugprint "${PHASE_ASSOCIATEFUNC_SSID_ISVISIBLE_CHECK}" "${isssid}" "${WLN_NUM_2}"

            #         #Determine whether 'isssid' is visible or not
            #         isssid_isvisible=$(Associate_SsidIsFound "${isssid}")

            #         #Update boolean
            #         ssid_isvisible_is_set_automatically=true

            #         #Print
            #         Associate_Debugprint "${PHASE_ASSOCIATEFUNC_SSID_ISVISIBLE_CHECK}" "${isssid}" "${WLN_NUM_3}"
            #     fi

            #     #Update print-message
            #     printmsg="${isssid},${isssid_isvisible}"

            #     #Print
            #     Associate_Debugprint "${PHASE_ASSOCIATEFUNC_SSID_ISVISIBLE_CHECK}" "${printmsg}" "${WLN_NUM_4}"

            #     #Goto next-phase
            #     phase="${PHASE_ASSOCIATEFUNC_DATABASE_UPDATE}"
            #     ;;
            "${PHASE_ASSOCIATEFUNC_DATABASE_UPDATE}")
                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_DATABASE_UPDATE}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Update database
                Associate_Intfstates_Ctx_Update "${isbssid}" \
                        "${isssid}" \
                        "${ischannel}" \
                        "${isbssmode}"
                        # "${isssid_isvisible}"

                #Goto next-phase
                phase="${PHASE_ASSOCIATEFUNC_NETPLAN_HANDLER}"

                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_DATABASE_UPDATE}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_ASSOCIATEFUNC_NETPLAN_HANDLER}")
                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_NETPLAN_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup and Apply Netplan
                if [[ $(WLN_Netplan_Handler "${isbssmode}" "${WLN_WLAN_YAML_FPATH}" "false") == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_WIFIPOWERSAVEOFF_HANDLER}"
                fi

                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_NETPLAN_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_ASSOCIATEFUNC_WIFIPOWERSAVEOFF_HANDLER}")
                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_WIFIPOWERSAVEOFF_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup dnsmasq and run service
                if [[ $(WLN_WifiPowerSave_Handler) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_SOFTWARE_INSTALL}"
                fi

                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_WIFIPOWERSAVEOFF_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_ASSOCIATEFUNC_SOFTWARE_INSTALL}")
                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_SOFTWARE_INSTALL}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                if [[ $(WLN_SoftwareInst_OnDemand_Handler "${isbssmode}") == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_WPASUPPLICANT_HANDLER}"
                fi

                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_SOFTWARE_INSTALL}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            # "${PHASE_ASSOCIATEFUNC_DNSMASQ_DISABLESTOP}")
            #     #Print
            #     Associate_Debugprint "${PHASE_ASSOCIATEFUNC_DNSMASQ_DISABLESTOP}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

            #     if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_DNSMASQ_SRV}" \
            #             "${WLN_DNSMASQ}" \
            #             "${WLN_DNSMASQ_SERVICE_FPATH}") == false ]]; then
            #         ret="${REJECTED}"

            #         phase="${PHASE_ASSOCIATEFUNC_EXIT}"
            #     else
            #         phase="${PHASE_ASSOCIATEFUNC_HOSTAPD_DISABLESTOP}"
            #     fi

            #     #Print
            #     Associate_Debugprint "${PHASE_ASSOCIATEFUNC_DNSMASQ_DISABLESTOP}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
            #     ;;
            # "${PHASE_ASSOCIATEFUNC_HOSTAPD_DISABLESTOP}")
            #     #Print
            #     Associate_Debugprint "${PHASE_ASSOCIATEFUNC_HOSTAPD_DISABLESTOP}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

            #     if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_HOSTAPD_SRV}" \
            #             "${WLN_HOSTAPD}" \
            #             "${WLN_HOSTAPD_SERVICE_FPATH}") == false ]]; then
            #         ret="${REJECTED}"

            #         phase="${PHASE_ASSOCIATEFUNC_EXIT}"
            #     else
            #         phase="${PHASE_ASSOCIATEFUNC_WPASUPPLICANT_HANDLER}"
            #     fi

            #     #Print
            #     Associate_Debugprint "${PHASE_ASSOCIATEFUNC_HOSTAPD_DISABLESTOP}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
            #     ;;
            "${PHASE_ASSOCIATEFUNC_WPASUPPLICANT_HANDLER}")
                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_WPASUPPLICANT_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup dnsmasq and run service
                if [[ $(WLN_WpaSupplicant_Handler) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_AUTORECONNECTONBOOT_HANDLER}"
                fi

                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_WPASUPPLICANT_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_ASSOCIATEFUNC_AUTORECONNECTONBOOT_HANDLER}")
                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_AUTORECONNECTONBOOT_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup hostapd-ng and run service
                if [[ $(WLN_AutoReconnectOnBoot_Handler) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_ASSOCIATEFUNC_TASK_UPDATE}"
                fi

                #Print
                Networkstart_Debugprint "${PHASE_NETWORKSTARTFUNC_AUTORECONNECTONBOOT_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_ASSOCIATEFUNC_TASK_UPDATE}")
                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_TASK_UPDATE}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Update database
                WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" \
                        "WLN_intfstates_ctx__associationstate" \
                        "${PL_WLN_ASSOCIATED}"

                #Update output result
                ret="${ACCEPTED}"

                #Goto next-phase
                phase="${PHASE_ASSOCIATEFUNC_EXIT}"

                #Print
                Associate_Debugprint "${PHASE_ASSOCIATEFUNC_TASK_UPDATE}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_ASSOCIATEFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

Associate_Debugprint() {
    #Input args
    local phase=${1}
    local printmsg_val=${2}
    local printmsg_num=${3}

    #Define constants
    local PRINTMSG_ASSOCIATE="${WLN_PRINTMSG_STATUS}: ${WLN_LIGHTGREY}Associate${WLN_RESETCOLOR}"

    #Define variables
    local printmsg="${PRINTMSG_ASSOCIATE}: "
    local printmsg_val1=$(echo "${printmsg_val}" | cut -d"," -f1)
    local printmsg_val2=$(echo "${printmsg_val}" | cut -d"," -f2)
    local printmsg_val3=$(echo "${printmsg_val}" | cut -d"," -f3)
    local printmsg_val4=$(echo "${printmsg_val}" | cut -d"," -f4)
    local printmsg_val5=$(echo "${printmsg_val}" | cut -d"," -f5)

    #Print
    case "${phase}" in
        "${PHASE_ASSOCIATEFUNC_TASK_CHECK}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="TASK (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): "
                printmsg+="${WLN_PRINTMSG_REJECTED}" 
            else    #printmsg_num = WLN_NUM_2
                printmsg+="TASK (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): "
                printmsg+="${WLN_PRINTMSG_ACCEPTED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_INTFSTATE_CHECK}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="WIFI: ${WLN_PRINTMSG_DISABLED}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="WIFI: ${WLN_PRINTMSG_ENABLED}" 
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_SERVICES_DISABLESTOP_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="ALL SERVICES: ${WLN_PRINTMSG_DISABLESTOP}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="ALL SERVICES: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_WEP_WPA_VALIDATION}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="WEP & WPA VALIDATION: ${WLN_PRINTMSG_REJECTED}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="WEP & WPA VALIDATION: ${WLN_PRINTMSG_ACCEPTED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_BSS_MODE_CHECK}")
            printmsg+="WLN_BSS_MODE {"
            printmsg+="${WLN_LIGHTGREY}INFRA(${WLN_RESETCOLOR}0${WLN_LIGHTGREY})${WLN_RESETCOLOR}"
            printmsg+="|"
            printmsg+="${WLN_LIGHTGREY}AP(${WLN_RESETCOLOR}1${WLN_LIGHTGREY})${WLN_RESETCOLOR}"
            printmsg+="|"
            printmsg+="${WLN_LIGHTGREY}ROUTER(${WLN_RESETCOLOR}2${WLN_LIGHTGREY})${WLN_RESETCOLOR}"
            printmsg+="}: ${WLN_YELLOW}${printmsg_val1}${WLN_RESETCOLOR}"
            ;;
        "${PHASE_ASSOCIATEFUNC_SSID_CHECK}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="SSID (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): "
                printmsg+="${WLN_PRINTMSG_REJECTED}" 
            else    #printmsg_num = WLN_NUM_2
                printmsg+="SSID (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): "
                printmsg+="${WLN_PRINTMSG_ACCEPTED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_SSID_ISVISIBLE_CHECK}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="SSID_IS_VISIBLE (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): ${WLN_PRINTMSG_VALIDATING}"
            elif [[ ${printmsg_num} -eq ${WLN_NUM_2} ]]; then
                printmsg+="SSID_IS_VISIBLE (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): ${WLN_PRINTMSG_NOT_SET}"
            elif [[ ${printmsg_num} -eq ${WLN_NUM_3} ]]; then
                printmsg+="SSID_IS_VISIBLE (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): ${WLN_PRINTMSG_COMPLETED}"
            else    #printmsg_num = WLN_NUM_4
                printmsg+="SSID_IS_VISIBLE (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): ${WLN_YELLOW}${printmsg_val2}${WLN_RESETCOLOR}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_DATABASE_UPDATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="DATABASE: ${WLN_PRINTMSG_UPDATING}"
            else  #printmsg_num = WLN_NUM_2
                printmsg+="DATABASE: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_NETPLAN_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="NETPLAN: ${WLN_PRINTMSG_UPDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="NETPLAN: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_WIFIPOWERSAVEOFF_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="WIFI-POWERSAVE-OFF: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="WIFI-POWERSAVE-OFF: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_SOFTWARE_INSTALL}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="SOFTWARE INSTALL: ${WLN_PRINTMSG_INSTALLING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="SOFTWARE INSTALL: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_DNSMASQ_DISABLESTOP}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="DNSMASQ SERVICE: ${WLN_PRINTMSG_DISABLESTOP}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="DNSMASQ SERVICE: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_HOSTAPD_DISABLESTOP}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="HOSTAPD SERVICE: ${WLN_PRINTMSG_DISABLESTOP}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="HOSTAPD SERVICE: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_WPASUPPLICANT_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="WPA-SUPPLICANT SERVICE & DAEMON: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="WPA-SUPPLICANT SERVICE & DAEMON: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_TASK_UPDATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="DATABASE: ${WLN_PRINTMSG_UPDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="DATABASE: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_ASSOCIATEFUNC_EXIT}")
            break
            ;;
    esac

    #Print
    DebugPrint "${printmsg}"
}

Associate_Intfstates_Ctx_Update() {
    #Input args
	local isbssid=${1}
    local isssid=${2}
    local ischannel=${3}
    local isbssmode=${4}

    #Write data to file
	WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__bssid" "${isbssid}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__ssid" "${isssid}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__channel" "${ischannel}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__bssmode" "${isbssmode}"
}
