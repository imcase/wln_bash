#!/bin/bash
#---MAIN FUNCTIONS
WLN_Dnsmasq_Handler() {
    #Input args
    local isbssmode=${1}
    local isautoreconnectonboot_istriggered=${2}  # {true | false}

    #Define constants
    local PHASE_DNSMASQFUNC_SERVICE_STOP_DISABLE=1
    local PHASE_DNSMASQFUNC_DIR_CREATE=10
    local PHASE_DNSMASQFUNC_SERVICE_CREATE=20
    local PHASE_DNSMASQFUNC_BRIDGE_ADD_AND_BRINGUP=30
    local PHASE_DNSMASQFUNC_SERVICE_ENABLESTART=40
    local PHASE_DNSMASQFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_DNSMASQFUNC_SERVICE_STOP_DISABLE}"
    local intfstates_ctx_fpath="${WLN_EMPTYSTRING}"
    local targetfpath="${WLN_EMPTYSTRING}"
    local srv_enablestate="${WLN_DISABLED}"
    local srv_activestate="${WLN_INACTIVE}"
    local ret="${REJECTED}"


    #Set variable(s) based on 'isautoreconnectonboot_istriggered' input value
    if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
        intfstates_ctx_fpath="${WLN_INTFSTATES_CTX_DAT_FPATH}"
        targetfpath="${WLN_DNSMASQ_CONF_FPATH}"
    else
        intfstates_ctx_fpath="${WLN_INTFSTATES_CTX_INIT_DAT_FPATH}"
        targetfpath="${WLN_DNSMASQ_CONF_AUTORECONNECTONBOOT_FPATH}"
    fi

    #Retrieve data from database
    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_DNSMASQFUNC_SERVICE_STOP_DISABLE}")
                if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
                    if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_DNSMASQ_SRV}" \
                            "${WLN_DNSMASQ}" \
                            "${WLN_DNSMASQ_SERVICE_FPATH}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_DNSMASQFUNC_EXIT}"
                    else
                        if [[ "${isbssmode}" != "${PL_WLN_BSS_MODE_ROUTER}" ]]; then
                            ret="${ACCEPTED}"

                            phase="${PHASE_DNSMASQFUNC_EXIT}"
                        else
                            phase="${PHASE_DNSMASQFUNC_DIR_CREATE}"
                        fi
                    fi
                else
                    phase="${PHASE_DNSMASQFUNC_DIR_CREATE}"
                fi
                ;;
            "${PHASE_DNSMASQFUNC_DIR_CREATE}")
                if [[ ${isautoreconnectonboot_istriggered} == "${YES}" ]]; then
                    if [[ $(Mkdir "${WLN_ETC_TIBBO_DNSMASQ_WLN_DIR}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_DNSMASQFUNC_EXIT}"
                    else
                        phase="${PHASE_DNSMASQFUNC_SERVICE_CREATE}"
                    fi
                else
                    phase="${PHASE_DNSMASQFUNC_SERVICE_CREATE}"
                fi
                ;;
            "${PHASE_DNSMASQFUNC_SERVICE_CREATE}")
                if [[ $(WLN_Dnsmasq_Conf_Create "${targetfpath}" \
                        "${intfstates_ctx_fpath}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_DNSMASQFUNC_EXIT}"
                else
                    phase="${PHASE_DNSMASQFUNC_BRIDGE_ADD_AND_BRINGUP}"
                fi
                ;;
            "${PHASE_DNSMASQFUNC_BRIDGE_ADD_AND_BRINGUP}")
                if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
                    if [[ $(WLN_Bridge_Add_And_BringUp) == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_DNSMASQFUNC_EXIT}"
                    else
                        phase="${PHASE_DNSMASQFUNC_SERVICE_ENABLESTART}"
                    fi
                else
                    phase="${PHASE_DNSMASQFUNC_SERVICE_ENABLESTART}"
                fi
                ;;
            "${PHASE_DNSMASQFUNC_SERVICE_ENABLESTART}")
                if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
                    if [[ $(Service_Enable_And_Start "${WLN_DNSMASQ_SRV}" \
                            "${WLN_DNSMASQ_SERVICE_RETRY_MAX}") == false ]]; then
                        ret="${REJECTED}"
                    else
                        ret="${ACCEPTED}"
                    fi
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_DNSMASQFUNC_EXIT}"
                ;;
            "${PHASE_DNSMASQFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0; 
}

WLN_Dnsmasq_Conf_Create() {
    #Input args
    local istargetfpath=${1}
    local isintfstates_ctx_fpath=${2}

    #Define variables
	local bridge="${WLN_EMPTYSTRING}"
	local filecontent="${WLN_EMPTYSTRING}"
	local ip="${WLN_EMPTYSTRING}"
	local netmask="${WLN_EMPTYSTRING}"
	local networkdhcprangeip="${WLN_EMPTYSTRING}"
	local networkdhcpstartip="${WLN_EMPTYSTRING}"
	local networkdhcpendip="${WLN_EMPTYSTRING}"
	local ipv6="${WLN_EMPTYSTRING}"
	local cidrv6="${WLN_EMPTYSTRING}"
	local networkdhcprangeipv6="${WLN_EMPTYSTRING}"
	local networkdhcpstartipv6="${WLN_EMPTYSTRING}"
	local networkdhcpendipv6="${WLN_EMPTYSTRING}"
	local networkdomainname="${WLN_EMPTYSTRING}"



    #Retrieve data from file
	bridge=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__bridge")
	ip=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__ip")
	netmask=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__netmask")
	networkdhcpstartip=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__networkdhcpstartip")
	networkdhcpendip=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__networkdhcpendip")
	ipv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__ipv6")
	cidrv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__cidrv6")
	networkdhcpstartipv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__networkdhcpstartipv6")
	networkdhcpendipv6=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__networkdhcpendipv6")
	networkdomainname=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__networkdomainname")

    #Double-check and Update 'networkdhcpstartip', 'networkdhcpendip' (if necessary)
    networkdhcprangeip=$(Ipv4_Check_And_Generate_Iprange_Handler \
            "${ip}" \
            "${netmask}" \
            "${networkdhcpstartip}" \
            "${networkdhcpendip}")
    networkdhcpstartip=$(echo "${networkdhcprangeip}" | cut -d"," -f1)
    networkdhcpendip=$(echo "${networkdhcprangeip}" | cut -d"," -f2)

    #Double-check 'networkdhcpstartipv6', 'networkdhcpendipv6' (if necessary)
    networkdhcprangeipv6=$(Ipv6_Check_And_Generate_Iprange_Handler \
            "${ipv6}" \
            "${cidrv6}" \
            "${networkdhcpstartipv6}" \
            "${networkdhcpendipv6}")
    networkdhcpstartipv6=$(echo "${networkdhcprangeipv6}" | cut -d"," -f1)
    networkdhcpendipv6=$(echo "${networkdhcprangeipv6}" | cut -d"," -f2)



    #Generate config file
    filecontent="#---DNS configuration\n"
    filecontent+="port=${WLN_PORT_5553}\n"
    filecontent+="\n"

    if [[ -n "${networkdomainname}" ]]; then
        filecontent+="#---Domain options\n"
        filecontent+="domain-needed\n"
        filecontent+="domain=${networkdomainname}\n"
        filecontent+="\n"
    fi

    filecontent+="#---DHCP configuration\n"
    filecontent+="interface=${bridge}\n"
    filecontent+="dhcp-ignore=${ip}\n"
    filecontent+="dhcp-ignore=${ipv6}\n"
    filecontent+="dhcp-range=${networkdhcpstartip},"
        filecontent+="${networkdhcpendip},${netmask},${WLN_DNSMASQ_LEASETTIME}\n"
    filecontent+="dhcp-range=${networkdhcpstartipv6},"
        filecontent+="${networkdhcpendipv6},${cidrv6},${WLN_DNSMASQ_LEASETTIME}\n"
    # if [[ -n "${ip}" ]]; then
        filecontent+="dhcp-option=option:router,${ip}\n"
        filecontent+="dhcp-option=option:dns-server,${NET_GOOGLE_DNSV4_8888},${ip}\n"
    # else
    #     filecontent+="dhcp-option=option:dns-server,${NET_GOOGLE_DNSV4_8888}\n"
    # fi
    # if [[ -n "${ip}" ]]; then
        filecontent+="dhcp-option=option6:dns-server,${NET_GOOGLE_DNSV6_8888},${ipv6}\n"
    # else
    #     filecontent+="dhcp-option=option6:dns-server,${NET_GOOGLE_DNSV6_8888}\n"
    # fi

    filecontent+="\n"
    filecontent+="#---Other options\n"
    filecontent+="bogus-priv\n"
    filecontent+="strict-order\n"
    filecontent+="expand-hosts\n"
    filecontent+="bind-interfaces\n"
    filecontent+="enable-ra\n"
    filecontent+="dhcp-authoritative"

    #Remove 'dnsmasq.conf'
    if [[ $(RemoveFile "${istargetfpath}") == true ]]; then
        ret=true
    else
        ret=false
    fi

    #Write to file
    if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == true ]]; then
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}
