#!/bin/bash
#---FUNCTIONS
WLN_Netplan_Handler() {
    #Input args
    local isbssmode=${1}
    local istargetfpath=${2}
    local isautoreconnectonboot_istriggered=${3}   # {YES | NO}

    #Define variables
    local intfstates_ctx_fpath="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Set variable(s) based on 'isautoreconnectonboot_istriggered' input value
    if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
        intfstates_ctx_fpath="${WLN_INTFSTATES_CTX_DAT_FPATH}"
    else
        intfstates_ctx_fpath="${WLN_INTFSTATES_CTX_INIT_DAT_FPATH}"
    fi

    #----------------------------------------------------------------
    #REMARK:
    #   if 'wln_ip', 'wln_netmask', 'wln_ipv6', 'wln_netmaskv6' 
    #   ...is NOT provided, then the default values 
    #   ...(1.2.0.1, 255.255.255.255, 1:2::1, 128) will be used.
    #----------------------------------------------------------------

    # #Retrieve data from database
    # if [[ "${isbssmode}" == "${WLN_EMPTYSTRING}"]]; then
    #     isbssmode=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__bssmode")
    # fi

    #Create directory '/etc/tibbo/netplan/wln' (if not present)
    if [[ $(Mkdir "${WLN_ETC_TIBBO_NETPLAN_WLN_DIR}") == false ]]; then
        ret="${REJECTED}"
    else
        #Generate 'wlan.yaml'
        case "${isbssmode}" in
            "${PL_WLN_BSS_MODE_INFRASTRUCTURE}")
                ret=$(Netplan_For_Infrastructure "${intfstates_ctx_fpath}")
                ;;
            "${PL_WLN_BSS_MODE_ACCESSPOINT}")
                ret=$(Netplan_For_AccessPoint "${intfstates_ctx_fpath}")
                ;;
            "${PL_WLN_BSS_MODE_ROUTER}")
                ret=$(Netplan_For_Router "${intfstates_ctx_fpath}")
                ;;
        esac
    fi

    #Netplan apply
    # ret=$(WLN_Netplan_Apply)

    #Output
    echo "${ret}"

    return 0;
}
Netplan_For_Infrastructure() {
    #Input args
    local isintfstates_ctx_fpath=${1}
    
    #Define constants
    local PHASE_NETPLANFUNC_RETRIEVE_DATA=1
    local PHASE_NETPLANFUNC_YAML_CREATE=10
    local PHASE_NETPLANFUNC_YAML_REMOVE=20
    local PHASE_NETPLANFUNC_YAML_WRITE=30
    local PHASE_NETPLANFUNC_EXIT=100
    local SCAN_SSID_1_HACK="\\\"\\\n  scan_ssid=1\\\n# \\\"hack!"

    #Define variables
    local intf="${WLN_EMPTYSTRING}"
    local dhcp="${WLN_EMPTYSTRING}"
    local ip="${WLN_EMPTYSTRING}"
    local cidr="${WLN_EMPTYSTRING}"
    local gatewayip="${WLN_EMPTYSTRING}"
    local dns1="${WLN_EMPTYSTRING}"
    local dns2="${WLN_EMPTYSTRING}"
    local WLN_intfstates_ctx__dhcpv6="${WLN_EMPTYSTRING}"
    local ipv6="${WLN_EMPTYSTRING}"
    local cidrv6="${WLN_EMPTYSTRING}"
    local gatewayipv6="${WLN_EMPTYSTRING}"
    local dns1v6="${WLN_EMPTYSTRING}"
    local dns2v6="${WLN_EMPTYSTRING}"
    local ssid="${WLN_EMPTYSTRING}"
    # local ssid_isvisible="${WLN_EMPTYSTRING}"
    local wepmode="${WLN_EMPTYSTRING}"
    local wepkey="${WLN_EMPTYSTRING}"
    local wpamode="${WLN_EMPTYSTRING}"
    local wpakey="${WLN_EMPTYSTRING}"

    local filecontent="${WLN_EMPTYSTRING}"
    local phase="${PHASE_NETPLANFUNC_RETRIEVE_DATA}"
    local ret="${REJECTED}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_NETPLANFUNC_RETRIEVE_DATA}")
                #Retrieve data from database
                intf=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__intf")
                if [[ -z "${intf}" ]]; then
                    intf="${WLN_WLAN0}"
                fi
                #If 'dhcp = false', then the 'addresses' field in 'netplan'
                #   can NOT be an empty.
                #Therefore, if the 'ip' and 'cidr' are Empty Strings, then
                #   use the default values instead.
                dhcp=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__dhcp")
                ip=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__ip")
                if [[ -z "${ip}" ]]; then
                    ip="${WLN_IPV4_DEFAULT}"
                fi
                cidr=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__cidr")
                if [[ -z "${cidr}" ]]; then
                    cidr="${WLN_IPV4_CIDR_PREFIX_24}"
                fi
                gatewayip=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__gatewayip")
                dns1=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__dns1")
                dns2=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__dns2")

                #If 'dhcpv6 = false', then the 'addresses' field in 'netplan'
                #   can NOT be an empty.
                #Therefore, if the 'ipv6' and 'cidrv6' are Empty Strings, then
                #   use the default values instead.
                dhcpv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__dhcpv6")
                ipv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__ipv6")
                if [[ -z "${ipv6}" ]]; then
                    ipv6="${WLN_IPV6_DEFAULT}"
                fi
                cidrv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__cidrv6")
                if [[ -z "${cidrv6}" ]]; then
                    cidrv6="${WLN_IPV6_CIDR_DEFAULT}"
                fi
                gatewayipv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__gatewayipv6")
                dns1v6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__dns1v6")
                dns2v6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__dns2v6")
                ssid=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__ssid")
                bssid=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__bssid")
                wepmode=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__wepmode")
                wepkey=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__wepkey")
                wpamode=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__wpamode")
                wpakey=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__wpakey")

                #Goto next-phase
                phase="${PHASE_NETPLANFUNC_YAML_CREATE}"
                ;;
            "${PHASE_NETPLANFUNC_YAML_CREATE}")
                #Generate
                filecontent="network:\n"
                filecontent+="  version: 2\n"
                filecontent+="  renderer: networkd\n"
                filecontent+="  wifis:\n"
                filecontent+="    ${intf}:\n"
                if [[ "${dhcp}" == true ]]; then
                    filecontent+="      dhcp4: true\n"
                else
                    filecontent+="      addresses: [${ip}/${cidr}]\n"
                    if [[ -n "${gatewayip}" ]]; then
                        filecontent+="      gateway4: \"${gatewayip}\"\n"
                    fi
                fi
                if [[ "${dhcpv6}" == true ]]; then
                    filecontent+="      dhcp6: true\n"
                else
                    filecontent+="      addresses: [${ipv6}/${cidrv6}]\n"
                    if [[ -n "${gatewayipv6}" ]]; then
                        filecontent+="      gateway6: \"${gatewayipv6}\"\n"
                    fi
                fi
                if [[ -n "${dns1}" ]] || [[ -n "${dns2}" ]] || [[ -n "${dns1v6}" ]] || [[ -n "${dns2v6}" ]]; then
                    filecontent+="      nameservers:\n"
                    if [[ -n "${dns1}" ]]; then
                        filecontent+="        addresses: [${dns1}]\n"
                    fi
                    if [[ -n "${dns2}" ]]; then
                        filecontent+="        addresses: [${dns2}]\n"
                    fi
                    if [[ -n "${dns1v6}" ]]; then
                        filecontent+="        addresses: [${dns1v6}]\n"
                    fi
                    if [[ -n "${dns2v6}" ]]; then
                        filecontent+="        addresses: [${dns2v6}]\n"
                    fi
                fi
                filecontent+="      access-points:\n"
                if [[ "${wepmode}" == "${PL_WLN_WEP_MODE_DISABLED}" ]] && \
                        [[ "${wpamode}" == "${PL_WLN_WPA_DISABLED}" ]]; then
                    if [[ -n "${bssid}" ]] && [[ "${bssid}" != ${WLN_BSSID_000000} ]]; then
                        filecontent+="        \"${ssid}${SCAN_SSID_1_HACK}\":\n"
                        filecontent+="          bssid: \"${bssid}\"\n"
                    else
                        filecontent+="        \"${ssid}${SCAN_SSID_1_HACK}\": {}\n" #always use 'scan_ssid=1' in whether the SSID is visible or not.
                    fi
                else    #wepmode != PL_WLN_WEP_MODE_DISABLED or wpamode != PL_WLN_WPA_DISABLED
                    filecontent+="        \"${ssid}${SCAN_SSID_1_HACK}\":\n"    #always use 'scan_ssid=1' in whether the SSID is visible or not.
                    if [[ "${wepmode}" != "${PL_WLN_WEP_MODE_DISABLED}" ]]; then
                        filecontent+="          password: \"${wepkey}\"\n"
                    else    #wpamode != PL_WLN_WPA_DISABLED
                        filecontent+="          password: \"${wpakey}\"\n"
                    fi

                    if [[ -n "${bssid}" ]] && [[ "${bssid}" != ${WLN_BSSID_000000} ]]; then
                        filecontent+="          bssid: \"${bssid}\"\n"
                    fi
                fi

                #Goto next-phase
                phase="${PHASE_NETPLANFUNC_YAML_REMOVE}"
                ;;
            "${PHASE_NETPLANFUNC_YAML_REMOVE}")
                if [[ $(RemoveFile "${istargetfpath}") == "${REJECTED}" ]]; then
                    #Set output-result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETPLANFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETPLANFUNC_YAML_WRITE}"
                fi
                ;;
            "${PHASE_NETPLANFUNC_YAML_WRITE}")
                if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == "${REJECTED}" ]]; then
                    #Set output-result
                    ret="${REJECTED}"
                else
                    #Set output-result
                    ret="${ACCEPTED}"
                fi

                #Goto next-phase
                phase="${PHASE_NETPLANFUNC_EXIT}"
                ;;
            "${PHASE_NETPLANFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}
