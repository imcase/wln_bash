#!/bin/bash
#---MAIN FUNCTIONS
WLN_AutoReconnectOnBoot_Handler() {
    #Define constants
    local PHASE_SERVICES_DISABLESTOP_HANDLER=1
    local PHASE_AUTORECONNECTONBOOT_DIRS_FILES_CLEANUP=10
    local PHASE_AUTORECONNECTONBOOT_DIRS_CREATE=11
    local PHASE_AUTORECONNECTONBOOT_LOG_CREATE=21
    local PHASE_AUTORECONNECTONBOOT_RUNATLOGIN_CREATE=22
    local PHASE_AUTORECONNECTONBOOT_CHANNEL_CHECK=30
    local PHASE_AUTORECONNECTONBOOT_UFW_PORTS_SET=31
    local PHASE_AUTORECONNECTONBOOT_IPV46_FORWARDING=32
    local PHASE_AUTORECONNECTONBOOT_SOFTWARE_INSTALL=40
    local PHASE_AUTORECONNECTONBOOT_NETPLAN_HANDLER=50
    local PHASE_AUTORECONNECTONBOOT_DNSMASQ_HANDLER=60
    local PHASE_AUTORECONNECTONBOOT_IPTABLES_HANDLER=70
    local PHASE_AUTORECONNECTONBOOT_IP6TABLES_HANDLER=80
    local PHASE_AUTORECONNECTONBOOT_HOSTAPD_HANDLER=90
    local PHASE_AUTORECONNECTONBOOT_SIMLINKS_REMOVE=100
    local PHASE_AUTORECONNECTONBOOT_THIS_SERVICE_CREATE=110
    local PHASE_AUTORECONNECTONBOOT_RELOADCONNECT_SERVICE_CREATE=111
    local PHASE_AUTORECONNECTONBOOT_RESETCONNECT_SERVICE_CREATE=112
    local PHASE_AUTORESETCONNECT_SCRIPT_CREATE=113
    local PHASE_AUTORECONNECTONBOOT_THIS_SERVICE_START=114
    local PHASE_AUTORECONNECTONBOOT_EXIT=130

    #Define variables
    local phase="${PHASE_SERVICES_DISABLESTOP_HANDLER}"
    local channel_init_retrieved="${WLN_EMPTYSTRING}"
    local channel_validated="${WLN_EMPTYSTRING}"
    local phymode_init_retrieved="${WLN_EMPTYSTRING}"
    local timestamp="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Retrieve channel from initial database
    autoreconnectonboot_retrieved=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__autoreconnectonboot")
    bssmode_retrieved=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__bssmode")
    channel_init_retrieved=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_INIT_DAT_FPATH}" "WLN_intfstates_ctx__channel")
    phymode_init_retrieved=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_INIT_DAT_FPATH}" "WLN_intfstates_ctx__phymode")

    #Create timestamp
    timestamp=$(date +%s)

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SERVICES_DISABLESTOP_HANDLER}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_SERVICES_DISABLESTOP_HANDLER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(AutoReconnectOnBoot_Services_DisableStop) == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_DIRS_FILES_CLEANUP}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_SERVICES_DISABLESTOP_HANDLER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_DIRS_FILES_CLEANUP}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_DIRS_FILES_CLEANUP}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(AutoReconnectOnBoot_CleanUp_Dirs_And_Files) == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_DIRS_CREATE}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_DIRS_FILES_CLEANUP}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_DIRS_CREATE}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_DIRS_CREATE}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(AutoReconnectOnBoot_Create_Dirs) == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_LOG_CREATE}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_DIRS_CREATE}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_LOG_CREATE}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_LOG_CREATE}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(WriteToFile "${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_LOG_FPATH}" \
                        "${timestamp}" \
                        "true") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_RUNATLOGIN_CREATE}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_LOG_CREATE}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_RUNATLOGIN_CREATE}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_RUNATLOGIN_CREATE}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(AutoReconnectOnBoot_RunAtLogin_Script_Create \
                        "${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_SRC_FPATH}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_CHANNEL_CHECK}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_RUNATLOGIN_CREATE}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_CHANNEL_CHECK}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_CHANNEL_CHECK}" \
                        "${channel_init_retrieved}" \
                        "${WLN_NUM_1}"

                #Validate channel and update initial database
                #Remark:
                #   Writing to database must be done, because
                #   ...WLN_Hostapd_Handler needs this validated channel.
                channel_validated=$(Channel_Validate_And_Update_Database "${channel_init_retrieved}" \
                        "${phymode_init_retrieved}" \
                        "${WLN_INTFSTATES_CTX_INIT_DAT_FPATH}")
                if [[ "${channel_validated}" == "${WLN_EMPTYSTRING}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_UFW_PORTS_SET}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_CHANNEL_CHECK}" \
                        "${channel_validated}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_UFW_PORTS_SET}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_UFW_PORTS_SET}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(WLN_Ufw_Ports_Allow) == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_IPV46_FORWARDING}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_UFW_PORTS_SET}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_IPV46_FORWARDING}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_IPV46_FORWARDING}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(WLN_Ipv46_Forwarding_Enable) == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_SOFTWARE_INSTALL}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_IPV46_FORWARDING}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_SOFTWARE_INSTALL}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_SOFTWARE_INSTALL}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(WLN_SoftwareInst_OnDemand_Handler "${PL_WLN_BSS_MODE_ROUTER}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_NETPLAN_HANDLER}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_SOFTWARE_INSTALL}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_NETPLAN_HANDLER}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_NETPLAN_HANDLER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(WLN_Netplan_Handler "${PL_WLN_BSS_MODE_ROUTER}" \
                        "${WLN_WLAN_YAML_AUTORECONNECTONBOOT_FPATH}" \
                        "true") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_NETPLAN_HANDLER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(WLN_Dnsmasq_Handler "${PL_WLN_BSS_MODE_ROUTER}" "true") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_IPTABLES_HANDLER}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_IPTABLES_HANDLER}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_IPTABLES_HANDLER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(WLN_Ip46tables_Rules_Create "${WLN_IPTABLES}" \
                        "${WLN_IPTABLES_SRV}" \
                        "${WLN_IPTABLES_RULES_V4_ORG_FPATH}" \
                        "${WLN_IPTABLES_RULES_V4_AUTORECONNECTONBOOT_FPATH}" \
                        "${WLN_IPTABLES_SERVICE_FPATH}" \
                        "${WLN_MOD_776}" \
                        "${WLN_INTFSTATES_CTX_INIT_DAT_FPATH}" \
                        "false") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_IPTABLES_HANDLER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_1}"

                if [[ $(WLN_Ip46tables_Rules_Create "${WLN_IP6TABLES}" \
                        "${WLN_IP6TABLES_SRV}" \
                        "${WLN_IP6TABLES_RULES_V6_ORG_FPATH}" \
                        "${WLN_IP6TABLES_RULES_V6_AUTORECONNECTONBOOT_FPATH}" \
                        "${WLN_IP6TABLES_SERVICE_FPATH}" \
                        "${WLN_MOD_776}" \
                        "${WLN_INTFSTATES_CTX_INIT_DAT_FPATH}" \
                        "false") == "${REJECTED}" ]]; then

                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}" \
                        "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Setup hostapd-ng and run service
                #Remark:
                #   The 'domain-code' is set in function 'WLN_IntfStates_Ctx_Init_Handler'
                if [[ $(WLN_Hostapd_Handler "true") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_SIMLINKS_REMOVE}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORECONNECTONBOOT_SIMLINKS_REMOVE}")
                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_SIMLINKS_REMOVE}" \
                        "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                if [[ $(AutoReconnectOnBoot_CleanUp_Simlinks) == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORESETCONNECT_SCRIPT_CREATE}"
                fi

                #Print
                AutoReconnectOnBoot_Debugprint "${PHASE_AUTORECONNECTONBOOT_SIMLINKS_REMOVE}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_NUM_2}"
                ;;
            "${PHASE_AUTORESETCONNECT_SCRIPT_CREATE}")
                if [[ $(AutoResetConnect_Script_Create "${WLN_NTIOS_WLN_AUTORESETCONNECT_SH_FPATH}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_THIS_SERVICE_CREATE}"
                fi
                ;;
            "${PHASE_AUTORECONNECTONBOOT_THIS_SERVICE_CREATE}")
                if [[ $(AutoReconnectOnBoot_Service_Create \
                        "${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_SRV_FPATH}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_RELOADCONNECT_SERVICE_CREATE}"
                fi
                ;;
            "${PHASE_AUTORECONNECTONBOOT_RELOADCONNECT_SERVICE_CREATE}")
                #Translate enum to string
                if [[ "${bssmode_retrieved}" == "${PL_WLN_BSS_MODE_INFRASTRUCTURE}" ]]; then
                    bssmode_string="${WLN_SERVICE_INPUTARG_INFRASTRUCTURE}"
                elif [[ "${bssmode_retrieved}" == "${PL_WLN_BSS_MODE_ACCESSPOINT}" ]]; then
                    bssmode_string="${WLN_SERVICE_INPUTARG_ACCESSPOINT}"
                else
                    bssmode_string="${WLN_SERVICE_INPUTARG_ROUTER}"
                fi

                if [[ $(ReloadConnect_Service_Create \
                        "${WLN_NTIOS_WLN_RELOADCONNECT_SRV_FPATH}" "${bssmode_string}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_RESETCONNECT_SERVICE_CREATE}"
                fi
                ;;
            "${PHASE_AUTORECONNECTONBOOT_RESETCONNECT_SERVICE_CREATE}")
                if [[ $(ResetConnect_Service_Create \
                        "${WLN_NTIOS_WLN_RESETCONNECT_SRV_FPATH}" \
                        "${WLN_SERVICE_INPUTARG_ROUTER}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                else
                    phase="${PHASE_AUTORECONNECTONBOOT_THIS_SERVICE_START}"
                fi
                ;;
            "${PHASE_AUTORECONNECTONBOOT_THIS_SERVICE_START}")
                if [[ $(AutoReconnectOnboot_Service_Start_Or_Stop \
                        "${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_SRV}" \
                        "${autoreconnectonboot_retrieved}") == false ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_AUTORECONNECTONBOOT_EXIT}"
                ;;        
            "${PHASE_AUTORECONNECTONBOOT_EXIT}")
                break
                ;;  
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

#---SUPPORT FUNCTIONS
AutoReconnectOnBoot_Debugprint() {
    #Input args
    local phase=${1}
    local printmsg_val=${2}
    local printmsg_num=${3}

    #Define constants
    local PRINTMSG_AUTORECONNECTONBOOTONBOOT="${WLN_PRINTMSG_STATUS}: ${WLN_LIGHTGREY}AutoReconnectOnBoot${WLN_RESETCOLOR}"

    #Define variables
    local printmsg="${PRINTMSG_AUTORECONNECTONBOOTONBOOT}: "
    local printmsg_val1=$(echo "${printmsg_val}" | cut -d"," -f1)
    local printmsg_val2=$(echo "${printmsg_val}" | cut -d"," -f2)
    local printmsg_val3=$(echo "${printmsg_val}" | cut -d"," -f3)
    local printmsg_val4=$(echo "${printmsg_val}" | cut -d"," -f4)
    local printmsg_val5=$(echo "${printmsg_val}" | cut -d"," -f5)

    #Print
    case "${phase}" in
        "${PHASE_SERVICES_DISABLESTOP_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="SERVICES: DISABLE & STOP: ${WLN_PRINTMSG_IN_PROGRESS}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="SERVICES: DISABLE & STOP: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_DIRS_FILES_CLEANUP}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="DIRS AND FILES: ${WLN_PRINTMSG_STARTING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="DIRS AND FILES: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_DIRS_CREATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="DIRS: ${WLN_PRINTMSG_CREATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="DIRS: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_LOG_CREATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="TIMESTAMP-LOG: ${WLN_PRINTMSG_CREATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="TIMESTAMP-LOG: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_RUNATLOGIN_CREATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="AUTORECONNECTONBOOT_RUNATLOGIN SCRIPT: "
                    printmsg+="${WLN_PRINTMSG_CREATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="AUTORECONNECTONBOOT_RUNATLOGIN SCRIPT: "
                    printmsg+="${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_CHANNEL_CHECK}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="CHANNEL ${WLN_YELLOW}${printmsg_val1}${WLN_RESETCOLOR}: " 
                    printmsg+="${WLN_PRINTMSG_VALIDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="CHANNEL ${WLN_YELLOW}${printmsg_val1}${WLN_RESETCOLOR}: " 
                    printmsg+="${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_SOFTWARE_INSTALL}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="SOFTWARE INSTALL: ${WLN_PRINTMSG_INSTALLING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="SOFTWARE INSTALL: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_UFW_PORTS_SET}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="UFW PORTS: ${WLN_PRINTMSG_UPDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="UFW PORTS: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_IPV46_FORWARDING}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="IPV4 & IPV6 FORWARDING: ${WLN_PRINTMSG_UPDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="IPV4 & IPV6 FORWARDING: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_NETPLAN_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="NETPLAN: ${WLN_PRINTMSG_UPDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="NETPLAN: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="DNSMASQ: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="DNSMASQ: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_IPTABLES_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="IPTABLES: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="IPTABLES: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="IP6TABLES: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="IP6TABLES: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="HOSTAPD: ${WLN_PRINTMSG_CREATE_AND_TRIGGER}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="HOSTAPD: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_SIMLINKS_REMOVE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="SIMLINKS: ${WLN_PRINTMSG_REMOVING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="SIMLINKS: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORESETCONNECT_SCRIPT_CREATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="AUTORESETCONNECT SCRIPT: ${WLN_PRINTMSG_CREATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="AUTORESETCONNECT SCRIPT: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_THIS_SERVICE_CREATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="AUTORECONNECTONBOOT SERVICE: ${WLN_PRINTMSG_CREATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="AUTORECONNECTONBOOT SERVICE: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_RELOADCONNECT_SERVICE_CREATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="RELOADCONNECT SERVICE: ${WLN_PRINTMSG_CREATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="RELOADCONNECT SERVICE: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_RESETCONNECT_SERVICE_CREATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="RESETCONNECT SERVICE: ${WLN_PRINTMSG_CREATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="RESETCONNECT SERVICE: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_THIS_SERVICE_START}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="AUTORECONNECTONBOOT SERVICE: ${WLN_PRINTMSG_STARTING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="AUTORECONNECTONBOOT SERVICE: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_AUTORECONNECTONBOOT_EXIT}")
            break
            ;;
    esac

    #Print
    DebugPrint "${printmsg}"
}



AutoReconnectOnBoot_RunAtLogin_Script_Create() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Generate 'ntios-wln-autoreconnectonboot-runatlogin.sh'
    filecontent="#!/bin/bash\n"
    filecontent+="mypid=\$\$\n"
    filecontent+="sudo systemctl start ${SYSTEMCTL_NTIOS_SU_ADD_AT}\${mypid}\n"
    filecontent+="\n"
    filecontent+="srv_input=${WLN_SIXTEENBACKSLASHES_SLASH_HEX}bin"
        filecontent+="${WLN_SIXTEENBACKSLASHES_SLASH_HEX}rm"
        filecontent+="${WLN_SIXTEENBACKSLASHES_SPACE_HEX}${WLN_SIXTEENBACKSLASHES_ASTERISK_HEX}\n"
    filecontent+="sudo systemctl start ${SYSTEMCTL_NTIOS_SU_ADD_AT}\${srv_input}\n"
    filecontent+="\n"
    filecontent+="srv_input=${WLN_SIXTEENBACKSLASHES_SLASH_HEX}usr"
        filecontent+="${WLN_SIXTEENBACKSLASHES_SLASH_HEX}bin"
        filecontent+="${WLN_SIXTEENBACKSLASHES_SLASH_HEX}systemctl"
        filecontent+="${WLN_SIXTEENBACKSLASHES_SPACE_HEX}${WLN_SIXTEENBACKSLASHES_ASTERISK_HEX}\n"
    filecontent+="sudo systemctl start ${SYSTEMCTL_NTIOS_SU_ADD_AT}\${srv_input}\n"
    filecontent+="\n"
    filecontent+="sudo systemctl start ${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_SRV}\n"
    filecontent+="\n"
    filecontent+="sudo rm ${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_DST_FPATH}"

    #Check if file exist
    RemoveFile "${istargetfpath}"

    #Write to file
    if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == true ]]; then
        #Change permisions
        if [[ $( Chmod "${istargetfpath}" "${WLN_MOD_755}") == true ]]; then
            ret="${ACCEPTED}"
        else
            ret="${REJECTED}"
        fi
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}

AutoReconnectOnBoot_CleanUp_Dirs_And_Files() {
    local dir="${WLN_EMPTYSTRING}"
    local file="${WLN_EMPTYSTRING}"
    local i=1
    local ret=true

    while [[ ${i} -le 8 ]]
    do
        dir="${WLN_EMPTYSTRING}"
        file="${WLN_EMPTYSTRING}"

        case "${i}" in
            1)
                dir="${WLN_ETC_TIBBO_DNSMASQ_WLN_DIR}"
                ;;
            2)
                dir="${WLN_ETC_TIBBO_FIRMWARE_WLN_DIR}"
                ;;
            3)
                dir="${WLN_ETC_TIBBO_HOSTAPD_WLN_DIR}"
                ;;
            4)
                dir="${WLN_ETC_TIBBO_IPTABLES_WLN_DIR}"
                ;;
            5)
                dir="${WLN_ETC_TIBBO_IP6TABLES_WLN_DIR}"
                ;;
            6)
                dir="${WLN_ETC_TIBBO_NETPLAN_WLN_DIR}"
                ;;
            7)
                dir="${WLN_ETC_TIBBO_PROFILED_WLN_DIR}"
                ;;
            8)
                file="${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_LOG_FPATH}"
                ;;
        esac

        if [[ -n "${dir}" ]]; then
            if [[ $(RemoveDir "${dir}") == false ]]; then
                ret=false

                break
            fi
        else
            if [[ $(RemoveFile "${file}") == false ]]; then
                ret=false

                break
            fi
        fi

        ((i++))
    done

    #Output
    echo "${ret}"

    return 0;  
}

AutoReconnectOnBoot_CleanUp_Simlinks() {
    local file="${WLN_EMPTYSTRING}"
    local i=1
    local ret=true

    while [[ ${i} -le 2 ]]
    do
        case "${i}" in
            1)
                file="${WLN_NTIOS_WLN_RELOADCONNECT_SRV_SIMLINK_FPATH}"
                ;;
            2)
                file="${WLN_NTIOS_WLN_RESETCONNECT_SRV_SIMLINK_FPATH}"
                ;;
        esac

        if [[ $(RemoveFile "${file}") == false ]]; then
            ret=false

            break
        fi

        ((i++))
    done

    #Output
    echo "${ret}"

    return 0;  
}

AutoReconnectOnBoot_Create_Dirs() {
    local dir="${WLN_EMPTYSTRING}"
    local i=1
    local ret=true

    while [[ ${i} -le 8 ]]
    do
        case "${i}" in
            1)
                dir="${WLN_ETC_TIBBO_DNSMASQ_WLN_DIR}"
                ;;
            2)
                dir="${WLN_ETC_TIBBO_FIRMWARE_WLN_DIR}"
                ;;
            3)
                dir="${WLN_ETC_TIBBO_HOSTAPD_WLN_DIR}"
                ;;
            4)
                dir="${WLN_ETC_TIBBO_IPTABLES_WLN_DIR}"
                ;;
            5)
                dir="${WLN_ETC_TIBBO_IP6TABLES_WLN_DIR}"
                ;;
            6)
                dir="${WLN_ETC_TIBBO_NETPLAN_WLN_DIR}"
                ;;
            7)
                dir="${WLN_ETC_TIBBO_PROFILED_WLN_DIR}"
                ;;
            8)
                dir="${WLN_ETC_TIBBO_LOG_WLN_DIR}"
                ;;
        esac

        if [[ $(Mkdir "${dir}") == false ]]; then
            ret=false

            break
        fi

        ((i++))
    done

    #Output
    echo "${ret}"

    return 0;  
}

