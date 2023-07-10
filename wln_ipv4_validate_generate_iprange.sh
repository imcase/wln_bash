#!/bin/bash

#---CONSTANTS
# shellcheck disable=SC2034
WLN_EMPTYSTRING=""

WLN_DOT="."

WLN_IPV4_MIN=0
WLN_IPV4_MAX=255
WLN_IPV4_NUMOF_DOTS_MAX=3
WLN_IPV4_NUMOF_SEGMENTS_MAX=4

WLN_IPV4_CIDR_BITS_PER_SEGMENT=8
WLN_IPV4_CIDR_PREFIX_24=24
WLN_IPV4_CIDR_PREFIX_31=31
WLN_IPV4_CIDR_PREFIX_32=32
WLN_IPV4_SUBNET_LOWERBOUND_MINVAL=1
WLN_IPV4_SUBNET_UPPERBOUND_MAXVAL=254



#---GENERAL FUNCTIONS



#---IPV4 SUPPORT FUNCTIONS
NetMaskV4_DdmaskToCidrprefix() {
    #Input args
    local netmask=${1}
    
    #Convert to Bit-mask
    local cidrprefix=0
    local dot_ctr=0
    local netmask_ddval=0
    local netmask_tmp=${netmask}
    local ret=0
    
    
    while [[ ${dot_ctr} -le  ${WLN_IPV4_NUMOF_DOTS_MAX} ]]
    do
        #Get dotted-decimal value BEFORE the 1st dot    
        netmask_ddval=${netmask_tmp%%.*}
      
        #Convert dotted-decimal to cidr
        cidrprefix=$(NetMaskV4_DdvalToCidr "${netmask_ddval}")
        
        #Accumulate 'cidrprefix' with 'ret'
        ret=$(( ret + cidrprefix ))
        
        #Get dotted-decimal value AFTER the 1st dot
        netmask_tmp=${netmask_tmp#*.}
    
        #Increment 'dot_ctr' by 1
        dot_ctr=$(( dot_ctr + 1 ))
    done
    
    #Output
    echo "${ret}"
    
    return 0;
}
NetMaskV4_DdvalToCidr() {
    #Input args
    local ddval=${1}
    
    #Define variables
    local ret=0
    
    #Conversion
    case "${ddval}" in
        255)
            ret=8
            ;;
        254)
            ret=7
            ;;
        252)
            ret=6
            ;;
        248)
            ret=5
            ;;
        240)
            ret=4
            ;;
        224)
            ret=3
            ;;
        192)
            ret=2
            ;;
        128)
            ret=1
            ;;
        0)
            ret=0
            ;;
    esac
    
    #Output
    echo "${ret}"
    
    return 0;

}

NetMaskV4_CidrprefixToDdmask() {
    #Input args
    local cidrprefix=${1}
    
    #Define variables
    local cidr=0
    local cidrprefix_tmp=${cidrprefix}
    local dot_ctr=0
    local netmask=${WLN_EMPTYSTRING}
    local netmask_ddval=${WLN_EMPTYSTRING}
    
    #Loop and everytime take a piece from 'cidrprefix'.
    while [[ ${dot_ctr} -le  ${WLN_IPV4_NUMOF_DOTS_MAX} ]]
    do
        #Determine the 'cidr' for 1 segment
        if [[ ${cidrprefix_tmp} -eq 0 ]]; then
            cidr=0
        elif [[ ${cidrprefix_tmp} -lt ${WLN_IPV4_CIDR_BITS_PER_SEGMENT} ]]; then
            cidr=${cidrprefix_tmp}
            
            cidrprefix_tmp=0
        else
            cidr=${WLN_IPV4_CIDR_BITS_PER_SEGMENT}
        
            cidrprefix_tmp=$(( cidrprefix_tmp - WLN_IPV4_CIDR_BITS_PER_SEGMENT ))
        fi
        
        #Get the netmask of 1 segment
        netmask_ddval=$(NetMaskV4_CidrToDdval "${cidr}")
        
        #Add/append 'netmask_ddval' to 'netmask'
        if [[ ${netmask} == "${WLN_EMPTYSTRING}" ]]; then
            netmask="${netmask_ddval}"
        else
            netmask="${netmask}.${netmask_ddval}"
        fi
        
        #Increment 'dot_ctr' by 1
        dot_ctr=$(( dot_ctr + 1 ))
    done
    
    #Output
    echo "${netmask}"
    
    return 0;
}
NetMaskV4_CidrToDdval() {
    #Input args
    local cidr=${1}
    
    #Define variables
    local ret=0
    
    #Conversion
    case "${cidr}" in
        8)
            ret=255
            ;;
        7)
            ret=254
            ;;
        6)
            ret=252
            ;;
        5)
            ret=248
            ;;
        4)
            ret=240
            ;;
        3)
            ret=224
            ;;
        2)
            ret=192
            ;;
        1)
            ret=128
            ;;
        0)
            ret=0
            ;;
    esac
    
    #Output
    echo "${ret}"
    
    return 0;
}