Netplan_For_AccessPoint() {
    #Input args
    local isintfstates_ctx_fpath=${1}

    #Define constants
    local PHASE_NETPLANFUNC_RETRIEVE_DATA=1
    local PHASE_NETPLANFUNC_YAML_CREATE=10
    local PHASE_NETPLANFUNC_YAML_REMOVE=20
    local PHASE_NETPLANFUNC_YAML_WRITE=30
    local PHASE_NETPLANFUNC_BRIDGE_ADD_AND_BRINGUP=40
    local PHASE_NETPLANFUNC_EXIT=100

    #Define variables
    local intf="${WLN_EMPTYSTRING}"
    local bridge="${WLN_EMPTYSTRING}"
    local cidr="${WLN_EMPTYSTRING}"
    local cidrv6="${WLN_EMPTYSTRING}"
    local ip="${WLN_EMPTYSTRING}"
    local ipv6="${WLN_EMPTYSTRING}"

    local filecontent="${WLN_EMPTYSTRING}"
    local phase="${PHASE_NETPLANFUNC_RETRIEVE_DATA}"
    local ret="${REJECTED}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_NETPLANFUNC_RETRIEVE_DATA}")
                #Retrieve data from database
                intf=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__intf")
                bridge=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__bridge")
                ip=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__ip")
                cidr=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__cidr")
                ipv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__ipv6")
                cidrv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__cidrv6")

                #Goto next-phase
                phase="${PHASE_NETPLANFUNC_YAML_CREATE}"
                ;;
            "${PHASE_NETPLANFUNC_YAML_CREATE}")
                #Generate
                filecontent="network:\n"
                filecontent+="  version: 2\n"
                filecontent+="  renderer: networkd\n"
                filecontent+="  ethernets:\n"
                filecontent+="    ${intf}:\n"
                filecontent+="      dhcp4: no\n"
                filecontent+="      dhcp6: no\n"
                filecontent+="  bridges:\n"
                filecontent+="    ${bridge}:\n"
                filecontent+="      interfaces: [${WLN_AP_BRIF_LIST}]\n"
                filecontent+="      addresses: [${ip}/${cidr}]\n"
                filecontent+="      nameservers: {}\n"
                filecontent+="      addresses: [${ipv6}/${cidrv6}]\n"
                filecontent+="      nameservers: {}"

                #Goto next-phase
                phase="${PHASE_NETPLANFUNC_YAML_REMOVE}"
                ;;
            "${PHASE_NETPLANFUNC_YAML_REMOVE}")
                if [[ $(RemoveFile "${istargetfpath}") == "${REJECTED}" ]]; then
                    #Set output-result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETPLANFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETPLANFUNC_YAML_WRITE}"
                fi
                ;;
            "${PHASE_NETPLANFUNC_YAML_WRITE}")
                if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == "${REJECTED}" ]]; then
                    #Set output-result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETPLANFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETPLANFUNC_BRIDGE_ADD_AND_BRINGUP}"
                fi
                ;;
            "${PHASE_NETPLANFUNC_BRIDGE_ADD_AND_BRINGUP}")
                if [[ $(WLN_Bridge_Add_And_BringUp) == "${REJECTED}" ]]; then
                    #Set output-result
                    ret="${REJECTED}"
                else
                    #Set output-result
                    ret="${ACCEPTED}"
                fi

                #Goto next-phase
                phase="${PHASE_NETPLANFUNC_EXIT}"
                ;;
            "${PHASE_NETPLANFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}
