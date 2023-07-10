#!/bin/bash
#---FUNCTIONS
GetTimeStamps() {
    #Define variables
    local timestampsec=$(date +%s)

    #Output
    echo "${timestampsec}"
}

ModuleIsEnabled() {
    #Input args
    local isMod=${1}

    #Define variables
    local stdOutput=${WLN_EMPTYSTRING} 

    #Check if module is already enabled
    stdOutput=$(lsmod| grep "${isMod}")
    if [[ -n "${stdOutput}" ]]; then
        echo true
    else
        echo false
    fi
}

Service_Start_IfNotStartedYet() {
    #Input args
    local srv_name=${1}

    #Define variables
    local ret=false    

    #Check and Start srv_name (if needed)
    if [[ $(SystemctlServiceIsActive "${srv_name}") == false ]]; then
        if [[ $(SystemctlStartService "${srv_name}") == false ]]; then
            ret=false
        else
            ret=true
        fi
    else
        ret=true
    fi

    #Output
    echo "${ret}"

    return 0; 
}

SysClassNet_RetrieveInfo() {
    #Input args
    local intf=${1}
    local folder=${2}

    #Define fullpath
    local targetPath="${WLN_SYS_CLASS_NET_DIR}/${intf}/${folder}"

    #Retrieve file content
    local ret=$(cat "${targetPath}")

    #Output
    echo "${ret}"

    return 0;
}

TxBytes_Validate() {
    #Input args
    local isintf=${1}
    local ipaddr=${2}
    local count=${3}
    local deadline=${4}
    local folder=${5}

    #Define variables
    local exitcode=0
    local retry=0
    local tx_curr=0
    local tx_new=0
    local tx_diff=0
    local ret=false

    #Get the current tx-bytes value
    tx_curr=$(SysClassNet_RetrieveInfo "${isintf}" "${folder}")

    for ((retry=1; retry<=${WLN_TXBYTES_VALIDATE_RETRY_MAX}; retry++))
    do
        #Ping localhost (127.0.0.1) for 1 second
        #Remark:
        #   If the interface is working well, then the tx-bytes value should increase
        exitcode=$(Ping "${isintf}" "${ipaddr}" "${count}" "${deadline}")

        #Get the new tx-bytes value
        tx_new=$(SysClassNet_RetrieveInfo "${isintf}" "${folder}")

        #Calculate the difference between the new and current tx-bytes values
        tx_diff=$(( tx_new - tx_curr ))

        #Check if 'tx_diff != 0'
        if [[ ${tx_diff} -ne 0 ]]; then
            ret=true
            
            break
        fi
    done

    #Output
    echo "${ret}"

    return 0;
}

WLN_enable() {
    #Define constants
    local PHASE_ENABLEFUNC_BCMDHD_SET=1
    local PHASE_ENABLEFUNC_SERVICES_STOP=10
    local PHASE_ENABLEFUNC_INTFSTATE_SET=40
    local PHASE_ENABLEFUNC_INTFSTATE_CHECK=41
    local PHASE_ENABLEFUNC_SERVICES_START=50
    local PHASE_ENABLEFUNC_EXIT=100

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local phase="${PHASE_ENABLEFUNC_BCMDHD_SET}"
    local retry=0
    local ret=${REJECTED}
    local ret_dummy1=false
    local ret_dummy2=${REJECTED}

    #Start phase
    while true
    do
        case "${phase}" in
            ${PHASE_ENABLEFUNC_BCMDHD_SET})
                cmd="modprobe ${WLN_BCMDHD}"
                ret_dummy1=$(CmdExec "${cmd}")

                #Check if module is enabled
                if [[ $(ModuleIsEnabled "${WLN_BCMDHD}") == false ]]; then
                    #Update output value
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_ENABLEFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_ENABLEFUNC_SERVICES_STOP}"
                fi
                ;;
            "${PHASE_ENABLEFUNC_SERVICES_STOP}")
                #Stop service
                #Remark:
                #   Stopping the service is not part of 'enable()' function's validation.
                ret_dummy2=$(WLN_Services_CheckIfEnabled_And_ThenStop_Handler)

                #Goto next-phase
                phase="${PHASE_ENABLEFUNC_INTFSTATE_SET}"
                ;;
            "${PHASE_ENABLEFUNC_INTFSTATE_SET}")
                #Only bring interface down if failed to bring interface-up the 1st time.
                #Remark:
                #   Bringing interface DOWN and then UP may cause issues
                #   ...when trying to START hostapd-ng.service.
                if [[ ${retry} -gt 0 ]]; then
                    cmd="ip link set dev ${WLN_WLAN0} ${WLN_DOWN}"
                    ret_dummy1=$(CmdExec "${cmd}")
                fi

                #Bring interface up
                cmd="ip link set dev ${WLN_WLAN0} ${WLN_UP}"
                ret_dummy1=$(CmdExec "${cmd}")

                #Goto next-phase
                phase="${PHASE_ENABLEFUNC_INTFSTATE_CHECK}"
                ;;
            "${PHASE_ENABLEFUNC_INTFSTATE_CHECK}")
                if [[ $(WLN_enabled) == "${NO}" ]]; then
                    #Check if the maximum number of retries have been reached.
                    if [[ ${retry} -eq ${WLN_INTFSTATESET_RETRY_MAX} ]]; then
                        #Update output value
                        ret="${REJECTED}"

                        #Goto next-phase
                        phase="${PHASE_ENABLEFUNC_EXIT}"
                    else
                        #Wait for 1 sec
                        sleep 0.5

                        #Increment index by 1
                        ((retry++))

                        #Goto back-to-phase
                        phase="${PHASE_ENABLEFUNC_INTFSTATE_SET}"
                    fi
                else
                    phase="${PHASE_ENABLEFUNC_SERVICES_START}"
                fi
                ;;
            "${PHASE_ENABLEFUNC_SERVICES_START}")
                #Start service
                #Remark:
                #   Starting the service is not part of 'enable()' function's validation.
                ret_dummy2=$(WLN_Services_CheckIfEnabled_And_ThenStart_Handler)

                #Update output value
                ret="${ACCEPTED}"

                #Goto next-phase
                phase="${PHASE_ENABLEFUNC_EXIT}"
                ;;
            "${PHASE_ENABLEFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

