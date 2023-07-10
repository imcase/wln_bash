#!/bin/bash
#---FUNCTIONS
WLN_Ufw_Ports_Allow() {
    #Define constants
    local PHASE_PORT_ALLOW_53=1
    local PHASE_PORT_ALLOW_67=2
    local PHASE_PORT_ALLOW_68=3
    local PHASE_PORT_ALLOW_547=4
    local PHASE_PORT_ALLOW_5553=5
    local PHASE_EXIT=6

    #Define variables
    local phase="${PHASE_PORT_ALLOW_53}"
    local cmd="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_PORT_ALLOW_53}")
                if [[ $(WLN_Ufw_Port_IsAllowed "${WLN_PORT_53}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_EXIT}"
                else
                    phase="${PHASE_PORT_ALLOW_67}"
                fi
                ;;
            "${PHASE_PORT_ALLOW_67}")
                if [[ $(WLN_Ufw_Port_IsAllowed "${WLN_PORT_67}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_EXIT}"
                else
                    phase="${PHASE_PORT_ALLOW_68}"
                fi
                ;;
            "${PHASE_PORT_ALLOW_68}")
                if [[ $(WLN_Ufw_Port_IsAllowed "${WLN_PORT_68}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_EXIT}"
                else
                    phase="${PHASE_PORT_ALLOW_547}"
                fi
                ;;
            "${PHASE_PORT_ALLOW_547}")
                if [[ $(WLN_Ufw_Port_IsAllowed "${WLN_PORT_547}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_EXIT}"
                else
                    phase="${PHASE_PORT_ALLOW_5553}"
                fi
                ;;
            "${PHASE_PORT_ALLOW_5553}")
                if [[ $(WLN_Ufw_Port_IsAllowed "${WLN_PORT_5553}") == false ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_EXIT}"
                ;;
            "${PHASE_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

WLN_Ufw_Port_IsAllowed() {
    #Input args
    local isport=${1}

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Check if port is not allowed yet
    if [[ $(PortIsAllowed "${isport}") == false ]]; then
        #Define and run command
        cmd="ufw allow ${isport}"
        ret=$(CmdExec "${cmd}")

        #Double-check if port is still not allowed
        if [[ $(PortIsAllowed "${isport}") == false ]]; then
            ret="${REJECTED}"
        else
            ret="${ACCEPTED}"
        fi
    else
        ret="${ACCEPTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}
