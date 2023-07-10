#!/bin/bash
#---FUNCTIONS
WLN_Ipv46_Forwarding_Enable() {
    #Define constants
    local PHASE_IPV46FORWARDINGFUNC_IPV4_FORWARDING_ENABLE=1
    local PHASE_IPV46FORWARDINGFUNC_IPV6_FORWARDING_ENABLE=2
    local PHASE_IPV46FORWARDINGFUNC_SYSCTL_EXEC=3
    local PHASE_IPV46FORWARDINGFUNC_EXIT=4

    #Define variables
    local phase="${PHASE_IPV46FORWARDINGFUNC_IPV4_FORWARDING_ENABLE}"
    local cmd=${WLN_EMPTYSTRING}
    local ret="${REJECTED}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_IPV46FORWARDINGFUNC_IPV4_FORWARDING_ENABLE}")
                #Enable ipv4- and ipv6-forwarding
                if [[ $(IpIsForwarded "${WLN_PATTERN_NET_IPV4_IP_FORWARD_ENABLED}") == false ]]; then
                    #Remove leading hash (#)
                    sudo sed -i "s/^#${WLN_PATTERN_NET_IPV4_IP_FORWARD_ENABLED}/${WLN_PATTERN_NET_IPV4_IP_FORWARD_ENABLED}/g" ${WLN_SYSCTL_CONF_FPATH}

                    #Print
                    echo -e "${WLN_PRINTMSG_STATUS}: ${WLN_LIGHTGREY}Forwarding IPv4${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"
                    
                    #Double-check if remove was  successful
                    if [[ $(IpIsForwarded "${WLN_PATTERN_NET_IPV4_IP_FORWARD_ENABLED}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_IPV46FORWARDINGFUNC_EXIT}"
                    else
                        phase="${PHASE_IPV46FORWARDINGFUNC_IPV6_FORWARDING_ENABLE}"
                    fi
                else
                    phase="${PHASE_IPV46FORWARDINGFUNC_IPV6_FORWARDING_ENABLE}"
                fi
                ;;
            "${PHASE_IPV46FORWARDINGFUNC_IPV6_FORWARDING_ENABLE}")
                if [[ $(IpIsForwarded "${WLN_PATTERN_NET_IPV6_CONF_ALL_FORWARDING_ENABLED}") == false ]]; then
                    sudo sed -i "s/^#${WLN_PATTERN_NET_IPV6_CONF_ALL_FORWARDING_ENABLED}/${WLN_PATTERN_NET_IPV6_CONF_ALL_FORWARDING_ENABLED}/g" ${WLN_SYSCTL_CONF_FPATH}

                    #Print
                    echo -e "${WLN_PRINTMSG_STATUS}: ${WLN_LIGHTGREY}Forwarding IPv6${WLN_RESETCOLOR}: ${WLN_PRINTMSG_DONE}"

                    #Double-check if remove was  successful
                    if [[ $(IpIsForwarded "${WLN_PATTERN_NET_IPV4_IP_FORWARD_ENABLED}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_IPV46FORWARDINGFUNC_EXIT}"
                    else
                        phase="${PHASE_IPV46FORWARDINGFUNC_SYSCTL_EXEC}"
                    fi
                else
                    phase="${PHASE_IPV46FORWARDINGFUNC_SYSCTL_EXEC}"
                fi
                ;;
            "${PHASE_IPV46FORWARDINGFUNC_SYSCTL_EXEC}")
                #Set command
                cmd="${WLN_SYSCTL_P}"

                #Execute command
                if [[ $(CmdExec "${cmd}" "false") == false ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_IPV46FORWARDINGFUNC_EXIT}"
                ;;
            "${PHASE_IPV46FORWARDINGFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}
