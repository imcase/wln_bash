#!/bin/bash
#---MAIN FUNCTIONS
WLN_Hostapd_Handler() {
    #----------------------------------------------------------------
    # The following input args have been introduced for:
    #   ntios-wln-autoresetconnect.service / ntios-wln-autoresetconnect.sh
    # In order to use for 'ntios-wln-autoresetconnect', please make sure
    #   to pass the following values:
    #   (1) intfstates_ctx_fpath = WLN_INTFSTATES_CTX_INIT_DAT_FPATH
    #   (2) isautoreconnectonboot_istriggered = false
    #----------------------------------------------------------------
    #Input args
    local isautoreconnectonboot_istriggered=${1}   # {YES | NO}

    #Define constants
    local PHASE_HOSTAPDFUNC_HOSTAPD_SERVICE_DISABLESTOP=1
    local PHASE_HOSTAPDFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP=10
    local PHASE_HOSTAPDFUNC_DIR_CREATE=20
    local PHASE_HOSTAPDFUNC_FIRMWARE_CONFIG_TXT_REVISE=30
    local PHASE_HOSTAPDFUNC_DEFAULT_HOSTAPD_GENERATOR=40
    local PHASE_HOSTAPDFUNC_HOSTAPD_CONF_GENERATOR=50
    local PHASE_HOSTAPDFUNC_HOSTAPD_NG_SERVICE_GENERATOR=60
    local PHASE_HOSTAPDFUNC_HOSTAPD_NG_SCRIPT_GENERATOR=61
    local PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_SERVICE_GENERATOR=70
    local PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_TIMER_GENERATOR=71
    local PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_SCRIPT_GENERATOR=72
    local PHASE_HOSTAPDFUNC_HOSTAPD_NG_SERVICE_ENABLESTART=80
    local PHASE_HOSTAPDFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_HOSTAPDFUNC_HOSTAPD_SERVICE_DISABLESTOP}"
    local bssmode_string="${WLN_EMPTYSTRING}"
    local hostapdconf_fpath="${WLN_EMPTYSTRING}"
    local hostapdngsrv_fpath="${WLN_EMPTYSTRING}"
    local intfstates_ctx_fpath="${WLN_EMPTYSTRING}"
    local ret="${ACCEPTED}"

    #Set variable(s) based on 'isautoreconnectonboot_istriggered' input value
    if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
        # firmware_conftxt_fpath="${WLN_FIRMWARE_CONFIG_TXT_FPATH}"
        hostapdconf_fpath="${WLN_HOSTAPD_CONF_FPATH}"
        hostapdngsrv_fpath="${WLN_HOSTAPD_NG_SERVICE_FPATH}"
        intfstates_ctx_fpath="${WLN_INTFSTATES_CTX_DAT_FPATH}"
    else
        # firmware_conftxt_fpath="${WLN_FIRMWARE_CONFIG_TXT_AUTORECONNECTONBOOT_FPATH}"
        hostapdconf_fpath="${WLN_HOSTAPD_CONF_AUTORECONNECTONBOOT_FPATH}"
        hostapdngsrv_fpath="${WLN_HOSTAPD_NG_SERVICE_AUTORECONNECTONBOOT_FPATH}"
        intfstates_ctx_fpath="${WLN_INTFSTATES_CTX_INIT_DAT_FPATH}"
    fi

    # #Retrieve data from database
    interface_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__intf")
    bridge_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__bridge")
    bssmode=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__bssmode")
    driver_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__driver")
    country_code_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__domaincode")
    ssid_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__ssid")
    hw_mode_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__hwmode")
    ieee80211ac_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__ieee80211ac")
    ieee80211n_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__ieee80211n")
    ieee80211d_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__ieee80211d")
    ieee80211h_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__ieee80211h")
    channel_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__channel")
    wepkey_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__wepkey")
    wepmode_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__wepmode")
    # setwep_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__setwep")
    wpakey_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__wpakey")
    wpamode_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__wpamode")
    # setwpa_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__setwpa")
    wpaalgorithm_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__wpaalgorithm")
    ssidisvisible_retrieved=$(WLN_intfstates_ctx_retrievedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__ssidisvisible")

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_HOSTAPDFUNC_HOSTAPD_SERVICE_DISABLESTOP}")
                if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
                    if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_HOSTAPD_SRV}" \
                            "${WLN_HOSTAPD}" \
                            "${WLN_HOSTAPD_SERVICE_FPATH}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_HOSTAPDFUNC_EXIT}"
                    else
                        phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP}"
                    fi
                else
                     phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_HOSTAPDFUNC_HOSTAPD_NG_SERVICE_DISABLESTOP}")
                if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
                    if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_HOSTAPD_NG_SRV}" \
                            "${WLN_HOSTAPD}" \
                            "${hostapdngsrv_fpath}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_HOSTAPDFUNC_EXIT}"
                    else
                        phase="${PHASE_HOSTAPDFUNC_DIR_CREATE}"
                    fi
                else
                     phase="${PHASE_HOSTAPDFUNC_DIR_CREATE}"
                fi
                ;;
            "${PHASE_HOSTAPDFUNC_DIR_CREATE}")
                if [[ ${isautoreconnectonboot_istriggered} == ${YES} ]]; then
                    if [[ $(Mkdir "${WLN_ETC_TIBBO_HOSTAPD_WLN_DIR}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_HOSTAPDFUNC_EXIT}"
                    else
                        phase="${PHASE_HOSTAPDFUNC_FIRMWARE_CONFIG_TXT_REVISE}"
                    fi
                else
                     phase="${PHASE_HOSTAPDFUNC_FIRMWARE_CONFIG_TXT_REVISE}"
                fi
                ;;
            "${PHASE_HOSTAPDFUNC_FIRMWARE_CONFIG_TXT_REVISE}")
                #/etc/firmware/config.txt: set 'ccode'
                if [[ $(WLN_Firmware_Config_Txt_Revise "${country_code_retrieved}" \
                        "${isautoreconnectonboot_istriggered}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_HOSTAPDFUNC_EXIT}"
                else
                    phase="${PHASE_HOSTAPDFUNC_DEFAULT_HOSTAPD_GENERATOR}"
                fi
                ;;
            "${PHASE_HOSTAPDFUNC_DEFAULT_HOSTAPD_GENERATOR}") 
                #Check if value of 'WLN_SED_PATTERN_DAEMON_CONF_NEW' is already added to '/etc/default/hostapd'
                if [[ $(PatternIsFound "${WLN_SED_PATTERN_DAEMON_CONF_NEW}" \
                        "${WLN_DEFAULT_HOSTAPD_FPATH}") == false ]]; then   #not found
                    if [[ $(WLN_Default_Hostapd_Generator \
                            "${WLN_DEFAULT_HOSTAPD_FPATH}" \
                            "${WLN_HOSTAPD_CONF_FPATH}") == "${REJECTED}" ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_HOSTAPDFUNC_EXIT}"
                    else
                        phase="${PHASE_HOSTAPDFUNC_HOSTAPD_CONF_GENERATOR}"
                    fi
                else    #found
                    phase="${PHASE_HOSTAPDFUNC_HOSTAPD_CONF_GENERATOR}"
                fi
                ;;
            "${PHASE_HOSTAPDFUNC_HOSTAPD_CONF_GENERATOR}") 
                #hostapdconf_fpath: generate content and write to this file
                #   Variable could be:
                #   1. /etc/hostapd/hostapd.conf
                #   2. /etc/tibbo/hostapd/hostapd.conf.current
                if [[ $(WLN_Hostapd_Conf_Generator \
                        "${hostapdconf_fpath}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_HOSTAPDFUNC_EXIT}"
                else
                    phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_SERVICE_GENERATOR}"
                fi
                ;;
            "${PHASE_HOSTAPDFUNC_HOSTAPD_NG_SERVICE_GENERATOR}")
                #Translate enum to string
                if [[ "${bssmode}" == "${PL_WLN_BSS_MODE_ROUTER}" ]]; then
                    bssmode_string="${WLN_SERVICE_INPUTARG_ROUTER}"
                else
                    bssmode_string="${WLN_SERVICE_INPUTARG_ACCESSPOINT}"
                fi

                if [[ $(WLN_Hostapd_Ng_Service_Generator \
                        "${hostapdngsrv_fpath}" \
                        "${bssmode_string}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_HOSTAPDFUNC_EXIT}"
                else
                    phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_SCRIPT_GENERATOR}"
                fi
                ;;
            "${PHASE_HOSTAPDFUNC_HOSTAPD_NG_SCRIPT_GENERATOR}")
                if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
                    if [[ $(WLN_Hostapd_Ng_Script_Generator \
                            "${WLN_HOSTAPD_NG_SH_FPATH}") == "${REJECTED}" ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_HOSTAPDFUNC_EXIT}"
                    else
                        phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_SERVICE_GENERATOR}"
                    fi
                else
                    phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_SERVICE_GENERATOR}"
                fi
                ;;
            "${PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_SERVICE_GENERATOR}")
                if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
                    if [[ $(WLN_Hostapd_Ng_Autorecover_Service_Generator \
                            "${WLN_HOSTAPD_NG_AUTORECOVER_SERVICE_FPATH}") == "${REJECTED}" ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_HOSTAPDFUNC_EXIT}"
                    else
                        phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_SCRIPT_GENERATOR}"
                    fi
                else
                    phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_SCRIPT_GENERATOR}"
                fi
                ;;
            "${PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_SCRIPT_GENERATOR}")
                if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
                    if [[ $(WLN_Hostapd_Ng_Autorecover_Script_Generator \
                            "${WLN_HOSTAPD_NG_AUTORECOVER_SH_FPATH}") == "${REJECTED}" ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_HOSTAPDFUNC_EXIT}"
                    else
                        phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_TIMER_GENERATOR}"
                    fi
                else
                    phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_TIMER_GENERATOR}"
                fi
                ;;
            "${PHASE_HOSTAPDFUNC_HOSTAPD_NG_AUTORECOVER_TIMER_GENERATOR}")
                if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
                    if [[ $(WLN_Hostapd_Ng_Autorecover_Timer_Generator \
                            "${WLN_HOSTAPD_NG_AUTORECOVER_TIMER_FPATH}") == "${REJECTED}" ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_HOSTAPDFUNC_EXIT}"
                    else
                        phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_SERVICE_ENABLESTART}"
                    fi
                else
                    phase="${PHASE_HOSTAPDFUNC_HOSTAPD_NG_SERVICE_ENABLESTART}"
                fi
                ;;
            "${PHASE_HOSTAPDFUNC_HOSTAPD_NG_SERVICE_ENABLESTART}")
                if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
                    if [[ $(Service_Enable_And_Start "${WLN_HOSTAPD_NG_SRV}" \
                            "${WLN_SYSTEMCTL_START_SERVICE_RETRY_MAX}") == false ]]; then
                        ret="${REJECTED}"
                    else
                        ret="${ACCEPTED}"
                    fi
                else
                     ret="${ACCEPTED}"
                fi

                phase="${PHASE_HOSTAPDFUNC_EXIT}"
                ;;
            "${PHASE_HOSTAPDFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

