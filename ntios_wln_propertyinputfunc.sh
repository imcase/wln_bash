#!/bin/bash
#---FUNCTIONS
WLN_Property_Input_Handler() {
    #Input args
    bssmode=${1}
    dhcp_isenabled=${2} #only relevent for 'PL_WLN_BSS_MODE_INFRASTRUCTURE'
    dhcpv6_isenabled=${3}   #only relevent for 'PL_WLN_BSS_MODE_INFRASTRUCTURE'
    dns_isenabled=${4}  #only relevent for 'PL_WLN_BSS_MODE_INFRASTRUCTURE'
    dnsv6_isenabled=${5}    #only relevent for 'PL_WLN_BSS_MODE_INFRASTRUCTURE'
    ssid=${6} #only relevent for 'PL_WLN_BSS_MODE_INFRASTRUCTURE'
    phymode=${7}

    #---WLN Property Input
    wln_autoreconnectonboot=${YES}

    case "${bssmode}" in
        "${PL_WLN_BSS_MODE_INFRASTRUCTURE}")
            wln_gatewayintfset="${WLN_ETH1}"

            if [[ "${ssid}" == "vvh" ]]; then #used for 'ssid = vvh'
                wln_ip="172.16.1.119"
                wln_gatewayip="172.16.1.254"
                wln_ipv6="2001:172:16:1::119"
                wln_gatewayipv6="2001:172:16:1::254"
            else    #infra_ipchoice != WLN_VVH (used for 'ssid = hond en hond_5G')
                wln_ip="172.31.1.119"
                wln_gatewayip="172.31.1.254"
                wln_ipv6="2001:172:31:1::119"
                wln_gatewayipv6="2001:172:31:1::254"
            fi

            if [[ "${dhcp_isenabled}" == true ]]; then
                wln_dhcp=true
            else
                wln_dhcp=false
            fi
            if [[ "${dhcpv6_isenabled}" == true ]]; then
                wln_dhcpv6=true
            else
                wln_dhcpv6=false
            fi

            if [[ "${dns_isenabled}" == true ]]; then
                WLN_dns1="${wln_gatewayip}"
                WLN_dns2="${NET_GOOGLE_DNSV4_8888}"
            fi
            if [[ "${dnsv6_isenabled}" == true ]]; then
                WLN_dns1v6="${wln_gatewayipv6}"
                WLN_dns2v6="${NET_GOOGLE_DNSV6_8844}"
            fi

            wln_netmask="255.255.252.0"
            wln_netmaskv6="96"  #this means HostID is 32-bits
            ;;
        *)
            wln_ip="192.45.46.1"
            wln_netmask="255.255.255.0" #this means HostID is 8 bits
            wln_gatewayip=""
            wln_ipv6="2001:45:46::1"
            wln_netmaskv6="96"  #this means HostID is 32-bits
            wln_domain=$(IwDomainGet)
            
            #Let's assume that property 'wln_gatewayintfset' is NOT SET.
            #Then when GETTING the property 'gatewayintfset'value...
            #...with command 'wln.gatewayintfset',...
            #...the value is equal to the one stored in...
            #...structure-element 'WLN_intfstates_ctx__gatewayintf',...
            #...which is equal to 'WLN_ETH0'.
            wln_gatewayintfset="${PL_WLN_GATEWAY_INTFSET_UNSET}"
            wln_networkdhcpstartip="192.45.46.100"
            wln_networkdhcpendip="192.45.46.200"
            wln_networkdhcpstartipv6="2001:45:46::1"
            wln_networkdhcpendipv6="2001:45:46::ff"
            wln_networkdomainname="tibbo.com"   #also test WITHOUT DOMAIN-NAME!!!!
            wln_band="${phymode}" #this is the phymode of 'pl_wln_phy_modes'
            ;;
    esac

    #---Define variables
    local cidrprefix="${WLN_EMPTYSTRING}"
    local gatewayintfset="${WLN_EMPTYSTRING}"


    #---Update database
    #autoreconnectonboot
    if [[ -n "${wln_autoreconnectonboot}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__autoreconnectonboot" "${wln_autoreconnectonboot}"
    fi

    #IPv4 DHCP
    if [[ -n "${wln_dhcp}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dhcp" "${wln_dhcp}"
    fi

    #IPv4 Address
    if [[ -n "${wln_ip}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__ip" "${wln_ip}"
    fi

    #IPv4 Netmask
    if [[ -n "${wln_netmask}" ]]; then
        # if [[ -n "${wln_ip}" ]]; then
            WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__netmask" "${wln_netmask}"

            cidrprefix=$(NetMaskV4_DdmaskToCidrprefix "${wln_netmask}")
            WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__cidr" "${cidrprefix}"
        # fi
    fi

    #IPv4 Gateway
    if [[ -n "${wln_gatewayip}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__gatewayip" "${wln_gatewayip}"
    fi

    #IPv4 Dns1
    if [[ -n "${WLN_dns1}" ]]; then #not an Empty String
        #Check if 'WLN_dns1' is already in use by 'WLN_intfstates_ctx__dns2'
        if [[ "${WLN_dns1}" != $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2") ]]; then #not in use
            WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1" "${WLN_dns1}"
        # else    #in use
        #      if [[ $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2") != "${NET_GOOGLE_DNSV4_8888}" ]]; then
        #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1" "${NET_GOOGLE_DNSV6_8888}"
        #     else
        #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1" "${NET_GOOGLE_DNSV4_8844}"
        #     fi
        fi
    # else    #an Empty String
    #     if [[ $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2") != "${NET_GOOGLE_DNSV4_8888}" ]] && \
    #             [[ "${WLN_dns2}" != "${NET_GOOGLE_DNSV4_8888}" ]]; then
    #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1" "${NET_GOOGLE_DNSV4_8888}"
    #     else
    #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1" "${NET_GOOGLE_DNSV4_8844}"
    #     fi
    fi

    #IPv4 Dns2
    if [[ -n "${WLN_dns2}" ]]; then #not an Empty String
        #Check if 'WLN_dns2' is already in use by 'WLN_intfstates_ctx__dns1'
        if [[ "${WLN_dns2}" != $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1") ]]; then #not in use
            WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2" "${WLN_dns2}"
        # else    #in use
        #      if [[ $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1") != "${NET_GOOGLE_DNSV4_8888}" ]]; then
        #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2" "${NET_GOOGLE_DNSV4_8888}"
        #     else
        #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2" "${NET_GOOGLE_DNSV4_8844}"
        #     fi
        fi
    # else    #an Empty String
    #     if [[ $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1") != "${NET_GOOGLE_DNSV4_8888}" ]] && \
    #             [[ "${WLN_dns1}" != "${NET_GOOGLE_DNSV4_8888}" ]]; then
    #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2" "${NET_GOOGLE_DNSV4_8888}"
    #     else
    #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2" "${NET_GOOGLE_DNSV4_8844}"
    #     fi
    fi

    #IPv6 DHCP
    if [[ -n "${wln_dhcpv6}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dhcpv6" "${wln_dhcpv6}"
    fi

    #IPv6 Address
    if [[ -n "${wln_ipv6}" ]]; then
        #Write data to file
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__ipv6" "${wln_ipv6}"
    fi

    #IPv6 Netmask
    if [[ -n "${wln_netmaskv6}" ]]; then
        # if [[ -n "${wln_ipv6}" ]]; then
            WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__cidrv6" "${wln_netmaskv6}"
        # fi
    fi

    #IPv6 Gateway
    if [[ -n "${wln_gatewayipv6}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__gatewayipv6" "${wln_gatewayipv6}"
    fi

    #IPv6 Dns1
    if [[ -n "${WLN_dns1v6}" ]]; then #not an Empty String
        #Check if 'WLN_dns1v6' is already in use by 'WLN_intfstates_ctx__dns2v6'
        if [[ "${WLN_dns1v6}" != $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2v6") ]]; then  #not in use
            WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1v6" "${WLN_dns1v6}"
        # else    #in use
        #      if [[ $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2v6") != "${NET_GOOGLE_DNSV6_8888}" ]]; then
        #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1v6" "${NET_GOOGLE_DNSV6_8888}"
        #     else
        #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1v6" "${NET_GOOGLE_DNSV6_8844}"
        #     fi
        fi
    # else    #an Empty String
    #     if [[ $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2v6") != "${NET_GOOGLE_DNSV6_8888}" ]] && \
    #             [[ "${WLN_dns2v6}" != "${NET_GOOGLE_DNSV6_8888}" ]]; then
    #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1v6" "${NET_GOOGLE_DNSV6_8888}"
    #     else
    #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1v6" "${NET_GOOGLE_DNSV6_8844}"
    #     fi
    fi

    #IPv6 Dns2
    if [[ -n "${WLN_dns2v6}" ]]; then #not an Empty String
        #Check if 'WLN_dns2v6' is already in use by 'WLN_intfstates_ctx__dns1v6'
        if [[ "${WLN_dns2v6}" != $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1v6") ]]; then  #not in use
            WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2v6" "${WLN_dns2v6}"
        # else    #in use
        #      if [[ $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1v6") != "${NET_GOOGLE_DNSV6_8888}" ]]; then
        #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2v6" "${NET_GOOGLE_DNSV6_8888}"
        #     else
        #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2v6" "${NET_GOOGLE_DNSV6_8844}"
        #     fi
        fi
    # else    #an Empty String
    #     if [[ $(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns1v6") != "${NET_GOOGLE_DNSV6_8888}" ]] && \
    #             [[ "${WLN_dns1v6}" != "${NET_GOOGLE_DNSV6_8888}" ]]; then
    #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2v6" "${NET_GOOGLE_DNSV6_8888}"
    #     else
    #         WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__dns2v6" "${NET_GOOGLE_DNSV6_8844}"
    #     fi
    fi



    #Domain-code
    if [[ -n "${wln_domain}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__domaincode" "${wln_domain}"
    fi



    #Gateway Interface (eth0 or eth1)
    gatewayintfset=$(GatewayIntfValidation "${wln_gatewayintfset}")
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__gatewayintf" "${gatewayintfset}"
    


    #Dhcp IPv4-range
    if [[ -n "${wln_networkdhcpstartip}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__networkdhcpstartip" "${wln_networkdhcpstartip}"
    fi
    if [[ -n "${wln_networkdhcpendip}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__networkdhcpendip" "${wln_networkdhcpendip}"
    fi

    #Dhcp IPv6-range
    if [[ -n "${wln_networkdhcpstartipv6}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__networkdhcpstartipv6" "${wln_networkdhcpstartipv6}"
    fi
    if [[ -n "${wln_networkdhcpendipv6}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__networkdhcpendipv6" "${wln_networkdhcpendipv6}"
    fi



    #Domain-name
    if [[ -n "${wln_networkdomainname}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__networkdomainname" "${wln_networkdomainname}"
    fi



    #phy-mode
    if [[ -n "${wln_band}" ]]; then
        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__phymode" "${wln_band}"
    fi
}

GatewayIntfValidation() {
    #Input args
    local isGatewayIntf=${1}

    #Define constants
    local PHASE_PROPERTYINPUTFUNC_DAISYCHAIN_IS_SET_CHECK=0
    local PHASE_PROPERTYINPUTFUNC_GATEWAYINTF_IS_SET_CHECK=1
    local PHASE_PROPERTYINPUTFUNC_GATEWAYINTF_TRY_ETH0=2
    local PHASE_PROPERTYINPUTFUNC_GATEWAYINTF_TRY_ETH1=3
    local PHASE_PROPERTYINPUTFUNC_EXIT=4

    #Define variables
    local phase="${PHASE_PROPERTYINPUTFUNC_DAISYCHAIN_IS_SET_CHECK}"
    local ret="${isGatewayIntf}"   #default gateway-interface is 'eth0'

    #Start phase
    #--------------------------------------------------------------------
    #In case 'isGatewayIntf = PL_WLN_GATEWAY_INTFSET_UNSET'
    #   1. first ping 8.8.8.8 via interface 'eth0'
    #   2. if (1.) fails, then ping to 8.8.8.8 via interface 'eth1'
    #   3. if (1. and 2.) fail, then 'ret = eth0'
    #--------------------------------------------------------------------
    while true
    do
        case "${phase}" in
            "${PHASE_PROPERTYINPUTFUNC_DAISYCHAIN_IS_SET_CHECK}")
                if [[ $(DaisyChain_IsEnabled) == true ]]; then
                    ret="${WLN_ETH0}"

                    phase="${PHASE_PROPERTYINPUTFUNC_EXIT}"
                else
                    phase="${PHASE_PROPERTYINPUTFUNC_GATEWAYINTF_IS_SET_CHECK}"
                fi
                ;;
            "${PHASE_PROPERTYINPUTFUNC_GATEWAYINTF_IS_SET_CHECK}")
                if [[ "${isGatewayIntf}" != "${PL_WLN_GATEWAY_INTFSET_UNSET}" ]] && \
                        [[ "${isGatewayIntf}" != "${WLM_EMPTYSTRING}" ]]; then
                    ret="${isGatewayIntf}"

                    phase="${PHASE_PROPERTYINPUTFUNC_EXIT}"
                else
                    phase="${PHASE_PROPERTYINPUTFUNC_GATEWAYINTF_TRY_ETH0}"
                fi
                ;;
            "${PHASE_PROPERTYINPUTFUNC_GATEWAYINTF_TRY_ETH0}")
                if [[ $(Ping "${WLN_ETH0}" "${NET_GOOGLE_DNSV4_8888}" "${NET_PING_COUNT}" "${NET_PING_DEADLINE}") ]]; then
                    ret="${WLN_ETH0}"

                    phase="${PHASE_PROPERTYINPUTFUNC_EXIT}"
                else
                    phase="${PHASE_PROPERTYINPUTFUNC_GATEWAYINTF_TRY_ETH1}"
                fi
                ;;
            "${PHASE_PROPERTYINPUTFUNC_GATEWAYINTF_TRY_ETH1}")
                if [[ $(Ping "${WLN_ETH1}" "${NET_GOOGLE_DNSV4_8888}" "${NET_PING_COUNT}" "${NET_PING_DEADLINE}") ]]; then
                    ret="${WLN_ETH1}"
                else
                    ret="${WLN_ETH0}"
                fi

                phase="${PHASE_PROPERTYINPUTFUNC_EXIT}"
                ;;
            "${PHASE_PROPERTYINPUTFUNC_EXIT}")
                break
                ;;
        esac
    done


    #Output
    echo "${ret}"

    return 0;
}
