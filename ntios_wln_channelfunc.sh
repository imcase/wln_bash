#!/bin/bash
#---FUNCTIONS
AutoSelectChannel_2GHZ() {
    #Input args
    local broadcastdata_arrstring=${1}
    local scanneddata_arrstring=${2}

    #Define variables
    local scanneddata_chan_sigperc_arr="${WLN_EMPTYSTRING}"
    local scanneddata_chan_sigperc_arrstring="${WLN_EMPTYSTRING}"
    local chanchoosen="${WLN_EMPTYSTRING}"
    local chanchoosen_final="${WLN_EMPTYSTRING}"
    local chanchoosen_sigpercmean_arr="${WLN_EMPTYSTRING}"
    local chanchoosen_sigpercmean_sort_arr="${WLN_EMPTYSTRING}"

    local chan_lbound=0
    local chan_ubound=0
    local sig_lbound_perc=0
    local sig_ubound_perc=0
    local sigmean=0

    local channel_isfound=false

    local inext=0
    local j=0

    #Get a list of broadcast channels and their signal-strength (%) respectively.
    scanneddata_chan_sigperc_arrstring=$(GetSortUniqScannedChannelSignal "${PL_WLN_PHY_MODE_2G}" "${PL_WLN_SIGNALTYPE_PERC}" "${scanneddata_arrstring}")
    scanneddata_chan_sigperc_arr=( $(echo "${scanneddata_chan_sigperc_arrstring}") )

    #Loop thru array.
    #Handle each channel-pair (chan_lbound-chan_ubound).
    for i in "${!scanneddata_chan_sigperc_arr[@]}"
    do
        #Get lowerbound channel
        chan_lbound=$( echo "${scanneddata_chan_sigperc_arr[i]}" | cut -d"," -f1)
        #Get lowerbound signal-strength percentage
        sig_lbound_perc=$( echo "${scanneddata_chan_sigperc_arr[i]}" | cut -d"," -f2)

        #Get the next index 'inext'
        inext=$(( i + 1 ))

        #Get upperbound channel
        chan_ubound=$( echo "${scanneddata_chan_sigperc_arr[inext]}" | cut -d"," -f1)
        sig_ubound_perc=$( echo "${scanneddata_chan_sigperc_arr[inext]}" | cut -d"," -f2)

        #Exit loop if 'inext' has reached the end of array-length
        if [[ ${inext} -eq ${#scanneddata_chan_sigperc_arr[@]} ]]; then
            break
        fi

        #Get the choosen channel
        chanchoosen=$( AutoSelectChannelPerPair_2GHZ "${chan_lbound}" "${chan_ubound}" "${sig_lbound_perc}" "${sig_ubound_perc}" )
        #Calculate channel-pair's mean-signal
        sigmean=$(( (sig_lbound_perc + sig_ubound_perc)/2 ))

        #Add 'sigmean' and 'chanchoosen' to array
        #Remark:
        #   It is important to place 'signmean' in the first column...
        #   ...because later on we will sort based on 'sigmean'.
        chanchoosen_sigpercmean_arr[j]="${sigmean},${chanchoosen}"

        #Increment index 'j'
        ((j++))
    done

    #Sort the column 1
    readarray -t chanchoosen_sigpercmean_sort_arr < <( printf "%s\n" "${chanchoosen_sigpercmean_arr[@]}" | sort -t"," -k1,1n)

    #Get the channel with the lowest 'sigmean'
    #Remark:
    #   In other words, take the first array-element.
    for i in "${!scanneddata_chan_sigperc_arr[@]}"
    do
        #Retrieve the 'chanchoosen' without 'signmean'
        chanchoosen_final=$( echo "${chanchoosen_sigpercmean_sort_arr[0]}" | cut -d"," -f2)

        #Check if 'channel' is found in 'broadcastdata_arrstring'
        channel_isfound=$(CheckIFChannelIsWithinRange "${chanchoosen_final}" "${broadcastdata_arrstring}")
        if [[ "${channel_isfound}" == false ]]; then  #is NOT found
            break
        fi
    done

    #Output
    echo "${chanchoosen_final}"

    return 0;

}

AutoSelectChannelPerPair_2GHZ() {
    #----------------------------------------------------------------
    #Explanation:
    #
    #Step 1: Calculate: sigperc_diff and chanmean
    #
    #   sig_lbound_perc                          sig_ubound_perc
    #       |<-------------sigperc_diff -------------->|
    #       |                                          |
    #       |--------------------|---------------------|
    #   chan_lbound      chanmean       chan_ubound
    #
    #
    #Step 2: Calculate chanperc_diff using the 'sin^3' formula
    #
    #               chanperc_diff
    #                      ^
    #                      |
    #                      |           ++ 100
    #                      |         +
    #                      |       +
    #                      |      +
    #                      |     +
    #                      |    +
    #                      |+++
    #    ----|-------------/-------------|---------> sigperc_diff    
    #      -100        +++ |0           100
    #                +     | 
    #               +      | 
    #              +       | 
    #             +        |
    #           +          |
    #  -100  ++            |
    #                      |
    #                      0
    #
    #   Remark:
    #       If sigperc_diff < 0 ---> chanperc_diff < 0 ---> chanchoosen < chanmean (more shifted towards chan_lbound)
    #       If sigperc_diff > 0 ---> chanperc_diff > 0 ---> chanchoosen > chanmean more shifted towards chan_ubound)
    #
    #
    #Step3: Calculate: chanshift = (chanmean * chanperc_diff)/100
    #
    #
    #Step 4: Calculate: chanchoosen = chanmean + chanshift
    #----------------------------------------------------------------
    #Input args
    #Remark:
    #   both input arguments are values in percentage.
    local chan_lbound=${1}
    local chan_ubound=${2}
    local sig_lbound_perc=${3}
    local sig_ubound_perc=${4}

    #Define variables
    local chanchoosen=0
    local chanchoosen_float=0
    local chanmean=0
    local chanshift=0
    local chanperc_diff=0
    local sigperc_diff=0

    #Step1: Calculate: 'sigperc_diff' and 'chanmean'
    #   Remark:
    #       Notice that 'sigperc_diff' is always calculated by 
    #       ...SUBSTRACTING 'sig_lbound_perc (lowbound)' from 'sig_ubound_perc (upperbound)'
    sigperc_diff=$(( sig_lbound_perc - sig_ubound_perc ))
    chanmean=$(( (chan_lbound + chan_ubound)/2 ))
    #Step2: Calculate the 'chanperc_diff'
    chanperc_diff=$(awk -v"param1=${sigperc_diff}" -v"param2=${WLN_PI}" 'BEGIN{printf ( 100*( sin((param1*param2)/200) )^3 )}')
    #Step3: Calculate the 'chanchoosen'
    chanshift=$(awk -v"param1=${chanmean}" -v"param2=${chanperc_diff}" 'BEGIN{printf ( (param1 * param2)/100 )}')
    #Step4: Calculate the 'chanchoosen'
    chanchoosen_float=$(awk -v"param1=${chanmean}" -v"param2=${chanshift}" 'BEGIN{printf ( param1 + param2 )}')
    #Step5: Convert float to number
    chanchoosen=$(printf %.0f $chanchoosen_float)

    #Output
    echo "${chanchoosen}"

    return 0;
}

AutoSelectChannel_5GHZ() {
    #Input args
    local broadcastdata_arrstring=${1}
    local scanneddata_arrstring=${2}

    #Define variables
    local broadcastdata_arr="${WLN_EMPTYSTRING}"
    local broadcastdata_channel="${WLN_EMPTYSTRING}"
    local chanchoosen_final="${WLN_EMPTYSTRING}"
    local scanneddata_chan_arr="${WLN_EMPTYSTRING}"
    local scanneddata_chan_sigperc_arr="${WLN_EMPTYSTRING}"
    local scanneddata_chan_sigperc_arrstring="${WLN_EMPTYSTRING}"

    local channel_isfound=false

    #Get a list of broadcast channels and their signal-strength (%) respectively.
    scanneddata_chan_sigperc_arrstring=$(GetSortUniqScannedChannelSignal "${PL_WLN_PHY_MODE_5G}" "${PL_WLN_SIGNALTYPE_PERC}" "${scanneddata_arrstring}")

    #Convert array-string to array
    broadcastdata_arr=( $(echo "${broadcastdata_arrstring}") )
    scanneddata_chan_sigperc_arr=( $(echo "${scanneddata_chan_sigperc_arrstring}") )

    #Filter-out signal-strength
    for i in "${!scanneddata_chan_sigperc_arr[@]}"
    do
        scanneddata_chan_arr[i]=$(echo "${scanneddata_chan_sigperc_arr[i]}" | cut -d"," -f1 )
    done

    #Compare 'broadcastdata_arr' with 'scanneddata_chan_arr'...
    #...and find any channel that does not match.
    for i in "${!broadcastdata_arr[@]}"
    do
        #Get channel
        broadcastdata_channel="${broadcastdata_arr[i]}"

        #Check if 'broadcastdata_channel' is found in array 'scanneddata_chan_arr'
        channel_isfound=$(CheckIFChannelIsWithinRange "${broadcastdata_channel}" "${scanneddata_chan_arr}")
        if [[ "${channel_isfound}" == false ]]; then  #is NOT found
            chanchoosen_final="${broadcastdata_channel}"

            break
        fi        
    done 

    #Check if 'chanchoosen_final' is an Empty String.
    #If true, then get the FIRST array-element of array 'scanneddata_chan_arr'
    if [[ -z "${chanchoosen_final}" ]]; then
         chanchoosen_final="${scanneddata_chan_arr[0]}"
    fi

    #Output
    echo "${chanchoosen_final}"

    return 0;
}

CheckIFChannelIsWithinRange() {
    #Input args
    local channel=${1}
    local broadcastdata=${2}    #could be an array-string or array

    #Define variables
    local channel_isfound="${WLN_EMPTYSTRING}"

    #Check if 'channel' is found in 'broadcastdata'
    channel_isfound=$( printf "${broadcastdata[@]}\n" | grep -w "${channel}" )
    if [[ -n "${channel_isfound}" ]]; then  #is found
        echo true
    else
        echo false
    fi

    return 0;
}

GetBroadcastChannels() {
    #Input args
    local wln_phy_mode=${1}

    #Check if 'wln_phy_mode = PL_WLN_PHY_MODE_NULL'
    if [[ "${wln_phy_mode}" == "${PL_WLN_PHY_MODE_NULL}" ]]; then
        echo "${WLN_EMPTYSTRING}"

        return 0;
    fi

    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local cmd2="${WLN_EMPTYSTRING}"
    local cmd3="${WLN_EMPTYSTRING}"
    local ret="${WLN_EMPTYSTRING}"

    #Generate command based on the specified 'wln_phy_mode'
    cmd="sudo iw list"

    case "${wln_phy_mode}" in
        "${PL_WLN_PHY_MODE_2G_LEGACY}")
            cmd2="grep -o \"\\* 2.*\""
            cmd3="grep -v \"disabled\""
            ;;
        "${PL_WLN_PHY_MODE_2G}")
            cmd2="grep -o \"\\* 2.*\""
            cmd3="grep -v \"disabled\""
            ;;
        "${PL_WLN_PHY_MODE_5G}")
            cmd2="grep -o \"\\* 5.*\""
            cmd3="grep -v \"radar\" | grep -v \"no IR\""
            ;;
    esac

    cmd+=" | ${cmd2}"
    cmd+=" | grep -o \"\\[.*\""
    cmd+=" | ${cmd3}"
    cmd+=" |  awk '{print \$1}' | cut -d\"[\" -f2- | cut -d\"]\" -f1"

    #Execute command
    readarray -t ret < <(eval "${cmd}")

    #Output
    #--------------------------------------------------------------------
    #Remark:
    #   There is a difference between 'echo ${ret}' and 'echo "${ret}"'
    #   1. echo ${ret} -> shows the result as a string:
    #       1 2 3 4 5
    #   2. echo "${ret}" -> show the result as an 1D-array:
    #       1
    #       2
    #       3
    #       4
    #       5
    #--------------------------------------------------------------------
    echo "${ret[@]}"

    return 0;
}

