#!/bin/bash
#---SUPPORT FUNCTIONS
Aptget_Install() {
    #Input args
    local sw_name=${1}

    #Define variables
    local ret_dummy=false
    local ret=false

    #Check if software is already installed
    if [[ $(SoftwareIsInstalled "${sw_name}") == false ]]; then
        #Define command line
        cmd="apt-get -y -o DPkg::Lock::Timeout=${WLN_APTGET_LOCK_TIMEOUT} install ${sw_name}"

        #Install software
        ret_dummy=$(CmdExec "${cmd}")

        #Wait for 1 second
        sleep 1

        #Check if software is installed
        if [[ $(SoftwareIsInstalled "${sw_name}") == false ]]; then
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

Aptget_Purge_Remove() {
    #Input args
    local sw_name=${1}

    #Define variables
    local ret_dummy=false
    local ret=false

    if [[ $(SoftwareIsInstalled "${sw_name}") == true ]]; then
        #Define command line
        cmd="apt-get -y -o DPkg::Lock::Timeout=${WLN_APTGET_LOCK_TIMEOUT} --purge remove ${sw_name}"
    
        #Remove software
        ret_dummy=$(CmdExec "${cmd}")

        #Wait for 1 second
        sleep 1

        #Check if software is installed
        if [[ $(SoftwareIsInstalled "${sw_name}") == true ]]; then
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

Aptget_Reinstall() {
    #Input args
    local sw_name=${1}

    #Define command line
    cmd="apt-get -y -o Dpkg::Options::=--force-confmiss -o DPkg::Lock::Timeout=${WLN_APTGET_LOCK_TIMEOUT} --reinstall install ${sw_name}"

    #Install software
    ret_dummy=$(CmdExec "${cmd}")

    #Wait for 1 second
    sleep 1

    #Check if software is installed
    if [[ $(SoftwareIsInstalled "${sw_name}") == false ]]; then
        ret=false
    else
        ret=true
    fi

    #Output
    echo "${ret}"

    return 0;
}

Aptget_Update() {
    #Define command
    # cmd="apt-get -y -o DPkg::Lock::Timeout=${WLN_APTGET_LOCK_TIMEOUT} update"
    cmd="apt-get -y update"

    #Execute command
    ret=$(CmdExec "${cmd}")

    #Output
    echo "${ret}"

    return 0;
}

Dpkg_Fix() {
    #Define command
    cmd="dpkg --configure -a"

    #Execute command
    ret=$(CmdExec "${cmd}")

    #Output
    echo "${ret}"

    return 0;
}



#---COMBO FUNCTIONS
Aptget_Purge_And_Install() {
    #Input args
    local sw_name=${1}

    #Define constants
    local PHASE_SOFTWAREFUNC_UNINSTALL=1
    local PHASE_SOFTWAREFUNC_INSTALL=2
    local PHASE_SOFTWAREFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_SOFTWAREFUNC_UNINSTALL}"
    local ret=false

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SOFTWAREFUNC_UNINSTALL}")
                if [[ $(Aptget_Purge_Remove "${sw_name}") == false ]]; then
                    ret=false

                    phase="${PHASE_SOFTWAREFUNC_EXIT}"
                else
                    phase="${PHASE_SOFTWAREFUNC_INSTALL}"
                fi
                ;;
            "${PHASE_SOFTWAREFUNC_INSTALL}")
                #Chekc if software is installed
                if [[ $(Aptget_Install "${sw_name}") == false ]]; then
                    ret=false
                else
                    ret=true
                fi

                phase="${PHASE_SOFTWAREFUNC_EXIT}"
                ;;
            ${PHASE_SOFTWAREFUNC_EXIT})
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

Aptget_Check_And_Install() {
    #Input args
    local sw_name=${1}

    #Define variables
    local ret=false

    #Take action based on software
    case "${sw_name}" in
        "${WLN_WPASUPPLICANT}")
            ret=$(Aptget_Check_And_Reinstall_Package "${WLN_WPASUPPLICANT}" \
                    "${WPA_SUPPLICANT_FULLPATH_ARR[@]}")
            ;;
        "${WLN_DNSMASQ}")
            ret=$(Aptget_Check_And_Reinstall_Package "${WLN_DNSMASQ}" \
                    "${DNSMASQ_FULLPATH_ARR[@]}")
            ;;
        "${WLN_HOSTAPD}")
            ret=$(Aptget_Check_And_Reinstall_Package "${WLN_HOSTAPD}" \
                    "${HOSTAPD_FULLPATH_ARR[@]}")
            ;;
        *)
            ret=$(Aptget_Install "${sw_name}")  
            ;;
    esac

    #Output
    echo "${ret}"

    return 0;
}

