#!/bin/bash
#-------------------------------------------------------------------------------
# IMPORTANT TO KNOW
#-------------------------------------------------------------------------------
# Let's use an example:
#                     2   4     6   8     10  12    14  16    18  20    22  24    26  28    30  32
#     hex-postion:  1 | 3 |   5 | 7 |   9 | 11|   13| 15|   17| 19|   21| 23|   25| 27|   29| 31| 
#                   | | | |   | | | |   | | | |   | | | |   | | | |   | | | |   | | | |   | | | |   
#   IPv6 Address:   c d e f : 2 2 2 2 : 3 3 3 3 : 4 4 4 4 : a a a a : b b b b : c c c c : d d d d
#                  |------|  |------|  |------|  |------|  |------|  |------|  |------|  |------|
#                   block     block     block     block     block     block     block     block
#   block-numbers:    1         2         3         4         5         6         7         8
#
#-------------------------------------------------------------------------------
# unchanged_hexpos_abs & hexpos_abs:
#
# A few scenarios:
# 1. unchanged_hexpos_abs = hexpos_abs -> when the modulus of a netmask-value is 0,
#       in other words, when netmask = 4, 8, 12, 16, etc.
# 2. unchanged_hexpos_abs < hexpos_abs -> when the modulus of a netmask-value is not 0,
#       in other words, when netmask = 1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15, etc.
# 
#-------------------------------------------------------------------------------
# oneblock_hexpos_rel & oneblock_bitpos_rel:
#
# One hex-block contains 4 hex-digits (e.g. cdef)
#
#   oneblock_hexpos_rel:       1        2        3        4
#                              |        |        |        |
#           4 hex-digit:       c        d        e        f
#                          |------| |------| |------| |------| 
#                binary:   1 1 0 0  1 1 0 1  1 1 1 0  1 1 1 1
#                          | | | |  | | | |  | | | |  | | | |
#   oneblock_bitpos_rel:   1 | 3 |  5 | 7 |  9 | 11|  13| 15|   
#                            2   4    6   8   10  12   14  16
#
#-------------------------------------------------------------------------------
# onehex_bitpos_rel:
#
# One hex-digit contans 4 bits (e.g. e)
#   For example: binary represenation of hex-digit 'e' is: 1110
#           hex-digit:  1 1 1 0
#                       | | | |
#   onehex_bitpos_rel:  1 2 3 4
#
#-------------------------------------------------------------------------------
# REMARKS:
#   oneblock_hexpos_rel:
#   1. If 'oneblock_hexpos_rel = 0' then it means that the netmask falls within
#       the 1st hex-digit of a block (but this netmask does NOT cover the whole 
#       4-bits of the hex-digit)
#           netmask=1, 2, or 3
#           netmask=17, 18, or 19
#           ...
#   2. If 'oneblock_hexpos_rel = 1', then it means that the netmask falls at
#       the END of the 1st hex-digit, or it falls within the 2nd hex-digit 
#       of a block:
#           netmask=4, or netmask=5, 6, or 7
#           netmask=20, or netmask=21, 22, or 23
#           ...
#   3. If 'oneblock_hexpos_rel = 2', then it means that the netmask falls at
#       the END of the 2nd hex-digit, or it falls within the 3rd hex-digit 
#       of a block:
#           netmask=8, or netmask=9, 10, or 11
#           netmask=24, or netmask=25, 26, or 27
#           ...
#   4. If 'oneblock_hexpos_rel = 3', then it means that the netmask falls at
#       the END of the 3rd hex-digit, or it falls within the 2nd hex-digit 
#       of a block:
#           netmask=12, or netmask=13, 14, or 15
#           netmask=28, or netmask=29, 30, or 31
#           ...
#   4. If 'oneblock_hexpos_rel = 4', then it means that the netmask falls at
#       the END of the 4th hex-digit (last block):
#           netmask=16
#           netmask=32
#           ...
#-------------------------------------------------------------------------------

#---CONSTANTS
WLN_EMPTYSTRING=""
WLN_DOUBLECOLON="::"
WLN_COLON=":"
WLN_IPV6_ADDRLEN_IN_BITS=128
WLN_IPV6_ONEHEXLEN_IN_BITS=4
WLN_IPV6_ONEBLOCKLEN_IN_HEXES=4
WLN_IPV6_ONEBLOCKLEN_IN_BITS=$(( WLN_IPV6_ONEHEXLEN_IN_BITS * WLN_IPV6_ONEBLOCKLEN_IN_HEXES ))
WLN_IPV6_ADDRLEN_IN_HEXES=$(( WLN_IPV6_ADDRLEN_IN_BITS/WLN_IPV6_ONEHEXLEN_IN_BITS))
WLN_IPV6_ADDRLEN_IN_BLOCKS=$(( WLN_IPV6_ADDRLEN_IN_BITS/WLN_IPV6_ONEBLOCKLEN_IN_BITS ))

WLN_NUM_1=1
WLN_NUM_2=2

WLN_IPV6_TRAILCHAR_0="0"
WLN_IPV6_TRAILCHAR_1="1"
WLN_IPV6_TRAILCHAR_3="3"
WLN_IPV6_TRAILCHAR_7="7"
WLN_IPV6_TRAILCHAR_F="f"

WLN_IPV6_ONEHEXLEN_IN_DEC=16
WLN_IPV6_CIDR_112=112
WLN_IPV6_SUBNET_LOWERBOUND_MINVAL="0000"
WLN_IPV6_SUBNET_UPPERBOUND_MAXVAL="ffff"

WLN_IPV6_BOGUS_STRVAL=${WLN_EMPTYSTRING}
WLN_IPV6_BOGUS_INTVAL_255=255    #this is an invalid value



#---GENERAL FUNCTIONS
Append_Chars() {
    #Input args
    local str=${1}
    local char=${2}
    local numofchars=${3}

    #Define and initialize variables
    local ret=${str}
    
    #Append chars to 'ret'
    # shellcheck disable=SC2004
    for (( c=0; c<${numofchars}; c++ ))
    do
        ret="${ret}${char}"
    done
    
    #Output
    echo "${ret}"
    
    return 0;
}

CheckIf_Char_IsPresent() {
    #Input args
    local str=${1}
    local substr=${2}
    
    #Define variables
    local noccur=0

    #Count number of 'substr' within 'str'
    noccur=$(Count_NumOf_Substring_Within_String "${str}" "${substr}")
    
    #Output
    if [[ ${noccur} -gt 0 ]]; then
        echo true
    else
        echo false
    fi
    
    return 0;
}