AutoReconnectOnBoot_Services_DisableStop() {
    local srv_name="${WLN_EMPTYSTRING}"
    local i=1
    local ret=true

    while [[ ${i} -le 3 ]]
    do
        case "${i}" in
            1)
                srv_name="${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_SRV}"
                ;;
            2)
                srv_name="${WLN_NTIOS_WLN_RELOADCONNECT_SRV}"
                ;;
            3)
                srv_name="${WLN_NTIOS_WLN_RESETCONNECT_SRV}"
                ;;
        esac

        if [[ $(Service_ShouldBe_Disabled_And_Stopped  "${srv_name}" \
                "${WLN_EMPTYSTRING}" \
                "${WLN_EMPTYSTRING}") == false ]]; then
            ret=false

            break
        fi

        ((i++))
    done

    #Output
    echo "${ret}"

    return 0;  
}

AutoReconnectOnboot_Service_Start_Or_Stop() {
    #Input args
    local issrv_name=${1}
    local isautoreconnectonboot_istriggered=${2}

    #Define variables
    local ret="${REJECTED}"

    #Enable Service
    if [[ $(SystemctlStartService "${issrv_name}") == false ]]; then
        ret="${REJECTED}"
    else
        if [[ ${isautoreconnectonboot_istriggered} == ${NO} ]]; then
            #Disable Service
            if [[ $(SystemctlStopService "${issrv_name}") == false ]]; then
                ret="${REJECTED}"
            else
                ret="${ACCEPTED}"
            fi
        else
            ret="${ACCEPTED}"
        fi
    fi

    #Output
    echo "${ret}"

    return 0;  
}

