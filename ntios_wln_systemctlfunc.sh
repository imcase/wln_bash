#!/bin/bash
#---FUNCTIONS
Service_Enable_And_Start() {
    #Input args
    local srv_name=${1}
    local retry_max=${2}
  
    #Define constants
    local PHASE_SYSTEMCTLFUNC_DAEMON_RELOAD=1
    local PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE=20
    local PHASE_SYSTEMCTLFUNC_SERVICE_START=30
    local PHASE_SYSTEMCTLFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_SYSTEMCTLFUNC_DAEMON_RELOAD}"
    local enable_retry=0 
    local start_retry=0

    local ret=false



    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SYSTEMCTLFUNC_DAEMON_RELOAD}")
                if [[ $(SystemctlDaemonReload) == false ]]; then
                    ret=false

                    phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                else
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE}"
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE}")
                if [[ $(SystemctlEnableService "${srv_name}") == false ]]; then
                    if [[ ${enable_retry} -eq ${WLN_SYSTEMCTL_START_SERVICE_RETRY_MAX} ]]; then
                        ret=false

                        phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                    else
                        ((enable_retry++))

                        phase="${PHASE_SYSTEMCTLFUNC_DAEMON_RELOAD}"
                    fi
                else
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_START}"
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_START}")
                if [[ $(SystemctlStartService "${srv_name}") == false ]]; then
                    if [[ ${start_retry} -eq ${WLN_SYSTEMCTL_START_SERVICE_RETRY_MAX} ]]; then
                        ret=false

                        phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                    else
                        ((start_retry++))

                        phase="${PHASE_SYSTEMCTLFUNC_DAEMON_RELOAD}"
                    fi
                else
                    ret=true
                fi

                phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                ;;
            "${PHASE_SYSTEMCTLFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

Service_ShouldBe_Disabled_And_Stopped() {
    #----------------------------------------------------------------
    # The goal here is to Stop and Disable the specified service.
    # The following exceptions apply:
    # 1. if software is NOT installed, then return "ACCEPTED".
    # 2. if service fullpath is NOT present, then return "ACCEPTED".
    # 3. if service is already stopped and disabled, then return "ACCEPTED".
    # 4.1 if try to DISABLE service and SUCCESSFUL, go to try to STOP service.
    # 4.2 if try to DISABLE service and FAIL, then return "REJECTED".
    # 5.1 if try to STOP service and SUCCESSFUL, then return "ACCEPTED".
    # 5.2 if try to STOP service and FAIL, then return "REJECTED".
    #----------------------------------------------------------------
    #Input args
    local srv_name=${1}
    local sw_name=${2}
    local srv_fpath=${3}

    #Define constants
    local PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK=1
    local PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK=2
    local PHASE_SYSTEMCTLFUNC_SERVICE_STOP=3
    local PHASE_SYSTEMCTLFUNC_SERVICE_DISABLE=4
    local PHASE_SYSTEMCTLFUNC_EXIT=5

    #Define variables
    local phase="${PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK}"
    local ret=false

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK}")
                if [[ "${sw_name}" == "${WLN_EMPTYSTRING}" ]]; then
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}"
                else
                    if [[ $(SoftwareIsInstalled "${sw_name}") == false ]]; then
                        ret=true

                        phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                    else
                        phase="${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}"
                    fi
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}")
                if [[ "${srv_fpath}" == "${WLN_EMPTYSTRING}" ]]; then
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_DISABLE}"
                else
                    if [[ $(FileExists "${srv_fpath}") == false ]]; then
                        ret=true

                        phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                    else
                        phase="${PHASE_SYSTEMCTLFUNC_SERVICE_DISABLE}"
                    fi
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_DISABLE}")
                if [[ $(SystemctlServiceIsEnabled "${srv_name}") == false ]]; then
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_STOP}"     
                else
                    if [[ $(SystemctlDisableService "${srv_name}") == false ]]; then
                        ret=false

                        phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                    else
                        phase="${PHASE_SYSTEMCTLFUNC_SERVICE_STOP}"
                    fi
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_STOP}")
                if [[ $(SystemctlServiceIsActive "${srv_name}") == false ]]; then
                    ret=true       
                else
                    if [[ $(SystemctlStopService "${srv_name}") == false ]]; then
                        ret=false
                    else
                        ret=true 
                    fi
                fi

                phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                ;;
            "${PHASE_SYSTEMCTLFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