Aptget_Check_And_Reinstall_Package() {
    #Input args
    local sw_name=${1}
    shift
    local sw_files_arr=("$@")

    #Define constants
    local PHASE_SOFTWAREFUNC_PACKAGE_CHECK=1
    local PHASE_SOFTWAREFUNC_FULLPATH_LIST_CHECK=10
    local PHASE_SOFTWAREFUNC_PACKAGE_REINSTALL=20
    local PHASE_SOFTWAREFUNC_PURGE_AND_INSTALL=30
    local PHASE_SOFTWAREFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_SOFTWAREFUNC_PACKAGE_CHECK}"
    local files_are_present=false
    local ret=false

    #Take action based on software
    while true
    do
        case "${phase}" in
            "${PHASE_SOFTWAREFUNC_PACKAGE_CHECK}")
                #Check if software is installed
                if [[ $(SoftwareIsInstalled "${sw_name}") == false ]]; then
                    phase="${PHASE_SOFTWAREFUNC_PACKAGE_REINSTALL}"
                else
                    phase="${PHASE_SOFTWAREFUNC_FULLPATH_LIST_CHECK}"
                fi
                ;;
            "${PHASE_SOFTWAREFUNC_FULLPATH_LIST_CHECK}")
                #Initialize boolean
                files_are_present=true

                #For a list of fullpaths, check if they are all present
                for sw_fullpath_listitem in "${sw_files_arr[@]}"
                do
                    if [[ ! -z "${sw_fullpath_listitem}" ]] && \
                            [[ ! -f "${sw_fullpath_listitem}" ]] && \
                            [[ ! -d "${sw_fullpath_listitem}" ]]; then   #fullpath is not present
                        files_are_present=false

                        break
                    fi
                done

                #Update 'ret' based on 'files_are_present' value
                if [[ ${files_are_present} == false ]]; then
                    phase="${PHASE_SOFTWAREFUNC_PACKAGE_REINSTALL}"
                else
                    ret=true

                    phase="${PHASE_SOFTWAREFUNC_EXIT}"
                fi
                ;;
            "${PHASE_SOFTWAREFUNC_PACKAGE_REINSTALL}")
                if [[ $(Aptget_Reinstall "${sw_name}") == false ]]; then
                    phase="${PHASE_SOFTWAREFUNC_PURGE_AND_INSTALL}"
                else
                    ret=true

                    phase="${PHASE_SOFTWAREFUNC_EXIT}"
                fi
                ;;
            "${PHASE_SOFTWAREFUNC_PURGE_AND_INSTALL}")
                if [[ $(Aptget_Purge_And_Install "${sw_name}") == false ]]; then
                    ret=false
                else
                    ret=true
                fi

                phase="${PHASE_SOFTWAREFUNC_EXIT}"         
                ;;
            "${PHASE_SOFTWAREFUNC_EXIT}")
                break
                ;;
        esac  
    done

    #Output
    echo "${ret}"

    return 0;
}


SoftwareIsInstalled() {
    #Input args
    local sw_name=${1}

    #Define variables
    local stdOutput=${WLN_EMPTYSTRING}
    local ret=false
    
    #Check if software is installed
    stdOutput=$(dpkg -l | grep -E '^ii' | awk '{print $2}' | grep "^${sw_name}$")
    if [[ -n "${stdOutput}" ]]; then
        ret=true
    else
        #Double-check if software is installed
        #Remark:
        #   It could be the case that software cannot be found under 'ii'
        stdOutput=$(dpkg -l | grep -E '^pi' | awk '{print $2}' | grep "^${sw_name}$")
        if [[ -n "${stdOutput}" ]]; then
            ret=true
        else
            ret=false
        fi
    fi

    #Output
    echo "${ret}"

    return 0;   
}



