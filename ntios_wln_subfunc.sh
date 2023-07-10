#!/bin/bash
#---FUNCTIONS
Chmod() {
    #Input args
    local istargetfpath=${1}
    local ispermissionval=${2}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    if [[ $(FileExists "${istargetfpath}") == true ]]; then
        #Change permissions
        sudo chmod "${ispermissionval}" "${istargetfpath}" >/dev/null;exitcode=$?;pid=$!;wait ${pid}

        #Print
        if [[ ${exitcode} -eq 0 ]]; then
            printmsg="${WLN_PRINTMSG_STATUS}: Change permissions of ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"

            ret=true
        else
            printmsg="${WLN_PRINTMSG_STATUS}: Change permissions of ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"

            ret=false
        fi
    else
        printmsg="${WLN_PRINTMSG_STATUS}: file '${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}' "
        printmsg+="does ${WLN_PRINTMSG_NOT} exist"

        ret=false
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;   
}

CmdExec() {
    #Input args
    local cmd=${1}
    local sudo_isnot_required=${2}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    ##Update print-message
    printmsg="${WLN_PRINTMSG_STATUS}: Execute ${WLN_LIGHTGREY}${cmd}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_IN_PROGRESS}"
    #Print
    DebugPrint "${printmsg}"

    #Execute command
    # shellcheck disable=SC2086
    # sudo ${cmd} >/dev/null;exitcode=$?;pid=$!;wait ${pid}
    if [[ ${sudo_isnot_required} == true ]]; then
        ${cmd} ; exitcode=$? ; pid=$! ; wait ${pid}
    else
        sudo ${cmd} ; exitcode=$? ; pid=$! ; wait ${pid}
    fi

    #Update print-message
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Execute ${WLN_LIGHTGREY}${cmd}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"

        ret=true
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Execute ${WLN_LIGHTGREY}${cmd}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"

        ret=false
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;
}