GetScannedWifiData() {
    #Define variables
    local cmd="${WLN_EMPTYSTRING}"
    local filtered_arr="${WLN_EMPTYSTRING}"
    local filtered_arritem="${WLN_EMPTYSTRING}"
    local rawdata_arr="${WLN_EMPTYSTRING}"
    local rawdata_arritem="${WLN_EMPTYSTRING}"
    local rawdata_arrnextitem="${WLN_EMPTYSTRING}"
    local sortuniq_arr="${WLN_EMPTYSTRING}"
    local signalval="${WLN_EMPTYSTRING}"
    local ssidval="${WLN_EMPTYSTRING}"
    local channelval="${WLN_EMPTYSTRING}"

    local pattern1_isfound="${WLN_EMPTYSTRING}"
    local pattern2_isfound="${WLN_EMPTYSTRING}"
    local pattern3_isfound="${WLN_EMPTYSTRING}"
    local pattern3_arrnextitem_isfound="${WLN_EMPTYSTRING}"

    local i=0
    local inext=0
    local j=0
    local r=0

    #Generate command
    #Get the SSID, channels and dbm from other devices
    #Remark:
    #   Maximum number of retries is '3'
    while [[ ${r} -lt ${WLN_IW_RETRY_MAX} ]]
    do
        #Get the data
        readarray -t rawdata_arr < <(sudo iw wlan0 scan | grep -o "${WLN_IW_PATTERN_SIGNAL}.*\|${WLN_IW_PATTERN_SSID}.*\|${WLN_IW_PATTERN_SETCHANNEL}.*")

        #Check if 'rawdata_arr' is NOT an Empty String
        if [[ -n "${rawdata_arr}" ]]; then
            break
        fi

        #Wait for 1 second
        sleep 1

        #Increment index
        r=$(( r + 1 ))
    done
    

    #Rearrange and filter-out non-essential strings within data
    for i in "${!rawdata_arr[@]}";
    do
        #Update 'rawdata_arritem'
        rawdata_arritem="${rawdata_arr[i]}"

        #Check all three patterns
        pattern1_isfound=$(echo "${rawdata_arritem}" | grep "${WLN_IW_PATTERN_SIGNAL}")
        pattern2_isfound=$(echo "${rawdata_arritem}" | grep "${WLN_IW_PATTERN_SSID}")
        pattern3_isfound=$(echo "${rawdata_arritem}" | grep "${WLN_IW_PATTERN_SETCHANNEL}")

        #Add signal-value
        if [[ -n "${pattern1_isfound}" ]]; then
            #Retrieve 'signalval' from 'rawdata_arritem'
            signalval=$(echo "${rawdata_arritem}" | grep -o "${WLN_IW_PATTERN_SIGNAL}.*" | cut -d" " -f2- | cut -d" " -f1)
        fi

        #Prepend SSID-value
        if [[ -n "${pattern2_isfound}" ]]; then
            #Retrieve 'ssidval' from 'rawdata_arritem'
            ssidval=$(echo "${rawdata_arritem}" | grep -o "${WLN_IW_PATTERN_SSID}.*" | cut -d" " -f2)

            #Check if 'ssidval = <Empty String>'
            if [[ -z "${ssidval}" ]]; then
                ssidval="${WLN_HIDDEN}"
            fi

            #-----------------------------------------
            #Peek the next array-item of 'rawdata_arr'
            #-----------------------------------------
            inext=$(( i + 1 ))
            rawdata_arrnextitem=${rawdata_arr[inext]}

            #Check if 'WLN_IW_PATTERN_SETCHANNEL' is found
            pattern3_arrnextitem_isfound=$(echo "${rawdata_arrnextitem}" | grep "${WLN_IW_PATTERN_SETCHANNEL}")
            #Update 'channelval'
            if [[ -z "${pattern3_arrnextitem_isfound}" ]]; then #WLN_IW_PATTERN_SETCHANNEL not found
                channelval="${WLN_WIFI_CHANNEL_NULL}"
            fi
            #-----------------------------------------           
        fi

        #Retrieve 'channelval' from 'rawdata_arritem'
        if [[ -n "${pattern3_isfound}" ]]; then
            channelval=$(echo "${rawdata_arritem}" | grep -o "${WLN_IW_PATTERN_SETCHANNEL}.*" | cut -d" " -f3)
        fi

        #Check if all data have been retrieved for the current 'ssidval'
        if [[ -n "${signalval}" ]] && [[ -n "${ssidval}" ]] && [[ -n "${channelval}" ]]; then
            #Update 'filtered_arr'
            filtered_arr[j]="${ssidval},${channelval},${signalval}"

            #Reset all the three parameters
            signalval="${WLN_EMPTYSTRING}"
            ssidval="${WLN_EMPTYSTRING}"
            channelval="${WLN_EMPTYSTRING}"

            #Increment index 'j'
            ((j++))
        fi
    done

    #Sort and Uniq
    readarray -t sortuniq_arr < <( printf "%s\n" "${filtered_arr[@]}" | sort -u )

    #Output
    echo "${sortuniq_arr[@]}"

    return 0;
}