Count_NumOf_Substring_Within_String() {
    #Input args
    local str=${1}
    local substr=${2}
    
    #Define variables
    local noccur=0

    #Count number of 'substr' within 'str'
    noccur=$(echo "${str}" | grep -oF "${substr}" | wc -l)
    
    #Output
    echo "${noccur}"
    
    return 0;
}

Dec64ToHex() {
    #Input args
    local decval=${1}
    
    #Conversion
    printf '%x\n' "${decval}"
    
    return 0;
}
HexToDec64() {
    #Input args
    local hexval=${1}
    
    #Conversion
    local dec=$((16#${hexval}))
    
    #Output
    printf "%u\n" ${dec}
    
    return 0;
}

Get_Last_Nchar() {
    #Input args
    local str=${1}
    local numofchars=${2}
    
    #Check if 'str = <Empty String>'
    if [[ "${str}" == "${WLN_EMPTYSTRING}" ]]; then
        echo ${WLN_EMPTYSTRING}
        
        return 0;
    fi
    
    #Get length of 'str'
    local str_len=${#str}
    
    #Get position
    local str_lastchar_pos=$(( str_len - 1 ))
    
    #Get the last char of 'str'
    local lastChar=${str:str_lastchar_pos:numofchars}
    
    #Output
    echo "${lastChar}"
    
    return 0;
}

Get_StringLen_Exluding_Specified_Char() {
    #Input args
    local str=${1}
    local char=${2}
    
    #Define variables
    local str_wo_char=${WLN_EMPTYSTRING}

    #Substitute 'char' with an <Empty String>
    # shellcheck disable=SC2001
    str_wo_char=$(echo "${str}" | sed "s/${char}//g")

    #Get the length of 'str_wo_char'
    local str_wo_char_len=${#str_wo_char}
    
    #Output
    echo "${str_wo_char_len}"
    
    return 0;
}



#---IPV6 RELATED FUNCTIONS
Ipv6_Subst_DoubleColons_With_Zeros() {
    #Input args
    local ipaddr=${1}

    #Define variables
    local doubleColonIsPresent=false
    local noccur=0
    local ret=${WLN_EMPTYSTRING}

    #Check if there are any double-colons
    doubleColonIsPresent=$(CheckIf_Char_IsPresent "${ipaddr}" "${WLN_DOUBLECOLON}")
    if [[ ${doubleColonIsPresent} == false ]]; then
        echo "${ipaddr}"
    
        return 0;
    fi
    
    
    #Count the number of colon's (:)
    noccur=$(Count_NumOf_Substring_Within_String "${ipaddr}" "${WLN_COLON}")
    
    #Substract the double-colon(::) from 'noccur'
    noccur_wo_doubleColon=$((noccur-2))
 
    #Determine the substitute string (substStr) for the double-colon
    #Remark:
    #   'substStr' depends on the number of colons found within 'ipaddr'
    case "${noccur_wo_doubleColon}" in
        0)
            substStr=":0:0:0:0:0:0:"
            ;;
        1)
            substStr=":0:0:0:0:0:"
            ;;
        2)
            substStr=":0:0:0:0:"
            ;;
        3)
            substStr=":0:0:0:"
            ;;
        4)
            substStr=":0:0:"
            ;;
        5)
            substStr=":0:"
            ;;
    esac

    #Substiute double-colon (::) with 'substr'
    # shellcheck disable=SC2001
    ret=$(echo "${ipaddr}" | sed "s/${WLN_DOUBLECOLON}/${substStr}/g")

    #Output
    echo "${ret}"
    
    return 0;
}

Ipv6_Determine_Increment_Value_Of_4Bit_Block() {
    #Input args
    #   Definition:
    #       decimal:                8 4 2 1
    #       binary of a 4-bit Hex:  0 0 0 0
    #   Meaning:
    #       binary position: 1 -> binary: 1 0 0 0 -> decimal = 8
    #       binary position: 2 -> binary: 0 1 0 0 -> decimal = 4
    #       binary position: 3 -> binary: 0 0 1 0 -> decimal = 2
    #       binary position: 3 -> binary: 0 0 0 1 -> decimal = 1
    local netmask=${1}
    
    #Check if 'netmask > 128'
    if [[ ${netmask} -gt ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${WLN_IPV6_BOGUS_INTVAL_255}"
    
        return 0;
    fi
    
    #Determine the 'subnet_lowerval_incr'
    local subnet_lowerval_incr=0
    local mod_netmask=$(( netmask % WLN_IPV6_ONEHEXLEN_IN_BITS ))
    case "${mod_netmask}" in
        1)
            subnet_lowerval_incr=8
            #####################################
            # The ranges are:
            #   startVal| 0 | 8
            #   --------+---+---
            #   endVal  | 7 | f
            #####################################
            # For example: netmask=41
            #                               subnet_lowerval_dec
            #                                       |
            #   subnet_lowerbound #1:  cdef:2222:33[0]0:0000:0000:0000:0000:0000
            #   subnet_upperbound #1:  cdef:2222:33[7]f:ffff:ffff:ffff:ffff:ffff
            #                                       |
            #                               subnet_upperval_dec
            #
            #                               subnet_lowerval_dec
            #                                      |
            #   subnet_lowerbound #2: cdef:2222:33[8]0:0000:0000:0000:0000:0000
            #   subnet_upperbound #2: cdef:2222:33[f]f:ffff:ffff:ffff:ffff:ffff
            #                                      |
            #                               subnet_upperval_dec
            ;;
        2)
            subnet_lowerval_incr=4
            #####################################
            # The ranges are:
            #   startVal| 0 | 4 | 8 | c
            #   --------+---+---+---+---
            #   endVal  | 3 | 7 | b | f
            #####################################
            # For example: netmask=42
            #   subnet_lowerbound #1:  cdef:2222:33[0]0:0000:0000:0000:0000:0000
            #   subnet_upperbound #1:  cdef:2222:33[3]f:ffff:ffff:ffff:ffff:ffff
            #   subnet_lowerbound #2:  cdef:2222:33[4]0:0000:0000:0000:0000:0000
            #   subnet_upperbound #2:  cdef:2222:33[7]f:ffff:ffff:ffff:ffff:ffff
            #   subnet_lowerbound #3:  cdef:2222:33[8]0:0000:0000:0000:0000:0000
            #   subnet_upperbound #3:  cdef:2222:33[b]f:ffff:ffff:ffff:ffff:ffff
            #   subnet_lowerbound #3:  cdef:2222:33[c]0:0000:0000:0000:0000:0000
            #   subnet_upperbound #3:  cdef:2222:33[f]f:ffff:ffff:ffff:ffff:ffff
            ;;
        3)
            subnet_lowerval_incr=2
            #####################################
            # The ranges are:
            #   startVal| 0 | 2 | .. | c | e |
            #   --------+---+---+----+---+---+
            #   endVal  | 1 | 3 | .. | d | f |
            #####################################
            # For example: netmask=43
            #   subnet_lowerbound #1:  cdef:2222:33[0]0:0000:0000:0000:0000:0000
            #   subnet_upperbound #1:  cdef:2222:33[1]f:ffff:ffff:ffff:ffff:ffff
            #   subnet_lowerbound #2:  cdef:2222:33[2]0:0000:0000:0000:0000:0000
            #   subnet_upperbound #2:  cdef:2222:33[3]f:ffff:ffff:ffff:ffff:ffff
            #   ...
            #   subnet_lowerbound #3:  cdef:2222:33[c]0:0000:0000:0000:0000:0000
            #   subnet_upperbound #3:  cdef:2222:33[d]f:ffff:ffff:ffff:ffff:ffff
            #   subnet_lowerbound #3:  cdef:2222:33[e]0:0000:0000:0000:0000:0000
            #   subnet_upperbound #3:  cdef:2222:33[f]f:ffff:ffff:ffff:ffff:ffff
            ;;
        4)
            subnet_lowerval_incr=0
            #####################################
            # The ranges are:
            #   startVal| 0 | 1 | .. | e | f |
            #   --------+---+---+----+----+----
            #   endVal  | 0 | 1 | .. | e | f |
            #####################################
            # For example: netmask=44
            #   subnet_lowerbound: cdef:2222:33[3]0:0000:0000:0000:0000:0000
            #   subnet_upperbound: cdef:2222:33[3]f:ffff:ffff:ffff:ffff:ffff
            # 
            # REMARK:
            #   In this SPECIAL case it means that the hex-digit '3',...
            #       at hexpos_abs=11 belongs to the networkID and can NOT be
            #       used for the HostID.
            #####################################
            ;;
    esac
    
    #Output
    echo "${subnet_lowerval_incr}"
    
    return 0;
}