CopyFile() {
    #Input args
    local issourcefpath=${1}
    local istargetfpath=${2}

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    #Check if 'issourcefpath' exists
    if [[ $(FileExists "${issourcefpath}") == false ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: file '${WLN_LIGHTGREY}${issourcefpath}${WLN_RESETCOLOR}' "
        printmsg+="does ${WLN_PRINTMSG_NOT} exist"

        ret=false
    else
        #Write to file
        sudo cp "${issourcefpath}" "${istargetfpath}" >/dev/null; exitcode=$?; pid=$!; wait ${pid}

        #Print
        if [[ ${exitcode} -eq 0 ]]; then
            printmsg="${WLN_PRINTMSG_STATUS}: copy from '${WLN_LIGHTGREY}${issourcefpath}${WLN_RESETCOLOR}' "
            printmsg+="to '${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}': ${WLN_PRINTMSG_DONE}"

            ret=true
        else
            printmsg="${WLN_PRINTMSG_STATUS}: copy from '${WLN_LIGHTGREY}${issourcefpath}${WLN_RESETCOLOR}' "
            printmsg+="to '${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}': ${WLN_PRINTMSG_FAILED}"

            ret=false
        fi
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;   
}

CurlDomainGet() {
    #Define variables
    local ret="${WLN_EMPTYSTRING}"

    #Get Domain-code using curl
    ret=$(curl --silent https://ipinfo.io  | grep -o 'country.*' | cut -d":" -f2 | cut -d"\"" -f2)

    #Output
    echo "${ret}"

    return 0
}

DaisyChain_IsEnabled() {
    #Remark:
    # This function is defined in ntios_net.cpp

    #Check if Path exist
    local ret=false
    local currDaisyChainModeSetting_U8=${PL_NET_DAISYCHAINSET_OFF}

    currDaisyChainModeSetting_U8=$(cat "${NET_DAISYCHAIN_MODE_FPATH}")
    if [[ $(FileExists "${NET_DAISYCHAIN_MODE_FPATH}") == true ]]; then
    # if [[ -f "${NET_DAISYCHAIN_MODE_FPATH}" ]]; then
        if [[ ${currDaisyChainModeSetting_U8} -eq ${PL_NET_DAISYCHAINSET_ON} ]]; then
            ret=true
        fi
    fi

    #Output
    echo "${ret}"

    return 0
}

DebugPrint() {
    #Input args
    local printmsg=${1}

    #Get the current shell-terminal
    local tty_curr=$(tty)

    #Print
    #Remark:
    #   By redirecting the 'echo' output to the current shell-terminal (e.g. /dev/ttyS1)
    #   ...the 'echo' output can be seen on the terminal. 
    #   Without the redirection (1>${tty_curr}), this is not possible!
    echo -e "${printmsg}" 1>${tty_curr}
}

DirExists() {
    #Input args
    local isdir=${1}

    #Define variables
    local ret=false

    #Check if 'isdir' exists
    if [[ -z "${isdir}" ]]; then
        ret=false
    else
        if sudo test -d "${isdir}"; then
            ret=true
        else
            ret=false
        fi
    fi

    #Output
    echo "${ret}"

    return 0
}

FileExists() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local ret=false

    #Check if 'istargetfpath' exists
    if [[ -z "${istargetfpath}" ]]; then
        ret=false
    else
        if sudo test -f "${istargetfpath}"; then
            ret=true
        else
            ret=false
        fi
    fi

    #Output
    echo "${ret}"

    return 0
}

EvalCmdExec() {
    #Input args
    local cmd=${1}
    local sudo_isnot_required=${2}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret="${WLN_EMPTYSTRING}"

    ##Update print-message
    printmsg="${WLN_PRINTMSG_STATUS}: Execute ${WLN_LIGHTGREY}${cmd}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_IN_PROGRESS}"
    #Print
    DebugPrint "${printmsg}"

    #Prepend 'sudo' (if applicable)
    if [[ ${sudo_isnot_required} == false ]]; then
        cmd="sudo ${cmd}"
    fi
    #Execute command
    ret=$(eval ${cmd}) ; exitcode=$? ; pid=$! ; wait ${pid}

    #Update print-message
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Execute ${WLN_LIGHTGREY}${cmd}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Execute ${WLN_LIGHTGREY}${cmd}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;
}

PatternIsFound() {
    #Input args
    local ispattern=${1}
    local istargetfpath=${2}

    #Define constants
    local PHASE_PATTERNISFOUND_PATTERN_CHECK=1
    local PHASE_PATTERNISFOUND_PATH_CHECK=10
    local PHASE_PATTERNISFOUND_PATTERN_VALIDATE=20
    local PHASE_PATTERNISFOUND_EXIT=100

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local phase="${PHASE_PATTERNISFOUND_PATTERN_CHECK}"
    local ret=false

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_PATTERNISFOUND_PATTERN_CHECK}")
                if [[ -z "${ispattern}" ]]; then
                    ret=false

                    phase="${PHASE_PATTERNISFOUND_EXIT}"
                else
                    phase="${PHASE_PATTERNISFOUND_PATH_CHECK}"
                fi
                ;;
            "${PHASE_PATTERNISFOUND_PATH_CHECK}")
                if [[ $(FileExists "${istargetfpath}") == false ]]; then
                    ret=false

                    phase="${PHASE_PATTERNISFOUND_EXIT}"
                else
                    phase="${PHASE_PATTERNISFOUND_PATTERN_VALIDATE}"
                fi
                ;;
            "${PHASE_PATTERNISFOUND_PATTERN_VALIDATE}")
                cmd="grep \"${ispattern}\" \"${istargetfpath}\"" 
                if [[ -z $(EvalCmdExec "${cmd}" "false") ]]; then
                    ret=false
                else
                    ret=true
                fi

                phase="${PHASE_PATTERNISFOUND_EXIT}"
                ;;
            "${PHASE_PATTERNISFOUND_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0
}

IwDomainGet() {
    #Define variables
    local ret=${WLN_EMPTYSTRING} 
    
    #Get Domain-code
    ret=$(sudo iw reg get | grep -o "country.*" | cut -d" " -f2 | cut -d":" -f1)

    #Output
    echo "${ret}"

    return 0
}

