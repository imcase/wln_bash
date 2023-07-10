#!/bin/bash
#---FUNCTIONS
exit_handler() {
    #Input args
    local result=${1}

    #Check if 'result' is set to 'REJECTED'
    if [[ "${result}" == "${REJECTED}" ]]; then
        bridge_delif_and_print
    fi
}



bridge_delif_and_print() {
    #Define constants
    local PRINTMSG_NETPLAN_APPLY="netplan> ${WLN_LIGHTGREY}apply${WLN_RESETCOLOR}"
    local PRINTMSG_WLAN_YAML_INSERT_INTO_LINE="${WLN_WLAN_YAML}> ${WLN_LIGHTGREEN}insert${WLN_RESETCOLOR} into line"
    local PRINTMSG_WLAN_YAML_DELETE_LINE="${WLN_WLAN_YAML}> ${WLN_SOFLIGHTRED}delete${WLN_RESETCOLOR} line"
    local PRINTMSG_WAIT_FOR_1_SEC="wait for ${WLN_LIGHTGREY}1${WLN_RESETCOLOR} sec"

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local sed_netplan_interfaces_svstop="${WLN_EMPTYSTRING}"
    local linenum=0
    local nextlinenum=0
    local ret=false

    #Bring bridge interface down
    cmd="ip link set dev ${WLN_BR0} down"
    ret=$(CmdExec "${cmd}" "false")

    #Delete bridge interface
    cmd="ip link del ${WLN_BR0}"
    ret=$(CmdExec "${cmd}" "false")

    #Get 'linenum' matching the pattern 'WLN_PATTERN_INTERFACES'
    linenum=$(interfaces_linenum_get)
    if [[ ${linenum} -eq 0 ]]; then
        return 0;
    fi

    #Update variable
    sed_netplan_interfaces_svstop="${WLN_SED_SIXSPACES_ESCAPED}${WLN_PATTERN_INTERFACES}: [${WLN_WLAN0}]"

    #Insert
    sudo sed -i "${linenum}i ${sed_netplan_interfaces_svstop}" "${WLN_WLAN_YAML_FPATH}"

    #Get printable string of 'sed_netplan_interfaces_svstop'
    printmsg=$(echo "${sed_netplan_interfaces_svstop}" | sudo sed 's/\\//g')
    #Print
    echo -e "${WLN_PRINTMSG_STATUS}: ${PRINTMSG_WLAN_YAML_INSERT_INTO_LINE} '${WLN_LIGHTGREY}${linenum}${WLN_RESETCOLOR}': ${WLN_LIGHTGREY}${printmsg}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"

    #Get 'nextlinenum'
    nextlinenum=$(( linenum + 1 ))
    #Delete 'nextlinenum'
    sudo sed -i "${nextlinenum}d" "${WLN_WLAN_YAML_FPATH}"
    #Print
    echo -e "${WLN_PRINTMSG_STATUS}: ${PRINTMSG_WLAN_YAML_DELETE_LINE} '${WLN_LIGHTGREY}${nextlinenum}${WLN_RESETCOLOR}': ${WLN_PRINTMSG_DONE}"

    #Apply netplan
    cmd="${WLN_NETPLAN_APPLY}"
    ret=$(CmdExec "${cmd}" "false")

    #Wait for 1 second
    cmd="sleep 1"
    ret=$(CmdExec "${cmd}" "false")

    #Print empty-line
    echo -e "\r"
}
interfaces_linenum_get() {
    #Define constants
    local PHASE_EXITFUNC_LINENUMS_GET=1
    local PHASE_EXITFUNC_BRIDGES_LINENUM_VALIDATE=10
    local PHASE_EXITFUNC_BR0_LINENUM_VALIDATE=20
    local PHASE_EXITFUNC_INTERFACES_LINENUM_VALIDATE=30
    local PHASE_EXITFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_EXITFUNC_LINENUMS_GET}"
    local mytext="${WLN_EMPTYSTRING}"
    local br0_linenum=0
    local bridges_linenum=0
    local diff_linenum=0
    local interfaces_linenum=0

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_EXITFUNC_LINENUMS_GET}")
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
                phase="${PHASE_EXITFUNC_BRIDGES_LINENUM_VALIDATE}"
                ;;
            "${PHASE_EXITFUNC_BRIDGES_LINENUM_VALIDATE}")
                #Do not continue if 'bridges_linenum = <Empty String>'
                if [[ -z "${bridges_linenum}" ]]; then
                    #Set 'interfaces_linenum = 0'
                    interfaces_linenum=0

                    #Goto next-phase
                    phase="${PHASE_EXITFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_EXITFUNC_BR0_LINENUM_VALIDATE}"
                fi
                ;;
            "${PHASE_EXITFUNC_BR0_LINENUM_VALIDATE}")
                #Check if 'br0_linenum' is an Empty string or not.
                if [[ -z "${br0_linenum}" ]]; then
                    #Set 'interfaces_linenum = 0'
                    interfaces_linenum=0

                    #Goto next-phase
                    phase="${PHASE_EXITFUNC_EXIT}"
                else
                    #Check if 'diff_linenum = br0_linenum - bridges_linenum = 1'
                    diff_linenum=$((br0_linenum - bridges_linenum))
                    #Do not continue if 'diff_linenum != 1'
                    if [[ ${diff_linenum} -ne 1 ]]; then
                        #Set 'interfaces_linenum = 0'
                        interfaces_linenum=0

                        #Goto next-phase
                        phase="${PHASE_EXITFUNC_EXIT}"
                    else
                        #Goto next-phase
                        phase="${PHASE_EXITFUNC_INTERFACES_LINENUM_VALIDATE}"
                    fi
                fi
                ;;
            "${PHASE_EXITFUNC_INTERFACES_LINENUM_VALIDATE}")
                #Do not continue if 'interfaces_linenum = <Empty String>'
                if [[ -z "${interfaces_linenum}" ]]; then
                    #Set 'interfaces_linenum = 0'
                    interfaces_linenum=0
                else
                    #Check if 'diff_linenum = interfaces_linenum - br0_linenum = 1'
                    diff_linenum=$((interfaces_linenum - br0_linenum))
                    #Do not continue if 'diff_linenum != 1'
                    if [[ ${diff_linenum} -ne 1 ]]; then
                        #Set 'interfaces_linenum = 0'
                        interfaces_linenum=0
                    fi
                fi

                #Goto next-phase
                phase="${PHASE_EXITFUNC_EXIT}"
                ;;
            "${PHASE_EXITFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${interfaces_linenum}"

    return 0;
}