#---MAIN FUNCTIONS
WLN_SoftwareInst_Mandatory_Handler() {
    #Define constants
    local PHASE_SOFTWAREFUNC_APTGET_UPDATE=1
    local PHASE_SOFTWAREFUNC_IW_INSTALL=10
    local PHASE_SOFTWAREFUNC_WIRELESSTOOLS_INSTALL=20
    local PHASE_SOFTWAREFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_SOFTWAREFUNC_IW_INSTALL}"
    local cmd="${WLN_EMPTYSTRING}"
    local aptgetupdate_dpkgfix_done=false
    local ret="${REJECTED}"

    # #Print
    # echo -e "${WLN_PRINTMSG_STATUS}: ${WLN_LIGHTGREY}Software${WLN_RESETCOLOR}: ${WLN_LIGHTBLUE}Updating...${WLN_RESETCOLOR}"
    # echo -e "${WLN_PRINTMSG_STATUS}: ${WLN_LIGHTGREY}Software${WLN_RESETCOLOR}: ${WLN_LIGHTBLUE}Please wait...${WLN_RESETCOLOR}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SOFTWAREFUNC_APTGET_UPDATE}")
                if [[ $(Aptget_Update) == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SOFTWAREFUNC_EXIT}"
                else
                    phase="${PHASE_SOFTWAREFUNC_IW_INSTALL}"
                fi

                aptgetupdate_dpkgfix_done=true
                ;;
            "${PHASE_SOFTWAREFUNC_IW_INSTALL}")
                if [[ $(Aptget_Install "${WLN_IW}") == false ]]; then
                    if [[ ${aptgetupdate_dpkgfix_done} == false ]]; then
                        phase="${PHASE_SOFTWAREFUNC_APTGET_UPDATE}"
                    else
                        ret="${REJECTED}"

                        phase="${PHASE_SOFTWAREFUNC_EXIT}"
                    fi
                else
                    phase="${PHASE_SOFTWAREFUNC_WIRELESSTOOLS_INSTALL}"
                fi
                ;;
            "${PHASE_SOFTWAREFUNC_WIRELESSTOOLS_INSTALL}")
                if [[ $(Aptget_Install "${WLN_WIRELESSTOOLS}") == false ]]; then
                    if [[ ${aptgetupdate_dpkgfix_done} == false ]]; then
                        phase="${PHASE_SOFTWAREFUNC_APTGET_UPDATE}"
                    else
                        ret="${REJECTED}"

                        phase="${PHASE_SOFTWAREFUNC_EXIT}"
                    fi
                else
                    ret="${ACCEPTED}"

                    phase="${PHASE_SOFTWAREFUNC_EXIT}"
                fi
                ;;
            "${PHASE_SOFTWAREFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    # echo "${ret}"

    # return 0;
}

