#!/bin/bash
WLN_EnvVarLoad() {
	Wln_current_script_fpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    Wln_current_script_dir=$(dirname ${Wln_current_script_fpath})	#/repo/LTPP3_ROOTFS/development_tools

    ntios_wln_includefunc_filename="ntios_wln_includefunc.sh"
    ntios_wln_includefunc_fpath=${Wln_current_script_dir}/${ntios_wln_includefunc_filename}

    source "${ntios_wln_includefunc_fpath}"
}

GatewayIntfValidation() {
    #Input args
    local isGatewayIntf=${1}

    #Define constants
    local PHASE_DAISYCHAIN_IS_SET_CHECK=0
    local PHASE_GATEWAYINTF_IS_SET_CHECK=1
    local PHASE_GATEWAYINTF_TRY_ETH0=2
    local PHASE_GATEWAYINTF_TRY_ETH1=3
    local PHASE_EXIT=4

    #Define variables
    local phase="${PHASE_DAISYCHAIN_IS_SET_CHECK}"
    local ret="${isGatewayIntf}"   #default gateway-interface is 'eth0'

    #Start phase
    #--------------------------------------------------------------------
    #In case 'isGatewayIntf = PL_WLN_GATEWAY_INTFSET_UNSET'
    #   1. first ping 8.8.8.8 via interface 'eth0'
    #   2. if (1.) fails, then ping to 8.8.8.8 via interface 'eth1'
    #   3. if (1. and 2.) fail, then 'ret = eth0'
    #--------------------------------------------------------------------
    while true
    do
        case "${phase}" in
            "${PHASE_DAISYCHAIN_IS_SET_CHECK}")
                if [[ $(DaisyChain_IsEnabled) == true ]]; then
                    ret="${WLN_ETH0}"

                    phase="${PHASE_EXIT}"
                else
                    phase="${PHASE_GATEWAYINTF_IS_SET_CHECK}"
                fi
                ;;
            "${PHASE_GATEWAYINTF_IS_SET_CHECK}")
                if [[ "${isGatewayIntf}" != "${PL_WLN_GATEWAY_INTFSET_UNSET}" ]] && \\
                        [[ "${isGatewayIntf}" != "${WLM_EMPTYSTRING}" ]]; then
                    ret="${isGatewayIntf}"

                    phase="${PHASE_EXIT}"
                else
                    phase="${PHASE_GATEWAYINTF_TRY_ETH0}"
                fi
                ;;
            "${PHASE_GATEWAYINTF_TRY_ETH0}")
                if [[ $(Ping "${WLN_ETH0}" "${NET_GOOGLE_DNSV4_8888}" "${NET_PING_COUNT}" "${NET_PING_DEADLINE}") ]]; then
                    ret="${WLN_ETH0}"

                    phase="${PHASE_EXIT}"
                else
                    phase="${PHASE_GATEWAYINTF_TRY_ETH1}"
                fi
                ;;
            "${PHASE_GATEWAYINTF_TRY_ETH1}")
                if [[ $(Ping "${WLN_ETH1}" "${NET_GOOGLE_DNSV4_8888}" "${NET_PING_COUNT}" "${NET_PING_DEADLINE}") ]]; then
                    ret="${WLN_ETH1}"
                else
                    ret="${WLN_ETH0}"
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


#---MAIN SUBROUTINE
main__sub() {
    WLN_EnvVarLoad

    GatewayIntfValidation "${PL_WLN_GATEWAY_INTFSET_UNSET}"
}



#---EXECUTE MAIN
main__sub
