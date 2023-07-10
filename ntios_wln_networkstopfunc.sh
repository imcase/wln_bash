#!/bin/bash
#---CONSTANTS
PHASE_NETWORKSTOPFUNC_TASK_CHECK="1"
PHASE_NETWORKSTOPFUNC_SERVICES_DISABLESTOP_HANDLER="2"
PHASE_NETWORKSTOPFUNC_TASK_UPDATE="3"
PHASE_NETWORKSTOPFUNC_EXIT="4"



#---FUNCTIONS
WLN_networkstop() {
    #Define variables
    local phase="${PHASE_NETWORKSTOPFUNC_TASK_CHECK}"
    local ret="${REJECTED}"
    local wlntask="${PL_WLN_NOT_ASSOCIATED}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_NETWORKSTOPFUNC_TASK_CHECK}")
                #Retrieve data from database
                wlntask=$(WLN_intfstates_ctx_retrievedata \
                        "${WLN_INTFSTATES_CTX_DAT_FPATH}" \
                        "WLN_intfstates_ctx__associationstate")
                if [[ "${wlntask}" != "${PL_WLN_OWN_NETWORK}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTOPFUNC_EXIT}"

                    #Print
                    Networkstop_Debugprint "${PHASE_NETWORKSTOPFUNC_TASK_CHECK}" \
                            "${wlntask}" \
                            "${WLN_NUM_1}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTOPFUNC_SERVICES_DISABLESTOP_HANDLER}"

                    #Print
                    Networkstop_Debugprint "${PHASE_NETWORKSTOPFUNC_TASK_CHECK}" \
                            "${wlntask}" \
                            "${WLN_NUM_2}"
                fi
                ;;
            ${PHASE_NETWORKSTOPFUNC_SERVICES_DISABLESTOP_HANDLER})
                #Print
                Networkstop_Debugprint "${PHASE_NETWORKSTOPFUNC_SERVICES_DISABLESTOP_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                if [[ $(WLN_Services_Disassociate_Handler) == "${REJECTED}" ]]; then
                    #Update output result
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_NETWORKSTOPFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_NETWORKSTOPFUNC_TASK_UPDATE}"
                fi

                #Print
                Networkstop_Debugprint "${PHASE_NETWORKSTOPFUNC_SERVICES_DISABLESTOP_HANDLER}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTOPFUNC_TASK_UPDATE}")
                #Print
                Networkstop_Debugprint "${PHASE_NETWORKSTOPFUNC_TASK_UPDATE}" "${WLN_EMPTYSTRING}" "${WLN_NUM_1}"

                #Update database
                WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" \
                        "WLN_intfstates_ctx__associationstate" \
                        "${PL_WLN_NOT_ASSOCIATED}"

                #Update output result
                ret="${ACCEPTED}"

                #Goto next-phase
                phase="${PHASE_NETWORKSTOPFUNC_EXIT}"

                #Print
                Networkstop_Debugprint "${PHASE_NETWORKSTOPFUNC_TASK_UPDATE}" "${WLN_EMPTYSTRING}" "${WLN_NUM_2}"
                ;;
            "${PHASE_NETWORKSTOPFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}
Networkstop_Debugprint() {
    #Input args
    local phase=${1}
    local printmsg_val=${2}
    local printmsg_num=${3}

    #Define constants
    local PRINTMSG_NETWORKSTOP="${WLN_PRINTMSG_STATUS}: ${WLN_LIGHTGREY}Networkstop${WLN_RESETCOLOR}"

    #Define variables
    local printmsg="${PRINTMSG_NETWORKSTOP}: "
    local printmsg_val1=$(echo "${printmsg_val}" | cut -d"," -f1)
    local printmsg_val2=$(echo "${printmsg_val}" | cut -d"," -f2)
    local printmsg_val3=$(echo "${printmsg_val}" | cut -d"," -f3)
    local printmsg_val4=$(echo "${printmsg_val}" | cut -d"," -f4)
    local printmsg_val5=$(echo "${printmsg_val}" | cut -d"," -f5)

    #Print
    case "${phase}" in
        "${PHASE_NETWORKSTOPFUNC_TASK_CHECK}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="TASK (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): "
                printmsg+="${WLN_PRINTMSG_REJECTED}" 
            else    #printmsg_num = WLN_NUM_2
                printmsg+="TASK (${WLN_LIGHTGREY}${printmsg_val1}${WLN_RESETCOLOR}): "
                printmsg+="${WLN_PRINTMSG_ACCEPTED}"
            fi
            ;;
        "${PHASE_NETWORKSTOPFUNC_SERVICES_DISABLESTOP_HANDLER}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="ALL SERVICES: ${WLN_PRINTMSG_DISABLESTOP}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="ALL SERVICES: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTOPFUNC_TASK_UPDATE}")
            if [[ ${printmsg_num} -eq ${WLN_NUM_1} ]]; then
                printmsg+="DATABASE: ${WLN_PRINTMSG_UPDATING}"
            else    #printmsg_num = WLN_NUM_2
                printmsg+="DATABASE: ${WLN_PRINTMSG_COMPLETED}"
            fi
            ;;
        "${PHASE_NETWORKSTOPFUNC_EXIT}")
            break
            ;;
    esac

    #Print
    DebugPrint "${printmsg}"
}
