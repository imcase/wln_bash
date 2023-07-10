#!/bin/bash
#---GET PID
mypid=$$



#---ENV VARIABLES
WLN_EnvVarLoad() {
	Wln_current_script_fpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    Wln_current_script_dir=$(dirname ${Wln_current_script_fpath})	#/repo/LTPP3_ROOTFS/development_tools

    ntios_wln_includefunc_filename="ntios_wln_includefunc.sh"
    ntios_wln_includefunc_fpath=${Wln_current_script_dir}/${ntios_wln_includefunc_filename}

    source "${ntios_wln_includefunc_fpath}"
}



#---MAIN SUBROUTINE
NonProperty_Input_Handler() {
    #Input args
    local isbssmode=${1}

    #Define variables
    local phymode_choice=1
    local wepmode_choice=1
    local wepkey_choice=2
    local wpamode_choice=1
    local wpakey_choice=1
    local wpaalgorithm_choice=1
    local dhcp_isenabled_choice=1
    local dhcpv6_isenabled_choice=1
    local dns_isenabled_choice=1
    local dnsv6_isenabled_choice=1
    local ssid_choice=1
    local bssid_choice=1
    local ssid_isvisible_choice=1
    local channel_choice=1



    #Update 'bssmode'
    bssmode="${isbssmode}"

    #Update the rest of the variables
    case "${bssmode}" in
        "${PL_WLN_BSS_MODE_INFRASTRUCTURE}")
            ssid_choice=3
            bssid_choice=3

            if [[ ${ssid_choice} -eq 1 ]]; then #vvh
                wepmode_choice=1
                wepkey_choice=2
                # wpamode_choice=1
                wpamode_choice=1
                wpakey_choice=1
                dhcp_isenabled_choice=2
                dhcpv6_isenabled_choice=2
                dns_isenabled_choice=1
                dnsv6_isenabled_choice=1
            elif [[ ${ssid_choice} -eq 2 ]]; then  #hond
                wepmode_choice=2
                wepkey_choice=1
                # wpamode_choice=1
                wpamode_choice=2
                wpakey_choice=1
                dhcp_isenabled_choice=1
                dhcpv6_isenabled_choice=1
                dns_isenabled_choice=2
                dnsv6_isenabled_choice=2
            else    #hond_5G
                wepmode_choice=3
                wepkey_choice=2
                # wpamode_choice=1
                wpamode_choice=3
                wpakey_choice=1
                dhcp_isenabled_choice=2
                dhcpv6_isenabled_choice=2
                dns_isenabled_choice=1
                dnsv6_isenabled_choice=1
            fi
            ;;
        "${PL_WLN_BSS_MODE_ACCESSPOINT}")
            ssid_choice=1
            phymode_choice=2
            wepmode_choice=2
            wepkey_choice=1
            wpamode_choice=2
            wpakey_choice=1
            wpaalgorithm_choice=2
            ssid_isvisible_choice=1
            channel_choice=1
            ;;
        *)
            ssid_choice=2
            phymode_choice=3
            wepmode_choice=3
            wepkey_choice=2
            wpamode_choice=3
            wpakey_choice=2
            wpaalgorithm_choice=1
            ssid_isvisible_choice=2
            channel_choice=4
            ;;
    esac

    #Only relevant for 'PL_WLN_BSS_MODE_ACCESSPOINT' and 'PL_WLN_BSS_MODE_ROUTER'
    case "${phymode_choice}" in
        "1")
            phymode=${PL_WLN_PHY_MODE_2G_LEGACY}
            ;;
        "2")
            phymode=${PL_WLN_PHY_MODE_2G}
            ;;
        "3")
            phymode=${PL_WLN_PHY_MODE_5G}
            ;;
        "4")
            phymode=${PL_WLN_PHY_MODE_NULL}
            ;;
    esac


    case "${wepmode_choice}" in
        "1")
            wepmode=${PL_WLN_WEP_MODE_DISABLED}
            ;;
        "2")
            wepmode=${PL_WLN_WEP_MODE_64}
            ;;
        "3")
            wepmode=${PL_WLN_WEP_MODE_128}
            ;;
    esac

    #Depending on the mode, wepkey will be unmodified, cut off or extended
    #Mode: PL_WLN_WEP_MODE_64
    #   number of hex-values = 10 -> do not modify 'wepkey'.
    #   number of hex-values < 10 -> append additional zeros (0).
    #   number of hex-values > 10 -> cut off trailing digits until the number of hex-values = 10
    #Mode: PL_WLN_WEP_MODE_128
    #   number of hex-values = 26 -> do not modify 'wepkey'.
    #   number of hex-values < 26 -> append additional zeros (0).
    #   number of hex-values > 26 -> cut off trailing digits until the number of hex-values = 26
    case "${wepkey_choice}" in
        "1")
            wln_wepkey="1234567890"
            ;;
        "2")
            wln_wepkey="11111111112222222222"
            ;;
        "3")
            wln_wepkey="11111111112222222222333333"
            ;;
        "4")
            wln_wepkey="111111111122222222223333334444444444"
            ;;
    esac

    case "${wpamode_choice}" in
        "1")
            wpamode=${PL_WLN_WPA_DISABLED}
            ;;
        "2")
            wpamode=${PL_WLN_WPA_WPA1_PSK}
            ;;
        "3")
            wpamode=${PL_WLN_WPA_WPA2_PSK}
            ;;
    esac

    case "${wpakey_choice}" in
        "1")
            wpakey="viezevuilehond"
            ;;
        "2")
            wpakey="tibbo168"
            ;;
        "3")
            wpakey="p@ssw0rd"
            ;;
        "4")
            wpakey="test1234"
            ;;
    esac

    case "${wpaalgorithm_choice}" in
        "1")
            wpaalgorithm=${PL_WLN_WPA_ALGORITHM_TKIP}
            ;;
        "2")
            wpaalgorithm=${PL_WLN_WPA_ALGORITHM_AES}
            ;;
        "3")
            wpaalgorithm=${PL_WLN_WPA_ALGORITHM_TKIP_AES}
            ;;
    esac

    case "${dhcp_isenabled_choice}" in
        "1")
            dhcp_isenabled=true
            ;;
        "2")
            dhcp_isenabled=false
            ;;
    esac

    case "${dhcpv6_isenabled_choice}" in
        "1")
            dhcpv6_isenabled=true
            ;;
        "2")
            dhcpv6_isenabled=false
            ;;
    esac

    case "${dns_isenabled_choice}" in
        "1")
            dns_isenabled=true
            ;;
        "2")
            dns_isenabled=false
            ;;
    esac

    case "${dnsv6_isenabled_choice}" in
        "1")
            dnsv6_isenabled=true
            ;;
        "2")
            dnsv6_isenabled=false
            ;;
    esac

    case "${dnsv6_isenabled_choice}" in
        "1")
            dnsv6_isenabled=true
            ;;
        "2")
            dnsv6_isenabled=false
            ;;
    esac
    
    if [[ "${bssmode}" == "${PL_WLN_BSS_MODE_INFRASTRUCTURE}" ]]; then
        case "${ssid_choice}" in
            "1")
                ssid="vvh"

                case "${bssid_choice}" in
                    "1")
                        bssid=""
                        ;;
                    "2")
                        bssid="${WLN_BSSID_000000}"
                        ;;
                    *)
                        bssid="80:26:89:59:2D:ED"
                        ;;
                esac
                ;;
            "2")
                ssid="hond"

                case "${bssid_choice}" in
                    "1")
                        bssid=""
                        ;;
                    "2")
                        bssid="${WLN_BSSID_000000}"
                        ;;
                    *)
                        bssid="F0:79:59:78:79:18"
                        ;;
                esac
                ;;
            "3")
                ssid="hond_5G"

                case "${bssid_choice}" in
                    "1")
                        bssid=""
                        ;;
                    "2")
                        bssid="${WLN_BSSID_000000}"
                        ;;
                    *)
                        bssid="F0:79:59:78:79:1C"
                        ;;
                esac
                ;;
        esac
    elif [[ "${bssmode}" == "${PL_WLN_BSS_MODE_ACCESSPOINT}" ]]; then
        case "${ssid_choice}" in
            "1")
                ssid=""
                ;;
            "2")
                if [[ "${phymode}" == "${PL_WLN_PHY_MODE_2G_LEGACY}" ]]; then
                    ssid="ltpp3g2_ap_2G(B)"
                elif [[ "${phymode}" == "${PL_WLN_PHY_MODE_2G}" ]]; then
                    ssid="ltpp3g2_ap_2G(G/N)"
                else
                    ssid="ltpp3g2_ap_5G(A/AC/N)"
                fi
                ;;
        esac
    else
        case "${ssid_choice}" in
            "1")
                ssid=""
                ;;
            "2")
                if [[ "${phymode}" == "${PL_WLN_PHY_MODE_2G_LEGACY}" ]]; then
                    ssid="ltpp3g2_rt_2G(B)"
                elif [[ "${phymode}" == "${PL_WLN_PHY_MODE_2G}" ]]; then
                    ssid="ltpp3g2_rt_2G(G/N)"
                else
                    ssid="ltpp3g2_rt_5G(A/AC/N)"
                fi
                ;;
        esac
    fi

    # if [[ "${bssmode}" == "${PL_WLN_BSS_MODE_INFRASTRUCTURE}" ]]; then
    #     ssid_isvisible="${NO}"    #is not relevant!
    # else
    case "${ssid_isvisible_choice}" in
        "1")
            ssid_isvisible="${YES}"
            ;;
        "2")
            ssid_isvisible="${NO}"
            ;;
    esac
    # fi

    case "${channel_choice}" in
        "1")
            channel=0
            ;;
        "2")
            channel=36
            ;;
        "3")
            channel=100
            ;;
        "4")
            channel=200
            ;;
    esac
}