WLN_enabled() {
    #Define constants
    local PHASE_ENABLEFUNC_BCMDHD_CHECK=0
    local PHASE_ENABLEFUNC_INTFSTATE_CHECK=1
    local PHASE_ENABLEFUNC_TXBYTES_CHECK=2
    local PHASE_ENABLEFUNC_PASS=3
    local PHASE_ENABLEFUNC_EXIT=4

    #Define variables
    local phase="${PHASE_ENABLEFUNC_BCMDHD_CHECK}"
    local timestampsec_new=0
    local timestampsec_old=0
    local timestampsec_diff=0
    local ret="${NO}"

    #Get the NEW timestamp
    timestampsec_new=$(GetTimeStamps)
    #Get the OLD timestamp
    timestampsec_old=$(WLN_intfstates_ctx_retrievedata \
            "${WLN_INTFSTATES_CTX_DAT_FPATH}" \
            "WLN_intfstates_ctx__updatetimestamp")
    #Get the difference
    timestampsec_diff=$(( timestampsec_new - timestampsec_old ))

    #Check if 'timestampsec_diff <= WLN_TIMESTAMPSEC_DIFF_MAX'
    if [[ ${timestampsec_diff} -le ${WLN_TIMESTAMPSEC_DIFF_MAX} ]]; then
        #Get the 'WLN_intfstates_ctx__enabled' from database
        ret=$(WLN_intfstates_ctx_retrievedata \
                "${WLN_INTFSTATES_CTX_DAT_FPATH}" \
                "WLN_intfstates_ctx__enabled")

        echo "${ret}"

        return 0;
    fi

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_ENABLEFUNC_BCMDHD_CHECK}")
                #Check if module is enabled
                if [[ $(ModuleIsEnabled "${WLN_BCMDHD}") == false ]]; then
                    #Update output value
                    ret="${NO}"

                    #Goto next-phase
                    phase=${PHASE_ENABLEFUNC_EXIT}
                else
                    #Goto next-phase
                    phase=${PHASE_ENABLEFUNC_INTFSTATE_CHECK}
                fi
                ;;
            "${PHASE_ENABLEFUNC_INTFSTATE_CHECK}")
                if [[ $(GetInterfaceState "${WLN_WLAN0}") != "${WLN_UP}" ]]; then
                    #Update output value
                    ret="${NO}"
  
                    #Goto next-phase
                    phase=${PHASE_ENABLEFUNC_EXIT}
                else
                    #Goto next-phase
                    phase=${PHASE_ENABLEFUNC_TXBYTES_CHECK}
                fi
                ;;
            "${PHASE_ENABLEFUNC_TXBYTES_CHECK}")
                if [[ $(TxBytes_Validate "${WLN_WLAN0}" \
                        "${WLN_IPV4_LOCALHOST}" \
                        "${NET_PING_COUNT}" \
                        "${NET_PING_DEADLINE}" \
                        "${WLN_STATISTICS_TXBYTES}") == false ]]; then
                    #Update output value
                    ret="${NO}"

                    #Goto next-phase
                    phase=${PHASE_ENABLEFUNC_EXIT}
                else
                    #Goto next-phase
                    phase=${PHASE_ENABLEFUNC_PASS}
                fi 
                ;;
            "${PHASE_ENABLEFUNC_PASS}")
                #Update output value
                ret="${YES}"

                #Goto next-phase
                phase=${PHASE_ENABLEFUNC_EXIT}
                ;;
            "${PHASE_ENABLEFUNC_EXIT}")
                break
                ;;
        esac
    done



    #Write data to file
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__enabled" "${ret}"

    #Get Timestamp (in sec)
    timestampsec=$(GetTimeStamps)

    #Update timestamp
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__updatetimestamp" "${timestampsec}"



    #Output
    echo "${ret}"

    return 0;
}