AutoResetConnect_Script_Create() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    filecontent="#!/bin/bash\n"
    filecontent+="#---Input args\n"
    filecontent+="action=\${1}     #valid input values {enable|disable}\n"
    filecontent+="bssmode=\${2}    #valid input values {infrastructure|accesspoint|router}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---COLORS CONSTANTS\n"
    filecontent+="WLN_RESETCOLOR=\$'\\\e[0m'\n"
    filecontent+="WLN_ORANGE=\$'\\\e[30;38;5;209m'\n"
    filecontent+="WLN_LIGHTGREY=\$'\\\e[30;38;5;246m'\n"
    filecontent+="WLN_LIGHTGREEN=\$'\\\e[30;38;5;71m'\n"
    filecontent+="WLN_LIGHTBLUE=\$'\\\e[30;38;5;45m'\n"
    filecontent+="WLN_LIGHTRED=\$'\\\e[1;31m'\n"
    filecontent+="WLN_SOFLIGHTRED=\$'\\\e[30;38;5;131m'\n"
    filecontent+="WLN_YELLOW=\$'\\\e[1;33m'\n"
    filecontent+="\n"
    filecontent+="#---BSSMODE CONSTANTS\n"
    filecontent+="WLN_SERVICE_INPUTARG_INFRASTRUCTURE=\"${WLN_SERVICE_INPUTARG_INFRASTRUCTURE}\"\n"
    filecontent+="WLN_SERVICE_INPUTARG_ACCESSPOINT=\"${WLN_SERVICE_INPUTARG_ACCESSPOINT}\"\n"
    filecontent+="WLN_SERVICE_INPUTARG_ROUTER=\"${WLN_SERVICE_INPUTARG_ROUTER}\"\n"
    filecontent+="\n"
    filecontent+="#---ENVIRONMENT CONSTANTS\n"
    filecontent+="WLN_DNSMASQ_CONF_FPATH=\"${WLN_DNSMASQ_CONF_FPATH}\"\n"
    filecontent+="WLN_DNSMASQ_CONF_AUTORECONNECTONBOOT_FPATH=\"${WLN_DNSMASQ_CONF_AUTORECONNECTONBOOT_FPATH}\"\n"
    filecontent+="WLN_DNSMASQ_CONF_CURRENT_FPATH=\"${WLN_DNSMASQ_CONF_CURRENT_FPATH}\"\n"
    filecontent+="WLN_HOSTAPD_CONF_FPATH=\"${WLN_HOSTAPD_CONF_FPATH}\"\n"
    filecontent+="WLN_HOSTAPD_CONF_AUTORECONNECTONBOOT_FPATH=\"${WLN_HOSTAPD_CONF_AUTORECONNECTONBOOT_FPATH}\"\n"
    filecontent+="WLN_HOSTAPD_CONF_CURRENT_FPATH=\"${WLN_HOSTAPD_CONF_CURRENT_FPATH}\"\n"
    filecontent+="WLN_HOSTAPD_NG_SERVICE_FPATH=\"${WLN_HOSTAPD_NG_SERVICE_FPATH}\"\n"
    filecontent+="WLN_HOSTAPD_NG_SERVICE_AUTORECONNECTONBOOT_FPATH=\"${WLN_HOSTAPD_NG_SERVICE_AUTORECONNECTONBOOT_FPATH}\"\n"
    filecontent+="WLN_HOSTAPD_NG_SERVICE_CURRENT_FPATH=\"${WLN_HOSTAPD_NG_SERVICE_CURRENT_FPATH}\"\n"
    filecontent+="WLN_IPTABLES_RULES_V4_FPATH=\"${WLN_IPTABLES_RULES_V4_FPATH}\"\n"
    filecontent+="WLN_IPTABLES_RULES_V4_AUTORECONNECTONBOOT_FPATH=\"${WLN_IPTABLES_RULES_V4_AUTORECONNECTONBOOT_FPATH}\"\n"
    filecontent+="WLN_IPTABLES_RULES_V4_CURRENT_FPATH=\"${WLN_IPTABLES_RULES_V4_CURRENT_FPATH}\"\n"
    filecontent+="WLN_IP6TABLES_RULES_V6_FPATH=\"${WLN_IP6TABLES_RULES_V6_FPATH}\"\n"
    filecontent+="WLN_IP6TABLES_RULES_V6_AUTORECONNECTONBOOT_FPATH=\"${WLN_IP6TABLES_RULES_V6_AUTORECONNECTONBOOT_FPATH}\"\n"
    filecontent+="WLN_IP6TABLES_RULES_V6_CURRENT_FPATH=\"${WLN_IP6TABLES_RULES_V6_CURRENT_FPATH}\"\n"
    filecontent+="WLN_NTIOS_WLN_AUTORECONNECTONBOOT_LOG_FPATH=\"${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_LOG_FPATH}\"\n"
    filecontent+="WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_SRC_FPATH=\"${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_SRC_FPATH}\"\n"
    filecontent+="WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_DST_FPATH=\"${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_DST_FPATH}\"\n"
    filecontent+="WLN_NTIOS_WLN_RELOADCONNECT_SRV_FPATH=\"${WLN_NTIOS_WLN_RELOADCONNECT_SRV_FPATH}\"\n"
    filecontent+="WLN_NTIOS_WLN_RESETCONNECT_SRV_FPATH=\"${WLN_NTIOS_WLN_RESETCONNECT_SRV_FPATH}\"\n"
    filecontent+="WLN_WLAN_YAML_FPATH=\"${WLN_WLAN_YAML_FPATH}\"\n"
    filecontent+="WLN_WLAN_YAML_AUTORECONNECTONBOOT_FPATH=\"${WLN_WLAN_YAML_AUTORECONNECTONBOOT_FPATH}\"\n"
    filecontent+="WLN_WLAN_YAML_CURRENT_FPATH=\"${WLN_WLAN_YAML_CURRENT_FPATH}\"\n"
    filecontent+="\n"
    filecontent+="#---OTHER CONSTANTS\n"
    filecontent+="WLN_EMPTYSTRING=\"\"\n"
    filecontent+="\n"
    filecontent+="#---PHASE CONSTANTS\n"
    filecontent+="PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_DISABLE=1\n"
    filecontent+="PHASE_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_HANDLER=10\n"
    filecontent+="PHASE_WLN_AUTORECONNECTONBOOT_NETPLAN_HANDLER=20\n"
    filecontent+="PHASE_WLN_AUTORECONNECTONBOOT_DNSMASQ_HANDLER=30\n"
    filecontent+="PHASE_WLN_AUTORECONNECTONBOOT_IPTABLES_HANDLER=40\n"
    filecontent+="PHASE_WLN_AUTORECONNECTONBOOT_IP6TABLES_HANDLER=50\n"
    filecontent+="PHASE_WLN_AUTORECONNECTONBOOT_HOSTAPD_HANDLER=60\n"
    filecontent+="PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE=70\n"
    filecontent+="PHASE_WLN_AUTORECONNECTONBOOT_EXIT=100\n"
    filecontent+="\n"
    filecontent+="#---PRINT CONSTANTS\n"
    filecontent+="WLN_PRINTMSG_STATUS=\":-->\${WLN_ORANGE}STATUS\${WLN_RESETCOLOR}\"\n"
    filecontent+="WLN_PRINTMSG_DONE=\"\${WLN_YELLOW}DONE\${WLN_RESETCOLOR}\"\n"
    filecontent+="WLN_PRINTMSG_FAILED=\"\${WLN_SOFLIGHTRED}FAILED\${WLN_RESETCOLOR}\"\n"
    filecontent+="WLN_PRINTMSG_NOT=\"\${WLN_SOFLIGHTRED}NOT\${WLN_RESETCOLOR}\"\n"
    filecontent+="\n"
    filecontent+="#---SERVICES CONSTANTS\n"
    filecontent+="WLN_DNSMASQ_SRV=\"${WLN_DNSMASQ_SRV}\"\n"
    filecontent+="WLN_HOSTAPD_NG_SRV=\"${WLN_HOSTAPD_NG_SRV}\"\n"
    filecontent+="WLN_IPTABLES_SRV=\"${WLN_IPTABLES_SRV}\"\n"
    filecontent+="WLN_IP6TABLES_SRV=\"${WLN_IP6TABLES_SRV}\"\n"
    filecontent+="WLN_WIFI_POWERSAVE_OFF_SRV=\"${WLN_WIFI_POWERSAVE_OFF_SRV}\"\n"
    filecontent+="WLN_WIFI_POWERSAVE_OFF_TIMER=\"${WLN_WIFI_POWERSAVE_OFF_TIMER}\"\n"
    filecontent+="WLN_WPA_SUPPLICANT_DAEMON_SRV=\"${WLN_WPA_SUPPLICANT_DAEMON_SRV}\"\n"
    filecontent+="WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV=\"${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}\"\n"
    filecontent+="\n"
    filecontent+="#---STATES CONSTANTS\n"
    filecontent+="WLN_DISABLE=\"${WLN_DISABLE}\"\n"
    filecontent+="WLN_ENABLE=\"${WLN_ENABLE}\"\n"
    filecontent+="WLN_DISABLED=\"${WLN_DISABLED}\"\n"
    filecontent+="WLN_ENABLED=\"${WLN_ENABLED}\"\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---VARIABLES\n"
    filecontent+="phase=\"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="timestamp=0\n"
    filecontent+="dnsmasq_current_timestamp_fpath=\"\${WLN_DNSMASQ_CONF_CURRENT_FPATH}.\${timestamp}\"\n"
    filecontent+="hostapd_conf_current_timestamp_fpath=\"\${WLN_HOSTAPD_CONF_CURRENT_FPATH}.\${timestamp}\"\n"
    filecontent+="rules_v4_current_timestamp_fpath=\"\${WLN_IPTABLES_RULES_V4_CURRENT_FPATH}.\${timestamp}\"\n"
    filecontent+="rules_v6_current_timestamp_fpath=\"\${WLN_IP6TABLES_RULES_V6_CURRENT_FPATH}.\${timestamp}\"\n"
    filecontent+="wlan_yaml_current_timestamp_fpath=\"\${WLN_WLAN_YAML_CURRENT_FPATH}.\${timestamp}\"\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---FUNCTIONS\n"
    filecontent+="CheckIfFilesAreIdentical() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local isfpath1=\${1}\n"
    filecontent+="    local isfpath2=\${2}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local stdoutput=\${WLN_EMPTYSTRING}\n"
    filecontent+="    local ret=false\n"
    filecontent+="\n"
    filecontent+="    #Check if files are identical\n"
    filecontent+="    if cmp --silent -- \"\${isfpath1}\" \"\${isfpath2}\"; then\n"
    filecontent+="        ret=true\n"
    filecontent+="    else\n"
    filecontent+="        ret=false\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Output\n"
    filecontent+="    echo \"\${ret}\"\n"
    filecontent+="\n"
    filecontent+="    return 0;\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="FileExists() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local istargetfpath=\${1}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local stdoutput=\${WLN_EMPTYSTRING}\n"
    filecontent+="    local ret=false\n"
    filecontent+="\n"
    filecontent+="    #Check if file exists\n"
    filecontent+="    if sudo test -f \"\${istargetfpath}\"; then\n"
    filecontent+="        ret=true\n"
    filecontent+="    else\n"
    filecontent+="        ret=false\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Output\n"
    filecontent+="    echo \"\${ret}\"\n"
    filecontent+="\n"
    filecontent+="    return 0;\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="CopyFile() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local issourcefpath=\${1}\n"
    filecontent+="    local istargetfpath=\${2}\n"
    filecontent+="    local isvalidatefpath=\${3}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local cmd=\"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="    local printmsg=\"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="    local exitcode=0\n"
    filecontent+="    local pid=0\n"
    filecontent+="\n"
    filecontent+="    #Check if 'issourcefpath' exists\n"
    filecontent+="    if [[ \$(FileExists \"\${issourcefpath}\") == true ]]; then\n"
    filecontent+="        #Check if 'issourcefpath' is identical to 'isvalidatefpath'\n"
    filecontent+="        #Remark:\n"
    filecontent+="        #   This check has been implemented to make sure that\n"
    filecontent+="        #       'istargetfpath' is not overwritten by 'issourcefpath'\n"
    filecontent+="        #       in case the contents of 'issourcefpath' is the same \n"
    filecontent+="        #       as that of 'isvalidatefpath'.\n"
    filecontent+="        if [[ \$(FileExists \"\${istargetfpath}\") == true ]] && [[ -n \${isvalidatefpath} ]]; then\n"
    filecontent+="            #Check if 'issourcefpath = isvalidatefpath'.\n"
    filecontent+="            #If true, then exit function.\n"
    filecontent+="            if [[ \$(CheckIfFilesAreIdentical \"\${issourcefpath}\" \"\${isvalidatefpath}\") == true ]]; then\n"
    filecontent+="                return 0;\n"
    filecontent+="            fi\n"
    filecontent+="        fi\n"
    filecontent+="        \n"
    filecontent+="        #Write to file\n"
    filecontent+="        cp \"\${issourcefpath}\" \"\${istargetfpath}\" >/dev/null; exitcode=\$?; pid=\$!; wait \${pid}\n"
    filecontent+="\n"
    filecontent+="        #Print\n"
    filecontent+="        if [[ \${exitcode} -eq 0 ]]; then\n"
    filecontent+="            printmsg=\"\${WLN_PRINTMSG_STATUS}: copy from '\${WLN_LIGHTGREY}\${issourcefpath}\${WLN_RESETCOLOR}' \"\n"
    filecontent+="                printmsg+=\"to '\${WLN_LIGHTGREY}\${istargetfpath}\${WLN_RESETCOLOR}': \${WLN_PRINTMSG_DONE}\"\n"
    filecontent+="        else\n"
    filecontent+="            printmsg=\"\${WLN_PRINTMSG_STATUS}: copy from '\${WLN_LIGHTGREY}\${issourcefpath}\${WLN_RESETCOLOR}' \"\n"
    filecontent+="                printmsg+=\"to '\${WLN_LIGHTGREY}\${istargetfpath}\${WLN_RESETCOLOR}': \${WLN_PRINTMSG_FAILED}\"\n"
    filecontent+="        fi\n"
    filecontent+="    else\n"
    filecontent+="        printmsg=\"\${WLN_PRINTMSG_STATUS}: copy from '\${WLN_LIGHTGREY}\${issourcefpath}\${WLN_RESETCOLOR}' \"\n"
    filecontent+="            printmsg+=\"to '\${WLN_LIGHTGREY}\${istargetfpath}\${WLN_RESETCOLOR}': \${WLN_PRINTMSG_NOT} exist\"\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \"\${printmsg}\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="RemoveFile() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local istargetfpath=\${1}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local printmsg=\"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="    #Remove 'wifi-powersave-off.service'\n"
    filecontent+="    if [[ \$(FileExists \"\${istargetfpath}\") == true ]]; then\n"
    filecontent+="        sudo rm \"\${istargetfpath}\" >/dev/null; exitcode=\$?; pid=\$!; wait \${pid}\n"
    filecontent+="\n"
    filecontent+="        if [[ \${exitcode} -eq 0 ]]; then\n"
    filecontent+="            printmsg=\"\${WLN_PRINTMSG_STATUS}: Remove \${WLN_LIGHTGREY}\${istargetfpath}\${WLN_RESETCOLOR}: \${WLN_PRINTMSG_DONE}\"\n"
    filecontent+="        else\n"
    filecontent+="            printmsg=\"\${WLN_PRINTMSG_STATUS}: Remove \${WLN_LIGHTGREY}\${istargetfpath}\${WLN_RESETCOLOR}: \${WLN_PRINTMSG_FAILED}\"\n"
    filecontent+="        fi\n"
    filecontent+="    else\n"
    filecontent+="        printmsg=\"\${WLN_PRINTMSG_STATUS}: file '\${WLN_LIGHTGREY}\${istargetfpath}\${WLN_RESETCOLOR}' \"\n"
    filecontent+="        printmsg+=\"does \${WLN_PRINTMSG_NOT} exist (ignore)\"\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \"\${printmsg}\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="systemctlDisableService() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local srv_name=\${1}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local printmsg=\"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="    local exitcode=0\n"
    filecontent+="    local pid=0\n"
    filecontent+="\n"
    filecontent+="    #Disable service\n"
    filecontent+="    if [[ \$(SystemctlServiceIsEnabled \"\${srv_name}\") == true ]]; then\n"
    filecontent+="        systemctl disable \"\${srv_name}\" >/dev/null; exitcode=\$?; pid=\$!; wait \${pid}\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Choose print-message\n"
    filecontent+="    if [[ \${exitcode} -eq 0 ]]; then\n"
    filecontent+="        printmsg=\"\${WLN_PRINTMSG_STATUS}: Systemctl Disable \${WLN_LIGHTGREY}\${srv_name}\${WLN_RESETCOLOR}: \${WLN_PRINTMSG_DONE}\"\n"
    filecontent+="    else\n"
    filecontent+="        printmsg=\"\${WLN_PRINTMSG_STATUS}: Systemctl Disable \${WLN_LIGHTGREY}\${srv_name}\${WLN_RESETCOLOR}: \${WLN_PRINTMSG_FAILED}\"\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \"\${printmsg}\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="SystemctlEnableService() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local srv_name=\${1}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local printmsg=\"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="    #Enable service\n"
    filecontent+="    if [[ \$(SystemctlServiceIsEnabled \"\${srv_name}\") == false ]]; then\n"
    filecontent+="        systemctl enable \"\${srv_name}\" >/dev/null; exitcode=\$?; pid=\$!; wait \${pid}\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Choose print-message\n"
    filecontent+="    if [[ \${exitcode} -eq 0 ]]; then\n"
    filecontent+="        printmsg=\"\${WLN_PRINTMSG_STATUS}: Systemctl Enable \${WLN_LIGHTGREY}\${srv_name}\${WLN_RESETCOLOR}: \${WLN_PRINTMSG_DONE}\"\n"
    filecontent+="    else\n"
    filecontent+="        printmsg=\"\${WLN_PRINTMSG_STATUS}: Systemctl Enable \${WLN_LIGHTGREY}\${srv_name}\${WLN_RESETCOLOR}: \${WLN_PRINTMSG_FAILED}\"\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \"\${printmsg}\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="SystemctlServiceIsEnabled() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local srv_name=\${1}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local printmsg=\"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="    local srv_state=\"\${WLN_DISABLED}\"\n"
    filecontent+="    local pid=0\n"
    filecontent+="    local ret=false\n"
    filecontent+="\n"
    filecontent+="    #Get service -state (enabled/disabled)\n"
    filecontent+="    srv_state=\$(sudo systemctl is-enabled \"\${srv_name}\" ; pid=\$! ; wait \${pid})\n"
    filecontent+="\n"
    filecontent+="    #Choose print-message\n"
    filecontent+="    if [[ \"\${srv_state}\" == \"\${WLN_ENABLED}\" ]]; then\n"
    filecontent+="        ret=true\n"
    filecontent+="    else\n"
    filecontent+="        ret=false\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Output\n"
    filecontent+="    echo \"\${ret}\"\n"
    filecontent+="\n"
    filecontent+="    return 0;\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---MAIN SUBROUTINE\n"
    filecontent+="append_timestamp_tofile_handler() {\n"
    filecontent+="    if [[ \$(FileExists \"\${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_LOG_FPATH}\") == true ]]; then\n"
    filecontent+="        timestamp=\$(cat \"\${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_LOG_FPATH}\")\n"
    filecontent+="\n"
    filecontent+="        dnsmasq_current_timestamp_fpath=\"\${WLN_DNSMASQ_CONF_CURRENT_FPATH}.\${timestamp}\"\n"
    filecontent+="        hostapd_conf_current_timestamp_fpath=\"\${WLN_HOSTAPD_CONF_CURRENT_FPATH}.\${timestamp}\"\n"
    filecontent+="        hostapdng_service_current_timestamp_fpath=\"\${WLN_HOSTAPD_NG_SERVICE_CURRENT_FPATH}.\${timestamp}\"\n"
    filecontent+="        rules_v4_current_timestamp_fpath=\"\${WLN_IPTABLES_RULES_V4_CURRENT_FPATH}.\${timestamp}\"\n"
    filecontent+="        rules_v6_current_timestamp_fpath=\"\${WLN_IP6TABLES_RULES_V6_CURRENT_FPATH}.\${timestamp}\"\n"
    filecontent+="        wlan_yaml_current_timestamp_fpath=\"\${WLN_WLAN_YAML_CURRENT_FPATH}.\${timestamp}\"\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="enable_handler() {\n"
    filecontent+="    append_timestamp_tofile_handler\n"
    filecontent+="\n"
    filecontent+="    phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_DISABLE}\"\n"
    filecontent+="\n"
    filecontent+="    while true\n"
    filecontent+="    do\n"
    filecontent+="        case \"\${phase}\" in\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_DISABLE}\")\n"
    filecontent+="                systemctlDisableService \"\${WLN_WPA_SUPPLICANT_DAEMON_SRV}\"\n"
    filecontent+="                systemctlDisableService \"\${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}\"\n"
    filecontent+="                systemctlDisableService \"\${WLN_DNSMASQ_SRV}\"\n"
    filecontent+="                systemctlDisableService \"\${WLN_IPTABLES_SRV}\"\n"
    filecontent+="                systemctlDisableService \"\${WLN_IP6TABLES_SRV}\"\n"
    filecontent+="                systemctlDisableService \"\${WLN_HOSTAPD_NG_SRV}\"\n"
    filecontent+="                systemctlDisableService \"\${WLN_WIFI_POWERSAVE_OFF_SRV}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_HANDLER}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_HANDLER}\")\n"
    filecontent+="                RemoveFile \"\${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_DST_FPATH}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_NETPLAN_HANDLER}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_NETPLAN_HANDLER}\")\n"
    filecontent+="                CopyFile \"\${WLN_WLAN_YAML_FPATH}\" \\\ \n"
    filecontent+="                        \"\${wlan_yaml_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_WLAN_YAML_AUTORECONNECTONBOOT_FPATH}\"\n"
    filecontent+="\n"
    filecontent+="                CopyFile \"\${WLN_WLAN_YAML_AUTORECONNECTONBOOT_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_WLAN_YAML_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}\")\n"
    filecontent+="                CopyFile \"\${WLN_DNSMASQ_CONF_FPATH}\" \\\ \n"
    filecontent+="                        \"\${dnsmasq_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_DNSMASQ_CONF_AUTORECONNECTONBOOT_FPATH}\"\n"
    filecontent+="\n"
    filecontent+="                CopyFile \"\${WLN_DNSMASQ_CONF_AUTORECONNECTONBOOT_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_DNSMASQ_CONF_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_IPTABLES_HANDLER}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_IPTABLES_HANDLER}\")\n"
    filecontent+="                CopyFile \"\${WLN_IPTABLES_RULES_V4_FPATH}\" \\\ \n"
    filecontent+="                        \"\${rules_v4_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_IPTABLES_RULES_V4_AUTORECONNECTONBOOT_FPATH}\"\n"
    filecontent+="\n"
    filecontent+="                CopyFile \"\${WLN_IPTABLES_RULES_V4_AUTORECONNECTONBOOT_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_IPTABLES_RULES_V4_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}\")\n"
    filecontent+="                CopyFile \"\${WLN_IP6TABLES_RULES_V6_FPATH}\" \\\ \n"
    filecontent+="                        \"\${rules_v6_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_IP6TABLES_RULES_V6_AUTORECONNECTONBOOT_FPATH}\"\n"
    filecontent+="\n"
    filecontent+="                CopyFile \"\${WLN_IP6TABLES_RULES_V6_AUTORECONNECTONBOOT_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_IP6TABLES_RULES_V6_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}\")\n"
    filecontent+="                CopyFile \"\${WLN_HOSTAPD_CONF_FPATH}\" \\\ \n"
    filecontent+="                        \"\${hostapd_conf_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_HOSTAPD_CONF_AUTORECONNECTONBOOT_FPATH}\"\n"
    filecontent+="\n"
    filecontent+="                CopyFile \"\${WLN_HOSTAPD_CONF_AUTORECONNECTONBOOT_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_HOSTAPD_CONF_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                #Persistent Overwrite\n"
    filecontent+="                CopyFile \"\${WLN_HOSTAPD_NG_SERVICE_FPATH}\" \\\ \n"
    filecontent+="                        \"\${hostapdng_service_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                CopyFile \"\${WLN_HOSTAPD_NG_SERVICE_AUTORECONNECTONBOOT_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_HOSTAPD_NG_SERVICE_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE}\")\n"
    filecontent+="                SystemctlEnableService \"\${WLN_DNSMASQ_SRV}\"\n"
    filecontent+="                SystemctlEnableService \"\${WLN_IPTABLES_SRV}\"\n"
    filecontent+="                SystemctlEnableService \"\${WLN_IP6TABLES_SRV}\"\n"
    filecontent+="                SystemctlEnableService \"\${WLN_HOSTAPD_NG_SRV}\"\n"
    filecontent+="\n"
    filecontent+="                SystemctlEnableService \"\${WLN_WIFI_POWERSAVE_OFF_SRV}\"\n"
    filecontent+="                SystemctlEnableService \"\${WLN_WIFI_POWERSAVE_OFF_TIMER}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_EXIT}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_EXIT}\")\n"
    filecontent+="                break\n"
    filecontent+="                ;;\n"
    filecontent+="        esac\n"
    filecontent+="    done\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="timestamp_validate() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local istimestamp=\${1}\n"
    filecontent+="\n"
    filecontent+="    #Check \n"
    filecontent+="}\n"
    filecontent+="disable_handler() {\n"
    filecontent+="    append_timestamp_tofile_handler\n"
    filecontent+="\n"
    filecontent+="    phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_DISABLE}\"\n"
    filecontent+="\n"
    filecontent+="    while true\n"
    filecontent+="    do\n"
    filecontent+="        case \"\${phase}\" in\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_DISABLE}\")\n"
    filecontent+="                systemctlDisableService \"\${WLN_WPA_SUPPLICANT_DAEMON_SRV}\"\n"
    filecontent+="                systemctlDisableService \"\${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}\"\n"
    filecontent+="                systemctlDisableService \"\${WLN_DNSMASQ_SRV}\"\n"
    filecontent+="                systemctlDisableService \"\${WLN_IPTABLES_SRV}\"\n"
    filecontent+="                systemctlDisableService \"\${WLN_IP6TABLES_SRV}\"\n"
    filecontent+="                systemctlDisableService \"\${WLN_HOSTAPD_NG_SRV}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_HANDLER}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_HANDLER}\")\n"
    filecontent+="                CopyFile \"\${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_SRC_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_NTIOS_WLN_AUTORECONNECTONBOOT_RUNATLOGIN_SH_DST_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="                \n"
    filecontent+="                if [[ \${timestamp} -eq 0 ]]; then\n"
    filecontent+="                    phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE}\"\n"
    filecontent+="                else\n"
    filecontent+="                    phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_NETPLAN_HANDLER}\"\n"
    filecontent+="                fi\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_NETPLAN_HANDLER}\")\n"
    filecontent+="                CopyFile \"\${wlan_yaml_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_WLAN_YAML_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_DNSMASQ_HANDLER}\")\n"
    filecontent+="                CopyFile \"\${dnsmasq_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_DNSMASQ_CONF_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_IPTABLES_HANDLER}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_IPTABLES_HANDLER}\")\n"
    filecontent+="                CopyFile \"\${rules_v4_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_IPTABLES_RULES_V4_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_IP6TABLES_HANDLER}\")\n"
    filecontent+="                CopyFile \"\${rules_v6_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_IP6TABLES_RULES_V6_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_HOSTAPD_HANDLER}\")\n"
    filecontent+="                CopyFile \"\${hostapd_conf_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_HOSTAPD_CONF_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                CopyFile \"\${hostapdng_service_current_timestamp_fpath}\" \\\ \n"
    filecontent+="                        \"\${WLN_HOSTAPD_NG_SERVICE_FPATH}\" \\\ \n"
    filecontent+="                        \"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_SERVICES_ENABLE}\")\n"
    filecontent+="                case \"\${bssmode}\" in\n"
    filecontent+="                    \"\${WLN_SERVICE_INPUTARG_INFRASTRUCTURE}\")\n"
    filecontent+="                        SystemctlEnableService \"\${WLN_WPA_SUPPLICANT_DAEMON_SRV}\"\n"
    filecontent+="                        ;;\n"
    filecontent+="                    \"\${WLN_SERVICE_INPUTARG_ACCESSPOINT}\")\n"
    filecontent+="                        SystemctlEnableService \"\${WLN_HOSTAPD_NG_SRV}\"\n"
    filecontent+="                        ;;\n"
    filecontent+="                    \"\${WLN_SERVICE_INPUTARG_ROUTER}\")\n"
    filecontent+="                        SystemctlEnableService \"\${WLN_DNSMASQ_SRV}\"\n"
    filecontent+="                        SystemctlEnableService \"\${WLN_IPTABLES_SRV}\"\n"
    filecontent+="                        SystemctlEnableService \"\${WLN_IP6TABLES_SRV}\"\n"
    filecontent+="                        SystemctlEnableService \"\${WLN_HOSTAPD_NG_SRV}\"\n"
    filecontent+="                        ;;\n"
    filecontent+="                esac\n"
    filecontent+="\n"
    filecontent+="                SystemctlEnableService \"\${WLN_WIFI_POWERSAVE_OFF_SRV}\"\n"
    filecontent+="                SystemctlEnableService \"\${WLN_WIFI_POWERSAVE_OFF_TIMER}\"\n"
    filecontent+="\n"
    filecontent+="                phase=\"\${PHASE_WLN_AUTORECONNECTONBOOT_EXIT}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WLN_AUTORECONNECTONBOOT_EXIT}\")\n"
    filecontent+="                break\n"
    filecontent+="                ;;\n"
    filecontent+="        esac\n"
    filecontent+="    done\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---SELECT CASE\n"
    filecontent+="case \"\${action}\" in\n"
    filecontent+="    \"\${WLN_ENABLE}\")\n"
    filecontent+="        enable_handler\n"
    filecontent+="        ;;\n"
    filecontent+="    \"\${WLN_DISABLE}\")\n"
    filecontent+="        disable_handler\n"
    filecontent+="        ;;\n"
    filecontent+="esac"

    #Check if file exist
    RemoveFile "${istargetfpath}"

    #Write to file
    if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == true ]]; then
        #Change permisions
        if [[ $( Chmod "${istargetfpath}" "${WLN_MOD_755}") == true ]]; then
            ret="${ACCEPTED}"
        else
            ret="${REJECTED}"
        fi
    else
        ret="${REJECTED}"
    fi

    #Replace any lines which end with '<space>\<space>' with '<space>\'
    #Note: <space> represents a SPACE ( )
    sudo sed -i 's/\ \\ $/\ \\/g' "${istargetfpath}"

    #Output
    echo "${ret}"

    return 0;
}
AutoReconnectOnBoot_Service_Create() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local ret="${REJECTED}"



    #Generate service
    filecontent="[Unit]\n"
    filecontent+="Description=resets/restores the etherwln interfaces' ip-address before shutdown\n"
    filecontent+="DefaultDependencies=no\n"
    filecontent+="\n"
    filecontent+="[Service]\n"
    filecontent+="Type=oneshot\n"
    filecontent+="#User MUST BE SET TO 'root'\n"
    filecontent+="User=root\n"
    filecontent+="RemainAfterExit=true\n"
    filecontent+="\n"
    filecontent+="ExecStart=/usr/bin/systemctl enable ntios-wln-reloadconnect.service\n"
    filecontent+="ExecStartPost=/usr/bin/systemctl disable ntios-wln-resetconnect.service\n"
    filecontent+="ExecStartPost=/usr/bin/systemctl disable ntios-wln-autoreconnectonboot.service\n"
    filecontent+="\n"
    filecontent+="ExecStop=/usr/bin/systemctl enable ntios-wln-resetconnect.service\n"
    filecontent+="ExecStopPost=/usr/bin/systemctl disable ntios-wln-reloadconnect.service\n"
    filecontent+="ExecStopPost=/usr/bin/systemctl disable ntios-wln-autoreconnectonboot.service\n"
    filecontent+="\n"
    filecontent+="[Install]\n"
    filecontent+="WantedBy=multi-user.target"



    #Check if file exist
    RemoveFile "${istargetfpath}"
    
    #Write to file
    if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}