GetInterfaceState() {
    #Input args
    local isintf=${1}

    #Define variables
    local intfstate=${WLN_UNKNOWN}
    local intfstate_alternative=${WLN_PATTERN_DOWN}

    #Get interface-state
    intfstate=$(cat "/sys/class/net/${isintf}/operstate")

    #Chekc if 'intfstate = unknown'
    if [[ "${intfstate}" != "${WLN_UP}" ]] && [[ "${intfstate}" != "${WLN_DOWN}" ]]; then
        #Check the interface-state using the 'ip' command
        intfstate_alternative=$(ip a list "${isintf}" | grep -o "${WLN_PATTERN_UP}.*" | cut -d"," -f1)
        #Translate 'intfstate_alternative' to 'intfstate'
        if [[ "${intfstate_alternative}" == "${WLN_PATTERN_UP}" ]]; then
            intfstate="${WLN_UP}"
        else
            intfstate="${WLN_DOWN}"
        fi
    fi

    #Output
    echo "${intfstate}"

    return 0;
}

IpIsForwarded() {
    #Input args
    local isPattern=${1}

    #Define variables
    local stdOutput=${WLN_EMPTYSTRING} 

    #Check if pattern is present
    stdOutput=$(grep -w "^${isPattern}" "${WLN_SYSCTL_CONF_FPATH}")
    if [[ -n "${stdOutput}" ]]; then
        echo true
    else
        echo false
    fi
}