main__sub() {
    #---CONSTANTS
    # local PHASE_INPUT="1"
    local PHASE_UNBRIDGE_INTERFACES="2"
    local PHASE_SERVICES_DISABLESTOP_HANDLER="3"
    local PHASE_SOFTWARE_MANDATORY_INSTALL="4"
    local PHASE_DOMAINCODE_SET="5"
    local PHASE_NET_PROPERTY_INPUT="6"
    local PHASE_WLN_INTFSTATES_CTX_INIT="7"
    local PHASE_ENABLE="8"
    local PHASE_SETWEP="9"
    local PHASE_SETWPA="10"
    local PHASE_NETWORKSTART_ACCESSPOINT1="11"
    local PHASE_NETWORKSTOP_ACCESSPOINT1="12"
    local PHASE_NETWORKSTART_ROUTER1="13"
    local PHASE_NETWORKSTOP_ROUTER1="14"
    local PHASE_ASSOCIATE1="15"
    local PHASE_DISASSOCIATE1="16"
    local PHASE_EXIT="17"

    #---VARAIBLES
    local phase="${PHASE_UNBRIDGE_INTERFACES}"
    # local bssmode="${WLN_EMPTYSTRING}"
    # local channel=0
    # local dhcp_isenabled=true
    # local dhcpv6_isenabled=true
    # local dns_isenabled=false
    # local dnsv6_isenabled=false
    # local phymode="${WLN_EMPTYSTRING}"
    # local ssid="${WLN_EMPTYSTRING}"
    # local ssid_isvisible=${NO}
    # local wepkey="${WLN_EMPTYSTRING}"
    # local wepmode=${WLN_EMPTYSTRING}
    # local wpaalgorithm=${WLN_EMPTYSTRING}
    # local wpakey=""
    # local wpamode=${WLN_EMPTYSTRING}
    local printmsg="${WLN_EMPTYSTRING}"
    local networkstart_result="${REJECTED}"
    local ret="${REJECTED}"



    #---LOAD ENVIRONMENT VARIABLES
    WLN_EnvVarLoad
    


    #***IMPORTANT*** Add Set of Commands to '/etc/sudoers'
    Sudoers_Allow_SetOfCmds "${mypid}"


    #---PHASE
    #Print
    printmsg="${WLN_PRINTMSG_STATUS}:---:${WLN_LIGHTGREY}ntios_wln.sh${WLN_RESETCOLOR}: ${WLN_LIGHTBLUE}START${WLN_RESETCOLOR}"
    echo -e "\r${printmsg}\r"



    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_UNBRIDGE_INTERFACES}")
                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:INTERFACES: UNBRDIGE"
                echo -e "\r${printmsg}"

                #Remark:
                #   We may want to pre-install 'iw' and 'iwtools' during the...
                #   ...docker-image creation.
                WLN_Unbridge_Interfaces_Handler

                phase="${PHASE_SERVICES_DISABLESTOP_HANDLER}"

                ;;
            "${PHASE_SERVICES_DISABLESTOP_HANDLER}")
                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:ALL SERVICES: DISABLE & STOP"
                echo -e "\r${printmsg}"

                WLN_Services_DisableStop_Handler

                phase="${PHASE_SOFTWARE_MANDATORY_INSTALL}"
                ;;
            "${PHASE_SOFTWARE_MANDATORY_INSTALL}")
                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:MANDATORY SOFTWARE: INSTALLATION"
                echo -e "\r${printmsg}"

                #Remark:
                #   We may want to pre-install 'iw' and 'iwtools' during the...
                #   ...docker-image creation.
                WLN_SoftwareInst_Mandatory_Handler

                phase="${PHASE_DOMAINCODE_SET}"
                ;;
            "${PHASE_DOMAINCODE_SET}")
                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:COUNTRY-CODE: SET"
                echo -e "\r${printmsg}"

                #   The domain-code needs to be set according to the customer's...
                #   ...location (in which country will this ltpp3-g2 reside?)...
                #   ...or preference.
                #   We HAVE to pre-set the domain-code during the docker-image creation.
                WLN_DomainSet "${PL_WLN_DOMAIN_NL}"

                phase="${PHASE_NET_PROPERTY_INPUT}"
                ;;
            "${PHASE_NET_PROPERTY_INPUT}")
                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:NET-PROPERTY INPUT: SET"
                echo -e "\r${printmsg}"
            
                NET_Property_Netplan_Handler

                phase="${PHASE_WLN_INTFSTATES_CTX_INIT}"
                ;;
            "${PHASE_WLN_INTFSTATES_CTX_INIT}")
                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:WLN_INTFSTATES_CTX: INIT"
                echo -e "\r${printmsg}"

                WLN_IntfStates_Ctx_Init_Handler

                phase="${PHASE_ENABLE}"
                ;;
            "${PHASE_ENABLE}")
                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:WLN_ENABLE"
                echo -e "\r${printmsg}"

                if [[ $(WLN_enable) == ${REJECTED} ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_EXIT}"
                else
                    phase="${PHASE_NETWORKSTART_ACCESSPOINT1}"
                fi
                ;;
            "${PHASE_NETWORKSTART_ACCESSPOINT1}")
                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:PL_WLN_BSS_MODE_ACCESSPOINT: ${WLN_PRINTMSG_START}"
                echo -e "\r${printmsg}"

                #Non-Property Input values
                NonProperty_Input_Handler "${PL_WLN_BSS_MODE_ACCESSPOINT}"

                # phymode (=wln_band): is provided in file 'ntios_wln_propertyinputfunc.sh', function 'WLN_Property_Input_Handler'
                WLN_Property_Input_Handler "${bssmode}" \
                        "${WLN_NA}" "${WLN_NA}" \
                        "${WLN_NA}" "${WLN_NA}" \
                        "${ssid}" \
                        "${phymode}"

                #Set WEP
                WLN_setwep "${wepkey}" "${wepmode}"

                #Set WPA
                WLN_setwpa "${wpamode}" \
                        "${wpaalgorithm}" \
                        "${wpakey}" \
                        "${PL_WLN_WPA_CAST_MULTICAST}"

                #Execute wln.networkstart
                if [[ $(WLN_networkstart "${ssid}" \
                        "${channel}"\
                        "${bssmode}" \
                        "${ssid_isvisible}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_EXIT}"
                else
                    ret="${ACCEPTED}"

                    phase="${PHASE_NETWORKSTOP_ACCESSPOINT1}"
                fi

                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:PL_WLN_BSS_MODE_ACCESSPOINT:->RESULT "
                printmsg+="{${WLN_LIGHTGREY}ACCEPTED(${WLN_RESETCOLOR}0${WLN_LIGHTGREY})${WLN_RESETCOLOR}|"
                printmsg+="${WLN_LIGHTGREY}REJECTED(${WLN_RESETCOLOR}1${WLN_LIGHTGREY})${WLN_RESETCOLOR}}: "
                printmsg+="${ret}"
                echo -e "\r${printmsg}\r"

                #Press any key to continue
                tput cud1; read -N1 -rs -p "press any key to continue"; tput cud1; tput cud1
                ;;
            "${PHASE_NETWORKSTOP_ACCESSPOINT1}")
                if [[ $(WLN_networkstop) == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_EXIT}"
                else
                    ret="${ACCEPTED}"

                    phase="${PHASE_NETWORKSTART_ROUTER1}"
                fi

                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:PL_WLN_BSS_MODE_ACCESSPOINT: ${WLN_PRINTMSG_STOP}"
                echo -e "\r${printmsg}"

                #Press any key to continue
                tput cud1; read -N1 -rs -p "press any key to continue"; tput cud1; tput cud1
                ;;
            "${PHASE_NETWORKSTART_ROUTER1}")
                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:PL_WLN_BSS_MODE_ROUTER: ${WLN_PRINTMSG_START}"
                echo -e "\r${printmsg}"

                #Non-Property Input values
                NonProperty_Input_Handler "${PL_WLN_BSS_MODE_ROUTER}"

                # phymode (=wln_band): is provided in file 'ntios_wln_propertyinputfunc.sh', function 'WLN_Property_Input_Handler'
                WLN_Property_Input_Handler "${bssmode}" \
                        "${WLN_NA}" "${WLN_NA}" \
                        "${WLN_NA}" "${WLN_NA}" \
                        "${ssid}" \
                        "${phymode}"

                #Set WEP
                WLN_setwep "${wepkey}" "${wepmode}"

                #Set WPA
                WLN_setwpa "${wpamode}" \
                        "${wpaalgorithm}" \
                        "${wpakey}" \
                        "${PL_WLN_WPA_CAST_MULTICAST}"

                #Execute wln.networkstart
                if [[ $(WLN_networkstart "${ssid}" \
                        "${channel}"\
                        "${bssmode}" \
                        "${ssid_isvisible}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_EXIT}"
                else
                    ret="${ACCEPTED}"

                    phase="${PHASE_NETWORKSTOP_ROUTER1}"
                fi

                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:PL_WLN_BSS_MODE_ROUTER:->RESULT "
                printmsg+="{${WLN_LIGHTGREY}ACCEPTED(${WLN_RESETCOLOR}0${WLN_LIGHTGREY})${WLN_RESETCOLOR}|"
                printmsg+="${WLN_LIGHTGREY}REJECTED(${WLN_RESETCOLOR}1${WLN_LIGHTGREY})${WLN_RESETCOLOR}}: "
                printmsg+="${ret}"
                echo -e "\r${printmsg}\r"

                #Press any key to continue
                tput cud1; read -N1 -rs -p "press any key to continue"; tput cud1; tput cud1
                ;;
            "${PHASE_NETWORKSTOP_ROUTER1}")
                if [[ $(WLN_networkstop) == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_EXIT}"
                else
                    ret="${ACCEPTED}"

                    phase="${PHASE_ASSOCIATE1}"
                fi

                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:PL_WLN_BSS_MODE_ROUTER: ${WLN_PRINTMSG_STOP}"
                echo -e "\r${printmsg}"

                #Press any key to continue
                tput cud1; read -N1 -rs -p "press any key to continue"; tput cud1; tput cud1
                ;;
            "${PHASE_ASSOCIATE1}")
                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:PL_WLN_BSS_MODE_INFRASTRUCTURE: ${WLN_PRINTMSG_START}"
                echo -e "\r${printmsg}"

                #Non-Property Input values
                NonProperty_Input_Handler "${PL_WLN_BSS_MODE_INFRASTRUCTURE}"

                # phymode (=wln_band): is provided in file 'ntios_wln_propertyinputfunc.sh', function 'WLN_Property_Input_Handler'
                WLN_Property_Input_Handler "${bssmode}" \
                        "${dhcp_isenabled}" "${dhcpv6_isenabled}" \
                        "${dns_isenabled}" "${dnsv6_isenabled}" \
                        "${ssid}" \
                        "${phymode}"

                #Set WEP
                WLN_setwep "${wepkey}" "${wepmode}"

                #Set WPA
                WLN_setwpa "${wpamode}" \
                        "${wpaalgorithm}" \
                        "${wpakey}" \
                        "${PL_WLN_WPA_CAST_MULTICAST}"

                #Execute wln.associate
                if [[ $(WLN_associate "${bssid}" \
                        "${ssid}" \
                        "${channel}" \
                        "${bssmode}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_EXIT}"
                else
                    ret="${ACCEPTED}"

                    phase="${PHASE_DISASSOCIATE1}"
                fi

                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:PL_WLN_BSS_MODE_INFRASTRUCTURE:->RESULT "
                printmsg+="{${WLN_LIGHTGREY}ACCEPTED(${WLN_RESETCOLOR}0${WLN_LIGHTGREY})${WLN_RESETCOLOR}|"
                printmsg+="${WLN_LIGHTGREY}REJECTED(${WLN_RESETCOLOR}1${WLN_LIGHTGREY})${WLN_RESETCOLOR}}: "
                printmsg+="${ret}"
                echo -e "\r${printmsg}\r"

                #Press any key to continue
                tput cud1; read -N1 -rs -p "press any key to continue"; tput cud1; tput cud1
                ;;
            "${PHASE_DISASSOCIATE1}")
                if [[ $(WLN_disassociate) == "${REJECTED}" ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                #Print
                printmsg="${WLN_PRINTMSG_STATUS}:-:PL_WLN_BSS_MODE_INFRASTRUCTURE: ${WLN_PRINTMSG_STOP}"
                echo -e "\r${printmsg}"

                #Press any key to continue
                tput cud1; read -N1 -rs -p "press any key to continue"; tput cud1; tput cud1

                #Goto next-phase
                phase="${PHASE_EXIT}"
                ;;
            "${PHASE_EXIT}")
                exit_handler "${ret}"

                break
                ;;
        esac
    done

    #Print
    printmsg="${WLN_PRINTMSG_STATUS}:---:${WLN_LIGHTGREY}ntios_wln.sh${WLN_RESETCOLOR}:->RESULT "
    printmsg+="{${WLN_LIGHTGREY}ACCEPTED(${WLN_RESETCOLOR}0${WLN_LIGHTGREY})${WLN_RESETCOLOR}|"
    printmsg+="${WLN_LIGHTGREY}REJECTED(${WLN_RESETCOLOR}1${WLN_LIGHTGREY})${WLN_RESETCOLOR}}: ${ret}"
    echo -e "\r${printmsg}\r"
}



#---EXECUTE
main__sub