Ipv6_Get_Trailing_HexBlock_Len() {
    #Input args
    local ipaddr=${1}
    
    #Define variables
    local ipaddr_wo_colons=${WLN_EMPTYSTRING}
    local hexblock_trail=${WLN_EMPTYSTRING}

    #IMPORTANT: Remove trailing colon's (:)
    # shellcheck disable=SC2001
    ipaddr_wo_colons=$(echo "${ipaddr}" | sed 's/:*$//g')
    
    #Get the substring on the right-side of the last colon (:)
    # shellcheck disable=SC2001
    hexblock_trail=$(echo "${ipaddr_wo_colons}" | sed 's/.*://')
    
    #Calculate the length of 'hexblock_trail'
    local hexblock_trail_hexlen=${#hexblock_trail}
    
    #Output
    echo "${hexblock_trail_hexlen}"
    
    return 0;
}



Ipv6_Prepend_Zeros(){
    #Input args
    local ipaddr=${1}

    #Fill up each IP-block with zeros to consist of 4 hex-digits
    local ipaddr_new=${WLN_EMPTYSTRING}
    local ipblock_curr=${WLN_EMPTYSTRING}
    local ipblock_curr_len=0
    local ipblock_new=${WLN_EMPTYSTRING}
    # shellcheck disable=SC2004
    for (( blocknum=1; blocknum<=${WLN_IPV6_ADDRLEN_IN_BLOCKS}; blocknum++ ))
    do
        #Get the 4 hex-digits of each blocknum
        ipblock_curr=$(echo "${ipaddr}" | cut -d":" -f"${blocknum}")
        #Get the length of 'ipblock'
        ipblock_curr_len=${#ipblock_curr}
        case "${ipblock_curr_len}" in
            1)
                ipblock_new="000${ipblock_curr}"
                ;;
            2)
                ipblock_new="00${ipblock_curr}"
                ;;
            3)
                ipblock_new="0${ipblock_curr}"
                ;;
            *)
                ipblock_new="${ipblock_curr}"
                ;;  
        esac
        
        #Reconstruct 'ipaddr_new'
        if [[ -z "${ipaddr_new}" ]]; then
            ipaddr_new="${ipblock_new}"
        else
            ipaddr_new="${ipaddr_new}:${ipblock_new}"
        fi
    done
    
    #Output
    echo "${ipaddr_new}"
    
    return 0;
    
}