ReloadConnect_Service_Create() {
    #Input args
    local istargetfpath=${1}
    local isbssmode=${2}

    #Define variables
    local ret="${REJECTED}"



    filecontent="#--------------------------------------------------------------------\n"
    filecontent+="# Remark:\n"
    filecontent+="#   Please do not enable/disable/stop/start this service.\n"
    filecontent+="#   Use 'ntios-wln-autoreconnectonboot.service' instead.\n"
    filecontent+="#--------------------------------------------------------------------\n"
    filecontent+="[Unit]\n"
    filecontent+="Description=restores the ethernet interfaces' ip-address to user-defined settings before shutdown\n"
    filecontent+="DefaultDependencies=no\n"
    filecontent+="Before=shutdown.target\n"
    filecontent+="\n"
    filecontent+="[Service]\n"
    filecontent+="Type=oneshot\n"
    filecontent+="#User MUST BE SET TO 'root'\n"
    filecontent+="User=root\n"
    filecontent+="\n"
    filecontent+="ExecStart=/usr/local/bin/ntios-wln-autoresetconnect.sh disable ${isbssmode}\n"
    filecontent+="TimeoutStartSec=0\n"
    filecontent+="\n"
    filecontent+="[Install]\n"
    filecontent+="WantedBy=shutdown.target\n"



    #Check if file exist
    RemoveFile "${istargetfpath}"
    
    #Write to file
    if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}