GetSortUniqScannedChannelSignal() {
    #Input args
    local wln_phy_mode=${1}
    local sigtype=${2}
    local scanneddata_arrstring=${3}

    #Define variables
    local channel_rssi_arr="${WLN_EMPTYSTRING}"
    local channel_rssi_sort_uniq_arr="${WLN_EMPTYSTRING}"
    local scanneddata_arr="${WLN_EMPTYSTRING}"

    local channel=0
    local sig=0
    local sigstrength=0

    #Check if 'wln_phy_mode = PL_WLN_PHY_MODE_NULL'
    if [[ "${wln_phy_mode}" == "${PL_WLN_PHY_MODE_NULL}" ]]; then
        echo "${WLN_EMPTYSTRING}"

        return 0;
    fi

    #Convert string to array
    scanneddata_arr=( $(echo "${scanneddata_arrstring}") )

    #Check if 'ssi_channel_sig_arrstring' is an Empty String
    if [[ -z "${scanneddata_arr[@]}" ]]; then
        if [[ "${wln_phy_mode}" == "${PL_WLN_PHY_MODE_5G}" ]]; then #is 5.2Ghz
            channel=${WLN_WIFI_CHANNEL_5G_DEFAULT}
        else
            channel=${WLN_WIFI_CHANNEL_2G_DEFAULT}
        fi

        return 0;
    fi
    
    #Loop thru all array-elements
    for i in "${!scanneddata_arr[@]}"
    do
        #Get channel
        channel=$(echo "${scanneddata_arr[i]}" | cut -d"," -f2)
        #Get 'sig'
        sig=$(echo "${scanneddata_arr[i]}" | cut -d"," -f3)
        #Get the signal-strength (RSSI or percentage) value
        sigstrength=$(SignalStrengthCalc "${sig}" "${sigtype}")

        #Check if channel is valid (channel cannot be 255)
        if [[ ${channel} -ne ${WLN_WIFI_CHANNEL_NULL} ]]; then
            if [[ "${wln_phy_mode}" == "${PL_WLN_PHY_MODE_5G}" ]]; then #is 5.2Ghz
                if [[ ${channel} -gt ${WLN_WIFI_CHANNEL_5G_LOWERBOUND} ]]; then
                    channel_rssi_arr[i]="${channel},${sigstrength}"
                fi
            else    #is 2.4Ghz
                                if [[ ${channel} -le ${WLN_WIFI_CHANNEL_2G_UPPERBOUND} ]]; then
                    channel_rssi_arr[i]="${channel},${sigstrength}"
                fi
            fi
        fi
    done

    #Sort
    #1. field which are delimited by a comma (-t ",")
    #2. start with field 1: sort numeric ascending (-k1,1n)
    #3. then field 2: sort numeric desecending (k2,2nr)
    #4. lastly, take unique values based on field 1 (awk -F"," '!_[$1]++')
    #Explanation awk:
    #   -F sets the field separator.
    #   $1 is the first field.
    #   _[val] looks up val in the hash _(a regular variable).
    #   ++ increment, and return old value.
    #   ! returns logical not.
    readarray -t channel_rssi_sort_uniq_arr < <( printf "%s\n" "${channel_rssi_arr[@]}" | sort -t"," -k1,1n -k2,2nr | awk -F"," '!_[$1]++')

    #Output
    echo "${channel_rssi_sort_uniq_arr[@]}"

    return 0;
}

