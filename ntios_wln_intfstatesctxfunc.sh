#!/bin/bash
#---FUNCTIONS
WLN_IntfStates_Ctx_Init_Handler() {
    #Define variables
    local domaincode="${WLN_EMPTYSTRING}"
    local networkdhcprangeip="${WLN_EMPTYSTRING}"
    local networkdhcprangeipv6="${WLN_EMPTYSTRING}"
    local intfstates_ctx_content="${WLN_EMPTYSTRING}"
    local ret="${WLN_EMPTYSTRING}"

    #Initialization
    WLN_intfstates_ctx__intf="${WLN_WLAN0}"
    WLN_intfstates_ctx__associationstate="${PL_WLN_NOT_ASSOCIATED}"
    WLN_intfstates_ctx__autoreconnectonboot="${YES}"
    WLN_intfstates_ctx__bridge="${WLN_BR0}"
    WLN_intfstates_ctx__bssid="${WLN_EMPTYSTRING}"
    WLN_intfstates_ctx__bssmode="${PL_WLN_BSS_MODE_ROUTER}"
    WLN_intfstates_ctx__cast="${PL_WLN_WPA_CAST_MULTICAST}"
    WLN_intfstates_ctx__channel=${WLN_HOSTAPD_CHANNEL_0}
    WLN_intfstates_ctx__cidr="${WLN_IPV4_CIDR_PREFIX_24}"
    WLN_intfstates_ctx__cidrv6="${WLN_IPV6_CIDR_DEFAULT}"
    WLN_intfstates_ctx__dhcp="${NO}"
    WLN_intfstates_ctx__dhcpv6="${NO}"
    WLN_intfstates_ctx__dns1="${NET_GOOGLE_DNSV4_8888}"
    WLN_intfstates_ctx__dns1v6=${NET_GOOGLE_DNSV6_8888} 
    WLN_intfstates_ctx__dns2="${NET_GOOGLE_DNSV4_8844}"
    WLN_intfstates_ctx__dns2v6=${NET_GOOGLE_DNSV6_8844} 

    domaincode=$(IwDomainGet)

    if [[ "${domaincode}" == "${WLN_DOMAINCODE_00}" ]]; then
        domaincode=$(CurlDomainGet)
    fi
    WLN_intfstates_ctx__domaincode="${domaincode}"
    WLN_intfstates_ctx__driver="${WLN_HOSTAPD_DRIVER}"
    WLN_intfstates_ctx__enabled="${NO}"
    WLN_intfstates_ctx__gatewayintf="${PL_WLN_GATEWAY_INTFSET_UNSET}"
    WLN_intfstates_ctx__gatewayip="${WLN_IPV4_GATEWAY_DEFAULT}"
    WLN_intfstates_ctx__gatewayipv6="${WLN_IPV6_GATEWAY_DEFAULT}"
    WLN_intfstates_ctx__hwmode="${WLN_HOSTAPD_HWMODE_G}"
    WLN_intfstates_ctx__ieee80211ac="${WLN_NUM_0}"
    WLN_intfstates_ctx__ieee80211d="${WLN_NUM_0}" #DFS
    WLN_intfstates_ctx__ieee80211h="${WLN_NUM_0}" #DFS
    WLN_intfstates_ctx__ieee80211n="${WLN_NUM_1}"
    WLN_intfstates_ctx__ip="${WLN_IPV4_DEFAULT}"
    WLN_intfstates_ctx__ipv6="${WLN_IPV6_DEFAULT}"
    WLN_intfstates_ctx__netmask="${WLN_IPV4_NETMASK_DEFAULT}"

    networkdhcprangeip=$(Ipv4_Check_And_Generate_Iprange_Handler \
            "${WLN_intfstates_ctx__ip}" \
            "${WLN_intfstates_ctx__netmask}" \
            "${WLN_EMPTYSTRING}" \
            "${WLN_EMPTYSTRING}")
    WLN_intfstates_ctx__networkdhcpstartip=$(echo "${networkdhcprangeip}" | cut -d"," -f1)
    WLN_intfstates_ctx__networkdhcpendip=$(echo "${networkdhcprangeip}" | cut -d"," -f2)
    networkdhcprangeipv6=$(Ipv6_Check_And_Generate_Iprange_Handler \
            "${WLN_intfstates_ctx__ipv6}" \
            "${WLN_intfstates_ctx__cidrv6}" \
            "${WLN_EMPTYSTRING}" \
            "${WLN_EMPTYSTRING}")
    WLN_intfstates_ctx__networkdhcpendipv6=$(echo "${networkdhcprangeipv6}" | cut -d"," -f2)
    WLN_intfstates_ctx__networkdhcpstartipv6=$(echo "${networkdhcprangeipv6}" | cut -d"," -f1)
    WLN_intfstates_ctx__networkdomainname="${WLN_EMPTYSTRING}"
    WLN_intfstates_ctx__phymode="${PL_WLN_PHY_MODE_2G}"
    WLN_intfstates_ctx__scanresultssid="${WLN_EMPTYSTRING}"
    WLN_intfstates_ctx__scanresultbssid="${WLN_EMPTYSTRING}"
    WLN_intfstates_ctx__scanresultbssmode=${PL_WLN_BSS_MODE_UNKNOWN}
    WLN_intfstates_ctx__scanresultchannel=0
    WLN_intfstates_ctx__scanresultrssi=0
    WLN_intfstates_ctx__scanresultwpainfo=${WLN_EMPTYSTRING}
    WLN_intfstates_ctx__setwep=${UNSET}
    WLN_intfstates_ctx__setwpa="${UNSET}"
    WLN_intfstates_ctx__ssid="${WLN_HOSTAPD_SSID_RT_GN}"
    WLN_intfstates_ctx__ssidisvisible="${YES}"
    WLN_intfstates_ctx__updatetimestamp="${WLN_NUM_0}"
    WLN_intfstates_ctx__wepkey="${WLN_EMPTYSTRING}"
    WLN_intfstates_ctx__wepmode="${PL_WLN_WEP_MODE_DISABLED}"
    WLN_intfstates_ctx__wpaalgorithm="${PL_WLN_WPA_ALGORITHM_AES}"
    WLN_intfstates_ctx__wpakey="${WLN_HOSTAPD_WPA_PASSPHRASE_DEFAULT}"
    WLN_intfstates_ctx__wpamode="${PL_WLN_WPA_WPA2_PSK}"



    #Generate data to-be-written to file
    intfstates_ctx_content="WLN_intfstates_ctx__intf:"${WLN_intfstates_ctx__intf}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__associationstate:"${WLN_intfstates_ctx__associationstate}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__autoreconnectonboot:"${WLN_intfstates_ctx__autoreconnectonboot}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__bridge:"${WLN_intfstates_ctx__bridge}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__bssid:"${WLN_intfstates_ctx__bssid}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__bssmode:"${WLN_intfstates_ctx__bssmode}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__cast:"${WLN_intfstates_ctx__cast}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__channel:"${WLN_intfstates_ctx__channel}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__cidr:"${WLN_intfstates_ctx__cidr}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__cidrv6:"${WLN_intfstates_ctx__cidrv6}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__dhcp:"${WLN_intfstates_ctx__dhcp}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__dhcpv6:"${WLN_intfstates_ctx__dhcpv6}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__dns1:"${WLN_intfstates_ctx__dns1}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__dns1v6:"${WLN_intfstates_ctx__dns1v6}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__dns2:"${WLN_intfstates_ctx__dns2}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__dns2v6:"${WLN_intfstates_ctx__dns2v6}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__domaincode:"${WLN_intfstates_ctx__domaincode}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__driver:"${WLN_intfstates_ctx__driver}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__enabled:"${WLN_intfstates_ctx__enabled}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__gatewayintf:"${WLN_intfstates_ctx__gatewayintf}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__gatewayip:"${WLN_intfstates_ctx__gatewayip}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__gatewayipv6:"${WLN_intfstates_ctx__gatewayipv6}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__hwmode:"${WLN_intfstates_ctx__hwmode}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__ieee80211ac:"${WLN_intfstates_ctx__ieee80211ac}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__ieee80211d:"${WLN_intfstates_ctx__ieee80211d}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__ieee80211h:"${WLN_intfstates_ctx__ieee80211h}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__ieee80211n:"${WLN_intfstates_ctx__ieee80211n}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__ip:"${WLN_intfstates_ctx__ip}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__ipv6:"${WLN_intfstates_ctx__ipv6}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__netmask:"${WLN_intfstates_ctx__netmask}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__networkdhcpendip:"${WLN_intfstates_ctx__networkdhcpendip}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__networkdhcpendipv6:"${WLN_intfstates_ctx__networkdhcpendipv6}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__networkdhcpstartip:"${WLN_intfstates_ctx__networkdhcpstartip}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__networkdhcpstartipv6:"${WLN_intfstates_ctx__networkdhcpstartipv6}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__networkdomainname:"${WLN_intfstates_ctx__networkdomainname}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__phymode:"${WLN_intfstates_ctx__phymode}"\n"
    
    intfstates_ctx_content+="WLN_intfstates_ctx__scanresultssid:"${WLN_intfstates_ctx__scanresultssid}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__scanresultbssid:"${WLN_intfstates_ctx__scanresultbssid}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__scanresultbssmode:"${WLN_intfstates_ctx__scanresultbssmode}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__scanresultchannel:"${WLN_intfstates_ctx__scanresultchannel}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__scanresultrssi:"${WLN_intfstates_ctx__scanresultrssi}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__scanresultwpainfo:"${WLN_intfstates_ctx__scanresultwpainfo}"\n"

    intfstates_ctx_content+="WLN_intfstates_ctx__setwep:"${WLN_intfstates_ctx__setwep}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__setwpa:"${WLN_intfstates_ctx__setwpa}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__ssid:"${WLN_intfstates_ctx__ssid}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__ssidisvisible:"${WLN_intfstates_ctx__ssidisvisible}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__updatetimestamp:"${WLN_intfstates_ctx__updatetimestamp}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__wepkey:"${WLN_intfstates_ctx__wepkey}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__wepmode:"${WLN_intfstates_ctx__wepmode}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__wpaalgorithm:"${WLN_intfstates_ctx__wpaalgorithm}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__wpakey:"${WLN_intfstates_ctx__wpakey}"\n"
    intfstates_ctx_content+="WLN_intfstates_ctx__wpamode:"${WLN_intfstates_ctx__wpamode}""



    #Make directory
    if [[ ! -d "${WLN_ETC_TIBBO_DATA_WLN_DIR}" ]]; then
        ret=$(Mkdir "${WLN_ETC_TIBBO_DATA_WLN_DIR}")
    fi

    #Remove file
    if [[ -f "${WLN_INTFSTATES_CTX_DAT_FPATH}" ]]; then
        ret=$(RemoveFile "${WLN_INTFSTATES_CTX_DAT_FPATH}")
    fi

    #Write to file
    #Remark:
    #   variable 'ret' is used here to suppress the 'echo "${ret}"' of the function.
    #intfstates_ctx.dat (this is the CURRENT structure content)
    ret=$(WriteToFile "${WLN_INTFSTATES_CTX_DAT_FPATH}" "${intfstates_ctx_content}" "true")
    #intfstates_ctx.init.dat (this is the INITIAL structure content)
    ret=$(WriteToFile "${WLN_INTFSTATES_CTX_INIT_DAT_FPATH}" "${intfstates_ctx_content}" "true")
}

