#!/bin/bash
#---FUNCTIONS
WLN_Ip46tables_Rules_Create() {
    local iscmd=${1}
    local isip46tables_service=${2}
    local isip46tables_rules_org_fpath=${3}
    local isip46tables_rules_fpath=${4}
    local isip46tables_service_fpath=${5}
    local ispermission=${6}
    local isintfstates_ctx_fpath=${7}   # {WLN_INTFSTATES_CTX_DAT_FPATH | WLN_INTFSTATES_CTX_INIT_DAT_FPATH}
    local isip46tables_enablestart_setto=${8}   # {true | false}

    
    #Define constants
    local PHASE_IPTABLESFUNC_IP46TABLES_SERVICE_DISABLESTOP=1
    local PHASE_IPTABLESFUNC_GATEWAYINTF_RETRIEVE=10
    local PHASE_IPTABLESFUNC_DIRS_CREATE=20
    local SUBPHASE_IPTABLESFUNC_DIRS_CREATE_1=21
    local SUBPHASE_IPTABLESFUNC_DIRS_CREATE_2=22
    local SUBPHASE_IPTABLESFUNC_DIRS_CREATE_3=23
    local SUBPHASE_IPTABLESFUNC_DIRS_CREATE_4=24
    local PHASE_IPTABLESFUNC_RULE_ORG_FPATH_CREATE=21
    local PHASE_IPTABLESFUNC_RULE_ORG_FPATH_SAVE=22
    local PHASE_IPTABLESFUNC_RULE_FPATH_CREATE=23
    local PHASE_IPTABLESFUNC_RULE_FPATH_SAVE=24
    local PHASE_IPTABLESFUNC_RULE_INTEGRITYCHECK=30
    local PHASE_IPTABLESFUNC_RULE_INSERT=40
    local SUBPHASE_IPTABLESFUNC_RULE_INSERT_1=41
    local SUBPHASE_IPTABLESFUNC_RULE_INSERT_2=42
    local SUBPHASE_IPTABLESFUNC_RULE_INSERT_3=43
    local SUBPHASE_IPTABLESFUNC_RULE_INSERT_4=44
    local SUBPHASE_IPTABLESFUNC_RULE_INSERT_5=45
    local SUBPHASE_IPTABLESFUNC_RULE_INSERT_6=46
    local PHASE_IPTABLESFUNC_RULE_FPATH_RESTORE=50
    local PHASE_IPTABLESFUNC_IP46TABLES_SERVICE_GENERATOR=60
    local PHASE_IPTABLESFUNC_IP46TABLES_SERVICE_ENABLESTART=70
    local PHASE_IPTABLESFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_IPTABLESFUNC_IP46TABLES_SERVICE_DISABLESTOP}"
    local subphase="${WLN_EMPTYSTRING}"
    local bssmode_retrieved="${PL_WLN_BSS_MODE_UNKNOWN}"
    local gateway_intfset_retrieved="${PL_WLN_GATEWAY_INTFSET_UNSET}"
    local gatewayintf="${WLN_EMPTYSTRING}"
    local rule="${WLN_EMPTYSTRING}"
    local rules_fpath="${WLN_EMPTYSTRING}"
    local restorecmd="${WLN_EMPTYSTRING}"
    local savecmd="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"


    #Retrieve data from database
    bssmode_retrieved=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__bssmode")
    gateway_intfset_retrieved=$(WLN_intfstates_ctx_retrievedata "${isintfstates_ctx_fpath}" "WLN_intfstates_ctx__gatewayintf")

    #Select the 'savecmd' and 'restorecmd'
    if [[ "${iscmd}" == "${WLN_IPTABLES}" ]]; then
        savecmd="${WLN_IPTABLES_SAVE_FPATH}"
        restorecmd="${WLN_IPTABLES_RESTORE_FPATH}"
        rules_fpath="${WLN_IPTABLES_RULES_V4_FPATH}"    
    else    #iscmd = WLN_IP6TABLES
        savecmd="${WLN_IP6TABLES_SAVE_FPATH}"
        restorecmd="${WLN_IP6TABLES_RESTORE_FPATH}"
        rules_fpath="${WLN_IP6TABLES_RULES_V6_FPATH}"   
    fi

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_IPTABLESFUNC_IP46TABLES_SERVICE_DISABLESTOP}")
                if [[ ${isip46tables_enablestart_setto} == true ]]; then
                    if [[ $(Service_ShouldBe_Disabled_And_Stopped "${isip46tables_service}" \
                            "${WLN_IPTABLES}" \
                            "${isip46tables_service_fpath}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_IPTABLESFUNC_EXIT}"
                    else
                        #Exit function if:
                        #   bssmode != PL_WLN_BSS_MODE_ROUTER
                        # AND
                        #   isip46tables_rules_fpath == rules_fpath
                        #Remark:
                        #   'iptables' or 'ip6tables' is only required in 'Router' mode.
                        if [[ "${bssmode_retrieved}" != "${PL_WLN_BSS_MODE_ROUTER}" ]] && \
                                [[ "${isip46tables_rules_fpath}" == "${rules_fpath}" ]]; then
                            ret="${ACCEPTED}"

                            phase="${PHASE_IPTABLESFUNC_EXIT}"
                        else
                            phase="${PHASE_IPTABLESFUNC_DIRS_CREATE}"
                        fi
                    fi
                else
                     phase="${PHASE_IPTABLESFUNC_DIRS_CREATE}"
                fi
                ;;
            "${PHASE_IPTABLESFUNC_DIRS_CREATE}")
                subphase="${SUBPHASE_IPTABLESFUNC_DIRS_CREATE_1}"

                while true
                do
                    case "${subphase}" in
                        "${SUBPHASE_IPTABLESFUNC_DIRS_CREATE_1}")
                            if [[ $(Mkdir "${WLN_ETC_IPTABLES_DIR}") == false ]]; then
                                ret="${REJECTED}"

                                phase="${PHASE_IPTABLESFUNC_EXIT}"

                                break
                            else
                                subphase="${SUBPHASE_IPTABLESFUNC_DIRS_CREATE_2}"
                            fi
                            ;;
                        "${SUBPHASE_IPTABLESFUNC_DIRS_CREATE_2}")
                            if [[ $(Mkdir "${WLN_ETC_IP6TABLES_DIR}") == false ]]; then
                                ret="${REJECTED}"

                                phase="${PHASE_IPTABLESFUNC_EXIT}"

                                break
                            else
                                subphase="${SUBPHASE_IPTABLESFUNC_DIRS_CREATE_3}"
                            fi
                            ;;
                        "${SUBPHASE_IPTABLESFUNC_DIRS_CREATE_3}")
                            if [[ $(Mkdir "${WLN_ETC_TIBBO_IPTABLES_WLN_DIR}") == false ]]; then
                                ret="${REJECTED}"

                                phase="${PHASE_IPTABLESFUNC_EXIT}"

                                break
                            else
                                subphase="${SUBPHASE_IPTABLESFUNC_DIRS_CREATE_4}"
                            fi
                            ;;
                        "${SUBPHASE_IPTABLESFUNC_DIRS_CREATE_4}")
                            if [[ $(Mkdir "${WLN_ETC_TIBBO_IP6TABLES_WLN_DIR}") == false ]]; then
                                ret="${REJECTED}"

                                phase="${PHASE_IPTABLESFUNC_EXIT}"
                            else
                                phase="${PHASE_IPTABLESFUNC_GATEWAYINTF_RETRIEVE}"
                            fi

                            break
                            ;;
                    esac
                done                
                ;;
            "${PHASE_IPTABLESFUNC_GATEWAYINTF_RETRIEVE}")
                gatewayintf=$(ip46tables_get_gatewayintf "${gateway_intfset_retrieved}")

                phase="${PHASE_IPTABLESFUNC_RULE_ORG_FPATH_CREATE}"
                ;;
            "${PHASE_IPTABLESFUNC_RULE_ORG_FPATH_CREATE}")
                #Create '/etc/tibbo/iptables/wln/rules.v4.org'
                if [[ $(Touch_and_Chmod "${isip46tables_rules_org_fpath}" "${ispermission}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_IPTABLESFUNC_EXIT}"
                else
                    phase="${PHASE_IPTABLESFUNC_RULE_ORG_FPATH_SAVE}"
                fi
                ;;
            "${PHASE_IPTABLESFUNC_RULE_ORG_FPATH_SAVE}")
                #Save current 'iptables' rules to file '/etc/tibbo/iptables/wln/rules.v4.org' OR '/etc/tibbo/ip6tables/wln/rules.v6.org'
                if [[ $(ip46tables_rule_save "${savecmd}" "${isip46tables_rules_org_fpath}" "false") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_IPTABLESFUNC_EXIT}"
                else
                    phase="${PHASE_IPTABLESFUNC_RULE_FPATH_CREATE}"
                fi
                ;;
            "${PHASE_IPTABLESFUNC_RULE_FPATH_CREATE}")
                #Create '/etc/iptables/rules.v4 OR '/etc/tibbo/iptables/wln/rules.v4
                if [[ $(Touch_and_Chmod "${isip46tables_rules_fpath}" "${ispermission}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_IPTABLESFUNC_EXIT}"
                else
                    phase="${PHASE_IPTABLESFUNC_RULE_FPATH_SAVE}"
                fi
                ;;
            "${PHASE_IPTABLESFUNC_RULE_FPATH_SAVE}")
                if [[ "${isip46tables_rules_fpath}" != "${rules_fpath}" ]]; then
                    #copy '/etc/tibbo/iptables/wln/rules.v4.org' to '/etc/tibbo/iptables/wln/rules.v4.autoresetconnect'
                    # OR
                    #copy '/etc/tibbo/ip6tables/wln/rules.v6.org' to '/etc/tibbo/ip6tables/wln/rules.v6.autoresetconnect'
                    if [[ $(CopyFile "${isip46tables_rules_org_fpath}" "${isip46tables_rules_fpath}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_IPTABLESFUNC_EXIT}"
                    else
                        phase="${PHASE_IPTABLESFUNC_RULE_INTEGRITYCHECK}"
                    fi                    
                else    #isip46tables_rules_fpath = {WLN_IPTABLES_RULES_V4_FPATH|WLN_IP6TABLES_RULES_V6_FPATH}
                    #Save current 'iptables' rules as '/etc/iptables/rules.v4 OR /etc/iptables/rules.v6'
                    if [[ $(ip46tables_rule_save "${savecmd}" "${isip46tables_rules_fpath}" "true") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_IPTABLESFUNC_EXIT}"
                    else
                        phase="${PHASE_IPTABLESFUNC_RULE_INTEGRITYCHECK}"
                    fi
                fi
                ;;
            "${PHASE_IPTABLESFUNC_RULE_INTEGRITYCHECK}")
                #Check if '*nat' and '*filter' fields are present.
                #If not present, then create '*nat' and/or '*filter' fields.
                if [[ $(ip46tables_rules_integritycheck "${isip46tables_rules_fpath}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_IPTABLESFUNC_EXIT}"
                else
                    phase="${PHASE_IPTABLESFUNC_RULE_INSERT}"
                fi
                ;;
            "${PHASE_IPTABLESFUNC_RULE_INSERT}")
                subphase="${SUBPHASE_IPTABLESFUNC_RULE_INSERT_1}"

                while true
                do
                    case "${subphase}" in
                        "${SUBPHASE_IPTABLESFUNC_RULE_INSERT_1}")
                            rule="-A INPUT -i ${WLN_LOOPBACK} -j ACCEPT"
                            if [[ $(ip46tables_rule_insert "${isip46tables_rules_fpath}" \
                                    "${rule}" \
                                    "${WLN_PATTERN_ASTERISK_FILTER}" \
                                    "${WLN_PATTERN_COMMIT}") == false ]]; then
                                ret="${REJECTED}"

                                phase="${PHASE_IPTABLESFUNC_EXIT}"

                                break
                            else
                                subphase="${SUBPHASE_IPTABLESFUNC_RULE_INSERT_2}"
                            fi
                            ;;
                        "${SUBPHASE_IPTABLESFUNC_RULE_INSERT_2}")
                            rule="-A INPUT -i ${WLN_BR0} -j ACCEPT"
                            if [[ $(ip46tables_rule_insert "${isip46tables_rules_fpath}" \
                                    "${rule}" \
                                    "${WLN_PATTERN_ASTERISK_FILTER}" \
                                    "${WLN_PATTERN_COMMIT}") == false ]]; then
                                ret="${REJECTED}"

                                phase="${PHASE_IPTABLESFUNC_EXIT}"

                                break
                            else
                                subphase="${SUBPHASE_IPTABLESFUNC_RULE_INSERT_3}"
                            fi
                            ;;
                        "${SUBPHASE_IPTABLESFUNC_RULE_INSERT_3}")
                            rule="-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT"
                            if [[ $(ip46tables_rule_insert "${isip46tables_rules_fpath}" \
                                    "${rule}" \
                                    "${WLN_PATTERN_ASTERISK_FILTER}" \
                                    "${WLN_PATTERN_COMMIT}") == false ]]; then
                                ret="${REJECTED}"

                                phase="${PHASE_IPTABLESFUNC_EXIT}"

                                break
                            else
                                subphase="${SUBPHASE_IPTABLESFUNC_RULE_INSERT_4}"
                            fi
                            ;;
                        "${SUBPHASE_IPTABLESFUNC_RULE_INSERT_4}")
                            rule="-A POSTROUTING -o ${gatewayintf} -j MASQUERADE"
                            if [[ $(ip46tables_rule_insert "${isip46tables_rules_fpath}" \
                                    "${rule}" \
                                    "${WLN_PATTERN_ASTERISK_NAT}" \
                                    "${WLN_PATTERN_COMMIT}") == false ]]; then
                                ret="${REJECTED}"

                                phase="${PHASE_IPTABLESFUNC_EXIT}"

                                break
                            else
                                subphase="${SUBPHASE_IPTABLESFUNC_RULE_INSERT_5}"
                            fi
                            ;;
                        "${SUBPHASE_IPTABLESFUNC_RULE_INSERT_5}")
                            rule="-A FORWARD -i ${gatewayintf} -o ${WLN_BR0} -m state --state RELATED,ESTABLISHED -j ACCEPT"
                            if [[ $(ip46tables_rule_insert "${isip46tables_rules_fpath}" \
                                    "${rule}" \
                                    "${WLN_PATTERN_ASTERISK_FILTER}" \
                                    "${WLN_PATTERN_COMMIT}") == false ]]; then
                                ret="${REJECTED}"

                                phase="${PHASE_IPTABLESFUNC_EXIT}"

                                break
                            else
                                subphase="${SUBPHASE_IPTABLESFUNC_RULE_INSERT_6}"
                            fi
                            ;;
                        "${SUBPHASE_IPTABLESFUNC_RULE_INSERT_6}")
                            rule="-A FORWARD -i ${WLN_BR0} -o ${gatewayintf} -j ACCEPT"
                            if [[ $(ip46tables_rule_insert "${isip46tables_rules_fpath}" \
                                    "${rule}" \
                                    "${WLN_PATTERN_ASTERISK_FILTER}" \
                                    "${WLN_PATTERN_COMMIT}") == false ]]; then
                                ret="${REJECTED}"

                                phase="${PHASE_IPTABLESFUNC_EXIT}"
                            else
                                phase="${PHASE_IPTABLESFUNC_RULE_FPATH_RESTORE}"
                            fi

                            break
                            ;;
                    esac
                done                
                ;;
            "${PHASE_IPTABLESFUNC_RULE_FPATH_RESTORE}")
                if [[ "${isip46tables_rules_fpath}" != "${rules_fpath}" ]]; then
                    phase="${PHASE_IPTABLESFUNC_IP46TABLES_SERVICE_GENERATOR}"
                else
                    if [[ $(ip46tables_rule_restore "${restorecmd}" "${isip46tables_rules_fpath}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_IPTABLESFUNC_EXIT}"
                    else
                        phase="${PHASE_IPTABLESFUNC_IP46TABLES_SERVICE_GENERATOR}"
                    fi
                fi
                ;;
            "${PHASE_IPTABLESFUNC_IP46TABLES_SERVICE_GENERATOR}")
                if [[ $(Service_CheckIf_IsEnabled_AndOr_IsActive "${isip46tables_service}" \
                        "${WLN_IPTABLES}" \
                        "${isip46tables_service_fpath}") == false ]]; then
                    if [[ $(ip46tables_service_create "${iscmd}" \
                            "${restorecmd}" \
                            "${isip46tables_rules_org_fpath}" \
                            "${rules_fpath}" \
                            "${isip46tables_service_fpath}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_IPTABLESFUNC_EXIT}"
                    else
                        phase="${PHASE_IPTABLESFUNC_IP46TABLES_SERVICE_ENABLESTART}"
                    fi
                else
                    phase="${PHASE_IPTABLESFUNC_IP46TABLES_SERVICE_ENABLESTART}"
                fi
                ;;
            "${PHASE_IPTABLESFUNC_IP46TABLES_SERVICE_ENABLESTART}")
                if [[ ${isip46tables_enablestart_setto} == true ]]; then
                    if [[ $(Service_Enable_And_Start "${isip46tables_service}" \
                            "${WLN_IPTABLES_SERVICE_RETRY_MAX}") == false ]]; then
                        ret="${REJECTED}"
                    else
                        ret="${ACCEPTED}"
                    fi
                else
                     ret="${ACCEPTED}"
                fi

                phase="${PHASE_IPTABLESFUNC_EXIT}"
                ;;            
            "${PHASE_IPTABLESFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}



#---SUPPORT FUNCTIONS
ip46tables_get_gatewayintf() {
    #Input args
    local isgateway_intfset=${1}

    #Define variables
    local ret=${WLN_EMPTYSTRING}
    
    #Validate Gateway Interface
    ret=$(GatewayIntfValidation "${isgateway_intfset}")

    #Output
    echo "${ret}"

    return 0;
}

ip46tables_rules_integritycheck() {
    #Input args
    local isrules_fpath=${1}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local filter_isfound="${WLN_EMPTYSTRING}"
    local nat_isfound="${WLN_EMPTYSTRING}"
    local filter_ret=false
    local nat_ret=false
    local ret=false

    #Check if '*filter' is present
    filter_isfound=$(grep -wn "${WLN_PATTERN_ASTERISK_FILTER}" "${isrules_fpath}")
    if [[ -z "${filter_isfound}" ]]; then
        filecontent="# Generated by $(basename $BASH_SOURCE) on $(date) \n"
        filecontent+="*filter\n"
        filecontent+=":INPUT DROP [0:0]\n"
        filecontent+=":FORWARD DROP [0:0]\n"
        filecontent+=":OUTPUT ACCEPT [0:0]\n"
        filecontent+="COMMIT\n"
        filecontent+="# Completed on $(date)"

        #Insert 'filecontent' at line-number '1'
        sudo sed -i "1i ${filecontent}" ${isrules_fpath}; exitcode=$? ; pid=$! ; wait ${pid}

        #Update print-message
        if [[ ${exitcode} -eq 0 ]]; then
            printmsg="${WLN_PRINTMSG_STATUS}: "
            printmsg+="Insert ${WLN_YELLOW}*filter (+content)${WLN_RESETCOLOR} "
            printmsg+="in file ${WLN_LIGHTGREY}${isrules_fpath}${WLN_RESETCOLOR}: "
            printmsg+="${WLN_PRINTMSG_DONE}"

            filter_ret=true
        else
            printmsg="${WLN_PRINTMSG_STATUS}: "
            printmsg+="Insert ${WLN_YELLOW}*filter (+content)${WLN_RESETCOLOR} "
            printmsg+="in file ${WLN_LIGHTGREY}${isrules_fpath}${WLN_RESETCOLOR}: "
            printmsg+="${WLN_PRINTMSG_FAILED}"

            filter_ret=false
        fi

        #Print
        DebugPrint "${printmsg}"
    else
        filter_ret=true
    fi

    #Check if '*nat' is present
    nat_isfound=$(grep -wn "${WLN_PATTERN_ASTERISK_NAT}" "${isrules_fpath}")
    if [[ -z "${nat_isfound}" ]]; then
        filecontent="# Generated by $(basename $BASH_SOURCE) on $(date) \n"
        filecontent+="*nat\n"
        filecontent+=":PREROUTING ACCEPT [0:0]\n"
        filecontent+=":INPUT ACCEPT [0:0\n"
        filecontent+=":OUTPUT ACCEPT [0:0]\n"
        filecontent+=":POSTROUTING ACCEPT [0:0]\n"
        filecontent+="COMMIT\n"
        filecontent+="# Completed on $(date)"

        #Insert 'filecontent' at line-number '1'
        sudo sed -i "1i ${filecontent}" ${isrules_fpath}; exitcode=$? ; pid=$! ; wait ${pid}

        #Update print-message
        if [[ ${exitcode} -eq 0 ]]; then
            printmsg="${WLN_PRINTMSG_STATUS}: "
            printmsg+="Insert ${WLN_YELLOW}*nat (+content)${WLN_RESETCOLOR} "
            printmsg+="in file ${WLN_LIGHTGREY}${isrules_fpath}${WLN_RESETCOLOR}: "
            printmsg+="${WLN_PRINTMSG_DONE}"

            nat_ret=true
        else
            printmsg="${WLN_PRINTMSG_STATUS}: "
            printmsg+="Insert ${WLN_YELLOW}*nat (+content)${WLN_RESETCOLOR} "
            printmsg+="in file ${WLN_LIGHTGREY}${isrules_fpath}${WLN_RESETCOLOR}: "
            printmsg+="${WLN_PRINTMSG_FAILED}"

            nat_ret=false
        fi

        #Print
        DebugPrint "${printmsg}"
    else
        nat_ret=true
    fi

    #Update 'ret' based on the result for 'filter_ret' and 'nat_ret'
    if [[ ${filter_ret} == true ]] && [[ ${nat_ret} == true ]]; then
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}

ip46tables_rule_insert() {
    #Input args
    local isrules_fpath=${1}
    local isrule=${2}
    local isstart_pattern=${3}
    local isend_pattern=${4}

    #Define variables
    local isstart_pattern_isfound="${WLN_EMPTYSTRING}"
    local isstart_pattern_print="${WLN_EMPTYSTRING}"
    local isend_pattern_linenum=0
    local isend_pattern_linenum_rel=0
    local isstart_pattern_linenum=0
    local ret=false

    #Get linenum of 'isstart_pattern'
    isstart_pattern_isfound=$(grep -wn "${isstart_pattern}" "${isrules_fpath}")
    if [[ -z "${isstart_pattern_isfound}" ]]; then
        ret=false

        isstart_pattern_print=$(echo "${isstart_pattern}" | sed 's/\\//g')

        printmsg="${WLN_PRINTMSG_STATUS}: "
        printmsg+="pattern ${WLN_YELLOW}${isstart_pattern_print}${WLN_RESETCOLOR} "
        printmsg+="${WLN_PRINTMSG_NOT} found "
        printmsg+="in file ${WLN_LIGHTGREY}${isrules_fpath}${WLN_RESETCOLOR}"
    else    #pattern 'isstart_pattern' is found in file 'isrules_fpath'
        #Check if 'isrule' is alraedy added to file 'isrules_fpath'
        if [[ $(ip46tables_checkif_rule_isfound_in_file "${isrules_fpath}" "${isrule}") == false ]]; then
            isstart_pattern_linenum=$(grep -wn "${isstart_pattern}" "${isrules_fpath}" | cut -d":" -f1)
            isend_pattern_linenum_rel=$(cat "${isrules_fpath}" | tail -n +${isstart_pattern_linenum} | grep -n "${isend_pattern}" | head -n1 | cut -d":" -f1)
            isend_pattern_linenum=$((isstart_pattern_linenum + isend_pattern_linenum_rel - 1))

            #Insert rule at line-number 'isend_pattern_linenum'
            sudo sed -i "${isend_pattern_linenum}i ${isrule}" ${isrules_fpath}; exitcode=$? ; pid=$! ; wait ${pid}

            #Get 'printmsg' based on 'exitcode'
            if [[ ${exitcode} -eq 0 ]]; then
                ret=true

                printmsg="${WLN_PRINTMSG_STATUS}: "
                printmsg+="Insert ${WLN_YELLOW}${isrule}${WLN_RESETCOLOR} "
                printmsg+="in file ${WLN_LIGHTGREY}${isrules_fpath}${WLN_RESETCOLOR}: "
                printmsg+="${WLN_PRINTMSG_DONE}"
            else
                ret=false

                printmsg="${WLN_PRINTMSG_STATUS}: "
                printmsg+="Insert ${WLN_YELLOW}${isrule}${WLN_RESETCOLOR} "
                printmsg+="in file ${WLN_LIGHTGREY}${isrules_fpath}${WLN_RESETCOLOR}: "
                printmsg+="${WLN_PRINTMSG_FAILED}"
            fi
        else    #'isrule' is already added to file 'isrules_fpath'
            printmsg="${WLN_PRINTMSG_STATUS}: "
            printmsg+="Insert ${WLN_YELLOW}${isrule}${WLN_RESETCOLOR} "
            printmsg+="in file ${WLN_LIGHTGREY}${isrules_fpath}${WLN_RESETCOLOR}: "
            printmsg+="${WLN_PRINTMSG_ALREADYDONE}"

            ret=true
        fi
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;
}

ip46tables_checkif_rule_isfound_in_file() {
    #Input args
    local isrules_fpath=${1}
    local isrule=${2}

    #Define variables
    local isrule_escaped="${WLN_EMPTYSTRING}"
    local isrule_isfound="${WLN_EMPTYSTRING}"
    local ret=false

    #ESACPE DASH: prepend backslashes
    isrule_escaped=$(echo "${isrule}" | sed 's/-/\\-/g')

    #Check if 'isrule' is found in file 'isrules_fpath'
    isrule_isfound=$(grep -wn "${isrule_escaped}" "${isrules_fpath}")
    if [[ -n "${isrule_isfound}" ]]; then
        ret=true 
    else
        ret=false 
    fi

    #Output
    echo "${ret}"

    return 0;
}

ip46tables_rule_restore() {
    #Input args
    local isrestorecmd=${1}
    local isrules_fpath=${2}

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local exitcode=0
    local pid=0
    local ret="${WLN_EMPTYSTRING}" 

    #Restore from file
    sudo "${isrestorecmd}" < "${isrules_fpath}" ; exitcode=$? ; pid=$! ; wait ${pid}

    #Print
    if [[ ${exitcode} -eq 0 ]]; then
        printmsg="${WLN_PRINTMSG_STATUS}: Execute ${WLN_LIGHTGREY}${isrestorecmd} < ${isrules_fpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"

        ret=true
    else
        printmsg="${WLN_PRINTMSG_STATUS}: Execute ${WLN_LIGHTGREY}${isrestorecmd} < ${isrules_fpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"

        ret=false
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;
}

ip46tables_rule_save() {
    #Input args
    local issavecmd=${1}
    local isrules_fpath=${2}
    local isoverwrite=${3}

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local exitcode=0
    local isallowedtowrite=false
    local pid=0
    local ret="${WLN_EMPTYSTRING}" 

    #Determine whether it is allowed to write-to-file or not.
    if [[ ${isoverwrite} == false ]]; then
        if [[ -s ${isrules_fpath} ]]; then  #contains data
            isallowedtowrite=false
        else    #contains no data
            isallowedtowrite=true
        fi
    else    #isoverwrite = true
        isallowedtowrite=true
    fi

    if [[ ${isallowedtowrite} == true ]]; then
        #Save to file
        sudo "${issavecmd}" > "${isrules_fpath}" ; exitcode=$? ; pid=$! ; wait ${pid}

        #Print
        if [[ ${exitcode} -eq 0 ]]; then
            printmsg="${WLN_PRINTMSG_STATUS}: Execute ${WLN_LIGHTGREY}${issavecmd} > ${isrules_fpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"

            ret=true
        else
            printmsg="${WLN_PRINTMSG_STATUS}: Execute ${WLN_LIGHTGREY}${issavecmd} > ${isrules_fpath}${WLN_RESETCOLOR}: ${WLN_PRINTMSG_FAILED}"

            ret=false
        fi
    else
        printmsg="${WLN_PRINTMSG_STATUS}: ${WLN_LIGHTGREY}${isrules_fpath}${WLN_RESETCOLOR} already saved (not allowed to be overwritten)"

        ret=true
    fi

    #Print
    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;
}

ip46tables_service_create() {
    #Input args
    local iscmd=${1}
    local isrestorecmd=${2}
    local isrulesorgfpath=${3}
    local isrules_fpath=${4}
    local isservicefpath=${5}


    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Generate 'ipxables.service'
    filecontent="[Unit]\n"
    filecontent+="Description=Start/Stop iptables/ip6tables service\n"
    if [[ "${iscmd}" == "${WLN_IPTABLES}" ]]; then
        filecontent+="Wants=network.target\n"
        filecontent+="After=enable-ufw-before-login.service\n"
        filecontent+="After=dnsmasq.service\n"   
    else    #iscmd = WLN_IP6TABLES
        filecontent+="Wants=network.target\n"
        filecontent+="After=iptables.service\n"
    fi
    filecontent+="\n"
    filecontent+="[Service]\n"
    filecontent+="Type=oneshot\n"
    filecontent+="#User MUST BE SET TO 'root'\n"
    filecontent+="User=root\n"
    filecontent+="RemainAfterExit=yes\n"
    filecontent+="ExecStart=/bin/bash -c '${isrestorecmd} < ${isrules_fpath}'\n"
    filecontent+="ExecStop=/bin/bash -c '${isrestorecmd} < ${isrulesorgfpath}'\n"
    filecontent+="\n"
    filecontent+="[Install]\n"
    filecontent+="WantedBy=multi-user.target\n"
    
    #Write to file
    if [[ $(WriteToFile "${isservicefpath}" "${filecontent}" "true") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}