Service_CheckIf_IsEnabled_AndOr_IsActive() {
    #----------------------------------------------------------------
    # The goal here is to Enable and Start the specified service.
    # The following exceptions apply:
    # 1. if software is NOT installed, then return "ACCEPTED".
    # 2. if service fullpath is NOT present, then return "ACCEPTED".
    # 3. if service is DISABLED, then return "ACCEPTED".
    # 4. if service is ENABLED, and:
    # 4.1 if try to START service and SUCCESSFUL, then return "ACCEPTED".
    # 4.2 if try to START service and FAIL, then return "REJECTED".
    #----------------------------------------------------------------
    #Input args
    local srv_name=${1}
    local sw_name=${2}
    local srv_fpath=${3}

    #Define constants
    local PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK=1
    local PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK=2
    local PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK=3
    local PHASE_SYSTEMCTLFUNC_SERVICE_ACTIVE_CHECK=4
    local PHASE_SYSTEMCTLFUNC_EXIT=5

    #Define variables
    local phase="${PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK}"
    local ret=false

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK}")
                if [[ "${sw_name}" == "${WLN_EMPTYSTRING}" ]]; then
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}"
                else
                    if [[ $(SoftwareIsInstalled "${sw_name}") == false ]]; then
                        ret=false

                        phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                    else
                        phase="${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}"
                    fi
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}")
                if [[ "${srv_fpath}" == "${WLN_EMPTYSTRING}" ]]; then
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK}"
                else
                    if [[ ! -f "${srv_fpath}" ]]; then
                        ret=false

                        phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                    else
                        phase="${PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK}"
                    fi
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK}")
                if [[ $(SystemctlServiceIsEnabled "${srv_name}") == true ]]; then
                    ret=true

                    phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                else
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_ACTIVE_CHECK}"
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_ACTIVE_CHECK}")
                if [[ $(SystemctlServiceIsActive "${srv_name}") == true ]]; then
                    ret=true
                else
                    ret=false
                fi

                phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                ;;
            "${PHASE_SYSTEMCTLFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

Service_CheckIf_IsEnabled_Then_Start() {
    #----------------------------------------------------------------
    # The goal here is to Enable and Start the specified service.
    # The following exceptions apply:
    # 1. if software is NOT installed, then return "ACCEPTED".
    # 2. if service fullpath is NOT present, then return "ACCEPTED".
    # 3. if service is DISABLED, then return "ACCEPTED".
    # 4. if service is ENABLED, and:
    # 4.1 if try to START service and SUCCESSFUL, then return "ACCEPTED".
    # 4.2 if try to START service and FAIL, then return "REJECTED".
    #----------------------------------------------------------------
    #Input args
    local srv_name=${1}
    local sw_name=${2}
    local srv_fpath=${3}

    #Define constants
    local PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK=1
    local PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK=2
    local PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK=3
    local PHASE_SYSTEMCTLFUNC_SERVICE_START=4
    local PHASE_SYSTEMCTLFUNC_EXIT=5

    #Define variables
    local phase="${PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK}"
    local ret=false

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK}")
                if [[ "${sw_name}" == "${WLN_EMPTYSTRING}" ]]; then
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}"
                else
                    if [[ $(SoftwareIsInstalled "${sw_name}") == false ]]; then
                        ret=true

                        phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                    else
                        phase="${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}"
                    fi
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}")
                if [[ "${srv_fpath}" == "${WLN_EMPTYSTRING}" ]]; then
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK}"
                else
                    if [[ ! -f "${srv_fpath}" ]]; then
                        ret=true

                        phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                    else
                        phase="${PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK}"
                    fi
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK}")
                if [[ $(SystemctlServiceIsEnabled "${srv_name}") == false ]]; then
                    ret=true

                    phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                else
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_START}"
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_START}")
                if [[ $(SystemctlServiceIsActive "${srv_name}") == false ]]; then
                    if [[ $(SystemctlStartService "${srv_name}") == false ]]; then
                        ret=false
                    else
                        ret=true
                    fi
                else
                    ret=true
                fi

                phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                ;;
            "${PHASE_SYSTEMCTLFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

Service_CheckIf_IsEnabled_Then_Stop() {
    #----------------------------------------------------------------
    # The goal here is to Enable and Start the specified service.
    # The following exceptions apply:
    # 1. if software is NOT installed, then return "ACCEPTED".
    # 2. if service fullpath is NOT present, then return "ACCEPTED".
    # 3. if service is DISABLED, then return "ACCEPTED".
    # 4. if service is ENABLED, and:
    # 4.1 if try to STOP service and SUCCESSFUL, then return "ACCEPTED".
    # 4.2 if try to STOP service and FAIL, then return "REJECTED".
    #----------------------------------------------------------------
    #Input args
    local srv_name=${1}
    local sw_name=${2}
    local srv_fpath=${3}

    #Define constants
    local PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK=1
    local PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK=2
    local PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK=3
    local PHASE_SYSTEMCTLFUNC_SERVICE_STOP=4
    local PHASE_SYSTEMCTLFUNC_EXIT=5

    #Define variables
    local phase="${PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK}"
    local ret=false

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SYSTEMCTLFUNC_SOFTWARE_CHECK}")
                if [[ "${sw_name}" == "${WLN_EMPTYSTRING}" ]]; then
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}"
                else
                    if [[ $(SoftwareIsInstalled "${sw_name}") == false ]]; then
                        ret=true

                        phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                    else
                        phase="${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}"
                    fi
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_FPATH_CHECK}")
                if [[ "${srv_fpath}" == "${WLN_EMPTYSTRING}" ]]; then
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK}"
                else
                    if [[ ! -f "${srv_fpath}" ]]; then
                        ret=true

                        phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                    else
                        phase="${PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK}"
                    fi
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_ENABLE_CHECK}")
                if [[ $(SystemctlServiceIsEnabled "${srv_name}") == false ]]; then
                    ret=true

                    phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                else
                    phase="${PHASE_SYSTEMCTLFUNC_SERVICE_STOP}"
                fi
                ;;
            "${PHASE_SYSTEMCTLFUNC_SERVICE_STOP}")
                if [[ $(SystemctlServiceIsActive "${srv_name}") == true ]]; then
                    if [[ $(SystemctlStopService "${srv_name}") == false ]]; then
                        ret=false
                    else
                        ret=true
                    fi
                else
                    ret=true
                fi

                phase="${PHASE_SYSTEMCTLFUNC_EXIT}"
                ;;
            "${PHASE_SYSTEMCTLFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