#---SUPPORT FUNCTIONS
WLN_Default_Hostapd_Generator() {
    #Input args
    local istargetfpath=${1}
    local daemon_conf_fpath=${2}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local stdoutput="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Generate 'hostapd'
    filecontent="#---Set DAEMON_CONF to the absolute path of a hostapd configuration\n"
    filecontent+="DAEMON_CONF=${daemon_conf_fpath}\n"
    filecontent+="\n"
    filecontent+="#---Additional daemon options to be appended to hostapd command\n"
    filecontent+="#DAEMON_OPTS=\"\""

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
WLN_Hostapd_Conf_Generator() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local auth_algs_retrieved="${WLN_HOSTAPD_WPA_AUTH_ALGS_WPA}"
    local filecontent="${WLN_EMPTYSTRING}"
    local macaddr_acl_retrieved="${WLN_HOSTAPD_WPA_MACADDR_ACL_ACCEPT}"
    local rsnpairwise_retrieved="${WLN_HOSTAPD_WPA_CYPHER_CCMP}"
    local wpa_retrieved="${WLN_HOSTAPD_WPAMODE_WPA}"
    local wpamgmtalg_retrieved="${WLN_HOSTAPD_WPA_MGMTALG_WPA_PSK}"
    local wpapairwise_retrieved="${WLN_HOSTAPD_WPA_CYPHER_TKIP}"
    local ret="${REJECTED}"

    #Generate 'hostapd.conf'
    filecontent="#---WIRELESS INTERFACE\n"
    filecontent+="interface=${interface_retrieved}\n"
    filecontent+="\n"
    filecontent+="#---BRIDGE INTERFACE\n"
    filecontent+="bridge=${bridge_retrieved}\n"
    filecontent+="\n"
    filecontent+="#---DRIVER\n"
    filecontent+="driver=${driver_retrieved}\n"
    filecontent+="\n"
    filecontent+="#---COUNTRY-CODE (AKA DOMAIN-CODE)\n"
    filecontent+="country_code=${country_code_retrieved}\n"
    filecontent+="\n"
    filecontent+="#---SSID\n"
    filecontent+="ssid=${ssid_retrieved}\n"
    filecontent+="\n"
    filecontent+="#---WIRELESS OPERATION-MODE\n"
    filecontent+="hw_mode=${hw_mode_retrieved}\n"
    filecontent+="ieee80211ac=${ieee80211ac_retrieved}\n"
    filecontent+="ieee80211n=${ieee80211n_retrieved}\n"
    filecontent+="ieee80211d=${ieee80211d_retrieved}\n"
    filecontent+="ieee80211h=${ieee80211h_retrieved}\n"
    filecontent+="\n"
    filecontent+="#---CHANNEL\n"
    filecontent+="channel=${channel_retrieved}\n"
    filecontent+="\n"
    if [[ "${wepmode_retrieved}" != "${PL_WLN_WEP_MODE_DISABLED}" ]]; then
        filecontent+="#---WEP\n"
        filecontent+="wep_default_key=${WLN_HOSTAPD_WEPDEFAULTKEY_0}\n"
        filecontent+="wep_key0=${wepkey_retrieved}\n"
        filecontent+="\n"
    fi
    if [[ "${wpamode_retrieved}" != "${PL_WLN_WPA_DISABLED}" ]]; then
        filecontent+="#---WPA\n"
        case "${wpamode_retrieved}" in
            "${PL_WLN_WPA_WPA1_PSK}")
                wpa_retrieved="${WLN_HOSTAPD_WPAMODE_WPA}"
                wpamgmtalg_retrieved="${WLN_HOSTAPD_WPA_MGMTALG_WPA_PSK}"
                ;;
            "${PL_WLN_WPA_WPA2_PSK}")
                wpa_retrieved="${WLN_HOSTAPD_WPAMODE_WPA2}"
                wpamgmtalg_retrieved="${WLN_HOSTAPD_WPA_MGMTALG_WPA_PSK}"
                ;;
        esac
        filecontent+="wpa=${wpa_retrieved}\n"
        filecontent+="wpa_passphrase=${wpakey_retrieved}\n"
        filecontent+="wpa_key_mgmt=${wpamgmtalg_retrieved}\n"
        case "${wpaalgorithm_retrieved}" in
            "${PL_WLN_WPA_ALGORITHM_TKIP}")
                wpapairwise_retrieved="${WLN_HOSTAPD_WPA_CYPHER_TKIP}"
                ;;
            "${PL_WLN_WPA_ALGORITHM_AES}")
                wpapairwise_retrieved="${WLN_HOSTAPD_WPA_CYPHER_CCMP}"
                ;;
            "${PL_WLN_WPA_ALGORITHM_TKIP_AES}")
                wpapairwise_retrieved="${WLN_HOSTAPD_WPA_CYPHER_TKIP_CCMP}"
                ;;
        esac        
        filecontent+="wpa_pairwise=${wpapairwise_retrieved}\n"
        filecontent+="rsn_pairwise=${rsnpairwise_retrieved}\n"
        filecontent+="\n"
    fi
    filecontent+="#---AUTHENTICATION ALGORITHMS\n"
    if [[ "${wepmode_retrieved}" != "${PL_WLN_WEP_MODE_DISABLED}" ]] && \
            [[ "${wpamode_retrieved}" == "${PL_WLN_WPA_DISABLED}" ]]; then
        auth_algs_retrieved="${WLN_HOSTAPD_WPA_AUTH_ALGS_WEP}"
    elif [[ "${wpamode_retrieved}" != "${PL_WLN_WPA_DISABLED}" ]] && \
            [[ "${wepmode_retrieved}" == "${PL_WLN_WEP_MODE_DISABLED}" ]]; then
        auth_algs_retrieved="${WLN_HOSTAPD_WPA_AUTH_ALGS_WPA}"
    else    #this means an OPEN router/access-point (w/o authentication)
        auth_algs_retrieved="${WLN_HOSTAPD_WPA_AUTH_ALGS_WEP_WPA}"
    fi
    filecontent+="auth_algs=${auth_algs_retrieved}\n"
    filecontent+="\n"    
    filecontent+="#---MAC-ADDRESS BASED AUTHENTICATION\n"
    filecontent+="macaddr_acl=${macaddr_acl_retrieved}\n"
    filecontent+="\n"
    filecontent+="#---BROADCAST SSID\n"
    if [[ "${ssidisvisible_retrieved}" == "${YES}" ]]; then
        ignore_broadcast_ssid="${WLN_HOSTAPD_IGNORE_BROADCAST_SSID_VISIBLE}"
    else
        ignore_broadcast_ssid="${WLN_HOSTAPD_IGNORE_BROADCAST_SSID_HIDDEN}"
    fi
    filecontent+="ignore_broadcast_ssid=${ignore_broadcast_ssid}"

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