SignalStrengthCalc() {
    #Input args
    local sigfloat=${1} #must be the absolute value (thus without minus)
    local sigtype=${2}

    #Define variables
    local rate=0
    local rssi=0
    local rssi_float=0
    local rssi_base=0
    local sig=0
    local sigmax=0
    local sigrange=0

    #Convert float to rounded number
    sig=$(printf %.0f ${sigfloat})

    #Check if 'sig' is valid
    if [[ ${sig} -eq 0 ]]; then
        echo "${rssi}"

        return 0
    fi

    if [[ ${sig} -lt ${WLN_WIFI_SIGNAL_DBM_MIN} ]]; then
        echo "${rssi}"

        return 0
    fi

    #Check if '-30 < sig < 0'
    if [[ ${sig} -gt ${WLN_WIFI_SIGNAL_DBM_MAX} ]]; then
        sig="${WLN_WIFI_SIGNAL_DBM_MAX}"
    fi

    sigmax=${WLN_WIFI_SIGNAL_RSSI_MAX}
    if [[ "${sigtype}" == "${PL_WLN_SIGNALTYPE_PERC}" ]]; then
        sigmax=${WLN_WIFI_SIGNAL_PERC_MAX}
    fi

    #Determine the 'sigrange', 'rate' and 'rssi_base'
    sigrange=$(awk -v"param1=${WLN_WIFI_SIGNAL_DBM_MAX}" -v"param2=${WLN_WIFI_SIGNAL_DBM_MIN}" 'BEGIN{printf param1 - param2}')
    rate=$(awk -v"param1=${sigmax}" -v"param2=${sigrange}" 'BEGIN{printf param1 / param2}')
    rssi_base=$(awk -v"param1=${sigmax}" -v"param2=${sigrange}" 'BEGIN{printf (param1*100) / param2}')

    #Calculate the 'rssi_float':
    #   rssi_float = sig*rage + rssi_base
    rssi_float=$(awk -v"param1=${sig}" -v"param2=${rate}" -v"param3=${rssi_base}" 'BEGIN{printf (param1*param2) + param3}')

    #Calculate the 'rssi'
    rssi=$(printf %.0f $rssi_float)

    #Output
    echo "${rssi}"

    return 0;
}