IsHex() {
    #--------------------------------------------------------------------
    # Note: 
    #   Input arg 'isHex' is a value WITHOUT any preceding hex-sign (e.g. 0x)
    #--------------------------------------------------------------------
    #Input args
    local isHex=${1}

    #Define variables
    local hex_exec_ret=0
    local exitcode=0
    local ret=false

    #Get exit-code after executing the hex-command
    hex_exec_ret=$( (( 16#$isHex )) 2>&1); exitcode=$?
    
    if [[ ${exitcode} -eq 0 ]]; then
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}

Mkdir() {
    #Input args
    local isdir=${1}

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local ret="${WLN_EMPTYSTRING}"

    #Check and create dir
    if [[ $(DirExists "${isdir}") == false ]]; then
        cmd="mkdir -p ${isdir}"

        ret=$(CmdExec "${cmd}")
    else
        ret=true
    fi

    #Output
    echo "${ret}"

    return 0;
}

Ping() {
    #Input args
    local isintf=${1}
    local ipaddr=${2}
    local count=${3}
    local deadline=${4}

    #Define variables
    local exitcode=0
    local ret=false

    #Execute ping
    ping -n -I${isintf} -c "${count}" -w "${deadline}" "${ipaddr}" >/dev/null 2>&1; exitcode=$?

    #Output
    echo "${exitcode}"

    return 0;
}

PortIsAllowed() {
    #Input args
    local isPort=${1}

    #Define variables
     local stdOutput=${WLN_EMPTYSTRING}

    #Check if port is already allowed
    # shellcheck disable=SC2086
    stdOutput=$(sudo iptables -S | grep -w "${isPort}" | grep -w "${WLN_PATTERN_ACCEPT}")
    if [[ -n "${stdOutput}" ]]; then
        # shellcheck disable=SC2086
        stdOutput=$(sudo ip6tables -S | grep -w "${isPort}" | grep -w "${WLN_PATTERN_ACCEPT}")
        if [[ -n "${stdOutput}" ]]; then
            echo true
        else
            echo false
        fi
    else
        echo false
    fi
}

RemoveDir() {
    #Input args
    local istargetdir=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    #Remove 'wifi-powersave-off.service'
    if [[ $(DirExists "${istargetdir}") == true ]]; then
        sudo rm -rf "${istargetdir}" >/dev/null;exitcode=$?;pid=$!;wait ${pid}

        if [[ ${exitcode} -eq 0 ]]; then
            printmsg="${WLN_PRINTMSG_STATUS}: Remove ${WLN_LIGHTGREY}${istargetdir}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"

            ret=true
        else
            printmsg="${WLN_PRINTMSG_STATUS}: Remove ${WLN_LIGHTGREY}${istargetdir}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"
            
            ret=false
        fi
    else
        printmsg="${WLN_PRINTMSG_STATUS}: directory '${WLN_LIGHTGREY}${istargetdir}${WLN_RESETCOLOR}' "
        printmsg+="does ${WLN_PRINTMSG_NOT} exist (ignore)"

        ret=true
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;   
}

RemoveFile() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    #Remove 'wifi-powersave-off.service'
    if [[ $(FileExists "${istargetfpath}") == true ]]; then
        sudo rm "${istargetfpath}" >/dev/null;exitcode=$?;pid=$!;wait ${pid}

        if [[ ${exitcode} -eq 0 ]]; then
            printmsg="${WLN_PRINTMSG_STATUS}: Remove ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"

            ret=true
        else
            printmsg="${WLN_PRINTMSG_STATUS}: Remove ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"
            
            ret=false
        fi
    else
        printmsg="${WLN_PRINTMSG_STATUS}: file '${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}' "
        printmsg+="does ${WLN_PRINTMSG_NOT} exist (ignore)"

        ret=true
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;   
}

Substitute_String_With_Another_String() {
    #Input args
    local istargetfpath=${1}
    local oldstring=${2}
    local newstring=${3}

    #Substitute
    sudo sed -i "s/${oldstring}/${newstring}/g" ${istargetfpath}
}

Sudoers_Allow_SetOfCmds() {
    #Input args
    local ispid=${1}

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    # local col1="${WLN_EMPTYSTRING}"
    # local col2="${WLN_EMPTYSTRING}"
    # local col3="${WLN_EMPTYSTRING}"
    local colitem="${WLN_EMPTYSTRING}"
    local arritem="${WLN_EMPTYSTRING}"
    local srv_input="${WLN_EMPTYSTRING}"
    local i=1
    local ret_dummy=false

    #Define command line for 'ispid'
    cmd="systemctl start ${SYSTEMCTL_NTIOS_SU_ADD_AT}${ispid}"
    #Execute command
    ret_dummy=$(CmdExec "${cmd}" "false")

    #Loop thru array
    for arritem in "${BASH_SETSOFCMDS_ARR[@]}"
    do
        #Reset variables (IMPORTANT)
        colitem="${WLN_EMPTYSTRING}"
        srv_input="${WLN_EMPTYSTRING}"
        i=1

        while true
        do
            #Retrieve 'colitem' from 'arritem'
            colitem=$(echo "${arritem}" | cut -d"," -f${i})

            #Append to 'srv_input'
            if [[ -n "${colitem}" ]]; then  #is NOT <Empty String>
                srv_input+="${WLN_FOURBACKSLASHES_SLASH_HEX}${colitem}"
            else    #is <Empty String>
                srv_input+="${WLN_FOURBACKSLASHES_SPACE_HEX}${WLN_FOURBACKSLASHES_ASTERISK_HEX}"

                break
            fi

            #Increment index
            ((i++))
        done

        #Define command line for 'cmdfpath'
        cmd="systemctl start ${SYSTEMCTL_NTIOS_SU_ADD_AT}${srv_input}"
        #Execute command
        ret_dummy=$(CmdExec "${cmd}" "false")
    done
}

Touch() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local ret="${WLN_EMPTYSTRING}"

    #Check and create file
    if [[ ! -f "${istargetfpath}" ]]; then
        cmd="touch ${istargetfpath}"
        ret=$(CmdExec "${cmd}")
    else
        ret=true
    fi

    #Output
    echo "${ret}"

    return 0;
}

Touch_and_Chmod() {
    #Input args
    local istargetfpath=${1}
    local ispermissionval=${2}

    #Define variables
    local ret="${WLN_EMPTYSTRING}"

    #Check and create file
    if [[ $(Touch "${istargetfpath}" ) == true ]]; then
        if [[ $(Chmod "${istargetfpath}" "${ispermissionval}") == true ]]; then   
            ret=true
        else
            ret=false
        fi
    else
        ret=true
    fi

    #Output
    echo "${ret}"

    return 0;
}

WriteToFile() {
    #Input args
    local istargetfpath=${1}
    local data=${2}
    local issudoer=${3}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    #Write to file
    if [[ "${issudoer}" == true ]]; then
        echo -e "${data}" | sudo tee "${istargetfpath}" >/dev/null;exitcode=$?;pid=$!;wait ${pid}
    else
        echo -e "${data}" | tee "${istargetfpath}" >/dev/null;exitcode=$?;pid=$!;wait ${pid}
    fi

    #Print
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: write to ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"

        ret=true
    else
        printmsg="${WLN_PRINTMSG_STATUS}: write to ${WLN_LIGHTGREY}${istargetfpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"

        ret=false
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;   
}