Ipv6_Retrieve_Partial_Of_IpAddress() {
    #Input args
    local ipaddr=${1}
    local netmask=${2}

    #Check if 'netmask > 128'
    if [[ ${netmask} -gt ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${WLN_IPV6_BOGUS_STRVAL}"
    
        return 0;
    fi

    #Check if 'netmask < 4'
    if [[ ${netmask} -lt ${WLN_IPV6_ONEHEXLEN_IN_BITS} ]]; then
        echo "${WLN_EMPTYSTRING}"
        
        return 0;
    fi

    #Check if 'netmask = 128'
    if [[ ${netmask} -eq ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${networkid}"
        
        return 0;
    fi

    #Initialize variables
    local char=${WLN_EMPTYSTRING}
    local networkid=${WLN_EMPTYSTRING}
    local hexdigit_ctr=0
    local netmask_hexdigits=$(( netmask/WLN_IPV6_ONEHEXLEN_IN_BITS ))

    #Loop thru 'ipaddr'
    local ipaddr_len=${#ipaddr}
    # shellcheck disable=SC2004
    for (( h=0; h<${ipaddr_len}; h++ ))
    do
        #Get next 'char' from 'ipaddr'
        char="${ipaddr:${h}:1}"

        #Append 'char' to 'networkid'
        networkid="${networkid}${char}"

        #Check if 'char != WLN_COLON'
        #   if not, then increment counter 'hexdigit_ctr'.
        if [[ "${char}" != "${WLN_COLON}" ]]; then
            hexdigit_ctr=$((hexdigit_ctr + 1))
        fi

        #Check if 'hexdigit_ctr = netmask_hexdigits'
        if [[ ${hexdigit_ctr} -eq ${netmask_hexdigits} ]]; then
            break
        fi
    done
    
    #Output
    echo "${networkid}"
    
    return 0;
}

Ipv6_SubstituteFor_And_Prepend_Zeros() {
    #Input args
    local ipaddr=${1}

    #Define variables
    local ipaddr_conv=${WLN_EMPTYSTRING}
    local ret=${WLN_EMPTYSTRING}

    #Convert double-colon(::) to zeros
    ipaddr_conv=$(Ipv6_Subst_DoubleColons_With_Zeros "${ipaddr}")

    #Fill up each IP-block with zeros to consist of 4 hex-digits 
    ret=$(Ipv6_Prepend_Zeros "${ipaddr_conv}")
    
    #Output
    echo "${ret}"
    
    return 0;
}



#---IPV6 MAIN FUNCTIONS
Ipv6_Get_Parent_NetworkId() {
    #Input args
    local ipaddr=${1}
    local netmask=${2}

    #Define variables
    local hexblock_trail=${WLN_EMPTYSTRING}
    local ipaddr_zeros_added=${WLN_EMPTYSTRING}
    local lastchar=${WLN_EMPTYSTRING}
    local networkid=${WLN_EMPTYSTRING}
    local hexblock_trail_hexlen=0

    #Check if 'netmask > 128'
    if [[ ${netmask} -gt ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${WLN_IPV6_BOGUS_STRVAL}"
    
        return 0;
    fi

    #This function will handle 2 actions:
    #1. Substitute double-colon (::) with zeros (0).
    #2. Prepend zeros (0) to fill up any hex-block which is NOT 4 HEXes long.
    ipaddr_zeros_added=$(Ipv6_SubstituteFor_And_Prepend_Zeros "${ipaddr}")

    #Check if 'netmask = 128'
    if [[ ${netmask} -eq ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${ipaddr_zeros_added}"
        
        return 0;
    fi

    #Substract the NetworkID
    networkid=$(Ipv6_Retrieve_Partial_Of_IpAddress \
            "${ipaddr_zeros_added}" \
            "${netmask}")


    #Only do this part if 'netmask => 4'
    if [[ ${netmask} -ge 4 ]]; then
        #Append or Remove colon (:) handler
        local PHASE_CHECK_LAST_CHAR=1
        local PHASE_CHECK_TRAIL_HEXBLOCK_LENGTH=2
    
        local phase=${PHASE_CHECK_LAST_CHAR}
        while true
        do
            case "${phase}" in
                "${PHASE_CHECK_LAST_CHAR}")
                    #Get last char of 'networkid'
                    lastchar=$(Get_Last_Nchar "${networkid}" "${WLN_NUM_1}")
                    #Check if 'lastchar' is a colon (:)
                    #Remark:
                    #   If a colon is found then it means that the preceding...
                    #   ...hex-block is 4 hex-digits long. Therefore, in this case...
                    #   ...the while-loop can be exited.
                    if [[ "${lastchar}" == "${WLN_COLON}" ]]; then  #is a colon
                        #Exit Loop
                        break
                    else
                        #Goto next-phase
                        phase=${PHASE_CHECK_TRAIL_HEXBLOCK_LENGTH}                
                    fi
                    ;;
                "${PHASE_CHECK_TRAIL_HEXBLOCK_LENGTH}")
                    #Get the hex-block on the right-side of the last colon occurrence.
                    # shellcheck disable=SC2001
                    hexblock_trail=$(echo "${networkid}" | sed 's/.*://')
        
                    #Calculate the length of 'hexblock_trail'
                    hexblock_trail_hexlen=${#hexblock_trail}
                
                    #Check if 'hexblock_trail_hexlen == 4'   
                    if [[ ${hexblock_trail_hexlen} -eq ${WLN_IPV6_ONEBLOCKLEN_IN_HEXES} ]]; then
                        #Append colon (:)
                        networkid="${networkid}${WLN_COLON}"
                    fi
        
                    #Exit loop
                    break
                    ;;
            esac
        done
    fi
    
    # #Output
    echo "${networkid}"
    
    return 0;
}

IPv6_Get_Subnet_Data() {
    #Input args
    local ipaddr=${1}
    local netmask=${2}
    


    #Define variables
    local ipaddr_conv=${WLN_EMPTYSTRING}
    local networkid=${WLN_EMPTYSTRING}
    local subnet_lowerval=${WLN_EMPTYSTRING}


    local ipaddr_lasthexdigit_dec=0
    local subnet_lowerval_incr=0
    local subnet_upperval_dec=0


    #Check if 'netmask > 128'
    if [[ ${netmask} -gt ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${WLN_IPV6_BOGUS_STRVAL}"
    
        return 0;
    fi



    #Get 'networkid'
    #Remarks:
    #   Double-colon (::) is substituted in this function.
    #   Zeros (0) are prepended to hex-blocks which are not 4 HExEs in length.
    networkid=$(Ipv6_Get_Parent_NetworkId \
            "${ipaddr}" \
            "${netmask}")


    
    #Define and initialize variables
    local subnet_networkid="${networkid}/${WLN_IPV6_ADDRLEN_IN_BITS}"
    local subnet_lowerbound="${networkid}"
    local subnet_upperbound="${networkid}"
    
 
    
    #Check if 'netmask = 128'
    if [[ ${netmask} -eq ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${subnet_networkid},${subnet_lowerbound},${subnet_upperbound}"
        
        return 0;
    fi


 
    #Define and initialize variables
    #Remark:
    #    It is important to do it here, just in case subnet_lowerval_incr = 0
    local subnet_lowerboundhead="${networkid}"
    local subnet_upperboundhead="${networkid}"



    #Only handle the code within this condition if 'netmask != 4, 8, 12, 16, etc.'
    #In other words, when the modulus of the 'netmask and 4' is '0'
    mod_netmask=$(( netmask % WLN_IPV6_ONEBLOCKLEN_IN_HEXES ))
    if [[ ${mod_netmask} -ne 0 ]]; then
        #Get the length of 'networkid'
        local networkid_len=${#networkid}
    
        #Calculate the length to be retrieved from 'ipaddr'
        local ipaddr_numofchars_tobeused=$((networkid_len + 1))
        
        #IMPORTANT: before trimming 'ipaddr', make sure to...
        #           ...convert double-colon (::) to Zeros.
        ipaddr_conv=$(Ipv6_SubstituteFor_And_Prepend_Zeros "${ipaddr}")

        #Retrieve part of 'ipaddr' with length 'ipaddr_numofchars_tobeused'
        #Remark:
        #   The length of 'ipaddr_trimmed' is always 1 hex-digit...
        #   ...more than 'networkid'.
        local ipaddr_trimmed=${ipaddr_conv:0:ipaddr_numofchars_tobeused}

        #Get the LAST hex-digit of 'ipaddr_trimmed'
        #Remark:
        #   This is important, because with this LAST hex-digit...
        #   ...the subnet-range can be determined.
        local ipaddr_lasthexdigit_hex=${ipaddr_trimmed:networkid_len:ipaddr_numofchars_tobeused}

        #Convert 'ipaddr_lasthexdigit' from hex to decimal
        ipaddr_lasthexdigit_dec=$(HexToDec64 "${ipaddr_lasthexdigit_hex}")

        #Get the increment value
        subnet_lowerval_incr=$(Ipv6_Determine_Increment_Value_Of_4Bit_Block "${netmask}")

        #Get 'subnet_lowerval_dec'
        #Please note:
        #    The number of possible subnet-ranges depends on the netmask,...
        #   ...and thus the subnet_lowerval_incr'.
        #   The main idea is to compare 'subnet_lowerval_dec_try' with...
        #   ...'ipaddr_lasthexdigit_dec'. 
        #   The 'subnet_lowerval_dec' is found when:
        #       subnet_lowerval_dec_try > ipaddr_lasthexdigit_dec
        #   In this case, stop the loop.
        local subnet_lowerval_dec=0
        local subnet_lowerval_dec_try=0
        while [[ ${subnet_lowerval_dec_try} -lt ${WLN_IPV6_ONEHEXLEN_IN_DEC} ]]
        do
            #Compare 'subnet_lowerval_dec_try' with 'ipaddr_lasthexdigit_dec'
            if [[ ${subnet_lowerval_dec_try} -gt ${ipaddr_lasthexdigit_dec} ]]; then
                break
            fi
     
            #Backup 'subnet_lowerval_dec_try'
            subnet_lowerval_dec=${subnet_lowerval_dec_try}
    
            #Increment 'subnet_lowerval_dec'
            subnet_lowerval_dec_try=$(( subnet_lowerval_dec_try + subnet_lowerval_incr ))
        done

        #Get 'subnet_lowerval'
        subnet_lowerval=$(Dec64ToHex "${subnet_lowerval_dec}")
    
        #Get 'subnet_lowerboundhead'
        #   Explanation: 
        #       subnet_upperboundhead(1111:20)-------------+-----+
        #                                                  |     | 
        #                                                  cdef:20
        #                                                        |
        #                   subnet_upperval(0)-------------------+
        #
        subnet_lowerboundhead="${networkid}${subnet_lowerval}"

        #Get 'subnet_upperval_dec'
        local subnet_upperval_dec=$((subnet_lowerval_dec + subnet_lowerval_incr - 1))
        
        #Get 'subnet_upperval'
        subnet_upperval=$(Dec64ToHex "${subnet_upperval_dec}")
        
        #Get 'subnet_upperboundhead'
        #   Explanation: 
        #       subnet_upperboundhead(1111:2f)-------------+-----+
        #                                                  |     | 
        #                                                  cdef:2f
        #                                                        |
        #                   subnet_upperval(f)-------------------+
        #
        subnet_upperboundhead="${networkid}${subnet_upperval}"
    fi



    #Get the 'subnet_networkid'
    subnet_networkid=$(Ipv6_Get_Subnet_NetworkId \
            "${subnet_lowerboundhead}" \
            "${netmask}")

    #Get 'subnet_lowerbound'
    subnet_lowerbound=$(Ipv6_Get_Subnet_EdgeBound \
            "${subnet_lowerboundhead}" \
            "${netmask}" \
            "${WLN_IPV6_TRAILCHAR_0}")

    #Get 'subnet_upperbound'
    subnet_upperbound=$(Ipv6_Get_Subnet_EdgeBound \
            "${subnet_upperboundhead}" \
            "${netmask}" \
            "${WLN_IPV6_TRAILCHAR_F}")

    #Output
    echo "${subnet_networkid},${subnet_lowerbound},${subnet_upperbound}"

    return 0;
}
Ipv6_Get_Subnet_EdgeBound() {
    #Input args
    local subnet_header=${1}
    local netmask=${2}
    local char=${3}

    #Define variables
    local subnet_header_lastchar=${WLN_EMPTYSTRING}
    local hexblock_trail_hexlen=0
    local subnet_header_wo_colon_len=0

    #Check if 'netmask > 128'
    if [[ ${netmask} -gt ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${WLN_IPV6_BOGUS_STRVAL}"
    
        return 0;
    fi

    #Get the length of the trailing hex-block
    #Remark:
    #   hex-block: cdef:2222 -> hexblock_trail_hexlen = (length of '2222') = 4
    hexblock_trail_hexlen=$(Ipv6_Get_Trailing_HexBlock_Len "${subnet_header}")


    #Get last char of 'subnet_header'
    subnet_header_lastchar=$(Get_Last_Nchar "${subnet_header}" "${WLN_NUM_1}")

    #Append colon (:)
    #Remark:
    #   Only if:
    #   1. netmask < 124 -> not the last hex-block
    #   2. hexblock_trail_hexlen = 4 -> length the trailing hex-block is 4
    if [[ ${netmask} -le 124 ]]; then
        if [[ ${hexblock_trail_hexlen} -eq ${WLN_IPV6_ONEBLOCKLEN_IN_HEXES} ]]; then
            if [[ "${subnet_header_lastchar}" != "${WLN_COLON}" ]]; then
                subnet_header="${subnet_header}${WLN_COLON}"
            fi
        fi
    fi

    #Get the length of 'subnet_header_wo_colon'
    subnet_header_wo_colon_len=$(Get_StringLen_Exluding_Specified_Char \
            "${subnet_header}" \
            "${WLN_COLON}")

    #Append zeros (0) to 'subnet_header'
    local subnet_edgebound=${subnet_header}
    local mod_n=0
    local n_start=$(( subnet_header_wo_colon_len + 1 ))
    
    # shellcheck disable=SC2004
    for ((n=${n_start}; n<=${WLN_IPV6_ADDRLEN_IN_HEXES}; n++))
    do
        #Append zero (0)
        subnet_edgebound="${subnet_edgebound}${char}"
   
        #Calculate the modulus of 'n and WLN_IPV6_ONEBLOCKLEN_IN_HEXES'
        mod_n=$(( n % WLN_IPV6_ONEBLOCKLEN_IN_HEXES ))
        #Check if 'mod_n = 0 and n != 32
        if [[ ${mod_n} -eq 0 ]] && [[ ${n} -ne ${WLN_IPV6_ADDRLEN_IN_HEXES} ]]; then
            #Append colon (:)
            subnet_edgebound="${subnet_edgebound}${WLN_COLON}"
        fi
    done
    
    #Output
    echo "${subnet_edgebound}"

    return 0;
}
Ipv6_Get_Subnet_NetworkId() {
    #Input args
    local subnet_networkid=${1}
    local netmask=${2}

    #Define variables
    local lastchar=${WLN_EMPTYSTRING}
    local lasttwochars=${WLN_EMPTYSTRING}
    local subnet_networkid_header_wo_colon_len=0

    #Check if 'netmask > 128'
    if [[ ${netmask} -gt ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${WLN_IPV6_BOGUS_STRVAL}"
    
        return 0;
    fi
    
    #Get the length of 'subnet_networkid_header_wo_colon'
    subnet_networkid_header_wo_colon_len=$(Get_StringLen_Exluding_Specified_Char \
            "${subnet_networkid}" \
            "${WLN_COLON}")

    
    #Define and initialize variables 
    local subnet_networkid_output=${subnet_networkid}
    local n=${subnet_networkid_header_wo_colon_len}
    local mod_n=$(( n % WLN_IPV6_ONEBLOCKLEN_IN_HEXES ))
    
    #Append zeros (0) to 'subnet_networkid'
    #Remark:
    #   If 'mod_n = 0', then it means that this hex-block is completely occupied by 4 hex-digits.
    #       In this case, exit the loop immediately.
    #   This also means that should 'mod_n = 0' already from the start, then
    #       this loop won't be skipped automatically.
    while [[ ${mod_n} -ne 0 ]]
    do
        #Append zero (0)
        subnet_networkid_output="${subnet_networkid_output}${WLN_IPV6_TRAILCHAR_0}"
        
        #Increment counter
        n=$(( n + 1 ))
        
        #Calculate the modulus
        mod_n=$(( n % WLN_IPV6_ONEBLOCKLEN_IN_HEXES ))
    done
    
    #Append single-colon (:) or double-colon (::)
    if [[ ${netmask} -le 112 ]]; then   #not looking at the last hex-block
        #Get the last two chars of 'subnet_networkid_output'
        lasttwochars=$(Get_Last_Nchar "${subnet_networkid_output}" "${WLN_NUM_2}")
        #Check if the 'lasttwochars' is NOT a double-colon (::)
        if [[ "${lasttwochars}" != "${WLN_DOUBLECOLON}" ]]; then  #double-colon was found
            #Get the last char of 'subnet_networkid_output'
            lastchar=$(Get_Last_Nchar "${subnet_networkid_output}" "${WLN_NUM_1}")
            #Check if the 'lastchar' is a colon (:)
            if [[ "${lastchar}" == "${WLN_COLON}" ]]; then  #colon was found
                subnet_networkid_output="${subnet_networkid_output}${WLN_COLON}"
            else    #no colon (:) found
                subnet_networkid_output="${subnet_networkid_output}${WLN_DOUBLECOLON}"
            fi
        fi
    fi
    
    #Append 'netmask'
    subnet_networkid_output="${subnet_networkid_output}/${netmask}"
    
    #Output
    echo "${subnet_networkid_output}"
    
    return 0;
}

Ipv6_Check_And_Generate_Iprange_Handler() {
    #Input args
    local ipaddr=${1}
    local netmask=${2}
    local iprange_lowerbound=${3}
    local iprange_upperbound=${4}
    
    #Check if 'netmask > 128'
    if [[ ${netmask} -gt ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${WLN_IPV6_BOGUS_STRVAL}"
    
        return 0;
    fi
    
    #Define and initialize variables
    local PHASE_START=0
    local PHASE_CHECK_LOWERBOUND=1
    local PHASE_CHECK_UPPERBOUND=2
    local PHASE_COMPARE_LOWERBOUND_UPPERBOUND=3
    local PHASE_EXIT=4
    
    local iprange_lowerbound_extend=${WLN_EMPTYSTRING}
    local iprange_upperbound_extend=${WLN_EMPTYSTRING}
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
                iprange_lowerbound_extend=$(Ipv6_SubstituteFor_And_Prepend_Zeros "${iprange_lowerbound}")
                iprange_upperbound_extend=$(Ipv6_SubstituteFor_And_Prepend_Zeros "${iprange_upperbound}")
        
                ret="${iprange_lowerbound_extend},${iprange_upperbound_extend}"
        
                #Get Subnet NetworkID, Lowerbound and Upperbound
                subnet_result=$(IPv6_Get_Subnet_Data "${ipaddr}" "${netmask}")
                subnet_networkid=$(echo "${subnet_result}" | cut -d"," -f1)
                subnet_lowerbound=$(echo "${subnet_result}" | cut -d"," -f2)
                subnet_upperbound=$(echo "${subnet_result}" | cut -d"," -f3)
            
                #Goto next-phase
                phase=${PHASE_CHECK_LOWERBOUND}
                ;;
            "${PHASE_CHECK_LOWERBOUND}")
                #Check if 'iprange_lowerbound' is part-of 'ipaddr/netmask'
                check_result=$(Ipv6_CheckIf_Ip_Is_PartOf_Specified_IpRange \
                        "${iprange_lowerbound}" \
                        "${subnet_lowerbound}" \
                        "${subnet_upperbound}")
                
                #Counteract if 'check_result = false'
                if [[ ${check_result} == false ]]; then
                    #Validate and Generate IP-ranges
                    ret=$(Ipv6_Generate_Iprange "${netmask}" "${subnet_lowerbound}" "${subnet_upperbound}")
                    
                    #Goto next-phase
                    phase=${PHASE_EXIT}
                else
                    #Goto next-phase
                    phase=${PHASE_CHECK_UPPERBOUND}
                fi
                ;;
            "${PHASE_CHECK_UPPERBOUND}")
                #Check if 'iprange_upperbound' is part-of 'ipaddr/netmask'
                check_result=$(Ipv6_CheckIf_Ip_Is_PartOf_Specified_IpRange \
                        "${iprange_upperbound}" \
                        "${subnet_lowerbound}" \
                        "${subnet_upperbound}")
                        
                #Counteract if 'check_result = false'
                if [[ ${check_result} == false ]]; then
                    #Validate and Generate IP-ranges
                    ret=$(Ipv6_Generate_Iprange "${netmask}" "${subnet_lowerbound}" "${subnet_upperbound}")
                    
                    #Goto next-phase
                    phase=${PHASE_EXIT}
                else
                    #Goto next-phase
                    phase=${PHASE_COMPARE_LOWERBOUND_UPPERBOUND}
                fi
                ;;
            "${PHASE_COMPARE_LOWERBOUND_UPPERBOUND}")
                #Check if 'iprange_lowerbound' is smaller than 'iprange_upperbound'
                check_result=$(Ipv6_CheckIf_FirstIp_IsSmallerThan_SecondIp \
                        "${iprange_lowerbound}" \
                        "${iprange_upperbound}")
                
                #Counteract if 'check_result = false'
                if [[ ${check_result} == false ]]; then
                    #Validate and Generate IP-ranges
                    ret=$(Ipv6_Generate_Iprange "${netmask}" "${subnet_lowerbound}" "${subnet_upperbound}")
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
Ipv6_Generate_Iprange() {
    #Input args
    local netmask=${1}
    local subnet_lowerbound=${2}
    local subnet_upperbound=${3}
    
    #Check if 'netmask > 128'
    if [[ ${netmask} -gt ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${WLN_IPV6_BOGUS_STRVAL}"
    
        return 0;
    fi
    
    #Define and initialize variables
    local subnet_lowerbound_output=${subnet_lowerbound}
    local subnet_upperbound_output=${subnet_upperbound}
    local subnet_lowerbound_wo_last_hexblock=${subnet_upperbound::-4}   #use the 'subnet_upperbound'
    local ret="${subnet_lowerbound_output},${subnet_upperbound_output}"

    #Check if 'netmask => 112'
    #Remark:
    #   If 'netmask = 112', then a maximum of 65536 IP-addresses are available.
    #   However, the first and last IP-addresses can NOT be used:
    #       first IP-address -> network-number
    #       last IP-address -> broadcast IP
    if [[ ${netmask} -ge ${WLN_IPV6_CIDR_112} ]]; then
        echo "${ret}"
    
        return 0;
    fi
    
    #In case 'netmask < 112'
    #Update 'subnet_lowerbound_output' which should ALWAYS end with the 4 hex-digits (0000)
    subnet_lowerbound_output="${subnet_lowerbound_wo_last_hexblock}${WLN_IPV6_SUBNET_LOWERBOUND_MINVAL}"

    #Update 'subnet_upperbound_output' which should ALWAYS end with the 4 hex-digits (ffff)
    subnet_upperbound_output="${subnet_lowerbound_wo_last_hexblock}${WLN_IPV6_SUBNET_UPPERBOUND_MAXVAL}"
    
    #Update 'ret'
    ret="${subnet_lowerbound_output},${subnet_upperbound_output}"
    
    #Output
    echo "${ret}"
    
    return 0;
}
Ipv6_CheckIf_Ip_Is_PartOf_Specified_IpRange() {
    #Input args
    local ipaddr=${1}
    local iprange_lowerbound=${2}
    local iprange_upperbound=${3}

    #Define variables
    local ipaddr_conv=${WLN_EMPTYSTRING}
    local iprange_lowerbound_conv=${WLN_EMPTYSTRING}
    local iprange_upperbound_conv=${WLN_EMPTYSTRING}

    #Convert double-colon(::) to zeros
    ipaddr_conv=$(Ipv6_Subst_DoubleColons_With_Zeros "${ipaddr}")
    iprange_lowerbound_conv=$(Ipv6_Subst_DoubleColons_With_Zeros "${iprange_lowerbound}")
    iprange_upperbound_conv=$(Ipv6_Subst_DoubleColons_With_Zeros "${iprange_upperbound}")   
    
    #Compare 'ipaddr_conv' with 'iprange_lowerbound_conv' and 'iprange_upperbound_conv'
    local ret=false
    local ipaddr_conv_block_hex=""
    local iprange_lowerbound_block_hex=""
    local iprange_upperbound_block_hex=""
    local ipaddr_conv_block_dec=0
    local iprange_lowerbound_block_dec=0
    local iprange_upperbound_block_dec=0
    local ipaddr_is_above_lowerbound=false
    local ipaddr_is_below_upperbound=false

    # shellcheck disable=SC2004
    for (( b=1; b<=${WLN_IPV6_ADDRLEN_IN_BLOCKS}; b++ ))
    do
        #IMPORTANT: reset variables
        ipaddr_is_above_lowerbound=false
        ipaddr_is_below_upperbound=false
        # ipaddr_is_equalto_lowerbound=false
        # ipaddr_is_equalto_upperbound=false
        
        #Get the 4 hex-digits of each b
        ipaddr_conv_block_hex=$(echo "${ipaddr_conv}" | cut -d":" -f"${b}")
        iprange_lowerbound_block_hex=$(echo "${iprange_lowerbound_conv}" | cut -d":" -f"${b}")
        iprange_upperbound_block_hex=$(echo "${iprange_upperbound_conv}" | cut -d":" -f"${b}")

        #Convert the 4 hex-digits into decimal
        ipaddr_conv_block_dec=$(HexToDec64 "${ipaddr_conv_block_hex}")
        iprange_lowerbound_block_dec=$(HexToDec64 "${iprange_lowerbound_block_hex}")
        iprange_upperbound_block_dec=$(HexToDec64 "${iprange_upperbound_block_hex}")


        #Compare 'ipaddr_conv_block_dec' with 'iprange_lowerbound_block_dec'
        #Remark:
        #   If ipaddr_conv_block_dec = iprange_lowerbound_block_dec -> do nothing
        if [[ ${ipaddr_conv_block_dec} -gt ${iprange_lowerbound_block_dec} ]]; then
            #Compare 'ipaddr_conv_block_dec' with 'iprange_upperbound_block_dec'
            #Remark:
            #   If ipaddr_conv_block_dec = iprange_upperbound_block_dec -> do nothing
            if [[ ${ipaddr_conv_block_dec} -lt ${iprange_upperbound_block_dec} ]]; then #less
                echo "true"
                
                return 0;
            elif [[ ${ipaddr_conv_block_dec} -gt ${iprange_upperbound_block_dec} ]]; then #less
                echo "false"
                
                return 0;
            fi
        elif [[ ${ipaddr_conv_block_dec} -lt ${iprange_lowerbound_block_dec} ]]; then
            echo "false"
    
            return 0;
        fi
    done

    #Remark:
    #   If this stage has been reached, then it means that:
    #       'ipaddr_conv_block_dec = iprange_lowerbound_block_dec'
    #   And/or
    #       'ipaddr_conv_block_dec = iprange_upperbound_block_dec'
    #Output
    echo "true"
    
    return 0;
}
Ipv6_CheckIf_Ip_Is_PartOf_Specified_IpNetmask() {
    #Input args
    local ipaddr=${1}
    local netmask=${2}
    local ipaddr_target=${3}

    #Define variables
    local ret=${WLN_EMPTYSTRING}
    local subnet_result=${WLN_EMPTYSTRING}
    local subnet_networkid=${WLN_EMPTYSTRING}
    local subnet_lowerbound=${WLN_EMPTYSTRING}
    local subnet_upperbound=${WLN_EMPTYSTRING}

    #Check if 'netmask > 128'
    if [[ ${netmask} -gt ${WLN_IPV6_ADDRLEN_IN_BITS} ]]; then
        echo "${WLN_IPV6_BOGUS_STRVAL}"
    
        return 0;
    fi

    #Get Subnet Lowerbound and Upperbound
    subnet_result=$(IPv6_Get_Subnet_Data "${ipaddr}" "${netmask}")
    subnet_networkid=$(echo "${subnet_result}" | cut -d"," -f1)
    subnet_lowerbound=$(echo "${subnet_result}" | cut -d"," -f2)
    subnet_upperbound=$(echo "${subnet_result}" | cut -d"," -f3)
    
    #Check if IP is within the range 'subnet_lowerbound' and 'subnet_upperbound'
    ret=$(Ipv6_CheckIf_Ip_Is_PartOf_Specified_IpRange \
            "${ipaddr_target}" \
            "${subnet_lowerbound}" \
            "${subnet_upperbound}")
            
    #Output
    echo "${ret}"
    
    return 0;
}
Ipv6_CheckIf_FirstIp_IsSmallerThan_SecondIp() {
    #Input args
    local ipaddr1=${1}
    local ipaddr2=${2}

    #Define variables
    local ipaddr1_conv=${WLN_EMPTYSTRING}
    local ipaddr2_conv=${WLN_EMPTYSTRING}  

    #Convert double-colon(::) to zeros
    ipaddr1_conv=$(Ipv6_Subst_DoubleColons_With_Zeros "${ipaddr1}")
    ipaddr2_conv=$(Ipv6_Subst_DoubleColons_With_Zeros "${ipaddr2}")    

    #Define and initialize variables
    local ret=false
    local ipaddr1_conv_block_hex=""
    local ipaddr2_conv_block_hex=""
    local ipaddr1_conv_block_dec=0
    local ipaddr2_conv_block_dec=0

    #Compare 'ipaddr1_conv' with 'ipaddr2_conv'
    # shellcheck disable=SC2004
    for (( b=1; b<=${WLN_IPV6_ADDRLEN_IN_BLOCKS}; b++ ))
    do
        #Get the 4 hex-digits of each b
        ipaddr1_conv_block_hex=$(echo "${ipaddr1_conv}" | cut -d":" -f"${b}")
        ipaddr2_conv_block_hex=$(echo "${ipaddr2_conv}" | cut -d":" -f"${b}")

        #Convert the 4 hex-digits into decimal
        ipaddr1_conv_block_dec=$(HexToDec64 "${ipaddr1_conv_block_hex}")
        ipaddr2_conv_block_dec=$(HexToDec64 "${ipaddr2_conv_block_hex}")

        #Check if 'ipaddr1_conv_block_dec > ipaddr2_conv_block_dec'
        if [[ ${ipaddr1_conv_block_dec} -lt ${ipaddr2_conv_block_dec} ]]; then
            ret=true
    
            break
        elif [[ ${ipaddr1_conv_block_dec} -gt ${ipaddr2_conv_block_dec} ]]; then
            ret=false
    
            break
        fi
    done
    
    #Output
    echo "${ret}"
    
    return 0;    
}



#---MAIN SUBROUTINE
main__sub() {
    #Define variables
    local ipv6_addr_in=""
    local ipv6_range_lowerbound_in=""
    local ipv6_range_upperbound_in=""
    local netmaskv6_in=""
    local result=""
    local ipv6_range_lowerbound_out=""
    local ipv6_range_upperbound_out=""
    local subnet_networkid=""
    local subnet_lowerbound=""
    local subnet_upperbound=""

    local print_subnet_result=""



    #Get Subnet's NetworkID, Lowerbound, Upperbound
    # ipv6_addr_in="cdef:bbbb:cccc:dddd:7777:6666:5555:4321"
    # ipv6_addr_in="cdef:bbbb::8765:4321"
    # ipv6_addr_in="1234:5678:9abc:def0::1"
    ipv6_addr_in="2001:45:46::1"
    netmaskv6_in=64
    # ipv6_range_lowerbound_in="1234:5678:9abc:def0::1000"
    # ipv6_range_upperbound_in="1234:5678:9abc:def0::2000"
    ipv6_range_lowerbound_in="2001:45:46::0000"
    ipv6_range_upperbound_in="2001:45:46::ffff"
    
    result=$(IPv6_Get_Subnet_Data "${ipv6_addr_in}" "${netmaskv6_in}")
    subnet_networkid_out=$(echo "${result}" | cut -d"," -f1)
    subnet_lowerbound_out=$(echo "${result}" | cut -d"," -f2)
    subnet_upperbound_out=$(echo "${result}" | cut -d"," -f3)

    #Print
    print_subnet_result="subnet_networkid_out:\t${subnet_networkid_out}\n"
    print_subnet_result+="subnet_lowerbound_out:\t${subnet_lowerbound_out}\n"
    print_subnet_result+="subnet_upperbound_out:\t${subnet_upperbound_out}\n"
    echo -e "${print_subnet_result}"
    


    #Validate and Autocorrect IPv6-range
    result=$(Ipv6_Check_And_Generate_Iprange_Handler \
            "${ipv6_addr_in}" \
            "${netmaskv6_in}" \
            "${ipv6_range_lowerbound_in}" \
            "${ipv6_range_upperbound_in}")
    ipv6_range_lowerbound_out=$(echo "${result}" | cut -d"," -f1)
    ipv6_range_upperbound_out=$(echo "${result}" | cut -d"," -f2)

    #Print
    print_subnet_result="ipv6_range_lowerbound_out:\t${ipv6_range_lowerbound_out}\n"
    print_subnet_result+="ipv6_range_upperbound_out:\t${ipv6_range_upperbound_out}\n"
    echo -e "${print_subnet_result}"
}



#---EXECUTE MAIN SUBROUTINE
main__sub
