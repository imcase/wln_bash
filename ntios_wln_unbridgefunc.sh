#!/bin/bash
#---FUNCTIONS
WLN_Unbridge_Interfaces_Handler() {
    #Define constants
    local NETPLAN_INTERFACES_FIELD="${WLN_SED_SIXSPACES_ESCAPED}${WLN_PATTERN_INTERFACES}: [${WLN_WLAN0}]"

    #Define variables
    local mytext="${WLN_EMPTYSTRING}"
    local interfaces_linenum=0
    local nextlinenum=0
    local netplan_interfaces_field_printable="${WLN_EMPTYSTRING}"
    
    #Bring bridge interface down
    sudo ip link set dev ${WLN_BR0} down; exitcode=$?
    
    #Print
    mytext="ip> bring ${WLN_LIGHTGREY}${WLN_BR0}${WLN_RESETCOLOR} Down"
    PrintMessage "${mytext}" "${exitcode}" "false"

    #remove bridge interface
    sudo ip link del ${WLN_BR0}; exitcode=$?

    #Print
    mytext="ip> del bridge interface ${WLN_LIGHTGREY}${WLN_BR0}${WLN_RESETCOLOR}"
    PrintMessage "${mytext}" "${exitcode}" "false"

    if [[ -f "${WLN_WLAN_YAML_FPATH}" ]]; then
        #Get the line-number of the interfaces-field
        interfaces_linenum=$(interfaces_linenum_get)
        if [[ ${interfaces_linenum} -eq 0 ]]; then
            return 0;
        fi

        #Insert 
        sudo sed -i "${interfaces_linenum}i ${NETPLAN_INTERFACES_FIELD}" "${WLN_WLAN_YAML_FPATH}"; exitcode=$?
        #Get printable string of 'sed_netplan_interfaces_svstop'
        netplan_interfaces_field_printable=$(echo "${NETPLAN_INTERFACES_FIELD}" | sed 's/\\//g')
        #Print
        mytext="sed> insert '${WLN_LIGHTGREY}${netplan_interfaces_field_printable}${WLN_RESETCOLOR}' into line ${WLN_LIGHTGREY}${interfaces_linenum}${WLN_RESETCOLOR}"
        PrintMessage "${mytext}" "${exitcode}" "false"


        #Delete 'nextlinenum'
        nextlinenum=$(( interfaces_linenum + 1 ))
        sudo sed -i "${nextlinenum}d" "${WLN_WLAN_YAML_FPATH}"; exitcode=$?

        #Print
        mytext="sed> delete line-number ${WLN_LIGHTGREY}${nextlinenum}${WLN_RESETCOLOR} in ${WLN_LIGHTGREY}${WLN_WLAN_YAML_FPATH}${WLN_RESETCOLOR}"
        PrintMessage "${mytext}" "${exitcode}" "false"
    fi

    #Apply netplan
    sudo netplan apply; exitcode=$?
    #Print
    mytext="netplan> apply"
    PrintMessage "${mytext}" "${exitcode}" "false"

    #Wait for 3 second
    sleep 3
    #Print
    mytext="sleep> 3 seconds"
    PrintMessage "${mytext}" "${exitcode}" "true"

    # #Print empty-line
    # echo -e "\r"
}
interfaces_linenum_get() {
    #Define constants
    local PHASE_UNBRIDGEFUNCLINENUMS_GET=1
    local PHASE_UNBRIDGEFUNCBRIDGES_LINENUM_VALIDATE=10
    local PHASE_UNBRIDGEFUNCBR0_LINENUM_VALIDATE=20
    local PHASE_UNBRIDGEFUNCINTERFACES_LINENUM_VALIDATE=30
    local PHASE_UNBRIDGEFUNCEXIT=100

    #Define variables
    local phase="${PHASE_UNBRIDGEFUNCLINENUMS_GET}"
    local mytext="${WLN_EMPTYSTRING}"
    local br0_linenum=0
    local bridges_linenum=0
    local diff_linenum=0
    local interfaces_linenum=0

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_UNBRIDGEFUNCLINENUMS_GET}")
                #Get the line-numbers
                #Remark:
                #   The 'wlan.yaml' for ACCESSPOINT and ROUTER mode is designed
                #   ...to have the following inter-relationship between the line-numbers:
                #   bridges_linenum = based on the position in 'wlan.yaml' (e.g. 8)
                #   br0_linenum = bridges_linenum + 1 (e.g. 9)
                #   interfaces_linenum = br0_linenum + 1 (e.g. 10)
                bridges_linenum=$(grep -no "${WLN_PATTERN_BRIDGES}.*" "${WLN_WLAN_YAML_FPATH}" | cut -d":" -f1); exitcode=$?
                br0_linenum=$(grep -no "${WLN_BR0}.*" "${WLN_WLAN_YAML_FPATH}" | cut -d":" -f1); exitcode=$?
                interfaces_linenum=$(grep -no "${WLN_PATTERN_INTERFACES}.*" "${WLN_WLAN_YAML_FPATH}" | cut -d":" -f1); exitcode=$?

                #Goto next-phase
                phase="${PHASE_UNBRIDGEFUNCBRIDGES_LINENUM_VALIDATE}"
                ;;
            "${PHASE_UNBRIDGEFUNCBRIDGES_LINENUM_VALIDATE}")
                #Do not continue if 'bridges_linenum = <Empty String>'
                if [[ -z "${bridges_linenum}" ]]; then
                    #Update header message
                    mytext="grep> pattern ${WLN_LIGHTGREY}${WLN_PATTERN_BRIDGES}${WLN_RESETCOLOR} in file ${WLN_LIGHTGREY}${WLN_WLAN_YAML_FPATH}${WLN_RESETCOLOR}"

                    #Set 'interfaces_linenum = 0'
                    interfaces_linenum=0

                    #Goto next-phase
                    phase="${PHASE_UNBRIDGEFUNCEXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_UNBRIDGEFUNCBR0_LINENUM_VALIDATE}"                
                fi
                ;;
            "${PHASE_UNBRIDGEFUNCBR0_LINENUM_VALIDATE}")
                #Check if 'br0_linenum' is an Empty string or not.
                if [[ -z "${br0_linenum}" ]]; then
                    #Update header message
                    mytext="grep> pattern ${WLN_LIGHTGREY}${WLN_BR0}${WLN_RESETCOLOR} in file ${WLN_LIGHTGREY}${WLN_WLAN_YAML_FPATH}${WLN_RESETCOLOR}"

                    #Set 'interfaces_linenum = 0'
                    interfaces_linenum=0

                    #Goto next-phase
                    phase="${PHASE_UNBRIDGEFUNCEXIT}"
                else
                    #Check if 'diff_linenum = br0_linenum - bridges_linenum = 1'
                    diff_linenum=$((br0_linenum - bridges_linenum))
                    #Do not continue if 'diff_linenum != 1'
                    if [[ ${diff_linenum} -ne 1 ]]; then
                        #Update header message
                        mytext="netplan-check> field ${WLN_LIGHTGREY}${WLN_BR0}${WLN_RESETCOLOR} follows directly after ${WLN_LIGHTGREY}${WLN_PATTERN_BRIDGES}${WLN_RESETCOLOR}"

                        #Set 'interfaces_linenum = 0'
                        interfaces_linenum=0

                        #Goto next-phase
                        phase="${PHASE_UNBRIDGEFUNCEXIT}"
                    else
                        #Goto next-phase
                        phase="${PHASE_UNBRIDGEFUNCINTERFACES_LINENUM_VALIDATE}"                
                    fi
                fi
                ;;
            "${PHASE_UNBRIDGEFUNCINTERFACES_LINENUM_VALIDATE}")
                #Do not continue if 'interfaces_linenum = <Empty String>'
                if [[ -z "${interfaces_linenum}" ]]; then
                    #Update header message
                    mytext="grep> pattern ${WLN_LIGHTGREY}${WLN_PATTERN_INTERFACES}${WLN_RESETCOLOR} in file ${WLN_LIGHTGREY}${WLN_WLAN_YAML_FPATH}${WLN_RESETCOLOR}"

                    #Set 'interfaces_linenum = 0'
                    interfaces_linenum=0
                else
                    #Check if 'diff_linenum = interfaces_linenum - br0_linenum = 1'
                    diff_linenum=$((interfaces_linenum - br0_linenum))
                    #Do not continue if 'diff_linenum != 1'
                    if [[ ${diff_linenum} -ne 1 ]]; then
                        #Update header message
                        mytext="netplan-check> field ${WLN_LIGHTGREY}${WLN_PATTERN_INTERFACES}${WLN_RESETCOLOR} follows directly after ${WLN_LIGHTGREY}${WLN_BR0}${WLN_RESETCOLOR}"

                        #Set 'interfaces_linenum = 0'
                        interfaces_linenum=0            
                    fi
                fi

                #Goto next-phase
                phase="${PHASE_UNBRIDGEFUNCEXIT}"  
                ;;
            "${PHASE_UNBRIDGEFUNCEXIT}")
                #Only print if 'interfaces_linenum = 0', and thus 'mytext' contains texts.
                if [[ ${interfaces_linenum} -eq 0 ]]; then
                    PrintMessage "${mytext}" "${WLN_EXITCODE_99}" "true"
                fi

                break
                ;;
        esac
    done

    #Output
    echo "${interfaces_linenum}"

    return 0;
}
PrintMessage() {
    #Define variables
    local mytext=${1}
    local exitcode=${2}
    local append_emptyline=${3}
    
    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local scriptname="${WLN_EMPTYSTRING}"
    local tty_curr=$(tty)

    #Retrieve basename of this script
    scriptname=$(basename ${BASH_SOURCE[0]})

    #Get the current 'tty'
    tty_curr=$(tty)

    #Print
    printmsg=":-->${WLN_ORANGE}STATUS${WLN_RESETCOLOR}: ${WLN_LIGHTGREY}${scriptname}${WLN_RESETCOLOR}: ${mytext}: "
    
    #Append the status (based on the outcome of the 'exitcode')
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg+="${WLN_LIGHTGREEN}SUCCESSFUL${WLN_RESETCOLOR}"
    else
        printmsg+="${WLN_SOFLIGHTRED}FAILED${WLN_RESETCOLOR} (ignore error)"
    fi

    #Print
    printf "%s\n" "${printmsg}" 1>${tty_curr}

    #Append Empty line
    if [[ ${append_emptyline} == true ]]; then
        printf "%s\n" 1>${tty_curr}
    fi
}