ResetConnect_Service_Create() {
    #Input args
    local istargetfpath=${1}
    local isbssmode=${2}

    #Define variables
    local ret="${REJECTED}"



    #Generate service
    filecontent="#--------------------------------------------------------------------\n"
    filecontent+="# Remark:\n"
    filecontent+="#   Please do not enable/disable/stop/start this service.\n"
    filecontent+="#   Use 'ntios-wln-autoreconnectonboot.service' instead.\n"
    filecontent+="#--------------------------------------------------------------------\n"
    filecontent+="[Unit]\n"
    filecontent+="Description=resets the ethernet interfaces' ip-address to default settings before shutdown\n"
    filecontent+="DefaultDependencies=no\n"
    filecontent+="Before=shutdown.target\n"
    filecontent+="\n"
    filecontent+="[Service]\n"
    filecontent+="Type=oneshot\n"
    filecontent+="#User MUST BE SET TO 'root'\n"
    filecontent+="User=root\n"
    filecontent+="\n"
    filecontent+="ExecStart=/usr/local/bin/ntios-wln-autoresetconnect.sh enable ${isbssmode}\n"
    filecontent+="TimeoutStartSec=0\n"
    filecontent+="\n"
    filecontent+="[Install]\n"
    filecontent+="WantedBy=shutdown.target"



    #Check if file exist
    RemoveFile "${istargetfpath}"
    
    #Write to file
    if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}