WLN_intfstates_ctx_retrievedata() {
    #-------------------------------------------------
    #Input args
    local istargetfpath=${1}
    local isreference=${2}

    #Define variables
    local ret="${WLN_EMPTYSTRING}"

    #Retrieve data based on 'isreference'
    ret=$(cat "${istargetfpath}" | grep -w "${isreference}" | cut -d":" -f2-)

    #Output
    echo "${ret}"
}
WLN_intfstates_ctx_writedata() {
    #-------------------------------------------------
    #Input args
    local istargetfpath=${1}
    local isreference=${2}
    local isdata=${3}

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local linenum=0
    local nextlinenum=0
    local reference_data="${WLN_EMPTYSTRING}"
    local printmsg="${WLN_EMPTYSTRING}"

    #Find 'isreference' and get line-number
    linenum=$(grep -wFn "${isreference}" ${istargetfpath} | cut -d":" -f1)

    #Combine 'isreference' and 'isdata'
    reference_data="${isreference}:${isdata}"

    #Insert 'reference_data' at 'linenum'
    sudo sed -i "${linenum}i ${reference_data}" ${istargetfpath}; exitcode=$?

    #Update 'isdata'
    if [[ -z "${isdata}" ]]; then
        isdata="${WLN_PRINTMSG_EMPTYSTRING}"
    fi

    #Get 'printmsg' based on 'exitcode'
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: "
        printmsg+="Insert ${WLN_LIGHTGREY}${isreference}${WLN_RESETCOLOR}:${WLN_YELLOW}${isdata}${WLN_RESETCOLOR} "
        printmsg+="in file ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: "
        printmsg+="${WLN_PRINTMSG_DONE}"
    else
        printmsg="${WLN_PRINTMSG_STATUS}: "
        printmsg+="Insert ${WLN_LIGHTGREY}${isreference}${WLN_RESETCOLOR}:${WLN_YELLOW}${isdata}${WLN_RESETCOLOR} "
        printmsg+="in file ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: "
        printmsg+="${WLN_PRINTMSG_FAILED}"
    fi

    #Print
    DebugPrint "${printmsg}"


    #Get 'nextlinenum'
    nextlinenum=$((linenum + 1))

    #Delete 'nextlinenum'
    sudo sed -i "${nextlinenum}d" ${istargetfpath}

    #Get 'printmsg' based on 'exitcode'
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: "
        printmsg+="Delete line ${WLN_LIGHTGREY}${nextlinenum}${WLN_RESETCOLOR} "
        printmsg+="in file ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: "
        printmsg+="${WLN_PRINTMSG_DONE}"
    else
        printmsg="${WLN_PRINTMSG_STATUS}: "
        printmsg+="Delete line ${WLN_LIGHTGREY}${nextlinenum}${WLN_RESETCOLOR} "
        printmsg+="in file ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: "
        printmsg+="${WLN_PRINTMSG_FAILED}"
    fi

    #Print
    DebugPrint "${printmsg}"
}