WLN_Hostapd_Ng_Service_Generator() {
    #Input args
    local istargetfpath=${1}
    local bssmode_string=${2}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Generate 'hostapd-ng.service'
    filecontent="[Unit]\n"
    filecontent+="Description=enables/disables hostapd-ng daemon\n"
    filecontent+="Wants=network.target\n"
    filecontent+="After=ip6tables.service\n"
    filecontent+="\n"
    filecontent+="[Service]\n"
    filecontent+="Type=oneshot\n"
    filecontent+="#User MUST BE SET TO 'root'\n"
    filecontent+="User=root\n"
    filecontent+="RemainAfterExit=true\n"
    filecontent+="\n"
    filecontent+="ExecStart=/usr/local/bin/hostapd-ng.sh enable ${bssmode_string}\n"
    filecontent+="ExecStart=systemctl start hostapd-ng-autorecover.timer\n"
    filecontent+="\n"
    filecontent+="ExecStop=systemctl stop hostapd-ng-autorecover.timer\n"
    filecontent+="ExecStop=systemctl stop hostapd-ng-autorecover.service\n"
    filecontent+="ExecStop=/usr/local/bin/hostapd-ng.sh disable ${bssmode_string}\n"
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
WLN_Hostapd_Ng_Script_Generator() {
    #Input args
    local istargetfpath=${1}
    # local isbssmode=${2}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Generate 'hostapd-ng.service'
    filecontent="#!/bin/bash\n"
    filecontent+="#---Input args\n"
    filecontent+="action=\${1}\n"
    filecontent+="isbssmode=\${2}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---COLORS CONSTANTS\n"
    filecontent+="NOCOLOR=\$'\\\e[0m'\n"
    filecontent+="FG_LIGHTRED=\$'\\\e[1;31m'\n"
    filecontent+="FG_ORANGE=\$'\\\e[30;38;5;209m'\n"
    filecontent+="FG_LIGHTBLUE=\$'\\\e[30;38;5;45m'\n"
    filecontent+="FG_LIGHTGREY=\$'\\\e[30;38;5;246m'\n"
    filecontent+="FG_LIGHTGREEN=\$'\\\e[30;38;5;71m'\n"
    filecontent+="FG_SOFLIGHTRED=\$'\\\e[30;38;5;131m'\n"
    filecontent+="FG_YELLOW=\$'\\\e[1;33m'\n"
    filecontent+="\n"
    filecontent+="#---BOOLEAN CONSTANTS\n"
    filecontent+="ENABLE=\"${WLN_ENABLE}\"\n"
    filecontent+="DISABLE=\"${WLN_DISABLE}\"\n"
    filecontent+="ENABLED=\"${WLN_ENABLED}\"\n"
    filecontent+="\n"
    filecontent+="#---BSSMODE\n"
    filecontent+="SERVICE_INPUTARG_INFRASTRUCTURE=\"${WLN_SERVICE_INPUTARG_INFRASTRUCTURE}\"\n"
    filecontent+="SERVICE_INPUTARG_ACCESSPOINT=\"${WLN_SERVICE_INPUTARG_ACCESSPOINT}\"\n"
    filecontent+="SERVICE_INPUTARG_ROUTER=\"${WLN_SERVICE_INPUTARG_ROUTER}\"\n"
    filecontent+="\n"
    filecontent+="#---COUNTER CONSTANTS\n"
    filecontent+="HOSTAPD_NG_DAEMON_RUN_RETRY_MAX=${WLN_HOSTAPD_NG_DAEMON_RUN_RETRY_MAX}\n"
    filecontent+="\n"
    filecontent+="#---ENVIRONMENT CONSTANTS\n"
    filecontent+="ETC_TIBBO_LOG_WLN_DIR=\"${WLN_ETC_TIBBO_LOG_WLN_DIR}\"\n"
    filecontent+="if [[ ! -d \"\${ETC_TIBBO_LOG_WLN_DIR}\" ]]; then\n"
    filecontent+="    mkdir -p \"\${ETC_TIBBO_LOG_WLN_DIR}\"\n"
    filecontent+="fi\n"
    filecontent+="\n"
    filecontent+="DNSMASQ_SERVICE=\"${WLN_DNSMASQ_SRV}\"\n"
    filecontent+="HOSTAPD=\"${WLN_HOSTAPD}\"\n"
    filecontent+="HOSTAPD_NG=\"${WLN_HOSTAPD_NG}\"\n"
    filecontent+="HOSTAPD_NG_SERVICE=\"${WLN_HOSTAPD_NG_SRV}\"\n"
    filecontent+="WLAN_YAML=\"${WLN_WLAN_YAML}\"\n"
    filecontent+="\n"
    filecontent+="#---INTERFACE CONSTANTS\n"
    filecontent+="BR0=\"${WLN_BR0}\"\n"
    filecontent+="AP_BRIF_LIST=\"${WLN_AP_BRIF_LIST}\"\n"
    filecontent+="RT_BRIF_LIST=\"${WLN_RT_BRIF_LIST}\"\n"
    filecontent+="\n"
    filecontent+="#---PATTERN CONSTANTS\n"
    filecontent+="PATTERN_BRIDGES=\"${WLN_PATTERN_BRIDGES}\"\n"
    filecontent+="PATTERN_GREP=\"${WLN_PATTERN_GREP}\"\n"
    filecontent+="PATTERN_INTERFACES=\"${WLN_PATTERN_INTERFACES}\"\n"
    filecontent+="\n"
    filecontent+="#---PRINT CONSTANTS\n"
    filecontent+="PRINT_BRCTL_ADD_BRIDGE_INTERFACE=\"brctl> \${FG_LIGHTGREEN}add\${NOCOLOR} bridge interface\"\n"
    filecontent+="PRINT_BRCTL_DEL_BRIDGE_INTERFACE=\"brctl> \${FG_SOFLIGHTRED}del\${NOCOLOR} bridge interface\"\n"
    filecontent+="PRINT_BR0=\"\${FG_LIGHTGREY}\${BR0}\${NOCOLOR}\"\n"
    filecontent+="PRINT_INTERFACE_BRING_UP=\"interface> bring \${FG_LIGHTGREEN}up\${NOCOLOR}\"\n"
    filecontent+="PRINT_INTERFACE_BRING_DOWN=\"interface> bring \${FG_SOFLIGHTRED}down\${NOCOLOR}\"\n"
    filecontent+="PRINT_NETPLAN_APPLY=\"netplan> \${FG_LIGHTGREY}apply\${NOCOLOR}\"\n"
    filecontent+="PRINT_WLAN_YAML_INSERT_INTO_LINE=\"\${WLAN_YAML}> \${FG_LIGHTGREEN}insert\${NOCOLOR} into line\"\n"
    filecontent+="PRINT_WLAN_YAML_DELETE_LINE=\"\${WLAN_YAML}> \${FG_SOFLIGHTRED}delete\${NOCOLOR} line\"\n"
    filecontent+="PRINT_WAIT_FOR_1_SEC=\"wait for \${FG_LIGHTGREY}1\${NOCOLOR} sec\"\n"
    filecontent+="\n"
    filecontent+="PRINT_DONE=\"\${FG_YELLOW}DONE\${NOCOLOR}\"\n"
    filecontent+="PRINT_FAILED=\"\${FG_SOFLIGHTRED}FAILED\${NOCOLOR}\"\n"
    filecontent+="PRINT_NONE=\"\${FG_LIGHTGREY}\${NONE}\${NOCOLOR}\"\n"
    filecontent+="PRINT_STATUS=\"\${FG_ORANGE}STATUS\${NOCOLOR}\"\n"
    filecontent+="PRINT_START=\"\${FG_LIGHTGREEN}start\${NOCOLOR}\"\n"
    filecontent+="PRINT_STOP=\"\${FG_SOFLIGHTRED}stop\${NOCOLOR}\"\n"
    filecontent+="PRINT_SUCCESSFUL=\"\${FG_LIGHTGREEN}SUCCESSFUL\${NOCOLOR}\"\n"
    filecontent+="\n"
    filecontent+="#---SED CONSTANTS\n"
    filecontent+="SED_SIXSPACES_ESCAPED=\"${WLN_SED_SIXSPACES_ESCAPED_WITH_THREE_BACKSLASHES}\"\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---COUNTER VARIABLES\n"
    filecontent+="start_retry=0\n"
    filecontent+="tcounter_sec=1\n"
    filecontent+="\n"
    filecontent+="#---PATH VARIABLES\n"
    filecontent+="hostapd_conf_fpath=\"${WLN_HOSTAPD_CONF_FPATH}\"\n"
    filecontent+="hostapd_exec_fpath=\"${WLN_HOSTAPD_EXEC_FPATH}\"\n"
    filecontent+="hostapd_log_fpath=\"${WLN_HOSTAPD_LOG_FPATH}\"\n"
    filecontent+="hostapd_pid_fpath=\"${WLN_HOSTAPD_RUN_FPATH}\"\n"
    filecontent+="wlan_yaml_fpath=\"${WLN_WLAN_YAML_FPATH}\"\n"
    filecontent+="\n"
    filecontent+="#---VARIABLES\n"
    filecontent+="dnsmasq_isenabled=\$(systemctl is-enabled \${DNSMASQ_SERVICE} 2> /dev/null)\n"
    filecontent+="hostapd_daemon_run_cmd=\"\${hostapd_exec_fpath} -B -P \${hostapd_pid_fpath} -f \${hostapd_log_fpath} \${hostapd_conf_fpath}\"\n"
    filecontent+="hostapd_daemon_pid_kill_cmd=\"kill -9 \\\\\$(cat \${hostapd_pid_fpath})\"\n"
    filecontent+="hostapd_daemon_pspid_retrieve_cmd=\"ps axf | grep \\\\\"\${hostapd_exec_fpath}\\\" | grep -v \\\\\"\${PATTERN_GREP}\\\"\"\n"
    filecontent+="hostapd_daemon_proc_kill_cmd=\"pkill -9 \${HOSTAPD}\"\n"
    filecontent+="\n"
    filecontent+="if [[ \"\${isbssmode}\" == \"\${SERVICE_INPUTARG_ROUTER}\" ]]; then\n"
    filecontent+="    brif_list=\"\${RT_BRIF_LIST}\"\n"
    filecontent+="else\n"
    filecontent+="    brif_list=\"\${AP_BRIF_LIST}\"\n"
    filecontent+="fi\n"
    filecontent+="sed_netplan_interfaces_svstart=\"\${SED_SIXSPACES_ESCAPED}\${PATTERN_INTERFACES}: [\${brif_list}]\"\n"
    filecontent+="sed_netplan_interfaces_svstop=\"\${SED_SIXSPACES_ESCAPED}\${PATTERN_INTERFACES}: [\${RT_BRIF_LIST}]\"\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---FUNCTIONS\n"
    filecontent+="hostapd_cleanup_files() {\n"
    filecontent+="    if [[ -f \"\${hostapd_pid_fpath}\" ]]; then\n"
    filecontent+="        rm \"\${hostapd_pid_fpath}\"\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    if [[ -f \"\${hostapd_log_fpath}\" ]]; then\n"
    filecontent+="        rm \"\${hostapd_log_fpath}\"\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="hostapd_start() {\n"
    filecontent+="    #Initialize\n"
    filecontent+="    start_retry=0\n"
    filecontent+="\n"
    filecontent+="    #Start loop\n"
    filecontent+="    while [[ \${start_retry} -lt \${HOSTAPD_NG_DAEMON_RUN_RETRY_MAX} ]]\n"
    filecontent+="    do\n"
    filecontent+="        #Run hostapd-daemon\n"
    filecontent+="        eval \${hostapd_daemon_run_cmd}\n"
    filecontent+="        #Check if pid-file has been created\n"
    filecontent+="        if [[ -f \"\${hostapd_pid_fpath}\" ]]; then\n"
    filecontent+="            break\n"
    filecontent+="        fi\n"
    filecontent+="\n"
    filecontent+="        #Increment index\n"
    filecontent+="        ((start_retry++))\n"
    filecontent+="    done\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="hostapd_start_print() {\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local print_status=\"\"\n"
    filecontent+="    local hostapd_daemon_pid=0\n"
    filecontent+="\n"
    filecontent+="    #Print empty-line\n"
    filecontent+="    echo -e \"\\\r\"\n"
    filecontent+="\n"
    filecontent+="    #Get pid from file\n"
    filecontent+="    hostapd_daemon_pid=\$(cat \${hostapd_pid_fpath})\n"
    filecontent+="\n"
    filecontent+="    #Check hostapd-ng daemon was started successfully.\n"
    filecontent+="    print_status=\":-->\${PRINT_STATUS}: \${PRINT_START} \${FG_LIGHTGREY}\${HOSTAPD_NG} -> PID (\${NOCOLOR}\${hostapd_daemon_pid}\${FG_LIGHTGREY})\${NOCOLOR}: \"\n"
    filecontent+="    if [[ -f \"\${hostapd_pid_fpath}\" ]]; then    #successful\n"
    filecontent+="        print_status+=\"\${PRINT_SUCCESSFUL}\"\n"
    filecontent+="    else    #is Not Empty String\n"
    filecontent+="        print_status+=\"\${PRINT_FAILED}\"\n"
    filecontent+="\n"
    filecontent+="        #IMPORTANT: Stop hostapd-ng service\n"
    filecontent+="        systemctl stop \${HOSTAPD_NG_SERVICE}\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \"\${print_status}\"\n"
    filecontent+="\n"
    filecontent+="    #Print empty-line\n"
    filecontent+="    echo -e \"\\\r\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="hostapd_stop() {\n"
    filecontent+="    #Kill deamon based on pid found in /run/hostapd-ng.pid\n"
    filecontent+="    if [[ -f \"\${hostapd_pid_fpath}\" ]]; then\n"
    filecontent+="        eval \${hostapd_daemon_pid_kill_cmd}\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Double-check if pid has been killed\n"
    filecontent+="    if [[ -n \$(eval \${hostapd_daemon_pspid_retrieve_cmd}) ]]; then\n"
    filecontent+="        eval \${hostapd_daemon_proc_kill_cmd}\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="hostapd_stop_print() {\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local print_status=\"\"\n"
    filecontent+="    local hostapd_daemon_pid=0\n"
    filecontent+="\n"
    filecontent+="    #Print empty-line\n"
    filecontent+="    echo -e \"\\\r\"\n"
    filecontent+="\n"
    filecontent+="    #Get pid from file\n"
    filecontent+="    if [[ -f \${hostapd_pid_fpath} ]]; then\n"
    filecontent+="        hostapd_daemon_pid=\$(cat \${hostapd_pid_fpath})\n"
    filecontent+="\n"
    filecontent+="        #Check if pid was killed\n"
    filecontent+="        print_status=\":-->\${PRINT_STATUS}: \${PRINT_STOP} \${FG_LIGHTGREY}\${HOSTAPD_NG} -> PID (\${NOCOLOR}\${hostapd_daemon_pid}\${FG_LIGHTGREY})\${NOCOLOR}: \"\n"
    filecontent+="        if [[ -z \$(eval \${hostapd_daemon_pspid_retrieve_cmd}) ]]; then    #is Empty String\n"
    filecontent+="            print_status+=\"\${PRINT_SUCCESSFUL}\"\n"
    filecontent+="        else    #is Not Empty String\n"
    filecontent+="            print_status+=\"\${PRINT_FAILED}\"\n"
    filecontent+="        fi\n"
    filecontent+="\n"
    filecontent+="        #Print\n"
    filecontent+="        echo -e \"\${print_status}\"\n"
    filecontent+="\n"
    filecontent+="        #Print empty-line\n"
    filecontent+="        echo -e \"\\\r\"\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="bridge_addif_and_print() {\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local printmsg=\"\"\n"
    filecontent+="    local linenum=0\n"
    filecontent+="    local nextlinenum=0\n"
    filecontent+="\n"
    filecontent+="    #Bring bridge interface down\n"
    filecontent+="    ip link set dev \${BR0} down\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_INTERFACE_BRING_DOWN} \${FG_LIGHTGREY}\${BR0}\${NOCOLOR}: \${PRINT_DONE}\"\n"
    filecontent+="\n"
    filecontent+="    #Delete bridge interface\n"
    filecontent+="    ip link del \${BR0}\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_BRCTL_DEL_BRIDGE_INTERFACE} \${FG_LIGHTGREY}\${BR0}\${NOCOLOR}: \${PRINT_DONE}\"\n"
    filecontent+="\n"
    filecontent+="    #Add bridge interface\n"
    filecontent+="    ip link add name \${BR0} type bridge\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_BRCTL_ADD_BRIDGE_INTERFACE} \${FG_LIGHTGREY}\${BR0}\${NOCOLOR}: \${PRINT_DONE}\"\n"
    filecontent+="\n"
    filecontent+="    #Bring bridge interface up\n"
    filecontent+="    ip link set dev \${BR0} up\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_INTERFACE_BRING_UP} \${FG_LIGHTGREY}\${BR0}\${NOCOLOR}: \${PRINT_DONE}\"\n"
    filecontent+="\n"
    filecontent+="    #Get 'linenum' matching the pattern 'PATTERN_INTERFACES'\n"
    filecontent+="    linenum=\$(interfaces_linenum_get)\n"
    filecontent+="    if [[ \${linenum} -eq 0 ]]; then\n"
    filecontent+="        return 0;\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Insert\n"
    filecontent+="    sed -i \"\${linenum}i \${sed_netplan_interfaces_svstart}\" \"\${wlan_yaml_fpath}\"\n"
    filecontent+="    #Get printable string of 'sed_netplan_interfaces_svstart'\n"
    filecontent+="    printmsg=\$(echo \"\${sed_netplan_interfaces_svstart}\" | sed 's/\\\\\\//g')\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_WLAN_YAML_INSERT_INTO_LINE} '\${FG_LIGHTGREY}\${linenum}\${NOCOLOR}': \${FG_LIGHTGREY}\${printmsg}\${NOCOLOR}: \${PRINT_DONE}\\\n\"\n"
    filecontent+="\n"
    filecontent+="    #Get 'nextlinenum'\n"
    filecontent+="    nextlinenum=\$(( linenum + 1 ))\n"
    filecontent+="    #Delete 'nextlinenum'\n"
    filecontent+="    sed -i \"\${nextlinenum}d\" \"\${wlan_yaml_fpath}\"\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_WLAN_YAML_DELETE_LINE} '\${FG_LIGHTGREY}\${nextlinenum}\${NOCOLOR}': \${PRINT_DONE}\\\n\"\n"
    filecontent+="\n"
    filecontent+="    #Apply netplan\n"
    filecontent+="    netplan apply\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_NETPLAN_APPLY}: \${PRINT_DONE}\\\n\"\n"
    filecontent+="\n"
    filecontent+="    #Wait for 1 second\n"
    filecontent+="    sleep 1\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_WAIT_FOR_1_SEC}: \${PRINT_DONE}\\\n\"\n"
    filecontent+="\n"
    filecontent+="    #Print empty-line\n"
    filecontent+="    echo -e \"\\\r\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="bridge_delif_and_print() {\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local printmsg=\"\"\n"
    filecontent+="    local linenum=0\n"
    filecontent+="    local nextlinenum=0\n"
    filecontent+="\n"
    filecontent+="    #Bring bridge interface down\n"
    filecontent+="    ip link set dev \${BR0} down\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_INTERFACE_BRING_DOWN} \${FG_LIGHTGREY}\${BR0}\${NOCOLOR}: \${PRINT_DONE}\"\n"
    filecontent+="\n"
    filecontent+="    #Delete bridge interface\n"
    filecontent+="    ip link del \${BR0}\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_BRCTL_DEL_BRIDGE_INTERFACE} \${FG_LIGHTGREY}\${BR0}\${NOCOLOR}: \${PRINT_DONE}\"\n"
    filecontent+="\n"
    filecontent+="    #Get 'linenum' matching the pattern 'PATTERN_INTERFACES'\n"
    filecontent+="    linenum=\$(interfaces_linenum_get)\n"
    filecontent+="    if [[ \${linenum} -eq 0 ]]; then\n"
    filecontent+="        return 0;\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Insert\n"
    filecontent+="    sed -i \"\${linenum}i \${sed_netplan_interfaces_svstop}\" \"\${wlan_yaml_fpath}\"\n"
    filecontent+="    #Get printable string of 'sed_netplan_interfaces_svstop'\n"
    filecontent+="    printmsg=\$(echo \"\${sed_netplan_interfaces_svstop}\" | sed 's/\\\\\\//g')\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_WLAN_YAML_INSERT_INTO_LINE} '\${FG_LIGHTGREY}\${linenum}\${NOCOLOR}': \${FG_LIGHTGREY}\${printmsg}\${NOCOLOR}: \${PRINT_DONE}\\\n\"\n"
    filecontent+="\n"
    filecontent+="    #Get 'nextlinenum'\n"
    filecontent+="    nextlinenum=\$(( linenum + 1 ))\n"
    filecontent+="    #Delete 'nextlinenum'\n"
    filecontent+="    sed -i \"\${nextlinenum}d\" \"\${wlan_yaml_fpath}\"\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_WLAN_YAML_DELETE_LINE} '\${FG_LIGHTGREY}\${nextlinenum}\${NOCOLOR}': \${PRINT_DONE}\\\n\"\n"
    filecontent+="\n"
    filecontent+="    #Apply netplan\n"
    filecontent+="    netplan apply\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_NETPLAN_APPLY}: \${PRINT_DONE}\\\n\"\n"
    filecontent+="\n"
    filecontent+="    #Wait for 1 second\n"
    filecontent+="    sleep 1\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_WAIT_FOR_1_SEC}: \${PRINT_DONE}\\\n\"\n"
    filecontent+="\n"
    filecontent+="    #Print empty-line\n"
    filecontent+="    echo -e \"\\\r\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="interfaces_linenum_get() {\n"
    filecontent+="    #Define constants\n"
    filecontent+="    local PHASE_HOSTAPDFUNC_LINENUMS_GET=1\n"
    filecontent+="    local PHASE_HOSTAPDFUNC_BRIDGES_LINENUM_VALIDATE=10\n"
    filecontent+="    local PHASE_HOSTAPDFUNC_BR0_LINENUM_VALIDATE=20\n"
    filecontent+="    local PHASE_HOSTAPDFUNC_INTERFACES_LINENUM_VALIDATE=30\n"
    filecontent+="    local PHASE_HOSTAPDFUNC_EXIT=100\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local phase=\"\${PHASE_HOSTAPDFUNC_LINENUMS_GET}\"\n"
    filecontent+="    local mytext=\"\${WLN_EMPTYSTRING}\"\n"
    filecontent+="    local br0_linenum=0\n"
    filecontent+="    local bridges_linenum=0\n"
    filecontent+="    local diff_linenum=0\n"
    filecontent+="    local interfaces_linenum=0\n"
    filecontent+="\n"
    filecontent+="    #Start phase\n"
    filecontent+="    while true\n"
    filecontent+="    do\n"
    filecontent+="        case \"\${phase}\" in\n"
    filecontent+="            \"\${PHASE_HOSTAPDFUNC_LINENUMS_GET}\")\n"
    filecontent+="                #Get the line-numbers\n"
    filecontent+="                #Remark:\n"
    filecontent+="                #   The 'wlan.yaml' for ACCESSPOINT and ROUTER mode is designed\n"
    filecontent+="                #   ...to have the following inter-relationship between the line-numbers:\n"
    filecontent+="                #   bridges_linenum = based on the position in 'wlan.yaml' (e.g. 8)\n"
    filecontent+="                #   br0_linenum = bridges_linenum + 1 (e.g. 9)\n"
    filecontent+="                #   interfaces_linenum = br0_linenum + 1 (e.g. 10)\n"
    filecontent+="                bridges_linenum=\$(grep -no \"\${PATTERN_BRIDGES}.*\" \"\${wlan_yaml_fpath}\" | cut -d\":\" -f1); exitcode=\$?\n"
    filecontent+="                br0_linenum=\$(grep -no \"\${BR0}.*\" \"\${wlan_yaml_fpath}\" | cut -d\":\" -f1); exitcode=\$?\n"
    filecontent+="                interfaces_linenum=\$(grep -no \"\${PATTERN_INTERFACES}.*\" \"\${wlan_yaml_fpath}\" | cut -d\":\" -f1); exitcode=\$?\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_HOSTAPDFUNC_BRIDGES_LINENUM_VALIDATE}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_HOSTAPDFUNC_BRIDGES_LINENUM_VALIDATE}\")\n"
    filecontent+="                #Do not continue if 'bridges_linenum = <Empty String>'\n"
    filecontent+="                if [[ -z \"\${bridges_linenum}\" ]]; then\n"
    filecontent+="                    #Set 'interfaces_linenum = 0'\n"
    filecontent+="                    interfaces_linenum=0\n"
    filecontent+="\n"
    filecontent+="                    #Goto next-phase\n"
    filecontent+="                    phase=\"\${PHASE_HOSTAPDFUNC_EXIT}\"\n"
    filecontent+="                else\n"
    filecontent+="                    #Goto next-phase\n"
    filecontent+="                    phase=\"\${PHASE_HOSTAPDFUNC_BR0_LINENUM_VALIDATE}\"\n"
    filecontent+="                fi\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_HOSTAPDFUNC_BR0_LINENUM_VALIDATE}\")\n"
    filecontent+="                #Check if 'br0_linenum' is an Empty string or not.\n"
    filecontent+="                if [[ -z \"\${br0_linenum}\" ]]; then\n"
    filecontent+="                    #Set 'interfaces_linenum = 0'\n"
    filecontent+="                    interfaces_linenum=0\n"
    filecontent+="\n"
    filecontent+="                    #Goto next-phase\n"
    filecontent+="                    phase=\"\${PHASE_HOSTAPDFUNC_EXIT}\"\n"
    filecontent+="                else\n"
    filecontent+="                    #Check if 'diff_linenum = br0_linenum - bridges_linenum = 1'\n"
    filecontent+="                    diff_linenum=\$((br0_linenum - bridges_linenum))\n"
    filecontent+="                    #Do not continue if 'diff_linenum != 1'\n"
    filecontent+="                    if [[ \${diff_linenum} -ne 1 ]]; then\n"
    filecontent+="                        #Set 'interfaces_linenum = 0'\n"
    filecontent+="                        interfaces_linenum=0\n"
    filecontent+="\n"
    filecontent+="                        #Goto next-phase\n"
    filecontent+="                        phase=\"\${PHASE_HOSTAPDFUNC_EXIT}\"\n"
    filecontent+="                    else\n"
    filecontent+="                        #Goto next-phase\n"
    filecontent+="                        phase=\"\${PHASE_HOSTAPDFUNC_INTERFACES_LINENUM_VALIDATE}\"\n"
    filecontent+="                    fi\n"
    filecontent+="                fi\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_HOSTAPDFUNC_INTERFACES_LINENUM_VALIDATE}\")\n"
    filecontent+="                #Do not continue if 'interfaces_linenum = <Empty String>'\n"
    filecontent+="                if [[ -z \"\${interfaces_linenum}\" ]]; then\n"
    filecontent+="                    #Set 'interfaces_linenum = 0'\n"
    filecontent+="                    interfaces_linenum=0\n"
    filecontent+="                else\n"
    filecontent+="                    #Check if 'diff_linenum = interfaces_linenum - br0_linenum = 1'\n"
    filecontent+="                    diff_linenum=\$((interfaces_linenum - br0_linenum))\n"
    filecontent+="                    #Do not continue if 'diff_linenum != 1'\n"
    filecontent+="                    if [[ \${diff_linenum} -ne 1 ]]; then\n"
    filecontent+="                        #Set 'interfaces_linenum = 0'\n"
    filecontent+="                        interfaces_linenum=0\n"
    filecontent+="                    fi\n"
    filecontent+="                fi\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_HOSTAPDFUNC_EXIT}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_HOSTAPDFUNC_EXIT}\")\n"
    filecontent+="                break\n"
    filecontent+="                ;;\n"
    filecontent+="        esac\n"
    filecontent+="    done\n"
    filecontent+="\n"
    filecontent+="    #Output\n"
    filecontent+="    echo \"\${interfaces_linenum}\"\n"
    filecontent+="\n"
    filecontent+="    return 0;\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---SUBROUTINES\n"
    filecontent+="stop_handler() {\n"
    filecontent+="    #Stop hostapd daemons\n"
    filecontent+="    hostapd_stop\n"
    filecontent+="    hostapd_stop_print\n"
    filecontent+="\n"
    filecontent+="    #Unbridge interfaces\n"
    filecontent+="    bridge_delif_and_print\n"
    filecontent+="\n"
    filecontent+="    #Cleanup files\n"
    filecontent+="    hostapd_cleanup_files\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="start_handler() {\n"
    filecontent+="    #Stop hostapd daemons (which were not killed last time)\n"
    filecontent+="    hostapd_stop\n"
    filecontent+="    hostapd_stop_print\n"
    filecontent+="\n"
    filecontent+="    #Clean files (which were not cleaned up last time)\n"
    filecontent+="    hostapd_cleanup_files\n"
    filecontent+="\n"
    filecontent+="    #Bridge interfaces\n"
    filecontent+="    bridge_addif_and_print\n"
    filecontent+="\n"
    filecontent+="    #Initial start hostapd-daemon\n"
    filecontent+="    hostapd_start\n"
    filecontent+="    hostapd_start_print\n"
    filecontent+="\n"
    filecontent+="    #If dnsmasq.service is enabled, then restart service.\n"
    filecontent+="    if [[ \"\${dnsmasq_isenabled}\" == \"\${ENABLED}\" ]]; then\n"
    filecontent+="        systemctl restart \${DNSMASQ_SERVICE}\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---Select case\n"
    filecontent+="case \"\${action}\" in\n"
    filecontent+="    \${ENABLE})\n"
    filecontent+="        #Start subroutine in the BACKGROUND (&)\n"
    filecontent+="        start_handler\n"
    filecontent+="        ;;\n"
    filecontent+="    \${DISABLE})\n"
    filecontent+="        stop_handler\n"
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

    #Output
    echo "${ret}"

    return 0;
}
WLN_Hostapd_Ng_Autorecover_Service_Generator() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local ret="${REJECTED}"



    #Generate service
    local filecontent="[Unit]\n"
    filecontent+="Description=auto recovers hostapd-ng daemon when wireless interface goes down then up\n"
    filecontent+="Requires=sys-subsystem-net-devices-wlan0.device\n"
    filecontent+="Wants=hostapd-ng-autorecover.timer\n"
    filecontent+="After=hostapd-ng.service\n"
    filecontent+="\n"
    filecontent+="[Service]\n"
    filecontent+="Type=oneshot\n"
    filecontent+="#User MUST BE SET TO 'root'\n"
    filecontent+="User=root\n"
    filecontent+="\n"
    filecontent+="ExecStart=/usr/local/bin/hostapd-ng-autorecover.sh\n"
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
WLN_Hostapd_Ng_Autorecover_Service_Generator() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local ret="${REJECTED}"



    #Generate 'hostapd-ng.service'
    local filecontent="[Unit]\n"
    filecontent+="Description=auto recovers hostapd-ng daemon when wireless interface goes down then up\n"
    filecontent+="Requires=sys-subsystem-net-devices-wlan0.device\n"
    filecontent+="After=network.target\n"
    filecontent+="Wants=hostapd-ng-autorecover.timer\n"
    filecontent+="\n"
    filecontent+="[Service]\n"
    filecontent+="Type=oneshot\n"
    filecontent+="#User MUST BE SET TO 'root'\n"
    filecontent+="User=root\n"
    filecontent+="\n"
    filecontent+="ExecStart=/usr/local/bin/hostapd-ng-autorecover.sh\n"
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
WLN_Hostapd_Ng_Autorecover_Script_Generator() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Generate 'hostapd-ng.service'
    filecontent="#!/bin/bash\n"
    filecontent+="#---PATTERN CONSTANTS\n"
    filecontent+="PATTERN_ERROR1=\"${WLN_PATTERN_NL80211_KERNEL_REPORTS_KEY_NOT_ALLOWED}\"\n"
    filecontent+="PATTERN_ERROR2=\"${WLN_PATTERN_FAILED_TO_SET_BEACON_PARAMETERS}\"\n"
    filecontent+="\n"
    filecontent+="#---ENVIRONMENT VARIABLES\n"
    filecontent+="HOSTAPD_NG_SERVICE=\"${WLN_HOSTAPD_NG_SRV}\"\n"
    filecontent+="hostapd_log_fpath=\"${WLN_HOSTAPD_LOG_FPATH}\"\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---SUBROUTINES\n"
    filecontent+="    autorecover_handler() {\n"
    filecontent+="    if [[ ! -f \"\${hostapd_log_fpath}\" ]]; then\n"
    filecontent+="        exit\n"
    filecontent+="    fi\n"
    filecontent+="    #--------------------------------------------------------\n"
    filecontent+="    #Check whether one of the errors (specified \n"
    filecontent+="    #   by 'PATTERN_ERROR1' and 'PATTERN_ERROR2') are found.\n"
    filecontent+="    # These errors are caused when the Wireless Interface \n"
    filecontent+="    #   goes DOWN and then UP again. Because of that, the \n"
    filecontent+="    #   SSID appears to be available for remote devices to \n"
    filecontent+="    #   connect, but in reality this is not the case.\n"
    filecontent+="    # In order to fix the above mentioned issue, the \n"
    filecontent+="    #   hostapd daemon has to be stopped and started.\n"
    filecontent+="    #--------------------------------------------------------\n"
    filecontent+="    #Define variables\n"
    filecontent+="    hostapd_pattern_error1_cmd=\"grep -F \\\\\"\${PATTERN_ERROR1}\\\\\" \${hostapd_log_fpath}\"\n"
    filecontent+="    hostapd_pattern_error2_cmd=\"grep -F \\\\\"\${PATTERN_ERROR2}\\\\\" \${hostapd_log_fpath}\"\n"
    filecontent+="    local error1_output=\$(eval \${hostapd_pattern_error1_cmd})\n"
    filecontent+="    local error2_output=\$(eval \${hostapd_pattern_error2_cmd})\n"
    filecontent+="\n"
    filecontent+="    #Check if at least one variable contains data.\n"
    filecontent+="    #Remark:\n"
    filecontent+="    #   If one of the specified errors is found, then:\n"
    filecontent+="    #   1. kill hostapd-process\n"
    filecontent+="    #   2. start host\n"
    filecontent+="    if [[ -n \"\${error1_output}\" ]]  && [[ -n \"\${error2_output}\" ]]; then\n"
    filecontent+="        systemctl restart \${HOSTAPD_NG_SERVICE}\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Empty file without removing file\n"
    filecontent+="    if [[ -f \${hostapd_log_fpath} ]]; then\n"
    filecontent+="        cat /dev/null > \"\${hostapd_log_fpath}\"\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---EXECUTE SUBROUTINES\n"
    filecontent+="autorecover_handler"

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
WLN_Hostapd_Ng_Autorecover_Timer_Generator() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local ret="${REJECTED}"



    #Generate 'hostapd-ng.service'
    local filecontent="[Unit]\n"
    filecontent+="Description=Run wifi-powersave-off.service every 5 sec (active-state) and 5 sec (idle-state)\n"
    filecontent+="Requireshostapd-ng-autorecover.service\n"
    filecontent+="\n"
    filecontent+="[Timer]\n"
    filecontent+="#Run on boot after 1 seconds\n"
    filecontent+="OnBootSec=1s\n"
    filecontent+="#Run script every 5 sec when Device is Active\n"
    filecontent+="OnUnitActiveSec=5s\n"
    filecontent+="#Run script every 5 sec when Device is Idle\n"
    filecontent+="OnUnitInactiveSec=5s\n"
    filecontent+="AccuracySec=1s\n"
    filecontent+="\n"
    filecontent+="[Install]\n"
    filecontent+="WantedBy=timers.target"

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
