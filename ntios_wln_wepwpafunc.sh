#!/bin.bash
#---FUNCTIONS
WLN_setwep() {
    #Input args
    #--------------------------------------------------------------------
    #   Regarding 'wepkey':
    #   - if too LONG then the excessive digits will be truncated.
    #   - if too SHORT then the missing digits will be padded with zeros.
    #   Regarding 'wepmode':
    #   - if PL_WLN_WEP_MODE_DISABLED, then set:
    #       wepmode = PL_WLN_WEP_MODE_DISABLED
    #       wepkey = WLN_EMPTYSTRING
    #   - if NOT PL_WLN_WEP_MODE_DISABLED, then set:
    #       wpamode = PL_WLN_WPA_DISABLED
    #       wpakey = WLN_EMPTYSTRING
    #--------------------------------------------------------------------
    local wepkey=${1}
    local wepmode=${2}

    #Define constants
    local PHASE_WEPWPAFUNC_INTFSTATE_CHECK=0
    local PHASE_WEPWPAFUNC_WEPMODE_CHECK=1
    local PHASE_WEPWPAFUNC_WEPKEY_CHECK=2
    local PHASE_WEPWPAFUNC_WEPKEY_VALIDATE=3
    local PHASE_WEPWPAFUNC_PASS=4
    local PHASE_WEPWPAFUNC_EXIT=5
    local PRINTMSG_SETWEP_VALIDATING="${WLN_PRINTMSG_STATUS}: ${WLN_PRINTMSG_SETWEP}: ${WLN_PRINTMSG_VALIDATING} "
    local PRINTMSG_SETWEP_RESULT_ACCEPTED="${WLN_PRINTMSG_STATUS}: ${WLN_PRINTMSG_SETWEP}: ${WLN_PRINTMSG_ACCEPTED}"
    local PRINTMSG_SETWEP_RESULT_REJECTED="${WLN_PRINTMSG_STATUS}: ${WLN_PRINTMSG_SETWEP}: ${WLN_PRINTMSG_REJECTED}"


    #Define variables
    local phase="${PHASE_WEPWPAFUNC_INTFSTATE_CHECK}"
    local printmsg="${WLN_EMPTYSTRING}"
    local wepkey_maxlen=0
    local wepkey_output="${WLN_EMPTYSTRING}"
    local wpamode="${WLN_EMPTYSTRING}"
    local wpakey_output="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #(IMPORTANT) Update database with the input values
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wepkey" "${wepkey}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wepmode" "${wepmode}" 

    #Update print-message
    printmsg=${PRINTMSG_SETWEP_VALIDATING}

    #Print
    DebugPrint "${printmsg}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_WEPWPAFUNC_INTFSTATE_CHECK}")
                #Check if interface is enabled
                if [[ $(WLN_enabled) == "${NO}" ]]; then
                    #Update output-value
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_WEPWPAFUNC_EXIT}"
                else
                    #Update message
                    printmsg="${PRINTMSG_INTFSTATE_CHECK_DISABLED}"

                    #Goto next-phase
                    phase="${PHASE_WEPWPAFUNC_WEPMODE_CHECK}"
                fi
                ;;
            "${PHASE_WEPWPAFUNC_WEPMODE_CHECK}")
                #Check if 'wepmode' is Disabled or Not
                if [[ "${wepmode}" == "${PL_WLN_WEP_MODE_DISABLED}" ]]; then
                    #Unconditionally set 'wepkey = <Empty String>'
                    wepkey="${WLN_EMPTYSTRING}"

                    #Goto next-phase
                    phase="${PHASE_WEPWPAFUNC_WEPKEY_VALIDATE}"
                else
                    #Goto next-phase
                    phase="${PHASE_WEPWPAFUNC_WEPKEY_CHECK}"
                fi
                ;;
            "${PHASE_WEPWPAFUNC_WEPKEY_CHECK}")
                #If 'wpakey' is an Empty String, then 
                #...set 'wpakey = WLN_HOSTAPD_WEP_KEY128_DEFAULT'.
                if [[ "${wepkey}" == "${WLN_EMPTYSTRING}" ]]; then
                    if [[ "${wepmode}" == "${PL_WLN_WEP_MODE_64}" ]]; then
                         wepkey="${WLN_HOSTAPD_WEP_KEY64_DEFAULT}"
                    else
                        wepkey="${WLN_HOSTAPD_WEP_KEY128_DEFAULT}"
                    fi
                
                    phase="${PHASE_WEPWPAFUNC_WEPKEY_VALIDATE}"
                else
                    if [[ $(IsHex "${wepkey}") == false ]]; then
                        #Update output-value
                        ret="${REJECTED}"

                        #Goto next-phase
                        phase="${PHASE_WEPWPAFUNC_EXIT}"           
                    else
                        #Goto next-phase
                        phase="${PHASE_WEPWPAFUNC_WEPKEY_VALIDATE}"
                    fi
                fi
                ;;
            "${PHASE_WEPWPAFUNC_WEPKEY_VALIDATE}")
                #Take action based on the 'wepmode'
                case "${wepmode}" in
                    "${PL_WLN_WEP_MODE_DISABLED}")
                        wepkey_output=${wepkey}
                        ;;
                    *)
                        case "${wepmode}" in
                            "${PL_WLN_WEP_MODE_64}")
                                wepkey_maxlen="${WLN_WEPKEY64LEN_MAX}"
                                ;;
                            "${PL_WLN_WEP_MODE_128}")
                                 wepkey_maxlen="${WLN_WEPKEY128LEN_MAX}"
                                ;;
                        esac
        
                        #Disable WPA
                        wpamode="${PL_WLN_WPA_DISABLED}"
                        wpakey_output="${WLN_EMPTYSTRING}"
                        #Update database
                        #--------------------------------------------------------------------
                        #*BASH* IMPORTANT TO KNOW:
                        #   In bash updating a GLOBAL variable INSIDE a FUNCTION WHICH RETURNS...
                        #   ...an output is NOT possible!!!
                        #   On the other hand, if a function does NOT return an output, it is...
                        #   ...POSSIBLE to update a GLOBAL variable.
                        #
                        #*BASH8 WORKAROUND:
                        #   Write to file
                        #
                        #*C++* IMPORTANT TO KNOW:
                        #   In c++, when using an EXTERN variable, this variable can be updated...
                        #   ...even if it resides within a funcion which returns an output.
                        #--------------------------------------------------------------------
                        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpamode" "${PL_WLN_WPA_DISABLED}"
                        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpakey" "${WLN_EMPTYSTRING}"
                        WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__setwpa" "${ACCEPTED}"            

                        #Validate and return wepkey
                        wepkey_output=$(WepKeyLengthValidation "${wepkey}" "${wepkey_maxlen}")
                        ;;
                esac

                #Goto next-phase
                phase="${PHASE_WEPWPAFUNC_PASS}"
                ;;
            "${PHASE_WEPWPAFUNC_PASS}")
                #Update database
                #--------------------------------------------------------------------
                #*BASH* IMPORTANT TO KNOW:
                #   In bash updating a GLOBAL variable INSIDE a FUNCTION WHICH RETURNS...
                #   ...an output is NOT possible!!!
                #   On the other hand, if a function does NOT return an output, it is...
                #   ...POSSIBLE to update a GLOBAL variable.
                #
                #*BASH8 WORKAROUND:
                #   Write to file
                #
                #*C++* IMPORTANT TO KNOW:
                #   In c++, when using an EXTERN variable, this variable can be updated...
                #   ...even if it resides within a funcion which returns an output.
                #--------------------------------------------------------------------
                WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wepkey" "${wepkey_output}"
                WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wepmode" "${wepmode}"  

                #Update output-value
                ret="${ACCEPTED}"

                #Goto next-phase
                phase="${PHASE_WEPWPAFUNC_EXIT}"
                ;;
            "${PHASE_WEPWPAFUNC_EXIT}")
                break
                ;;
        esac
    done



    #Update database
    #--------------------------------------------------------------------
    #*BASH* IMPORTANT TO KNOW:
    #   In bash updating a GLOBAL variable INSIDE a FUNCTION WHICH RETURNS...
    #   ...an output is NOT possible!!!
    #   On the other hand, if a function does NOT return an output, it is...
    #   ...POSSIBLE to update a GLOBAL variable.
    #
    #*BASH8 WORKAROUND:
    #   Write to file
    #
    #*C++* IMPORTANT TO KNOW:
    #   In c++, when using an EXTERN variable, this variable can be updated...
    #   ...even if it resides within a funcion which returns an output.
    #--------------------------------------------------------------------
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__setwep" "${ret}"

    #Print
    if [[ "${ret}" == "${ACCEPTED}" ]]; then
        printmsg="${PRINTMSG_SETWEP_RESULT_ACCEPTED}"
    else
        printmsg="${PRINTMSG_SETWEP_RESULT_REJECTED}"
    fi

    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;
}
WepKeyLengthValidation() {
    #Input args
    local wepkey=${1}
    local wepkey_maxlen=${2}

    #Define variables
    local wepkey_len=0
    local wepkey_len_diff=0
    local wepkey_len_abs=0
    local ret=${WLN_EMPTYSTRING}

    #Get length
    wepkey_len=${#wepkey}
    wepkey_len_diff=$(( wepkey_len - wepkey_maxlen ))
    wepkey_len_abs=$(sed 's/-//g' <<< ${wepkey_len_diff})

    if [[ ${wepkey_len_diff} -lt 0 ]]; then
        ret=$(Append_Chars "${wepkey}" "${WLN_NUM_0}" "${wepkey_len_abs}")
    elif [[ ${wepkey_len} -gt ${wepkey_maxlen} ]]; then
        ret=$(Get_First_Nchar "${wepkey}" "${wepkey_maxlen}")
    else
        ret=${wepkey}
    fi

    #Output
    echo "${ret}"

    return 0;
}

WLN_setwpa() {
    #Input args
    #--------------------------------------------------------------------
    #   Regarding 'wpakey':
    #   - if too LONG then the excessive chars will be truncated.
    #   - if too SHORT then the missing chars will be padded with zeros.
    #   Regarding 'wepmode':
    #   - if PL_WLN_WPA_DISABLED, then set:
    #       wpamode = PL_WLN_WPA_DISABLED
    #       wpakey = WLN_EMPTYSTRING
    #   - if NOT PL_WLN_WPA_DISABLED, then set:
    #       wepmode = PL_WLN_WEP_MODE_DISABLED
    #       wepkey = WLN_EMPTYSTRING
    #--------------------------------------------------------------------
    local wpa_mode=${1}
    local algorithm=${2}
    local wpakey=${3}
    local cast=${4}

    #Define constants
    local PHASE_WEPWPAFUNC_INTFSTATE_CHECK=0
    local PHASE_WEPWPAFUNC_WPAKEY_CHECK=1
    local PHASE_WEPWPAFUNC_WPAKEY_VALIDATE=2
    local PHASE_WEPWPAFUNC_PASS=3
    local PHASE_WEPWPAFUNC_EXIT=4


    local PRINTMSG_SETWPA_VALIDATING="${WLN_PRINTMSG_STATUS}: ${WLN_PRINTMSG_SETWPA}: ${WLN_PRINTMSG_VALIDATING}" 
    local PRINTMSG_SETWPA_RESULT_ACCEPTED="${WLN_PRINTMSG_STATUS}: ${WLN_PRINTMSG_SETWPA}: ${WLN_PRINTMSG_ACCEPTED}"
    local PRINTMSG_SETWPA_RESULT_REJECTED="${WLN_PRINTMSG_STATUS}: ${WLN_PRINTMSG_SETWPA}: ${WLN_PRINTMSG_REJECTED}"

    #Define variables
    local phase="${PHASE_WEPWPAFUNC_INTFSTATE_CHECK}"
    local printmsg="${PHASE_WEPWPAFUNC_INTFSTATE_CHECK}"
    local wepkey_output="${WLN_EMPTYSTRING}"
    local wepmode="${WLN_EMPTYSTRING}"
    local wpakey_output="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #(IMPORTANT) Update database with the input values
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpamode" "${wpa_mode}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpakey" "${wpakey_output}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpaalgorithm" "${algorithm}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__cast" "${cast}"


    #Update print-message
    printmsg=${PRINTMSG_SETWPA_VALIDATING}

    #Print
    DebugPrint "${printmsg}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_WEPWPAFUNC_INTFSTATE_CHECK}")
                #Check if interface is enabled
                if [[ $(WLN_enabled) == "${NO}" ]]; then
                    #Update output-value
                    ret="${REJECTED}"

                    #Goto next-phase
                    phase="${PHASE_WEPWPAFUNC_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_WEPWPAFUNC_WPAKEY_CHECK}"
                fi
                ;;
            "${PHASE_WEPWPAFUNC_WPAKEY_CHECK}")
                # if [[ "${wpakey}" == "${WLN_EMPTYSTRING}" ]]; then
                #     #Update output-value
                #     ret="${REJECTED}"

                #     #Goto next-phase
                #     phase="${PHASE_WEPWPAFUNC_EXIT}"
                # else
                #     #Goto next-phase
                #     phase="${PHASE_WEPWPAFUNC_WPAKEY_VALIDATE}"
                # fi
                
                #If 'wpakey' is an Empty String, then 
                #...set 'wpakey = WLN_HOSTAPD_WPA_PASSPHRASE_DEFAULT'.
                if [[ "${wpakey}" == "${WLN_EMPTYSTRING}" ]]; then
                    wpakey="${WLN_HOSTAPD_WPA_PASSPHRASE_DEFAULT}"
                fi
                phase="${PHASE_WEPWPAFUNC_WPAKEY_VALIDATE}"
                ;;
            "${PHASE_WEPWPAFUNC_WPAKEY_VALIDATE}")
                #Check if 'wpa_mode' is Disabled or Not
                if [[ "${wpa_mode}" == "${PL_WLN_WPA_DISABLED}" ]]; then
                    #Unconditionally set 'wepkey = <Empty String>'
                    wpakey_output="${WLN_EMPTYSTRING}"
                else
                    #Check if 'wpakey' is (8..63) in length
                    wpakey_output=$(WpaKeyLengthValidation "${wpakey}")

                    #Disable WPA
                    #Update database
                    #--------------------------------------------------------------------
                    #*BASH* IMPORTANT TO KNOW:
                    #   In bash updating a GLOBAL variable INSIDE a FUNCTION WHICH RETURNS...
                    #   ...an output is NOT possible!!!
                    #   On the other hand, if a function does NOT return an output, it is...
                    #   ...POSSIBLE to update a GLOBAL variable.
                    #
                    #*BASH8 WORKAROUND:
                    #   Write to file
                    #
                    #*C++* IMPORTANT TO KNOW:
                    #   In c++, when using an EXTERN variable, this variable can be updated...
                    #   ...even if it resides within a funcion which returns an output.
                    #--------------------------------------------------------------------
                    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wepkey" "${WLN_EMPTYSTRING}"
                    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wepmode" "${PL_WLN_WEP_MODE_DISABLED}"  
                    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__setwep" "${ACCEPTED}"
                fi

                #Goto next-phase
                phase="${PHASE_WEPWPAFUNC_PASS}"
                ;;
            "${PHASE_WEPWPAFUNC_PASS}")
                #Update output-value
                ret="${ACCEPTED}"

                #Update database
                #--------------------------------------------------------------------
                #*BASH* IMPORTANT TO KNOW:
                #   In bash updating a GLOBAL variable INSIDE a FUNCTION WHICH RETURNS...
                #   ...an output is NOT possible!!!
                #   On the other hand, if a function does NOT return an output, it is...
                #   ...POSSIBLE to update a GLOBAL variable.
                #
                #*BASH8 WORKAROUND:
                #   Write to file
                #
                #*C++* IMPORTANT TO KNOW:
                #   In c++, when using an EXTERN variable, this variable can be updated...
                #   ...even if it resides within a funcion which returns an output.
                #--------------------------------------------------------------------
                WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpamode" "${wpa_mode}"
                WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpakey" "${wpakey_output}"
                WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpaalgorithm" "${algorithm}"
                WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__cast" "${cast}"



                #Goto next-phase
                phase="${PHASE_WEPWPAFUNC_EXIT}"
                ;;
            "${PHASE_WEPWPAFUNC_EXIT}")
                break
                ;;
        esac
    done



    #Update database
    #--------------------------------------------------------------------
    #*BASH* IMPORTANT TO KNOW:
    #   In bash updating a GLOBAL variable INSIDE a FUNCTION WHICH RETURNS...
    #   ...an output is NOT possible!!!
    #   On the other hand, if a function does NOT return an output, it is...
    #   ...POSSIBLE to update a GLOBAL variable.
    #
    #*BASH8 WORKAROUND:
    #   Write to file
    #
    #*C++* IMPORTANT TO KNOW:
    #   In c++, when using an EXTERN variable, this variable can be updated...
    #   ...even if it resides within a funcion which returns an output.
    #--------------------------------------------------------------------
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__setwpa" "${ret}" 

    #Print
    if [[ "${ret}" == "${ACCEPTED}" ]]; then
        printmsg="${PRINTMSG_SETWPA_RESULT_ACCEPTED}"
    else
        printmsg="${PRINTMSG_SETWPA_RESULT_REJECTED}"
    fi

    DebugPrint "${printmsg}"

    #Output
    echo "${ret}"

    return 0;
}
WpaKeyLengthValidation() {
    #Input args
    local wpakey=${1}

    #Define variables
    local wpakey_len=0
    local wpakey_len_diff_min=0
    local wpakey_len_abs_min=0
    local ret=${WLN_EMPTYSTRING}

    #Get length
    wpakey_len=${#wpakey}
    wpakey_len_diff_min=$(( wpakey_len - WLN_WPAKEY_PHRASELEN_MIN ))
    wpakey_len_abs_min=$(sed 's/-//g' <<< ${wpakey_len_diff_min})

    if [[ ${wpakey_len} -lt ${WLN_WPAKEY_PHRASELEN_MIN} ]]; then
        ret=$(Append_Chars "${wpakey}" "${WLN_NUM_0}" "${wpakey_len_abs_min}")
    elif [[ ${wpakey_len} -gt ${WLN_WPAKEY_PHRASELEN_MAX} ]]; then
        ret=$(Get_First_Nchar "${wpakey}" "${WLN_WPAKEY_PHRASELEN_MAX}")
    else
        ret=${wpakey}
    fi

    #Output
    echo "${ret}"

    return 0;
}

WLN_Wep_Wpa_Validation() {
    #Define constants
    local PHASE_WEPWPAFUNC_WEP_WPA_PRECHECK=1
    local PHASE_WEPWPAFUNC_DATA_RETRIEVE=2
    local PHASE_WEPWPAFUNC_WEP_WPA_SET=3
    local PHASE_WEPWPAFUNC_WEP_WPA_POSTCHECK=4
    local PHASE_WEPWPAFUNC_EXIT=5

    #Define variables
    local phase="${PHASE_WEPWPAFUNC_WEP_WPA_PRECHECK}"
    local wepkey="${WLN_EMPTYSTRING}"
    local wepmode="${PL_WLN_WEP_MODE_DISABLED}"
    local wpaalgorithm="${PL_WLN_WPA_ALGORITHM_AES}"
    local wpacast="${PL_WLN_WPA_CAST_MULTICAST}"
    local wpakey="${WLN_EMPTYSTRING}"
    local wpamode="${PL_WLN_WPA_DISABLED}"

    local wepmode=${PL_WLN_WEP_MODE_DISABLED}
    local setwep_result=${REJECTED}
    local setwpa_result=${REJECTED}

    local ret="${REJECTED}"



    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_WEPWPAFUNC_WEP_WPA_PRECHECK}")
                #Get 'WLN_intfstates_ctx__setwep' and 'WLN_intfstates_ctx__setwpa' from database
                setwep_result=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__setwep")
                setwpa_result=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__setwpa")

                #Take action based on the retrieved values
                if [[ "${setwep_result}" == "${ACCEPTED}" ]] && \
                        [[ "${setwpa_result}" == "${ACCEPTED}" ]]; then
                    ret="${ACCEPTED}"

                    phase="${PHASE_WEPWPAFUNC_EXIT}"
                elif [[ "${setwep_result}" != "${REJECTED}" ]] && \
                        [[ "${setwpa_result}" != "${REJECTED}" ]]; then
                    #Remark:
                    #   The following combination could apply:
                    #       setwep_result = UNSET & setwpa_result= UNSET
                    #       setwep_result = ACCEPTED & setwpa_result= UNSET
                    #       setwep_result = UNSET & setwpa_result= ACCEPTED
                    phase="${PHASE_WEPWPAFUNC_DATA_RETRIEVE}"
                else
                    ret="${REJECTED}"

                    phase="${PHASE_WEPWPAFUNC_EXIT}"
                fi
                ;;
            "${PHASE_WEPWPAFUNC_DATA_RETRIEVE}")
                #Retrieve data from database
                wepkey=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wepkey")
                wepmode=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wepmode")
                wpaalgorithm=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpaalgorithm")
                wpakey=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpakey")
                wpamode=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpamode")
                
                phase="${PHASE_WEPWPAFUNC_WEP_WPA_SET}"
                ;;
            "${PHASE_WEPWPAFUNC_WEP_WPA_SET}")
                #Set WEP
                setwep_result=$(WLN_setwep "${wepkey}" "${wepmode}")

                #Set WPA
                setwpa_result=$(WLN_setwpa "${wpamode}" \
                        "${wpaalgorithm}" \
                        "${wpakey}" \
                        "${PL_WLN_WPA_CAST_MULTICAST}")
                
                phase="${PHASE_WEPWPAFUNC_WEP_WPA_POSTCHECK}"
                ;;
            "${PHASE_WEPWPAFUNC_WEP_WPA_POSTCHECK}")
                # #Get 'WLN_intfstates_ctx__setwep' and 'WLN_intfstates_ctx__setwpa' from database
                # setwep_result=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__setwep")
                # setwpa_result=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__setwpa")

                #Take action based on the retrieved values
                if [[ "${setwep_result}" == "${ACCEPTED}" ]] && \
                        [[ "${setwpa_result}" == "${ACCEPTED}" ]]; then
                    ret="${ACCEPTED}"
                else
                    ret="${REJECTED}"
                fi

                phase="${PHASE_WEPWPAFUNC_EXIT}"
                ;;
            "${PHASE_WEPWPAFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}