SystemctlDaemonReload() {
    #Reload Daemon
    sudo systemctl daemon-reload >/dev/null;exitcode=$?;pid=$!;wait ${pid}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    #Choose print-message
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Daemon-Reload: ${WLN_PRINTMSG_DONE}"

        ret=true
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Daemon-Reload: ${WLN_PRINTMSG_FAILED}"

        ret=false
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;
}
SystemctlDisableService() {
    #Input args
    local srv_name=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    #Disable service
    sudo systemctl disable "${srv_name}" >/dev/null;exitcode=$?;pid=$!;wait ${pid}

    #Choose print-message
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Disable ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Disable ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"
    fi

    #Print
    DebugPrint "${printmsg}"

    #Check if service NOT is-active
    if [[ $(SystemctlServiceIsEnabled "${srv_name}") == false ]]; then
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}
SystemctlEnableService() {
    #Input args
    local srv_name=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false


    #Enable service
    sudo systemctl enable "${srv_name}" >/dev/null;exitcode=$?;pid=$!;wait ${pid}

    #Choose print-message
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Enable ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Enable ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"
    fi

    #Print
    DebugPrint "${printmsg}"

    #Check if service is-active
    if [[ $(SystemctlServiceIsEnabled "${srv_name}") == true ]]; then
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}
SystemctlRestartService() {
    #Input args
    local srv_name=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    #Restart service
    sudo systemctl restart "${srv_name}" >/dev/null;exitcode=$?;pid=$!;wait ${pid}

    #Choose print-message
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Restart ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Restart ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"
    fi

    #Print
    DebugPrint "${printmsg}"

    #Check if service is-active
    if [[ $(SystemctlServiceIsActive "${srv_name}") == true ]]; then
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}
SystemctlStartService() {
    #Input args
    local srv_name=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    #Start Service
    sudo systemctl start "${srv_name}" >/dev/null;exitcode=$?;pid=$!;wait ${pid}

    #Choose print-message
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Start ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Start ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"
    fi

    #Print
    DebugPrint "${printmsg}"

    #Check if service is-active
    if [[ $(SystemctlServiceIsActive "${srv_name}") == true ]]; then
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}
SystemctlStopService() {
    #Input args
    local srv_name=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    #Stop service
    sudo systemctl stop "${srv_name}" >/dev/null;exitcode=$?;pid=$!;wait ${pid}

    #Choose print-message
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Stop ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Stop ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"
    fi

    #Print
    DebugPrint "${printmsg}"

    #Check if service is-active
    if [[ $(SystemctlServiceIsActive "${srv_name}") == false ]]; then
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}
SystemctlUnmaskService() {
    #Input args
    local srv_name=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local ret=false

    #Unmask service
    sudo systemctl unmask "${srv_name}" >/dev/null;exitcode=$?;pid=$!;wait ${pid}

    #Choose print-message
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Unmask ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"

        ret=true
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Unmask ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"

        ret=false
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;
}

SystemctlServiceIsActive() {
    #Input args
    local srv_name=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local srv_activity="${WLN_INACTIVE}"
    local ret=false

    #Get service-activity (is-active/is-inactive)
    srv_activity=$(sudo systemctl is-active "${srv_name}" ; pid=$! ; wait ${pid})

    #Choose print-message
    if [[ "${srv_activity}" == "${WLN_ACTIVE}" ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Is-Active ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_TRUE}"

        ret=true
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Is-Active ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FALSE}"

        ret=false
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;
}
SystemctlServiceIsEnabled() {
    #Input args
    local srv_name=${1}

    #Define variables
    local printmsg="${WLN_EMPTYSTRING}"
    local srv_state="${WLN_DISABLED}"
    local ret=false

    #Get service -state (enabled/disabled)
    srv_state=$(sudo systemctl is-enabled "${srv_name}" ; pid=$! ; wait ${pid})

    #Choose print-message
    if [[ "${srv_state}" == "${WLN_ENABLED}" ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Is-Enabled ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_TRUE}"

        ret=true
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Systemctl Is-Enabled ${WLN_LIGHTGREY}${srv_name}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FALSE}"

        ret=false
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;
}