WLN_SoftwareInst_OnDemand_Handler() {
    #--------------------------------------------------------------------
    #   IMPORTANT:
    #       Please use 'apt-get' instead of 'apt'
    #   REASON:
    #       When using 'apt' instead of 'apt-get' the following WARNING is shown:
    #           apt-get does not have a stable CLI interface...
    #           ...Use with caution in scripts.
    #--------------------------------------------------------------------
    #Input args
    local isbssmode=${1}

    #Define constants
    local PHASE_SOFTWAREFUNC_APTGET_UPDATE=1
    local PHASE_SOFTWAREFUNC_DPKG_FIX=2
    local PHASE_SOFTWAREFUNC_WPASUPPLICANT_CHECK_AND_INSTALL=10
    local PHASE_SOFTWAREFUNC_BRIDGE_UTILS_CHECK_AND_INSTALL=20
    local PHASE_SOFTWAREFUNC_DNSMASQ_CHECK_AND_INSTALL=30
    local PHASE_SOFTWAREFUNC_HOSTAPD_CONF_REMOVE=40
    local PHASE_SOFTWAREFUNC_HOSTAPD_CHECK_AND_INSTALL=50
    local PHASE_SOFTWAREFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_SOFTWAREFUNC_WPASUPPLICANT_CHECK_AND_INSTALL}"
    local cmd="${WLN_EMPTYSTRING}"
    local printmsg="${WLN_EMPTYSTRING}"
    local aptgetupdate_dpkgfix_done=false
    local ret="${REJECTED}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_SOFTWAREFUNC_APTGET_UPDATE}")
                if [[ $(Aptget_Update) == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SOFTWAREFUNC_EXIT}"
                else
                    phase="${PHASE_SOFTWAREFUNC_DPKG_FIX}"
                fi
                ;;
            "${PHASE_SOFTWAREFUNC_DPKG_FIX}")
                if [[ $(Dpkg_Fix) == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_SOFTWAREFUNC_EXIT}"
                else
                    phase="${PHASE_SOFTWAREFUNC_WPASUPPLICANT_CHECK_AND_INSTALL}"
                fi

                aptgetupdate_dpkgfix_done=true
                ;;
            "${PHASE_SOFTWAREFUNC_WPASUPPLICANT_CHECK_AND_INSTALL}")
                if [[ "${isbssmode}" == "${PL_WLN_BSS_MODE_INFRASTRUCTURE}" ]]; then
                    if [[ $(Aptget_Check_And_Install "${WLN_WPASUPPLICANT}") == false ]]; then
                        if [[ ${aptgetupdate_dpkgfix_done} == false ]]; then
                            phase="${PHASE_SOFTWAREFUNC_APTGET_UPDATE}"
                        else
                            ret="${REJECTED}"

                            phase="${PHASE_SOFTWAREFUNC_EXIT}"
                        fi
                    else
                        ret="${ACCEPTED}"

                        phase="${PHASE_SOFTWAREFUNC_EXIT}"
                    fi
                else
                    phase="${PHASE_SOFTWAREFUNC_BRIDGE_UTILS_CHECK_AND_INSTALL}"
                fi
                ;;
            "${PHASE_SOFTWAREFUNC_BRIDGE_UTILS_CHECK_AND_INSTALL}")
                if [[ "${isbssmode}" != "${PL_WLN_BSS_MODE_INFRASTRUCTURE}" ]]; then
                    if [[ $(Aptget_Check_And_Install "${WLN_BRIDGE_UTILS}") == false ]]; then
                        if [[ ${aptgetupdate_dpkgfix_done} == false ]]; then
                            phase="${PHASE_SOFTWAREFUNC_APTGET_UPDATE}"
                        else
                            ret="${REJECTED}"

                            phase="${PHASE_SOFTWAREFUNC_EXIT}"
                        fi
                    else
                        phase="${PHASE_SOFTWAREFUNC_DNSMASQ_CHECK_AND_INSTALL}"
                    fi
                else
                    phase="${PHASE_SOFTWAREFUNC_DNSMASQ_CHECK_AND_INSTALL}"
                fi        
                ;;
            "${PHASE_SOFTWAREFUNC_DNSMASQ_CHECK_AND_INSTALL}")
                if [[ "${isbssmode}" == "${PL_WLN_BSS_MODE_ROUTER}" ]]; then
                    if [[ $(Aptget_Check_And_Install "${WLN_DNSMASQ}") == false ]]; then
                        if [[ ${aptgetupdate_dpkgfix_done} == false ]]; then
                            phase="${PHASE_SOFTWAREFUNC_APTGET_UPDATE}"
                        else
                            ret="${REJECTED}"

                            phase="${PHASE_SOFTWAREFUNC_EXIT}"
                        fi
                    else
                        phase="${PHASE_SOFTWAREFUNC_HOSTAPD_CHECK_AND_INSTALL}"
                    fi
                else
                    phase="${PHASE_SOFTWAREFUNC_HOSTAPD_CHECK_AND_INSTALL}"
                fi
                ;;
            # "${PHASE_SOFTWAREFUNC_HOSTAPD_CONF_REMOVE}")
            #     if [[ $(RemoveFile "${WLN_HOSTAPD_CONF_FPATH}") == false ]]; then
            #         if [[ ${aptgetupdate_dpkgfix_done} == false ]]; then
            #             phase="${PHASE_SOFTWAREFUNC_APTGET_UPDATE}"
            #         else
            #             ret="${REJECTED}"

            #             phase="${PHASE_SOFTWAREFUNC_EXIT}"
            #         fi
            #     else
            #         phase="${PHASE_SOFTWAREFUNC_HOSTAPD_CHECK_AND_INSTALL}"
            #     fi
            #     ;;
            "${PHASE_SOFTWAREFUNC_HOSTAPD_CHECK_AND_INSTALL}")
                if [[ $(Aptget_Check_And_Install "${WLN_HOSTAPD}") == false ]]; then
                    if [[ ${aptgetupdate_dpkgfix_done} == false ]]; then
                        phase="${PHASE_SOFTWAREFUNC_APTGET_UPDATE}"
                    else
                        ret="${REJECTED}"

                        phase="${PHASE_SOFTWAREFUNC_EXIT}"
                    fi
                else
                    ret="${ACCEPTED}"

                    phase="${PHASE_SOFTWAREFUNC_EXIT}"
                fi
                ;;
            "${PHASE_SOFTWAREFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0; 
}