#---IPV4 MAIN FUNCTIONS
IPv4_Get_Subnet_Data() {
    #Input args
    local ipaddr=${1}
    local netmask=${2}
    
    #Define variables
    local ipaddr_tmp=${ipaddr}
    local netmask_tmp=${netmask}

    local ipaddr_ddval=${WLN_EMPTYSTRING}
    local netmask_ddval=${WLN_EMPTYSTRING}
    local subnet_networkidddval=${WLN_EMPTYSTRING}
    local subnet_lowerbound_ddval=${WLN_EMPTYSTRING}
    local subnet_upperbound_ddval=${WLN_EMPTYSTRING}

    local subnet_lowerbound_to_upperbound_range=0
    local subnet_networkid="${WLN_EMPTYSTRING}"
    local subnet_lowerbound="${WLN_EMPTYSTRING}"
    local subnet_upperbound="${WLN_EMPTYSTRING}"
    
    local cidrprefix=0
    local dot_ctr=0


    #------------------
    # subnet_networkid
    #------------------
    while [[ ${dot_ctr} -le ${WLN_IPV4_NUMOF_DOTS_MAX} ]]
    do
        #Get part before dot (.)   
        ipaddr_ddval=${ipaddr_tmp%%.*}
        netmask_ddval=${netmask_tmp%%.*}
      
        #Convert dotted-decimal to cidr
        subnet_networkid_ddval=$(( ipaddr_ddval & netmask_ddval ))
        
        #Update 'subnet_networkid'
        if [[ ${subnet_networkid} == "${WLN_EMPTYSTRING}" ]]; then
            #Add the first networkid-dotted-decimal value
            subnet_networkid="${subnet_networkid_ddval}"
        else
            #Append the rest of the  networkid-dotted-decimal values
            subnet_networkid="${subnet_networkid}.${subnet_networkid_ddval}"
        fi
        
        #Update 'subnet_lowerbound' and 'subnet_upperbound'
        if [[ ${netmask_ddval} -eq ${WLN_IPV4_MAX} ]]; then #netmask_ddval = 255
            subnet_lowerbound_ddval="${subnet_networkid_ddval}"
            subnet_upperbound_ddval="${subnet_networkid_ddval}"
        else
            #Get the 'subnet_lowerbound_to_upperbound_range'
            #Remark:
            #   This is actually the difference between...
            #   ...the 'lowerbound' and 'upperbound'.
            #   Example:
            #           lowerbound = 192.168.  0.  0
            #                         |   |    |   |
            #           upperbound = 192.168.128.255
            #       In this example, for each loop-cycle that is the difference between:
            #       192 - 192 = 0
            #       168 - 168 = 0
            #       128 -   0 = 128
            #       255 -   0 = 255
            #
            subnet_lowerbound_to_upperbound_range=$(( WLN_IPV4_MAX - netmask_ddval ))
            
            #Determine the 'subnet_lowerbound_ddval' and 'subnet_upperbound_ddval'
            if [[ ${dot_ctr} -lt ${WLN_IPV4_NUMOF_DOTS_MAX} ]]; then    #not the last dotted-decimal
                subnet_lowerbound_ddval=${subnet_networkid_ddval}
                subnet_upperbound_ddval=$(( subnet_networkid_ddval + subnet_lowerbound_to_upperbound_range ))
            else    #the last dotted-decimal
                subnet_lowerbound_ddval=$(( subnet_networkid_ddval + 1 ))
                subnet_upperbound_ddval=$(( (subnet_networkid_ddval + subnet_lowerbound_to_upperbound_range) -1 ))
            fi
        fi

        if [[ ${subnet_lowerbound} == "${WLN_EMPTYSTRING}" ]]; then
            #Add the first networkid-dotted-decimal value
            subnet_lowerbound="${subnet_lowerbound_ddval}"
        else    #netmask_ddval< 255
            #Append the rest of the  networkid-dotted-decimal values
            subnet_lowerbound="${subnet_lowerbound}.${subnet_lowerbound_ddval}"
        fi

        if [[ ${subnet_upperbound} == "${WLN_EMPTYSTRING}" ]]; then
            #Add the first networkid-dotted-decimal value
            subnet_upperbound="${subnet_upperbound_ddval}"
        else
            #Append the rest of the  networkid-dotted-decimal values
            subnet_upperbound="${subnet_upperbound}.${subnet_upperbound_ddval}"
        fi

        #Update variables:
        #   Get dotted-decimal value AFTER the 1st dot.
        ipaddr_tmp=${ipaddr_tmp#*.}
        netmask_tmp=${netmask_tmp#*.}
        
        #Increment 'dot_ctr' by 1
        dot_ctr=$(( dot_ctr + 1 ))
    done
    
    
    
    #Get convert 'netmask' to 'cidrprefix'
    cidrprefix=$(NetMaskV4_DdvalToCidr "${netmask}")
    
    #SPECIAL CASE: Check if 'cidrprefix = 31 or 32'
    if [[ ${cidrprefix} -eq ${WLN_IPV4_CIDR_PREFIX_32} ]] || \
            [[ ${cidrprefix} -eq ${WLN_IPV4_CIDR_PREFIX_31} ]]; then
        subnet_lowerbound=${WLN_EMPTYSTRING}
        subnet_upperbound=${WLN_EMPTYSTRING}
        
        echo "${subnet_networkid},${subnet_lowerbound},${subnet_upperbound}"
        
        return 0;
    fi



    #Output
    echo "${subnet_networkid},${subnet_lowerbound},${subnet_upperbound}"
    
    return 0;
}

Ipv4_Check_And_Generate_Iprange_Handler() {
    #Input args
    local ipaddr=${1}
    local netmask=${2}
    local iprange_lowerbound=${3}
    local iprange_upperbound=${4}
    
    #Define and initialize variables
    local PHASE_START=0
    local PHASE_CHECK_LOWERBOUND=1
    local PHASE_CHECK_UPPERBOUND=2
    local PHASE_COMPARE_LOWERBOUND_UPPERBOUND=3
    local PHASE_EXIT=4
    
    local subnet_result=${WLN_EMPTYSTRING}
    local subnet_networkid=${WLN_EMPTYSTRING}
    local subnet_lowerbound=${WLN_EMPTYSTRING}
    local subnet_upperbound=${WLN_EMPTYSTRING}

    local ret=${WLN_EMPTYSTRING}

    local check_result=false

    local phase=${PHASE_START}

    #Start phase-loop
    while true
    do
        case "${phase}" in
            "${PHASE_START}")
                #Update variables
                ret="${iprange_lowerbound},${iprange_upperbound}"
        
                #Get Subnet NetworkID, Lowerbound and Upperbound
                subnet_result=$(IPv4_Get_Subnet_Data "${ipaddr}" "${netmask}")
                subnet_networkid=$(echo "${subnet_result}" | cut -d"," -f1)
                subnet_lowerbound=$(echo "${subnet_result}" | cut -d"," -f2)
                subnet_upperbound=$(echo "${subnet_result}" | cut -d"," -f3)

                #Goto next-phase
                phase=${PHASE_CHECK_LOWERBOUND}
                ;;
            "${PHASE_CHECK_LOWERBOUND}")
                #Check if 'iprange_lowerbound' is part-of 'ipaddr/netmask'
                check_result=$(Ipv4_CheckIf_Ip_Is_PartOf_Specified_IpRange \
                        "${iprange_lowerbound}" \
                        "${subnet_lowerbound}" \
                        "${subnet_upperbound}")

                #Counteract if 'check_result = false'
                if [[ ${check_result} == false ]]; then
                    #Validate and Generate IP-ranges
                    ret=$(Ipv4_Generate_Iprange "${netmask}" "${subnet_lowerbound}" "${subnet_upperbound}")
                    
                    #Goto next-phase
                    phase=${PHASE_EXIT}
                else
                    #Goto next-phase
                    phase=${PHASE_CHECK_UPPERBOUND}
                fi
                ;;
            "${PHASE_CHECK_UPPERBOUND}")
                #Check if 'iprange_upperbound' is part-of 'ipaddr/netmask'
                check_result=$(Ipv4_CheckIf_Ip_Is_PartOf_Specified_IpRange \
                        "${iprange_upperbound}" \
                        "${subnet_lowerbound}" \
                        "${subnet_upperbound}")
                        
                #Counteract if 'check_result = false'
                if [[ ${check_result} == false ]]; then
                    #Validate and Generate IP-ranges
                    ret=$(Ipv4_Generate_Iprange "${netmask}" "${subnet_lowerbound}" "${subnet_upperbound}")
                    
                    #Goto next-phase
                    phase=${PHASE_EXIT}
                else
                    #Goto next-phase
                    phase=${PHASE_COMPARE_LOWERBOUND_UPPERBOUND}
                fi
                ;;
            "${PHASE_COMPARE_LOWERBOUND_UPPERBOUND}")
                #Check if 'iprange_lowerbound' is smaller than 'iprange_upperbound'
                check_result=$(Ipv4_CheckIf_FirstIp_IsSmallerThan_SecondIp \
                        "${iprange_lowerbound}" \
                        "${iprange_upperbound}")
                
                #Counteract if 'check_result = false'
                if [[ ${check_result} == false ]]; then
                    #Validate and Generate IP-ranges
                    ret=$(Ipv4_Generate_Iprange "${netmask}" "${subnet_lowerbound}" "${subnet_upperbound}")
                fi
                
                #Goto next-phase
                phase=${PHASE_EXIT}
                ;;
            "${PHASE_EXIT}")
                #Output
                echo "${ret}"
                
                return 0;
                ;;
        esac
    done
}
Ipv4_CheckIf_FirstIp_IsSmallerThan_SecondIp() {
    #Input args
    local ipaddr1=${1}
    local ipaddr2=${2}
    
    #Define and initialize variables
    local ret=false

    local ipaddr1_ddval=${WLN_EMPTYSTRING}
    local ipaddr2_ddval=${iprange_upperbound}

    local ipaddr1_tmp=${ipaddr1}
    local ipaddr2_tmp=${ipaddr2}

    #Compare 'ipaddr1_conv' with 'ipaddr2_conv'
    # shellcheck disable=SC2004
    for (( s=1; s<=${WLN_IPV4_NUMOF_SEGMENTS_MAX}; s++ ))
    do
        #Get the value BEFORE the 1st dot (.) 
        ipaddr1_ddval=${ipaddr1_tmp%%.*}
        ipaddr2_ddval=${ipaddr2_tmp%%.*}
        
        #Get the remaining value AFTER the 1st dot (.)
        ipaddr1_tmp=${ipaddr1_tmp#*.}
        ipaddr2_tmp=${ipaddr2_tmp#*.}

        #Check if 'ipaddr1_conv_block_dec > ipaddr2_conv_block_dec'
        if [[ ${ipaddr1_ddval} -lt ${ipaddr2_ddval} ]]; then
            ret=true
    
            break
        elif [[ ${ipaddr1_ddval} -gt ${ipaddr2_ddval} ]]; then
            ret=false
    
            break
        fi
    done
    
    #Output
    echo "${ret}"
    
    return 0;    
}
Ipv4_CheckIf_Ip_Is_PartOf_Specified_IpRange() {
    #Input args
    local ipaddr=${1}
    local iprange_lowerbound=${2}
    local iprange_upperbound=${3}

    #Compare 'ipaddr_conv' with 'iprange_lowerbound_conv'
    local ret=false
    
    local ipaddr_tmp=${ipaddr}
    local iprange_lowerbound_tmp=${iprange_lowerbound}
    local iprange_upperbound_tmp=${iprange_upperbound}

    local ipaddr_ddval=${WLN_EMPTYSTRING}
    local iprange_lowerbound_ddval=${WLN_EMPTYSTRING}
    local iprange_upperbound_ddval=${WLN_EMPTYSTRING}

    local ipaddr_isabove_lowerbound=false
    local ipaddr_isbelow_upperbound=false

    # shellcheck disable=SC2004
    for (( s=1; s<=${WLN_IPV4_NUMOF_SEGMENTS_MAX}; s++ ))
    do
        #Get the value BEFORE the 1st dot (.) 
        ipaddr_ddval=${ipaddr_tmp%%.*}
        iprange_lowerbound_ddval=${iprange_lowerbound_tmp%%.*}
        iprange_upperbound_ddval=${iprange_upperbound_tmp%%.*}
        
        #Get the remaining value AFTER the 1st dot (.)
        ipaddr_tmp=${ipaddr_tmp#*.}
        iprange_lowerbound_tmp=${iprange_lowerbound_tmp#*.}
        iprange_upperbound_tmp=${iprange_upperbound_tmp#*.}


        #Compare 'ipaddr_ddval' with 'iprange_lowerbound_ddval'
        #If Greater than, set boolean 'ipaddr_isabove_lowerbound' to 'true'.
        #If Smaller than, set boolean 'ret' to 'false'.
        #If equal, do nothing.
        if [[ ${ipaddr_ddval} -gt ${iprange_lowerbound_ddval} ]]; then
            ipaddr_isabove_lowerbound=true
        elif [[ ${ipaddr_ddval} -lt ${iprange_lowerbound_ddval} ]]; then
            ret=false
    
            break
        fi
        
        #Compare 'ipaddr_ddval' with 'iprange_upperbound_ddval'
        #If Smaller than, set boolean 'ipaddr_isbelow_upperbound' to 'true'.
        #If Greater than, set boolean 'ret' to 'false'.
        #If equal, do nothing.
        if [[ ${ipaddr_ddval} -lt ${iprange_upperbound_ddval} ]]; then #less
            ipaddr_isbelow_upperbound=true
        elif [[ ${ipaddr_ddval} -gt ${iprange_upperbound_ddval} ]]; then   #Greater
            ret=false
            
            break
        fi
        
        #Check if both 'ipaddr_isabove_lowerbound' and 'ipaddr_isbelow_upperbound' are 'true'
        if [[ ${ipaddr_isabove_lowerbound} == true ]] && [[ ${ipaddr_isbelow_upperbound} == true ]]; then
            ret=true
            
            break
        fi
    done
    
    #Output
    echo "${ret}"
    
    return 0;
}
Ipv4_Generate_Iprange() {
    #Input args
    local netmask=${1}
    local subnet_lowerbound=${2}
    local subnet_upperbound=${3}

    #Define and initialize variables
    local cidrprefix=0
    cidrprefix=$(NetMaskV4_DdvalToCidr "${netmask}")
    local subnet_lowerbound_output=${subnet_lowerbound}
    local subnet_upperbound_output=${subnet_upperbound}
    local subnet_lowerbound_wo_last_hexblock=${subnet_upperbound%.*}   #use the 'subnet_upperbound'
    local ret="${subnet_lowerbound_output},${subnet_upperbound_output}"

    #Check if 'netmask => 24'
    #Remark:
    #   If 'netmask = 24', then a maximum of 254 IP-addresses are available.
    #   However, the first and last IP-addresses can NOT be used:
    #       first IP-address -> network-number
    #       last IP-address -> broadcast IP
    if [[ ${cidrprefix} -ge ${WLN_IPV4_CIDR_PREFIX_24} ]]; then
        echo "${ret}"
    
        return 0;
    fi
    
    #In case 'netmask < 112'
    #Update 'subnet_lowerbound_output' which should ALWAYS end with the 4 hex-digits (0000)
    subnet_lowerbound_output="${subnet_lowerbound_wo_last_hexblock}.${WLN_IPV4_SUBNET_LOWERBOUND_MINVAL}"

    #Update 'subnet_upperbound_output' which should ALWAYS end with the 4 hex-digits (ffff)
    subnet_upperbound_output="${subnet_lowerbound_wo_last_hexblock}.${WLN_IPV4_SUBNET_UPPERBOUND_MAXVAL}"
    
    #Update 'ret'
    ret="${subnet_lowerbound_output},${subnet_upperbound_output}"
    
    #Output
    echo "${ret}"
    
    return 0;
}



#---MAIN SUBROUTINE
main__sub() {
    #Define variables
    local ip_addr="192.45.46.1"
    local ip_range_lowerbound="192.45.32.100"
    local ip_range_upperbound="192.45.63.200"
    local netmask="255.255.224.0"
    local result=${WLN_EMPTYSTRING}
    
    local cidrprefix=1
    while [[ ${cidrprefix} -le ${WLN_IPV4_CIDR_PREFIX_32} ]]
    do
        netmask=$(NetMaskV4_CidrprefixToDdmask "${cidrprefix}")

        #Get subnet data
        result=$(IPv4_Get_Subnet_Data "${ip_addr}" "${netmask}")
        subnet_networkid=$(echo "${result}" | cut -d"," -f1)
        subnet_lowerbound=$(echo "${result}" | cut -d"," -f2)
        subnet_upperbound=$(echo "${result}" | cut -d"," -f3)
    
        #Print
        print_subnet_result="netmask:\t\t${netmask}\n"
        print_subnet_result+="subnet_networkid:\t${subnet_networkid}\n"
        print_subnet_result+="subnet_lowerbound:\t${subnet_lowerbound}\n"
        print_subnet_result+="subnet_upperbound:\t${subnet_upperbound}\n"
        echo -e "${print_subnet_result}"


        #Validate and Autocorrect IPv6-range
        result=$(Ipv4_Check_And_Generate_Iprange_Handler \
                "${ip_addr}" \
                "${netmask}" \
                "${ip_range_lowerbound}" \
                "${ip_range_upperbound}")
        iprange_lowerbound=$(echo "${result}" | cut -d"," -f1)
        iprange_upperbound=$(echo "${result}" | cut -d"," -f2)
    
        #Print
        print_subnet_result="iprange_lowerbound:\t${iprange_lowerbound}\n"
        print_subnet_result+="iprange_upperbound:\t${iprange_upperbound}\n"
        echo -e "${print_subnet_result}"


        sleep 2

        cidrprefix=$(( cidrprefix + 1 ))
        
        clear
        tput cuu1
        tput cuu1
        tput cuu1
        tput cuu1
        tput cuu1
        tput cuu1
        tput cuu1
    done
    
    return 0;
}

#---EXECUTE
main__sub


