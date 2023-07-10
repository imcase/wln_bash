#---FUNCTIONS
WLN_activescan() {
    #Input args
    local isssid=${1}

    #Define variables
    local ret="${REJECTED}"

    #Decide the action to be taken
    #1. scan for available SSIDs
    #2. scan the specified SSID and provide info
    if [[ -z "${isssid}" ]]; then
        ret=$(ActiveScan_For_Available_Ssids)
    else
        ret=$(ActiveScan_Specified_Ssid "${isssid}")
    fi

    #Output
    echo "${ret}"

    return 0
}
ActiveScan_For_Available_Ssids() {
    #Define constants
    local PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_SCANDATA_RETRIEVE=1
    local PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_SCANDATA_LENGTH=2
    local PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_UPDATE_OUTPUT=10
    local PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_EXIT=100

    #Define arrays & objects
    local ssid_list_arr=()
    local ssid_list_arritem="${WLN_EMPTYSTRING}"
    local ssid_list_arrlen=0

    #Define variables
    local phase="${PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_SCANDATA_RETRIEVE}"
    local iwscandata_ssid=${WLN_EMPTYSTRING}
    local r=0

    local ret="${REJECTED}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_SCANDATA_RETRIEVE}")
                #Write 'iw' scan result to array
                readarray -t ssid_list_arr < <( sudo iw dev wlan0 scan | grep -o "${WLN_PATTERN_SSID_COLONSPACE}.*" | cut -d" " -f2)

                phase="${PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_SCANDATA_LENGTH}"
                ;;
            "${PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_SCANDATA_LENGTH}")
                #Get array-length
                ssid_list_arrlen=${#ssid_list_arr[@]}

                if [[ ${ssid_list_arrlen} -eq 0 ]]; then
                    #Increment retry counter
                    ((r++))

                    if [[ ${r} -lt ${WLN_IW_RETRY_MAX} ]]; then
                        phase="${PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_SCANDATA_RETRIEVE}"
                    else
                        #Update 'ret'
                        ret="${REJECTED}"

                        phase="${PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_EXIT}"
                    fi
                else
                    phase="${PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_UPDATE_OUTPUT}"
                fi
                ;;
            "${PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_UPDATE_OUTPUT}")
                #Iterate thru each array-item
                for ssid_list_arritem in "${ssid_list_arr[@]}"
                do
                    #If 'ssid_list_arritem' is 'Empty String', then
                    #   change 'ssid_list_arritem' to '<HIDDEN>'
                    if [[ -z "${ssid_list_arritem}" ]]; then
                        ssid_list_arritem="${WLN_HIDDEN}"
                    fi

                    #Update 'iwscandata_ssid'
                    if [[ -z "${iwscandata_ssid}" ]]; then
                         iwscandata_ssid="${ssid_list_arritem}"
                    else
                        iwscandata_ssid="${iwscandata_ssid},${ssid_list_arritem}"
                    fi
                done

                #Update 'ret'
                ret="${ACCEPTED}"

                phase="${PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_EXIT}"
                ;;
            "${PHASE_ACTIVESCAN_FOR_AVAILABLE_SSIDS_EXIT}")
                break
                ;;
        esac
    done

    #Write to database
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultssid" "${iwscandata_ssid}"

    #Output
    echo "${ret}"

    return 0
}
ActiveScan_Specified_Ssid() {
    #Input args
    local isssid=${1}

    #Define constants
    local PHASE_ACTIVESCAN_SPECIFIED_SSID_SCANDATA_RETRIEVE=1
    local PHASE_ACTIVESCAN_SPECIFIED_SSID_SCANDATA_LENGTH=10
    local PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_SSID_LINEUM=20
    local PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_BSS_LINENUMS=30
    local PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_BSS_LINENUMRANGE=40
    local PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_DATA_WITHIN_LINENUMRANGE=50
    local PHASE_ACTIVESCAN_SPECIFIED_SSID_EXIT=100

    local J_CTR_MAX=5

    #Define arrays
    local iwscandata_arr=()
    local iwscandata_arrlen=0

    local iwscandata_bsslinenum_arr=()

    local iwscandata_ssidlinenum_arr=()
    local iwscandata_ssidlinenum_arrlen=0
    local iwscandata_ssidlinenum_string="${WLN_EMPTYSTRING}"
    local iwscandata_ssidlinenum=0

    #Define variables
    local phase="${PHASE_ACTIVESCAN_SPECIFIED_SSID_SCANDATA_RETRIEVE}"
    local iwscandata_bssid="${WLN_EMPTYSTRING}"
    local iwscandata_bssid_s="${WLN_EMPTYSTRING}"
    local iwscandata_bssmode="${WLN_EMPTYSTRING}"
    local iwscandata_bssmode_conv="${WLN_EMPTYSTRING}"
    local iwscandata_bssmode_s="${WLN_EMPTYSTRING}"
    local iwscandata_channel="${WLN_EMPTYSTRING}"
    local iwscandata_channel_s="${WLN_EMPTYSTRING}"
    local iwscandata_rssi="${WLN_EMPTYSTRING}"
    local iwscandata_rssi_conv="${WLN_EMPTYSTRING}"
    local iwscandata_rssi_s="${WLN_EMPTYSTRING}"
    local iwscandata_ssid="${WLN_EMPTYSTRING}"
    local iwscandata_ssid_s="${WLN_EMPTYSTRING}"
    local iwscandata_wpainfo="${WLN_EMPTYSTRING}"

    local iwscandata_bsslinenum_start=0
    local iwscandata_bsslinenum_end=0

    local i=0
    local j=0
    local j_ctr=0
    local j_start=0
    local j_end=0
    local r=0
    local s=0

    local ret="${REJECTED}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_ACTIVESCAN_SPECIFIED_SSID_SCANDATA_RETRIEVE}")
                #Write 'iw' scan result to array
                readarray -t iwscandata_arr < <( sudo iw dev wlan0 scan )

                phase="${PHASE_ACTIVESCAN_SPECIFIED_SSID_SCANDATA_LENGTH}"
                ;;
            "${PHASE_ACTIVESCAN_SPECIFIED_SSID_SCANDATA_LENGTH}")
                #Get array-length
                iwscandata_arrlen=${#iwscandata_arr[@]}

                phase="${PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_SSID_LINEUM}"
                ;;
            "${PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_SSID_LINEUM}")
                #Search for the SSID, retrieve its linenum(s), and put the result in string 'iwscandata_ssidlinenum_string'
                #   Note: it could happen that there are multiple SSIDs with the same name.
                #   grep -n "<pattern>": show any match with line-number containing keyword <pattern>
                #   grep -w "<pattern>$": show match ending with keyword <pattern>
                iwscandata_ssidlinenum_string=$(printf '%s\n' "${iwscandata_arr[@]}" | grep -n "${WLN_PATTERN_SSID_COLONSPACE}" | grep -w "${isssid}$" | cut -d":" -f1)

                #If 'iwscandata_ssidlinenum_string' is an <Empty String> then
                #...it means that no match was found.
                if [[ -z "${iwscandata_ssidlinenum_string}" ]]; then
                    #Increment retry counter
                    ((r++))

                    if [[ ${r} -lt ${WLN_IW_RETRY_MAX} ]]; then
                        phase="${PHASE_ACTIVESCAN_SPECIFIED_SSID_SCANDATA_RETRIEVE}"
                    else
                        #Update 'ret'
                        ret="${REJECTED}"

                        phase="${PHASE_ACTIVESCAN_SPECIFIED_SSID_EXIT}"
                    fi
                else
                    #Convert string to array
                    iwscandata_ssidlinenum_arr=(${iwscandata_ssidlinenum_string})

                    #Get the array-length
                    iwscandata_ssidlinenum_arrlen=${#iwscandata_ssidlinenum_arr}

                    phase="${PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_BSS_LINENUMS}"
                fi
                ;;
            "${PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_BSS_LINENUMS}")
                #Retrieve and write BSS (=MAC-address) with line-numbers to string
                iwscandata_bsslinenum_string=$(printf '%s\n' "${iwscandata_arr[@]}" | grep -on "^${WLN_PATTERN_BSS_SPACE}.*" | cut -d":" -f1)

                #Convert string to array
                iwscandata_bsslinenum_arr=(${iwscandata_bsslinenum_string})

                #Reset index
                s=0

                phase="${PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_BSS_LINENUMRANGE}"
                ;;
            "${PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_BSS_LINENUMRANGE}")
                #Get array-item value for index 's'
                iwscandata_ssidlinenum=${iwscandata_ssidlinenum_arr[s]}

                #Using 'iwscandata_bsslinenum_arr', determine the linenum-range
                #...to which 'iwscandata_ssidlinenum' belongs to.
                #Remark:
                #   a linenum-range starts with the linenumber of the 'BSS'
                #   ...and ends with the linenumber of the string BEFORE the next 'BSS'.
                for i in "${!iwscandata_bsslinenum_arr[@]}"
                do
                    #Get the start linenum
                    iwscandata_bsslinenum_start=${iwscandata_bsslinenum_arr[i]}
                    #Get the end linenum
                    iwscandata_bsslinenum_end=$((${iwscandata_bsslinenum_arr[i+1]} - 1))
                    #Check if 'iwscandata_bsslinenum_end => 0'
                    if [[ ${iwscandata_bsslinenum_end} -lt 0 ]]; then
                        iwscandata_bsslinenum_end=${iwscandata_arrlen}
                    fi

                    if [[ ${iwscandata_ssidlinenum} -gt ${iwscandata_bsslinenum_start} ]] && \
                            [[ ${iwscandata_ssidlinenum} -lt ${iwscandata_bsslinenum_end} ]]; then
                        #Get the start-index
                        j_start=$((iwscandata_bsslinenum_start - 1))

                        #Get the end-indx
                        j_end=$((iwscandata_bsslinenum_end - 1))

                        break
                    fi

                    #Decrement index
                    ((i--))
                done

                phase="${PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_DATA_WITHIN_LINENUMRANGE}"
                ;;
            "${PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_DATA_WITHIN_LINENUMRANGE}")
                #Check if 'j_end > 0'
                if [[ ${j_end} -gt 0 ]]; then
                    #Update index j
                    j=${j_start}

                    while [[ ${j} -le ${j_end} ]]
                    do
                        #Retrieve the BSSID
                        #Get the 'iwscandata_bssid_s' for the current 'iwscandata_ssidlinenum'
                        iwscandata_bssid_s=$(echo "${iwscandata_arr[j]}" | grep "^${WLN_PATTERN_BSS_SPACE}" | cut -d" " -f2 | cut -d"(" -f1)
                        if [[ -n "${iwscandata_bssid_s}" ]]; then
                            #Add/Append 'iwscandata_bssid_s' to 'iwscandata_bssid'
                            if [[ -z "${iwscandata_bssid}" ]]; then #add
                                iwscandata_bssid="${iwscandata_bssid_s}"
                            else    #append
                                iwscandata_bssid="${iwscandata_bssid},${iwscandata_bssid_s}"
                            fi

                            #Increment counter
                            ((j_ctr++))
                        fi

                        #Retrieve the BSSMODE
                        #Get the 'iwscandata_bssmode_s' for the current 'iwscandata_ssidlinenum'
                        iwscandata_bssmode_s=$(echo "${iwscandata_arr[j]}" | grep -o "${WLN_PATTERN_CAPABILITY_COLONSPACE}.*" | cut -d" " -f2 )
                        if [[ -n "${iwscandata_bssmode_s}" ]]; then
                            case "${iwscandata_bssmode_s}" in
                                "${WLN_PATTERN_ESS}")
                                    iwscandata_bssmode_conv="${PL_WLN_BSS_MODE_INFRASTRUCTURE}"
                                    ;;
                                "${WLN_PATTERN_IBSS}")
                                    iwscandata_bssmode_conv="${PL_WLN_BSS_MODE_ADHOC}"
                                    ;;
                                *)
                                    iwscandata_bssmode_conv="${PL_WLN_BSS_MODE_UNKNOWN}"
                                    ;;  
                            esac

                            #Add/Append 'iwscandata_bssmode_conv' to 'iwscandata_bssmode'
                            if [[ -z "${iwscandata_bssmode}" ]]; then #add
                                iwscandata_bssmode="${iwscandata_bssmode_conv}"
                            else    #append
                                iwscandata_bssmode="${iwscandata_bssmode},${iwscandata_bssmode_conv}"
                            fi

                            #Increment counter
                            ((j_ctr++))
                        fi

                        #Retrieve the RSSI
                        #Get the 'iwscandata_rssi_s' for the current 'iwscandata_ssidlinenum'
                        iwscandata_rssi_s=$(echo "${iwscandata_arr[j]}" | grep -o "signal.*" | cut -d" " -f2)
                        if [[ -n "${iwscandata_rssi_s}" ]]; then
                            #Convert to Signal Strength ranging from 0 to 255
                            iwscandata_rssi_conv=$(SignalStrengthCalc "${iwscandata_rssi_s}" "${PL_WLN_SIGNALTYPE_RSSI}")

                            #Add/Append 'iwscandata_rssi_conv' to 'iwscandata_rssi'
                            if [[ -z "${iwscandata_rssi}" ]]; then #add
                                iwscandata_rssi="${iwscandata_rssi_conv}"
                            else    #append
                                iwscandata_rssi="${iwscandata_rssi},${iwscandata_rssi_conv}"
                            fi

                            #Increment counter
                            ((j_ctr++))
                        fi

                        #Retrieve the SSID
                        #Get the 'iwscandata_ssid_s' for the current 'iwscandata_ssid'
                        iwscandata_ssid_s=$(echo "${iwscandata_arr[j]}" | grep -o "${WLN_PATTERN_SSID_COLONSPACE}.*" | cut -d" " -f2)
                        if [[ -n "${iwscandata_ssid_s}" ]]; then
                            #Add/Append 'iwscandata_channel_s' to 'iwscandata_channel'
                            if [[ -z "${iwscandata_ssid}" ]]; then #add
                                iwscandata_ssid="${iwscandata_ssid_s}"
                            else    #append
                                iwscandata_ssid="${iwscandata_ssid},${iwscandata_ssid_s}"
                            fi

                            #Increment counter
                            ((j_ctr++))
                        fi


                        #Retrieve the CHANNEL
                        #Get the 'iwscandata_channel_s' for the current 'iwscandata_ssidlinenum'
                        iwscandata_channel_s=$(echo "${iwscandata_arr[j]}" | grep -o "${WLN_PATTERN_DSPARAMETERSET_COLONSPACE}.*" | grep -o "${WLN_PATTERN_CHANNEL_SPACE}.*" | cut -d" " -f2)
                        if [[ -z "${iwscandata_channel_s}" ]]; then
                            iwscandata_channel_s=$(echo "${iwscandata_arr[j]}" | grep "${WLN_PATTERN_PRIMARY_CHANNEL_COLONSPACE}" | grep -o "${WLN_PATTERN_CHANNEL_COLONSPACE}.*" | cut -d" " -f2)
                        fi

                        if [[ -n "${iwscandata_channel_s}" ]]; then
                            #Add/Append 'iwscandata_channel_s' to 'iwscandata_channel'
                            if [[ -z "${iwscandata_channel}" ]]; then #add
                                iwscandata_channel="${iwscandata_channel_s}"
                            else    #append
                                iwscandata_channel="${iwscandata_channel},${iwscandata_channel_s}"
                            fi

                            #Increment counter
                            ((j_ctr++))
                        fi

                        #Check if 'j_ctr = J_CTR_MAX'
                        #If true, then all required data have been retrieved, break loop.
                        if [[ ${j_ctr} -eq ${J_CTR_MAX} ]]; then
                            break
                        fi

                        #Increment index
                        ((j++))
                    done
                fi

                #Increment index
                ((s++))

                if [[ ${s} -eq ${iwscandata_ssidlinenum_arrlen} ]]; then
                    #Update 'ret'
                    ret="${ACCEPTED}"

                    phase="${PHASE_ACTIVESCAN_SPECIFIED_SSID_EXIT}"
                else
                    #Reset index and counter
                    i=0
                    j=0
                    j_ctr=0
                    j_start=0
                    j_end=0
                    iwscandata_bsslinenum_start=0
                    iwscandata_bsslinenum_end=0

                    phase="${PHASE_ACTIVESCAN_SPECIFIED_SSID_GET_BSS_LINENUMRANGE}"
                fi
                ;;
            "${PHASE_ACTIVESCAN_SPECIFIED_SSID_EXIT}")
                break
                ;;
        esac
    done

    #Write to database
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultssid" "${iwscandata_ssid}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultbssid" "${iwscandata_bssid}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultbssmode" "${iwscandata_bssmode}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultchannel" "${iwscandata_channel}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultrssi" "${iwscandata_rssi}"
    WLN_intfstates_ctx_writedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultwpainfo" "${iwscandata_wpainfo}"

    #Output
    echo "${ret}"

    return 0
}