Channel_AutoSelect() {
    #Input args
    local channel=${1}
    local wln_phy_mode=${2}

    #Define variables
    local broadcastdata_arrstring="${WLN_EMPTYSTRING}"
    local scanneddata_arrstring="${WLN_EMPTYSTRING}"

    local channelchosen_final=0

    local channel_isfound=false

    #Retrieve available channels
    #as string
    broadcastdata_arrstring=$(GetBroadcastChannels "${wln_phy_mode}")

    #Check if 'channel' is found in 'broadcastdata_arrstring'
    channel_isfound=$(CheckIFChannelIsWithinRange "${channel}" "${broadcastdata_arrstring}")
    if [[ "${channel_isfound}" == true ]]; then  #is found
        echo "${channel}"

        return 0;
    fi

    #Get a list of broadcasted SSID, channels and their signal-strength (dbm) respectively.
    scanneddata_arrstring=$(GetScannedWifiData)

    #Select the a channel with the least interference
    if [[ "${wln_phy_mode}" == "${PL_WLN_PHY_MODE_5G}" ]]; then #is 5.2Ghz
        channelchosen_final=$(AutoSelectChannel_5GHZ "${broadcastdata_arrstring}" "${scanneddata_arrstring}")
    else    #is 2.4Ghz
        channelchosen_final=$(AutoSelectChannel_2GHZ "${broadcastdata_arrstring}" "${scanneddata_arrstring}")
    fi

    #Output
    echo "$channelchosen_final"

    return 0;
}

Channel_Validate_And_Update_Database() {
    #Retrieve channel from initial database
    local ischannel_retrieved=${1}
    local isphymode_retrieved=${2}
    local intfstates_ctx_fpath=${3}

    #Validate channel
    local ret=$(Channel_AutoSelect "${ischannel_retrieved}" "${isphymode_retrieved}")

    #Write data to file
    WLN_intfstates_ctx_writedata "${intfstates_ctx_fpath}" "WLN_intfstates_ctx__channel" "${ret}"

    #output
    echo "${ret}"

    return 0;
}