#!/bin/bash
#---FUNCTIONS
WLN_Firmware_Config_Txt_Revise() {
    #Input args
    local iscountrycode=${1}
    local isautoreconnectonboot_istriggered=${2}    # {YES | NO}

    #Define constants
    local PHASE_FIRMWAREFUNC_DIR_CREATE=1
    local PHASE_FIRMWAREFUNC_CONFIG_TXT_FPATH_UPDATE=10
    local PHASE_FIRMWAREFUNC_SED_PATTERN_UPDATE=20
    local PHASE_FIRMWAREFUNC_SED_PATTERN_REPLACE_OLD_WITH_NEW=30
    local PHASE_FIRMWAREFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_FIRMWAREFUNC_DIR_CREATE}"
    local config_txt_fpath="${WLN_EMPTYSTRING}"
    local sed_pattern_old="${WLN_EMPTYSTRING}"
    local sed_pattern_new="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Set variable(s) based on 'isautoreconnectonboot_istriggered' input value
    if [[ ${isautoreconnectonboot_istriggered} == "${NO}" ]]; then
        config_txt_fpath="${WLN_FIRMWARE_CONFIG_TXT_FPATH}"
    else
        config_txt_fpath="${WLN_FIRMWARE_CONFIG_TXT_AUTORECONNECTONBOOT_FPATH}"
    fi


    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_FIRMWAREFUNC_DIR_CREATE}")
                if [[ ${isautoreconnectonboot_istriggered} == "${YES}" ]]; then
                    if [[ $(Mkdir "${WLN_ETC_TIBBO_FIRMWARE_WLN_DIR}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_FIRMWAREFUNC_EXIT}"
                    else
                        phase="${PHASE_FIRMWAREFUNC_CONFIG_TXT_FPATH_UPDATE}"
                    fi
                else
                    phase="${PHASE_FIRMWAREFUNC_CONFIG_TXT_FPATH_UPDATE}"
                fi
                ;;
            "${PHASE_FIRMWAREFUNC_CONFIG_TXT_FPATH_UPDATE}")
                #Set 'config_txt_fpath' (default value)
                # config_txt_fpath="${WLN_FIRMWARE_CONFIG_TXT_FPATH}"

                #Check if 'config_txt_fpath != WLN_FIRMWARE_CONFIG_TXT_FPATH'
                #...thus whether 'config_txt_fpath = WLN_FIRMWARE_CONFIG_TXT_AUTORECONNECTONBOOT_FPATH'
                if [[ ${isautoreconnectonboot_istriggered} == "${YES}" ]]; then
                    if [[ $(CopyFile "${WLN_FIRMWARE_CONFIG_TXT_FPATH}" \
                            "${config_txt_fpath}") == false ]]; then
                        ret="${REJECTED}"

                        phase="${PHASE_FIRMWAREFUNC_EXIT}"
                    else
                        #Update 'config_txt_fpath'
                        # config_txt_fpath="${config_txt_fpath}"
                        
                        phase="${PHASE_FIRMWAREFUNC_SED_PATTERN_UPDATE}"
                    fi
                else
                    phase="${PHASE_FIRMWAREFUNC_SED_PATTERN_UPDATE}"
                fi
                ;;
            "${PHASE_FIRMWAREFUNC_SED_PATTERN_UPDATE}")
                sed_pattern_old="${WLN_PATTERN_CCODE}"
                sed_pattern_new="\\${WLN_PATTERN_CCODE}\\=\\${iscountrycode}"

                phase="${PHASE_FIRMWAREFUNC_SED_PATTERN_REPLACE_OLD_WITH_NEW}"
                ;;
            "${PHASE_FIRMWAREFUNC_SED_PATTERN_REPLACE_OLD_WITH_NEW}")
                sudo sed -i "/${sed_pattern_old}/c${sed_pattern_new}" ${config_txt_fpath}; exitcode=$?

                if [[ ${exitcode} -eq 0 ]]; then
                    ret="${ACCEPTED}"
                else
                    ret="${REJECTED}"
                fi

                phase="${PHASE_FIRMWAREFUNC_EXIT}"
                ;;
            "${PHASE_FIRMWAREFUNC_EXIT}")
                break;
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}