Netplan_For_Router() {
    #Input args
    local isintfstates_ctx_fpath=${1}

    #Define constants
    local PHASE_NETPLANFUNC_RETRIEVE_DATA=1
    local PHASE_NETPLANFUNC_YAML_CREATE=10
    local PHASE_NETPLANFUNC_YAML_REMOVE=20
    local PHASE_NETPLANFUNC_YAML_WRITE=30
    local PHASE_NETPLANFUNC_EXIT=100

    #Define variables
    local intf="${WLN_EMPTYSTRING}"
    local bridge="${WLN_EMPTYSTRING}"
    local cidr="${WLN_EMPTYSTRING}"
    local cidrv6="${WLN_EMPTYSTRING}"
    local ip="${WLN_EMPTYSTRING}"
    local ipv6="${WLN_EMPTYSTRING}"

    local filecontent="${WLN_EMPTYSTRING}"
    local phase="${PHASE_NETPLANFUNC_RETRIEVE_DATA}"
    local ret="${REJECTED}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_NETPLANFUNC_RETRIEVE_DATA}")
                #Retrieve data from database
                intf=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__intf")
                bridge=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__bridge")
                ip=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__ip")
                cidr=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__cidr")
                ipv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__ipv6")
                cidrv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__cidrv6")

                #Goto next-phase
                phase="${PHASE_NETPLANFUNC_YAML_CREATE}"
                ;;
            "${PHASE_NETPLANFUNC_YAML_CREATE}")
                #Generate
                filecontent="network:\n"
                filecontent+="  version: 2\n"
                filecontent+="  renderer: networkd\n"
                filecontent+="  ethernets:\n"
                filecontent+="    ${intf}:\n"
                filecontent+="      dhcp4: no\n"
                filecontent+="      dhcp6: no\n"
                filecontent+="  bridges:\n"
                filecontent+="    ${bridge}:\n"
                filecontent+="      interfaces: [${WLN_RT_BRIF_LIST}]\n"
                filecontent+="      addresses: [${ip}/${cidr}]\n"
                filecontent+="      nameservers: {}\n"
                filecontent+="      addresses: [${ipv6}/${cidrv6}]\n"
                filecontent+="      nameservers: {}"

                #Goto next-phase
                phase="${PHASE_NETPLANFUNC_YAML_REMOVE}"
                ;;
            "${PHASE_NETPLANFUNC_YAML_REMOVE}")
                if [[ $(RemoveFile "${istargetfpath}") == "${REJECTED}" ]]; then
                    #Set output-result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETPLANFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETPLANFUNC_YAML_WRITE}"
                fi
                ;;
            "${PHASE_NETPLANFUNC_YAML_WRITE}")
                if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == "${REJECTED}" ]]; then
                    #Set output-result
                    ret="${REJECTED}"
                else
                    #Set output-result
                    ret="${ACCEPTED}"
                fi

                #Goto next-phase
                phase="${PHASE_NETPLANFUNC_EXIT}"
                ;;
            "${PHASE_NETPLANFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}
WLN_Netplan_Apply() {
    #Define variables
    local ret="${ACCEPTED}"

    #Execute command
    if [[ $(CmdExec "${WLN_NETPLAN_APPLY}") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}
