#!/bin/bash
#---SUPPORT FUNCTIONS
IsConnected_To_Ssid() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local pattern="${WLN_EMPTYSTRING}"
    local pattern_isfound="${WLN_EMPTYSTRING}"
    local ret=false

    #Update 'pattern'
    pattern="${WLN_WPA_SUPPLICANT_DAEMON_SRV}:${WLN_WIFI_CONNECTED}"

    #Check if 'pattern' is found in '/etc/tibbo/log/wlan/wpa-wlan0.log'.
    pattern_isfound=$(sudo grep -F "${pattern}" ${WLN_WPA_WLAN0_LOG_FPATH})
    if [[ -n "${pattern_isfound}" ]]; then  #is found
        ret=true
    else
        ret=false
    fi

    #Output
    echo "${ret}"

    return 0;
}

Wpa_Supplicant_Conf_Generator() {
    #Input args
    local isssid=${1}
    local iswepmode=${2}
    local iswepkey=${3}
    local iswpamode=${4}
    local iswpakey=${5}
    local istargetfpath=${6}
    # local isssid_isvisible=${7}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Generate file-content
    filecontent="network={\n"
	filecontent+="    ssid=\"${isssid}\"\n"
    if [[ "${iswepmode}" != "${PL_WLN_WEP_MODE_DISABLED}" ]] && \
            [[ "${iswpamode}" == "${PL_WLN_WPA_DISABLED}" ]]; then  #wep
        filecontent+="    key_mgmt=NONE\n"
        filecontent+="    wep_key1=${iswepkey}\n"
        filecontent+="    wep_tx_keyidx=0\n"
    elif [[ "${iswpamode}" != "${PL_WLN_WPA_DISABLED}" ]] && \
            [[ "${iswepmode}" == "${PL_WLN_WEP_MODE_DISABLED}" ]]; then #wpa
        filecontent+="    key_mgmt=WPA-PSK\n"
        filecontent+="    psk=\"${iswpakey}\"\n"   
    else    #open network
        filecontent+="    key_mgmt=NONE\n"
    fi
    # if [[ "${isssid_isvisible}" == false ]]; then
        filecontent+="    scan_ssid=1\n"
    # fi
    filecontent+="}"

    #Check if file exist
    RemoveFile "${istargetfpath}"
    
    #Write to file
    if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;

}
Wpa_Supplicant_Daemon_Service_Generator() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Generate file-content
    filecontent="[Unit]\n"
    filecontent+="Description=enables/disables wpa_supplicant_daemon.service\n"
    filecontent+="Wants=network.target\n"
    filecontent+="After=network.target\n"
    filecontent+="\n"
    filecontent+="[Service]\n"
    filecontent+="Type=oneshot\n"
    filecontent+="#User MUST BE SET TO 'root'\n"
    filecontent+="User=root\n"
    filecontent+="RemainAfterExit=true\n"
    filecontent+="ExecStart=/usr/local/bin/wpa_supplicant_daemon.sh enable\n"
    filecontent+="ExecStartPost=/bin/systemctl enable wpa_supplicant_daemon.service\n"
    filecontent+="ExecStartPost=/bin/systemctl enable wpa_supplicant_netplan_daemon_kill.service\n"
    # filecontent+="ExecStartPost=/bin/systemctl start wpa_supplicant_netplan_daemon_kill.service\n"
    filecontent+="\n"
    filecontent+="ExecStop=/usr/local/bin/wpa_supplicant_daemon.sh disable\n"
    filecontent+="\n"
    filecontent+="[Install]\n"
    filecontent+="WantedBy=multi-user.target"

    #Check if file exist
    RemoveFile "${istargetfpath}"
    
    #Write to file
    if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}

Wpa_Supplicant_Daemon_Script_Generator() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Generate file-content
    filecontent="#!/bin/bash\n"
    filecontent+="#---INPUT ARGS\n"
    filecontent+="#Possible input values: enable | disable\n"
    filecontent+="action=\${1}\n"
    filecontent+="\n"
    filecontent+="#---THIS SCRIPT'S PID\n"
    filecontent+="mypid=\${BASHPID}\n"
    filecontent+="\n"
    filecontent+="#---COLORS CONSTANTS\n"
    filecontent+="NOCOLOR=\$'\\\e[0m'\n"
    filecontent+="FG_LIGHTRED=\$'\\\e[1;31m'\n"
    filecontent+="FG_ORANGE=\$'\\\e[30;38;5;209m'\n"
    filecontent+="FG_LIGHTBLUE=\$'\\\e[30;38;5;45m'\n"
    filecontent+="FG_LIGHTGREY=\$'\\\e[30;38;5;246m'\n"
    filecontent+="FG_LIGHTGREEN=\$'\\\e[30;38;5;71m'\n"
    filecontent+="FG_SOFLIGHTRED=\$'\\\e[30;38;5;131m'\n"
    filecontent+="FG_YELLOW=\$'\\\e[1;33m'\n"
    filecontent+="\n"
    filecontent+="#---ACTION/REACTION CONSTANTS\n"
    filecontent+="ACTIVE=\"${WLN_ACTIVE}\"\n"
    filecontent+="CONNECTED=\"${WLN_WIFI_CONNECTED}\"\n"
    filecontent+="FAILED_TO_CONNECT=\"${WLN_WIFI_FAILED_TO_CONNECT}\"\n"
    filecontent+="NOT_CONNECTED=\"${WLN_WIFI_NOT_CONNECTED}\"\n"
    filecontent+="DELETED=\"deleted\"\n"
    filecontent+="INSERTED=\"inserted\"\n"
    filecontent+="DISABLED=\"${WLN_DISABLED}\"\n"
    filecontent+="ENABLED=\"${WLN_ENABLED}\"\n"
    filecontent+="ENABLE=\"${WLN_ENABLE}\"\n"
    filecontent+="DISABLE=\"${WLN_DISABLE}\"\n"
    filecontent+="ISACTIVE=\"${WLN_ISACTIVE}\"\n"
    filecontent+="ISENABLED=\"${WLN_ISENABLED}\"\n"
    filecontent+="STATE_UP=\"${WLN_UP}\"\n"
    filecontent+="STATE_DOWN=\"${WLN_DOWN}\"\n"
    filecontent+="STATE_UNKNOWN=\"${WLN_UNKNOWN}\"\n"
    filecontent+="\n"
    filecontent+="#---COUNTER CONSTANTS\n"
    filecontent+="CONN_RETRY_MAX=${WLN_CONN_RETRY_MAX}\n"
    filecontent+="CONN_STATUS_CHECK_CTR_MAX=${WLN_CONN_STATUS_CHECK_CTR_MAX}\n"
    filecontent+="IPADDR_CTR_MAX=${WLN_IPADDR_CTR_MAX}\n"
    filecontent+="INTFSTATESET_RETRY_MAX=${WLN_INTFSTATESET_RETRY_MAX}\n"
    filecontent+="\n"
    filecontent+="#---ENVIRONMENT CONSTANTS\n"
    filecontent+="BR0=\"${WLN_BR0}\"\n"
    filecontent+="WLAN0=\"${WLN_WLAN0}\"\n"
    filecontent+="WPA_SUPPLICANT=\"${WLN_WPA_SUPPLICANT}\"\n"
    filecontent+="WPA_SUPPLICANT_SRV=\"${WLN_WPA_SUPPLICANT_SRV}\"\n"
    filecontent+="WPA_SUPPLICANT_DAEMON_SRV=\"${WLN_WPA_SUPPLICANT_DAEMON_SRV}\"\n"
    filecontent+="WPA_WLAN0_CONF=\"${WLN_WPA_WLAN0_CONF}\"\n"
    filecontent+="WPA_WLAN0_LOG=\"${WLN_WPA_WLAN0_LOG}\"\n"
    filecontent+="ETC_TIBBO_LOG_WLN_DIR=\"${WLN_ETC_TIBBO_LOG_WLN_DIR}\"\n"
    filecontent+="if [[ ! -d \"\${ETC_TIBBO_LOG_WLN_DIR}\" ]]; then\n"
    filecontent+="    mkdir -p \"\${ETC_TIBBO_LOG_WLN_DIR}\"\n"
    filecontent+="fi\n"
    filecontent+="ETC_TIBBO_NETPLAN_WLN_DIR=\"${WLN_ETC_TIBBO_NETPLAN_WLN_DIR}\"\n"
    filecontent+="if [[ ! -d \"\${ETC_TIBBO_NETPLAN_WLN_DIR}\" ]]; then\n"
    filecontent+="    mkdir -p \"\${ETC_TIBBO_NETPLAN_WLN_DIR}\"\n"
    filecontent+="fi\n"
    filecontent+="ETC_NETPLAN_DIR=\"${WLN_ETC_NETPLAN_DIR}\"\n"
    filecontent+="RUN_NETPLAN_DIR=\"${WLN_RUN_NETPLAN_DIR}\"\n"
    filecontent+="WLAN_YAML_FPATH=\"${WLN_WLAN_YAML_FPATH}\"\n"
    filecontent+="WPA_SUPPLICANT_CONF_FPATH=\"${WLN_WPA_SUPPLICANT_CONF_FPATH}\"\n"
    filecontent+="WPA_SUPPLICANT_EXEC_FPATH=\"${WLN_WPA_SUPPLICANT_EXEC_FPATH}\"\n"
    filecontent+="WPA_WLAN0_CONF_FPATH=\"${WLN_WPA_WLAN0_CONF_FPATH}\"\n"
    filecontent+="WPA_WLAN0_LOG_FPATH=\"${WLN_WPA_WLAN0_LOG_FPATH}\"\n"
    filecontent+="\n"
    filecontent+="#---PATTERN CONSTANTS\n"
    filecontent+="PATTERN_ACCESS_POINTS=\"${WPL_PATTERN_ACCESS_POINTS}\"\n"
    filecontent+="PATTERN_GLOBAL=\"${WLN_PATTERN_GLOBAL}\"\n"
    filecontent+="PATTERN_GREP=\"${WLN_PATTERN_GREP}\"\n"
    filecontent+="PATTERN_INET=\"${WLN_PATTERN_INET}\"\n"
    filecontent+="PATTERN_INET6=\"${WLN_PATTERN_INET6}\"\n"
    filecontent+="PATTERN_SSID=\"${WLN_PATTERN_SSID}\"\n"
    filecontent+="PATTERN_UP=\"${WLN_PATTERN_UP}\"\n"
    filecontent+="PATTERN_DOWN=\"${WLN_PATTERN_DOWN}\"\n"
    filecontent+="PATTERN_WLAN0_CLTR_EVENT_CONNECTED=\"${WLN_PATTERN_WLAN0_CLTR_EVENT_CONNECTED}\"\n"
    filecontent+="\n"
    filecontent+="#---PRINT CONSTANTS\n"
    filecontent+="PRINT_ASSIGNED_IPV4_ADDRESS=\"assigned ipv4 address\"\n"
    filecontent+="PRINT_ASSIGNED_IPV6_ADDRESS=\"assigned ipv6 address\"\n"
    filecontent+="PRINT_BRING_DOWN=\"bring \${FG_SOFLIGHTRED}down\${NOCOLOR}\"\n"
    filecontent+="PRINT_CONNECTED_TO=\"connected to\"\n"
    filecontent+="PRINT_DEL=\"\${FG_SOFLIGHTRED}del\${NOCOLOR}\"\n"
    filecontent+="PRINT_WRITE_TO=\"write to\"\n"
    filecontent+="\n"
    filecontent+="PRINT_DONE=\"\${FG_YELLOW}DONE\${NOCOLOR}\"\n"
    filecontent+="PRINT_FAILED=\"\${FG_SOFLIGHTRED}FAILED\${NOCOLOR}\"\n"
    filecontent+="PRINT_NOT_FOUND=\"\${FG_SOFLIGHTRED}<NOT FOUND>\${NOCOLOR}\"\n"
    filecontent+="PRINT_STATUS=\"\${FG_ORANGE}STATUS\${NOCOLOR}\"\n"
    filecontent+="PRINT_START=\"\${FG_LIGHTGREEN}start\${NOCOLOR}\"\n"
    filecontent+="PRINT_STOP=\"\${FG_SOFLIGHTRED}stop\${NOCOLOR}\"\n"
    filecontent+="PRINT_SUCCESSFUL=\"\${FG_LIGHTGREEN}SUCCESSFUL\${NOCOLOR}\"\n"
    filecontent+="\n"
    filecontent+="#---STRING CONSTANTS\n"
    filecontent+="EMPTYSTRING=\"${WLN_EMPTYSTRING}\"\n"
    filecontent+="COLON=\"${WLN_COLON}\"\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---VARIABLES\n"
    filecontent+="connection_isfully_established=false\n"
    filecontent+="netplan_apply_cmd=\"netplan apply\"\n"
    filecontent+="wifi_ip_flush_cmd=\"ip addr flush dev \${WLAN0}\"\n"
    filecontent+="wpa_supplicant_netplan_daemon_run_cmd=\"\${WPA_SUPPLICANT_EXEC_FPATH} -B -c \${WPA_WLAN0_CONF_FPATH} -f \${WPA_WLAN0_LOG_FPATH} -i\${WLAN0}\"\n"
    filecontent+="ret=false\n"
    filecontent+="ret_failed=false\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---SUPPORT FUNCTIONS\n"
    filecontent+="bridge_delif_and_print() {\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local printmsg=\"\"\n"
    filecontent+="    local linenum=0\n"
    filecontent+="    local nextlinenum=0\n"
    filecontent+="\n"
    filecontent+="    #Bring bridge interface down\n"
    filecontent+="    ip link set dev \${BR0} down\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_BRING_DOWN} \${FG_LIGHTGREY}\${BR0}\${NOCOLOR}: \${PRINT_DONE}\"\n"
    filecontent+="\n"
    filecontent+="    #Delete bridge interface\n"
    filecontent+="    ip link del \${BR0}\n"
    filecontent+="    #Print\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: \${PRINT_DEL} \${FG_LIGHTGREY}\${BR0}\${NOCOLOR}: \${PRINT_DONE}\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="CmdExec() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local iscmd=\${1}\n"
    filecontent+="\n"
    filecontent+="    #Kill all wpa_supplicant daemons\n"
    filecontent+="    \${iscmd}; pid=\$!; wait \${pid}; exitcode=\$?\n"
    filecontent+="\n"
    filecontent+="    #Print\n"
    filecontent+="    if [[ \${exitcode} -eq 0 ]]; then\n"
    filecontent+="        ret=true\n"
    filecontent+="\n"
    filecontent+="        echo -e \":-->\${PRINT_STATUS}: \${FG_LIGHTGREY}\${iscmd}\${NOCOLOR}: \${PRINT_DONE}\"\n"
    filecontent+="    else\n"
    filecontent+="        ret=false\n"
    filecontent+="\n"
    filecontent+="        echo -e \":-->\${PRINT_STATUS}: \${FG_LIGHTGREY}\${iscmd}\${NOCOLOR}: \${PRINT_FAILED}\"\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="Connection_Check_And_Data_Retrieval() {\n"
    filecontent+="    #Define constants\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_SSID_CONNECTION_CHECK=\"1\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_IPV4_RETRIEVE=\"2\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_IPV6_RETRIEVE=\"3\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_EXIT=\"4\"\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local phase=\"\${PHASE_WPASUPPLICANTFUNC_SSID_CONNECTION_CHECK}\"\n"
    filecontent+="    local ctr=0\n"
    filecontent+="    local getssid=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local ipv4_retrieved=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local ipv6_retrieved=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local netmaskv4_retrieved=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local netmaskv6_retrieved=\"\${EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="    local ssid_isconnected=false\n"
    filecontent+="    local ipv4isfound=false\n"
    filecontent+="    local ipv6isfound=false\n"
    filecontent+="\n"
    filecontent+="    #Initialize global variable\n"
    filecontent+="    connection_isfully_established=false\n"
    filecontent+="\n"
    filecontent+="    #Start phase\n"
    filecontent+="    while true\n"
    filecontent+="    do\n"
    filecontent+="        case \"\${phase}\" in\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_SSID_CONNECTION_CHECK}\")\n"
    filecontent+="                ctr=0\n"
    filecontent+="\n"
    filecontent+="                while [[ \${ctr} -lt \${CONN_STATUS_CHECK_CTR_MAX} ]]\n"
    filecontent+="                do\n"
    filecontent+="                    #Check if connected to ssid\n"
    filecontent+="                    getssid=\$(iwgetid -r); exitcode=\$?\n"
    filecontent+="                    #In case exitcode != 0, then get the result from log-file\n"
    filecontent+="                    if [[ \${exitcode} -ne 0 ]]; then\n"
    filecontent+="                        getssid=\$(sudo grep \"\${PATTERN_WLAN0_CLTR_EVENT_CONNECTED}\" \"\${WPA_WLAN0_LOG_FPATH}\")\n"
    filecontent+="                    fi\n"
    filecontent+="\n"
    filecontent+="                    #Check if 'getssid' contains a value\n"
    filecontent+="                    if [[ -n \"\${getssid}\" ]]; then\n"
    filecontent+="                        #Update boolean\n"
    filecontent+="                        ssid_isconnected=true\n"
    filecontent+="\n"
    filecontent+="                        #break loop\n"
    filecontent+="                        break\n"
    filecontent+="                    fi\n"
    filecontent+="\n"
    filecontent+="                    #Sleep for 1 second\n"
    filecontent+="                    sleep 1\n"
    filecontent+="\n"
    filecontent+="                    #Increment counter\n"
    filecontent+="                    ((ctr++))\n"
    filecontent+="                done\n"
    filecontent+="\n"
    filecontent+="                #Print\n"
    filecontent+="                if [[ \${ssid_isconnected} == true ]]; then\n"
    filecontent+="                    echo -e \":-->\${PRINT_STATUS}: \${PRINT_CONNECTED_TO} \${FG_LIGHTGREY}\${getssid}\${NOCOLOR}: \${PRINT_SUCCESSFUL}\"\n"
    filecontent+="\n"
    filecontent+="                    phase=\"\${PHASE_WPASUPPLICANTFUNC_IPV4_RETRIEVE}\"\n"
    filecontent+="                else\n"
    filecontent+="                    echo -e \":-->\${PRINT_STATUS}: \${PRINT_CONNECTED_TO} \${FG_LIGHTGREY}\${getssid}\${NOCOLOR}: \${PRINT_FAILED}\"\n"
    filecontent+="\n"
    filecontent+="                    phase=\"\${PHASE_WPASUPPLICANTFUNC_EXIT}\"\n"
    filecontent+="                fi\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_IPV4_RETRIEVE}\")\n"
    filecontent+="                ctr=0\n"
    filecontent+="\n"
    filecontent+="                while [[ \${ctr} -lt \${IPADDR_CTR_MAX} ]]\n"
    filecontent+="                do\n"
    filecontent+="                    #Retrieve IPv4-address\n"
    filecontent+="                    ipv4_retrieved=\$(Ipaddr_Retrieve \"\${PATTERN_INET}\" \"\${PATTERN_GLOBAL}\")\n"
    filecontent+="\n"
    filecontent+="                    if [[ -n \"\${ipv4_retrieved}\" ]]; then\n"
    filecontent+="                        #Update boolean\n"
    filecontent+="                        ipv4isfound=true\n"
    filecontent+="\n"
    filecontent+="                        #Retrieve netmask\n"
    filecontent+="                        netmaskv4_retrieved=\$(Netmask_Retrieve \"\${PATTERN_INET}\" \"\${PATTERN_GLOBAL}\")\n"
    filecontent+="\n"
    filecontent+="                        #break loop\n"
    filecontent+="                        break\n"
    filecontent+="                    fi\n"
    filecontent+="\n"
    filecontent+="                    #Sleep for 1 second\n"
    filecontent+="                    sleep 1\n"
    filecontent+="\n"
    filecontent+="                    #Increment counter\n"
    filecontent+="                    ((ctr++))\n"
    filecontent+="                done\n"
    filecontent+="\n"
    filecontent+="                #Print\n"
    filecontent+="                if [[ \${ipv4isfound} = true ]]; then\n"
    filecontent+="                    echo -e \":-->\${PRINT_STATUS}: \${PRINT_ASSIGNED_IPV4_ADDRESS}: \${FG_LIGHTGREY}\${ipv4_retrieved}\${NOCOLOR}/\${netmaskv4_retrieved}\"\n"
    filecontent+="                else\n"
    filecontent+="                    echo -e \":-->\${PRINT_STATUS}: \${PRINT_ASSIGNED_IPV4_ADDRESS}: \${PRINT_NOT_FOUND}\"\n"
    filecontent+="                fi\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_IPV6_RETRIEVE}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_IPV6_RETRIEVE}\")\n"
    filecontent+="                ctr=0\n"
    filecontent+="\n"
    filecontent+="                while [[ \${ctr} -lt \${IPADDR_CTR_MAX} ]]\n"
    filecontent+="                do\n"
    filecontent+="                    #Retrieve IPv4-address\n"
    filecontent+="                    ipv6_retrieved=\$(Ipaddr_Retrieve \"\${PATTERN_INET6}\" \"\${PATTERN_GLOBAL}\")\n"
    filecontent+="\n"
    filecontent+="                    if [[ -n \"\${ipv6_retrieved}\" ]]; then\n"
    filecontent+="                        #Update boolean\n"
    filecontent+="                        ipv6isfound=true\n"
    filecontent+="\n"
    filecontent+="                        #Retrieve netmask\n"
    filecontent+="                        netmaskv6_retrieved=\$(Netmask_Retrieve \"\${PATTERN_INET6}\" \"\${PATTERN_GLOBAL}\")\n"
    filecontent+="\n"
    filecontent+="                        #break loop\n"
    filecontent+="                        break\n"
    filecontent+="                    fi\n"
    filecontent+="\n"
    filecontent+="                    #Sleep for 1 second\n"
    filecontent+="                    sleep 1\n"
    filecontent+="\n"
    filecontent+="                    #Increment counter\n"
    filecontent+="                    ((ctr++))\n"
    filecontent+="                done\n"
    filecontent+="\n"
    filecontent+="                #Print\n"
    filecontent+="                if [[ \${ipv6isfound} = true ]]; then\n"
    filecontent+="                    echo -e \":-->\${PRINT_STATUS}: \${PRINT_ASSIGNED_IPV6_ADDRESS}: \${FG_LIGHTGREY}\${ipv6_retrieved}\${NOCOLOR}/\${netmaskv6_retrieved}\"\n"
    filecontent+="                else\n"
    filecontent+="                    echo -e \":-->\${PRINT_STATUS}: \${PRINT_ASSIGNED_IPV6_ADDRESS}: \${PRINT_NOT_FOUND}\"\n"
    filecontent+="                fi\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_EXIT}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_EXIT}\")\n"
    filecontent+="                #Determine 'connection_isfully_established'\n"
    filecontent+="                if [[ \${ssid_isconnected} == false ]]; then\n"
    filecontent+="                    connection_isfully_established=false\n"
    filecontent+="                else    #ssid_isconnected = true\n"
    filecontent+="                    if [[ \${ipv4isfound} == false ]] && [[ \${ipv6isfound} == false ]]; then\n"
    filecontent+="                        connection_isfully_established=false\n"
    filecontent+="                    else    #ipv4isfound = true and/or ipv6isfound = true\n"
    filecontent+="                        connection_isfully_established=true\n"
    filecontent+="                    fi\n"
    filecontent+="                fi\n"
    filecontent+="\n"
    filecontent+="                break\n"
    filecontent+="                ;;\n"
    filecontent+="        esac\n"
    filecontent+="    done\n"
    filecontent+="}\n"
    filecontent+="Ipaddr_Retrieve() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local ispattern1=\${1}\n"
    filecontent+="    local ispattern2=\${2}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local ipaddr=\"\${EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="    #Retrieve IP-address\n"
    filecontent+="    ipaddr=\$(ip addr show \${WLAN0} | grep -w \"\${ispattern1}\" | grep -w \"\${ispattern2}\" | grep -o \"\${ispattern1}.*\" | awk '{print \$2}' | cut -d\"/\" -f1)\n"
    filecontent+="\n"
    filecontent+="    #Output\n"
    filecontent+="    echo \"\${ipaddr}\"\n"
    filecontent+="\n"
    filecontent+="    return 0;\n"
    filecontent+="}\n"
    filecontent+="Netmask_Retrieve() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local ispattern1=\${1}\n"
    filecontent+="    local ispattern2=\${2}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local netmask=\"\${EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="    #Retrieve IP-address\n"
    filecontent+="    netmask=\$(ip addr show \${WLAN0} | grep -w \"\${ispattern1}\" | grep -w \"\${ispattern2}\" | grep -o \"\${ispattern1}.*\" | awk '{print \$2}' | cut -d\"/\" -f2)\n"
    filecontent+="\n"
    filecontent+="    #Output\n"
    filecontent+="    echo \"\${netmask}\"\n"
    filecontent+="\n"
    filecontent+="    return 0;\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="IntfStateGet() {\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local intfstate=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local intfstate_ucase=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local intfstate_fpath=\"\${EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="    #Set interface-state fullpath\n"
    filecontent+="    intfstate_fpath=\"/sys/class/net/\${WLAN0}/operstate\"\n"
    filecontent+="\n"
    filecontent+="    #Get interface-state from file\n"
    filecontent+="    if [[ -f \"\${intfstate_fpath}\" ]]; then\n"
    filecontent+="        intfstate=\$(cat \"\${intfstate_fpath}\")\n"
    filecontent+="    else\n"
    filecontent+="        intfstate=\"\${STATE_UNKNOWN}\"\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #In case 'intfstate is still an Empty String',\n"
    filecontent+="    #...then get the interface-state via the 'ip' command.\n"
    filecontent+="    if [[ \"\${intfstate}\" != \"\${STATE_UP}\" ]] && [[ \"\${intfstate}\" != \"\${STATE_DOWN}\" ]]; then\n"
    filecontent+="        intfstate_ucase=\$(ip a list \"\${WLAN0}\" | grep -o \"\${PATTERN_UP}.*\" | cut -d\",\" -f1)\n"
    filecontent+="\n"
    filecontent+="        #Translate 'intfstate_alternative' to 'intfstate'\n"
    filecontent+="        if [[ \"\${intfstate_ucase}\" == \"\${PATTERN_UP}\" ]]; then\n"
    filecontent+="            intfstate=\"\${STATE_UP}\"\n"
    filecontent+="        else\n"
    filecontent+="            intfstate=\"\${STATE_DOWN}\"\n"
    filecontent+="        fi\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Output\n"
    filecontent+="    echo \"\${intfstate}\"\n"
    filecontent+="\n"
    filecontent+="    return 0;\n"
    filecontent+="}\n"
    filecontent+="IntfStateSet() {\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local cmd=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local intfstateset_retry=0\n"
    filecontent+="\n"
    filecontent+="    #Check if interface is already up\n"
    filecontent+="    if [[ \$(IntfStateGet) == \"\${STATE_UP}\" ]]; then\n"
    filecontent+="        return 0;\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Bring interface up\n"
    filecontent+="    while [[ \${retry} -lt \${INTFSTATESET_RETRY_MAX} ]]\n"
    filecontent+="    do\n"
    filecontent+="        #If retry > 0, then bring interface down first\n"
    filecontent+="        if [[ \${retry} -gt 0 ]]; then\n"
    filecontent+="            cmd=\"ip link set dev \${WLAN0} down\"\n"
    filecontent+="            CmdExec \"\${cmd}\"\n"
    filecontent+="        fi\n"
    filecontent+="\n"
    filecontent+="        #Bring interface up\n"
    filecontent+="        cmd=\"ip link set dev \${WLAN0} up\"\n"
    filecontent+="        CmdExec \"\${cmd}\"\n"
    filecontent+="\n"
    filecontent+="        #Get interface-state\n"
    filecontent+="        if [[ \$(IntfStateGet) == \"\${STATE_UP}\" ]]; then\n"
    filecontent+="            break\n"
    filecontent+="        fi\n"
    filecontent+="\n"
    filecontent+="        #Wait for 1 second\n"
    filecontent+="        sleep 1\n"
    filecontent+="\n"
    filecontent+="        #Increment counter\n"
    filecontent+="        ((retry++))\n"
    filecontent+="    done\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="KillAllPids() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local ispattern=\${1}\n"
    filecontent+="    local ispidexclude=\${2}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local cmd=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local pid_listarr=()\n"
    filecontent+="    local pid_listarritem=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local pid_listarrlen=0\n"
    filecontent+="\n"
    filecontent+="    #Get pids for the specified 'ispattern'\n"
    filecontent+="    pid_listarr=(\$(ps axf | grep \"\${ispattern}\" | grep -v \"\${PATTERN_GREP}\" | awk '{print \$1}'))\n"
    filecontent+="\n"
    filecontent+="    #Get array-length\n"
    filecontent+="    pid_listarrlen=\${#pid_listarr[@]}\n"
    filecontent+="    if [[ \${pid_listarrlen} -eq 0 ]]; then\n"
    filecontent+="        return 0;\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Cycle thru array\n"
    filecontent+="    for pid_listarritem in \"\${pid_listarr[@]}\"\n"
    filecontent+="    do\n"
    filecontent+="        if [[ \${pid_listarritem} -ne \${ispidexclude} ]]; then\n"
    filecontent+="            cmd=\"kill -9 \${pid_listarritem}\"\n"
    filecontent+="            CmdExec \"\${cmd}\"\n"
    filecontent+="        fi\n"
    filecontent+="    done\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="WriteToFile() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local istargetfpath=\${1}\n"
    filecontent+="    local isdata=\${2}\n"
    filecontent+="\n"
    filecontent+="    #Write to file\n"
    filecontent+="    echo -e \"\${isdata}\" | tee \"\${istargetfpath}\" >/dev/null; pid=\$!; wait \${pid}; exitcode=\$?\n"
    filecontent+="\n"
    filecontent+="    #Print\n"
    filecontent+="    if [[ \${exitcode} -eq 0 ]]; then\n"
    filecontent+="        echo -e \":-->\${PRINT_STATUS}: \${PRINT_WRITE_TO} \${FG_LIGHTGREY}\${istargetfpath}\${NOCOLOR}: \${PRINT_DONE}\"\n"
    filecontent+="    else\n"
    filecontent+="        echo -e \":-->\${PRINT_STATUS}: \${PRINT_WRITE_TO} \${FG_LIGHTGREY}\${istargetfpath}\${NOCOLOR}: \${PRINT_FAILED}\"\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="Wpa_Supplicant_Service_DisableStop() {\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local cmd=\"\${EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="    #Check if service is-active\n"
    filecontent+="    if [[ \$(systemctl is-active \${WPA_SUPPLICANT_SRV}) == \"\${ACTIVE}\" ]]; then\n"
    filecontent+="        cmd=\"systemctl stop \${WPA_SUPPLICANT_SRV}\"\n"
    filecontent+="        CmdExec \"\${cmd}\"\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Check if service is-enabled\n"
    filecontent+="    if [[ \$(systemctl is-enabled \${WPA_SUPPLICANT_SRV}) == \"\${ENABLED}\" ]]; then\n"
    filecontent+="        cmd=\"systemctl disable \${WPA_SUPPLICANT_SRV}\"\n"
    filecontent+="        CmdExec \"\${cmd}\"\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="Wpa_Supplicant_Daemon_Service_DisableStop() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local srv_name=\${1}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local disable_cmd=\"systemctl disable \${srv_name}\"\n"
    filecontent+="    local stop_cmd=\"systemctl stop \${srv_name}\"\n"
    filecontent+="\n"
    filecontent+="    #Execute commands\n"
    filecontent+="    CmdExec \"\${disable_cmd}\"\n"
    filecontent+="    CmdExec \"\${stop_cmd}\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---MAIN FUNCTIONS\n"
    filecontent+="Start_Handler() {\n"
    filecontent+="    #Define constants\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_BRIDGE_INTERFACE_DEL=\"1\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_SERVICE_DISABLESTOP=\"2\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_WPA_APPLICANT_PROCS_KILL_1STTIME=\"3\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_IP_FLUSH_ALL=\"4\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_WPA_WLAN0_LOG_CLEAR=\"5\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_INTFSTATE_CHECK_AND_SET=\"6\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_NETPLAN_APPLY=\"7\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_WPA_APPLICANT_PROCS_KILL_2NDTIME=\"8\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_WPA_APPLICANT_NETPLAN_DAEMON_START=\"9\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_CONNECTION_STATUS_CHECK=\"10\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_WRITE_TO_FILE=\"11\"\n"
    filecontent+="    local PHASE_WPASUPPLICANTFUNC_EXIT=\"12\"\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local phase=\"\${PHASE_WPASUPPLICANTFUNC_BRIDGE_INTERFACE_DEL}\"\n"
    filecontent+="    local connection_status=\"\${NOT_CONNECTED}\"\n"
    filecontent+="    local filecontent=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local ctr=1\n"
    filecontent+="\n"
    filecontent+="    #Start phase\n"
    filecontent+="    while true\n"
    filecontent+="    do\n"
    filecontent+="        case \"\${phase}\" in\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_BRIDGE_INTERFACE_DEL}\")\n"
    filecontent+="                #Reset variable\n"
    filecontent+="                ret=false\n"
    filecontent+="\n"
    filecontent+="                #Stop and Disable 'wpa_supplicant.service'\n"
    filecontent+="                bridge_delif_and_print\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_SERVICE_DISABLESTOP}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_SERVICE_DISABLESTOP}\")\n"
    filecontent+="                #Stop and Disable 'wpa_supplicant.service'\n"
    filecontent+="                Wpa_Supplicant_Service_DisableStop\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_WPA_APPLICANT_PROCS_KILL_1STTIME}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_WPA_APPLICANT_PROCS_KILL_1STTIME}\")\n"
    filecontent+="                #Kill ALL wpa_supplicant daemons\n"
    filecontent+="                #   These daemons include:\n"
    filecontent+="                #   1. wpa_supplicant.service daemon\n"
    filecontent+="                #   2. initiated via command: /sbin/wpa_supplicant\n"
    filecontent+="                #   3. wpa_supplicant netplan daemon\n"
    filecontent+="                KillAllPids \"\${WPA_SUPPLICANT_CONF_FPATH}\" \"\${mypid}\"\n"
    filecontent+="                KillAllPids \"\${WPA_WLAN0_CONF_FPATH}\" \"\${mypid}\"\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_IP_FLUSH_ALL}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_IP_FLUSH_ALL}\")\n"
    filecontent+="                #Flush wifi-interface ip isdata\n"
    filecontent+="                CmdExec \"\${wifi_ip_flush_cmd}\"\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_WPA_WLAN0_LOG_CLEAR}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_WPA_WLAN0_LOG_CLEAR}\")\n"
    filecontent+="                #Check if log-file is present\n"
    filecontent+="                if [[ -f \${WPA_WLAN0_LOG_FPATH} ]]; then\n"
    filecontent+="                    #Clear log-file content (do not remove file)\n"
    filecontent+="                    WriteToFile \"\${WPA_WLAN0_LOG_FPATH}\" \"\${EMPTYSTRING}\"\n"
    filecontent+="                fi\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_INTFSTATE_CHECK_AND_SET}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_INTFSTATE_CHECK_AND_SET}\")\n"
    filecontent+="                #Check and set interface-state\n"
    filecontent+="                IntfStateSet\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_NETPLAN_APPLY}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_NETPLAN_APPLY}\")\n"
    filecontent+="                #Execute netplan apply\n"
    filecontent+="                #IMPORTANT TO KNOW:\n"
    filecontent+="                #1. Everytime when changes are made to wlan.yaml,\n"
    filecontent+="                #   ...netplan apply MUST be run for the changes\n"
    filecontent+="                #   ...to take effect!!!\n"
    filecontent+="                #2. netplan apply is executed to (re)create the\n"
    filecontent+="                #   ...file 'wpa-wlan0.conf'.\n"
    filecontent+="                CmdExec \"\${netplan_apply_cmd}\"\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_WPA_APPLICANT_PROCS_KILL_2NDTIME}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_WPA_APPLICANT_PROCS_KILL_2NDTIME}\")\n"
    filecontent+="                #Kill ALL wpa_supplicant daemons\n"
    filecontent+="                #   These daemons include:\n"
    filecontent+="                #   1. wpa_supplicant.service daemon\n"
    filecontent+="                #   2. initiated via command: /sbin/wpa_supplicant\n"
    filecontent+="                #   3. wpa_supplicant netplan daemon\n"
    filecontent+="                KillAllPids \"\${WPA_SUPPLICANT_CONF_FPATH}\" \"\${mypid}\"\n"
    filecontent+="                KillAllPids \"\${WPA_WLAN0_CONF_FPATH}\" \"\${mypid}\"\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_WPA_APPLICANT_NETPLAN_DAEMON_START}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_WPA_APPLICANT_NETPLAN_DAEMON_START}\")\n"
    filecontent+="                #Execute the wpa_supplicant netplan daemon,\n"
    filecontent+="                #...but now output messages to the specified log-file\n"
    filecontent+="                CmdExec \"\${wpa_supplicant_netplan_daemon_run_cmd}\"\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_CONNECTION_STATUS_CHECK}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_CONNECTION_STATUS_CHECK}\")\n"
    filecontent+="                #Check if 'wpa_supplicant_netplan_daemon_run_cmd' was executed successfully\n"
    filecontent+="                #If successful -> ret_failed = false\n"
    filecontent+="                #If failed -> ret_failed = true\n"
    filecontent+="                if [[ \${ret} == true ]]; then   #successful\n"
    filecontent+="                    #Check SSID connection status -> determine 'connection_isfully_established' {true|false}\n"
    filecontent+="                    #   Retrieve IPv4 address/netmask\n"
    filecontent+="                    #   Retrieve IPv6 address/netmask\n"
    filecontent+="                    Connection_Check_And_Data_Retrieval\n"
    filecontent+="\n"
    filecontent+="                    #Set boolean\n"
    filecontent+="                    ret_failed=false\n"
    filecontent+="                else    #failed\n"
    filecontent+="                    #Set booleans\n"
    filecontent+="                    connection_isfully_established=false\n"
    filecontent+="\n"
    filecontent+="                    ret_failed=true\n"
    filecontent+="                fi\n"
    filecontent+="\n"
    filecontent+="                if [[ \${ret_failed} == false ]]; then\n"
    filecontent+="                    if [[ \${connection_isfully_established} == true ]]; then   #connected\n"
    filecontent+="                        #Update status\n"
    filecontent+="                        connection_status=\"\${CONNECTED}\"\n"
    filecontent+="\n"
    filecontent+="                        #Goto next-phase\n"
    filecontent+="                        phase=\"\${PHASE_WPASUPPLICANTFUNC_WRITE_TO_FILE}\"\n"
    filecontent+="                    else    #not connected\n"
    filecontent+="                        if [[ \${ctr} -eq \${CONN_RETRY_MAX} ]]; then\n"
    filecontent+="                            phase=\"\${PHASE_WPASUPPLICANTFUNC_WRITE_TO_FILE}\"\n"
    filecontent+="                        else\n"
    filecontent+="                            #Increment counter\n"
    filecontent+="                            ((ctr++))\n"
    filecontent+="\n"
    filecontent+="                            #Go back to the beginning of this loop\n"
    filecontent+="                            phase=\"\${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_SERVICE_DISABLESTOP}\"\n"
    filecontent+="                        fi\n"
    filecontent+="\n"
    filecontent+="                        #Update status\n"
    filecontent+="                        connection_status=\"\${NOT_CONNECTED}\"\n"
    filecontent+="                    fi\n"
    filecontent+="                else\n"
    filecontent+="                    #Update status\n"
    filecontent+="                    connection_status=\"\${FAILED_TO_CONNECT}\"\n"
    filecontent+="\n"
    filecontent+="                    #Goto next-phase\n"
    filecontent+="                    phase=\"\${PHASE_WPASUPPLICANTFUNC_EXIT}\"\n"
    filecontent+="                fi\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_WRITE_TO_FILE}\")\n"
    filecontent+="                #Update filecontent\n"
    filecontent+="                filecontent=\"\${WPA_SUPPLICANT_DAEMON_SRV}:\${connection_status}\"\n"
    filecontent+="\n"
    filecontent+="                #Write to file\n"
    filecontent+="                WriteToFile \"\${WPA_WLAN0_LOG_FPATH}\" \"\${filecontent}\"\n"
    filecontent+="\n"
    filecontent+="                #Goto next-phase\n"
    filecontent+="                phase=\"\${PHASE_WPASUPPLICANTFUNC_EXIT}\"\n"
    filecontent+="                ;;\n"
    filecontent+="            \"\${PHASE_WPASUPPLICANTFUNC_EXIT}\")\n"
    filecontent+="                if [[ \${connection_isfully_established} == false ]]; then   #not connected\n"
    filecontent+="                    #Remark:\n"
    filecontent+="                    #   Do NOT disable 'wpa_supplicant_netplan_daemon_kill.service',\n"
    filecontent+="                    #       because this daemon can help to kill the wpa_supplicant daemon,\n"
    filecontent+="                    #       which is launched by netplan at boot.\n"
    filecontent+="                    Wpa_Supplicant_Daemon_Service_DisableStop \"\${WPA_SUPPLICANT_DAEMON_SRV}\"\n"
    filecontent+="                fi\n"
    filecontent+="\n"
    filecontent+="                break\n"
    filecontent+="                ;;\n"
    filecontent+="        esac\n"
    filecontent+="    done\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="Stop_Handler() {\n"
    filecontent+="    #Define variables\n"
    filecontent+="    #Kill ALL wpa_supplicant daemons\n"
    filecontent+="    #   These daemons could be:\n"
    filecontent+="    #   1. wpa_supplicant.service daemon\n"
    filecontent+="    #   2. initiated via command: /sbin/wpa_supplicant\n"
    filecontent+="    #   3. wpa_supplicant netplan daemon\n"
    filecontent+="    KillAllPids \"\${WPA_SUPPLICANT_CONF_FPATH}\" \"\${mypid}\"\n"
    filecontent+="    KillAllPids \"\${WPA_WLAN0_CONF_FPATH}\" \"\${mypid}\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---SELECT CASE\n"
    filecontent+="case \"\${action}\" in\n"
    filecontent+="    \"\${ENABLE}\")\n"
    filecontent+="        #Start subroutine in the BACKGROUND (&)\n"
    filecontent+="        Start_Handler\n"
    filecontent+="        ;;\n"
    filecontent+="    \"\${DISABLE}\")\n"
    filecontent+="        Stop_Handler\n"
    filecontent+="        ;;\n"
    filecontent+="esac"

    #Check if file exist
    RemoveFile "${istargetfpath}"
    
    #Write to file
    if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == true ]]; then
        #Change permisions
        if [[ $( Chmod "${istargetfpath}" "${WLN_MOD_755}") == true ]]; then
            ret="${ACCEPTED}"
        else
            ret="${REJECTED}"
        fi
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}

Wpa_Supplicant_Netplan_Daemon_Kill_Service_Generator() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Generate file-content
    filecontent="#--------------------------------------------------------------------\n"
    filecontent+="# Remarks:\n"
    filecontent+="#   This service is required to kill the wpa_supplicant daemon, which\n"
    filecontent+="#       is initiated by netplan (especially after a power off/on).\n"
    filecontent+="#   Using the ps-command, the following process is seen:\n"
    filecontent+="#       /sbin/wpa_supplicant -c /run/netplan/wpa-wlan0.conf -iwlan0 -Dnl80211,wext\n"
    filecontent+="#   In case an error occurs when trying to start the service, please\n"
    filecontent+="#       check the permissions of the script 'wpa_supplicant_netplan_daemon_kill.sh'.\n"
    filecontent+="#   The permission should be 755 (rwxr-xr-x).\n"
    filecontent+="#--------------------------------------------------------------------\n"
    filecontent+="[Unit]\n"
    filecontent+="Description=enables/disables wpa_supplicant_netplan_daemon_kill.service\n"
    filecontent+="After=network.target\n"
    filecontent+="\n"
    filecontent+="[Service]\n"
    filecontent+="Type=oneshot\n"
    filecontent+="#User MUST BE SET TO 'root'\n"
    filecontent+="User=root\n"
    filecontent+="RemainAfterExit=true\n"
    filecontent+="\n"
    filecontent+="ExecStart=/usr/local/bin/wpa_supplicant_netplan_daemon_kill.sh enable\n"
    filecontent+="ExecStop=/usr/local/bin/wpa_supplicant_netplan_daemon_kill.sh disable\n"
    filecontent+="\n"
    filecontent+="[Install]\n"
    filecontent+="WantedBy=multi-user.target"

    #Check if file exist
    RemoveFile "${istargetfpath}"
    
    #Write to file
    if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}

Wpa_Supplicant_Netplan_Daemon_Kill_Script_Generator() {
    #Input args
    local istargetfpath=${1}

    #Define variables
    local filecontent="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Generate file-content
    filecontent="#!/bin/bash\n"
    filecontent+="#---INPUT ARGS\n"
    filecontent+="#Possible input values: enable | disable\n"
    filecontent+="action=\${1}\n"
    filecontent+="\n"
    filecontent+="#---THIS SCRIPT'S PID\n"
    filecontent+="mypid=\${BASHPID}\n"
    filecontent+="\n"
    filecontent+="#---COLORS CONSTANTS\n"
    filecontent+="NOCOLOR=\$'\\\e[0m'\n"
    filecontent+="FG_LIGHTRED=\$'\\\e[1;31m'\n"
    filecontent+="FG_ORANGE=\$'\\\e[30;38;5;209m'\n"
    filecontent+="FG_LIGHTBLUE=\$'\\\e[30;38;5;45m'\n"
    filecontent+="FG_LIGHTGREY=\$'\\\e[30;38;5;246m'\n"
    filecontent+="FG_LIGHTGREEN=\$'\\\e[30;38;5;71m'\n"
    filecontent+="FG_SOFLIGHTRED=\$'\\\e[30;38;5;131m'\n"
    filecontent+="FG_YELLOW=\$'\\\e[1;33m'\n"
    filecontent+="\n"
    filecontent+="#---BOOLEANS CONSTANTS\n"
    filecontent+="ENABLE=\"${WLN_ENABLE}\"\n"
    filecontent+="DISABLE=\"${WLN_DISABLE}\"\n"
    filecontent+="START=\"${WLN_START}\"\n"
    filecontent+="STOP=\"${WLN_STOP}\"\n"
    filecontent+="\n"
    filecontent+="#---ENVIRONMENT CONSTANTS\n"
    filecontent+="WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV=\"${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}\"\n"
    filecontent+="WPA_WLAN0_CONF_FPATH=\"${WLN_WPA_WLAN0_CONF_FPATH}\"\n"
    filecontent+="WPA_WLAN0_LOG_FPATH=\"${WLN_WPA_WLAN0_LOG_FPATH}\"\n"
    filecontent+="\n"
    filecontent+="#---PATTERN CONSTANTS\n"
    filecontent+="PATTERN_GREP=\"${WLN_PATTERN_GREP}\"\n"
    filecontent+="\n"
    filecontent+="#---PRINT CONSTANTS\n"
    filecontent+="PRINT_DONE=\"\${FG_YELLOW}DONE\${NOCOLOR}\"\n"
    filecontent+="PRINT_FAILED=\"\${FG_SOFLIGHTRED}FAILED\${NOCOLOR}\"\n"
    filecontent+="PRINT_STATUS=\"\${FG_ORANGE}STATUS\${NOCOLOR}\"\n"
    filecontent+="PRINT_START=\"\${FG_LIGHTGREEN}start\${NOCOLOR}\"\n"
    filecontent+="PRINT_STOP=\"\${FG_SOFLIGHTRED}stop\${NOCOLOR}\"\n"
    filecontent+="PRINT_SUCCESSFUL=\"\${FG_LIGHTGREEN}SUCCESSFUL\${NOCOLOR}\"\n"
    filecontent+="PRINT_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV=\"\${FG_LIGHTGREY}\${WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}\${NOCOLOR}\"\n"
    filecontent+="\n"
    filecontent+="#---STRING CONSTANTS\n"
    filecontent+="EMPTYSTRING=\"${WLN_EMPTYSTRING}\"\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---SUPPORT FUNCTIONS\n"
    filecontent+="CmdExec() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local iscmd=\${1}\n"
    filecontent+="\n"
    filecontent+="    #Kill all wpa_supplicant daemons\n"
    filecontent+="    \${iscmd}; pid=\$!; wait \${pid}; exitcode=\$?\n"
    filecontent+="\n"
    filecontent+="    #Print\n"
    filecontent+="    if [[ \${exitcode} -eq 0 ]]; then\n"
    filecontent+="        echo -e \":-->:\${PRINT_STATUS}: \${FG_LIGHTGREY}\${iscmd}\${NOCOLOR}: \${PRINT_SUCCESSFUL}\"\n"
    filecontent+="    else\n"
    filecontent+="        echo -e \":-->\${PRINT_STATUS}: \${FG_LIGHTGREY}\${iscmd}\${NOCOLOR}: \${PRINT_FAILED}\"\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="KillAllPids() {\n"
    filecontent+="    #Input args\n"
    filecontent+="    local ispattern=\${1}\n"
    filecontent+="    local ispidexclude=\${2}\n"
    filecontent+="\n"
    filecontent+="    #Define variables\n"
    filecontent+="    local cmd=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local pid_listarr=()\n"
    filecontent+="    local pid_listarritem=\"\${EMPTYSTRING}\"\n"
    filecontent+="    local pid_listarrlen=0\n"
    filecontent+="\n"
    filecontent+="    #Get pids for the specified 'ispattern'\n"
    filecontent+="    #Note: the extra outer-bracket is to put the retrieved values in an array\n"
    filecontent+="    pid_listarr=(\$(ps axf | grep \"\${ispattern}\" | grep -v \"\${PATTERN_GREP}\" | grep -v \"\${WPA_WLAN0_LOG_FPATH}\" | awk '{print \$1}'))\n"
    filecontent+="\n"
    filecontent+="    #Get array-length\n"
    filecontent+="    pid_listarrlen=\${#pid_listarr[@]}\n"
    filecontent+="    if [[ \${pid_listarrlen} -eq 0 ]]; then\n"
    filecontent+="        return 0;\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Cycle thru array\n"
    filecontent+="    for pid_listarritem in \"\${pid_listarr[@]}\"\n"
    filecontent+="    do\n"
    filecontent+="        if [[ \${pid_listarritem} -ne \${ispidexclude} ]]; then\n"
    filecontent+="            cmd=\"kill -9 \${pid_listarritem}\"\n"
    filecontent+="            CmdExec \"\${cmd}\"\n"
    filecontent+="        fi\n"
    filecontent+="    done\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---MAIN FUNCTIONS\n"
    filecontent+="Start_Handler() {\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: systemctl \${PRINT_START} \${PRINT_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}: \${PRINT_DONE}\"\n"
    filecontent+="\n"
    filecontent+="    KillAllPids \"\${WPA_WLAN0_CONF_FPATH}\" \"\${mypid}\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="Stop_Handler() {\n"
    filecontent+="    echo -e \":-->\${PRINT_STATUS}: systemctl \${PRINT_STOP} \${PRINT_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}: \${PRINT_DONE}\"\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---SELECT CASE\n"
    filecontent+="case \"\${action}\" in\n"
    filecontent+="    \"\${ENABLE}\")\n"
    filecontent+="        #Start subroutine in the BACKGROUND (&)\n"
    filecontent+="        Start_Handler\n"
    filecontent+="        ;;\n"
    filecontent+="    \"\${DISABLE}\")\n"
    filecontent+="        Stop_Handler\n"
    filecontent+="        ;;\n"
    filecontent+="esac"

    #Check if file exist
    RemoveFile "${istargetfpath}"
    
    #Write to file
    if [[ $(WriteToFile "${istargetfpath}" "${filecontent}" "true") == true ]]; then
        #Change permisions
        if [[ $( Chmod "${istargetfpath}" "${WLN_MOD_755}") == true ]]; then
            ret="${ACCEPTED}"
        else
            ret="${REJECTED}"
        fi
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}

WpaSupplicant_StopDisable() {
    #Define constants
    local PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_SERVICE_DISABLESTOP=1
    local PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_DISABLESTOP=10
    local PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_DISABLESTOP=20
    local PHASE_WPASUPPLICANTFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_SERVICE_DISABLESTOP}"
    local ret="${REJECTED}"

    #Retrieve data from database
    isbssmode=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__bssmode")

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_SERVICE_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_WPA_SUPPLICANT_SRV}" \
                        "${WLN_WPASUPPLICANT}" \
                        "${WLN_WPA_SUPPLICANT_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                else
                    phase="${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SRV}" \
                        "${WLN_WPASUPPLICANT}" \
                        "${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                else
                    phase="${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_DISABLESTOP}"
                fi
                ;;
            "${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_DISABLESTOP}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_WPA_SUPPLICANT_DAEMON_SRV}" \
                        "${WLN_WPASUPPLICANT}" \
                        "${WLN_WPA_SUPPLICANT_DAEMON_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                ;;
            "${PHASE_WPASUPPLICANTFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}



#---FUNCTIONS
WLN_WpaSupplicant_Handler() {
    #Define constants
    local PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP=1
    local PHASE_WPASUPPLICANTFUNC_FIRMWARE_CONFIG_TXT_REVISE=10
    local PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_CONFIG_GENERATOR=20
    local PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_GENERATOR=30
    local PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SCRIPT_GENERATOR=31
    local PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_GENERATOR=40
    local PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SCRIPT_GENERATOR=41
    local PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_ENABLESTART=50
    local PHASE_WPASUPPLICANTFUNC_CONNECTION_STATUS_CHECK=51
    local PHASE_WPASUPPLICANTFUNC_EXIT=100

    #Define variables
    local phase="${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP}"
    local ret="${ACCEPTED}"

    # #Retrieve data from database
    country_code_retrieved=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__domaincode")
    ssid=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__ssid")
    # ssid_isvisible=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__ssidisvisible")
    wepmode=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wepmode")
    wepkey=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wepkey")
    wpamode=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpamode")
    wpakey=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__wpakey")

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICES_DISABLESTOP}")
                if [[ $(WpaSupplicant_StopDisable) == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                else
                    phase="${PHASE_WPASUPPLICANTFUNC_FIRMWARE_CONFIG_TXT_REVISE}"
                fi
                ;;
            "${PHASE_WPASUPPLICANTFUNC_FIRMWARE_CONFIG_TXT_REVISE}")
                #/etc/firmware/config.txt: set 'ccode'
                if [[ $(WLN_Firmware_Config_Txt_Revise "${country_code_retrieved}" "false") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                else
                    phase="${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_CONFIG_GENERATOR}"
                fi
                ;;
            "${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_CONFIG_GENERATOR}")
                #/etc/firmware/config.txt: set 'ccode'
                if [[ $(Wpa_Supplicant_Conf_Generator \
                        "${ssid}" \
                        "${wepmode}" "${wepkey}" \
                        "${wpamode}" "${wpakey}" \
                        "${WLN_WPA_SUPPLICANT_CONF_FPATH}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                else
                    phase="${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_GENERATOR}"
                fi
                ;;
            "${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_GENERATOR}")
                if [[ $(Wpa_Supplicant_Daemon_Service_Generator \
                        "${WLN_WPA_SUPPLICANT_DAEMON_SERVICE_FPATH}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                else
                    phase="${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SCRIPT_GENERATOR}"
                fi
                ;;
            "${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SCRIPT_GENERATOR}")
                if [[ $(Wpa_Supplicant_Daemon_Script_Generator \
                        "${WLN_WPA_SUPPLICANT_DAEMON_SH_FPATH}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                else
                    phase="${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_GENERATOR}"
                fi
                ;;
            "${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_GENERATOR}")
                if [[ $(Wpa_Supplicant_Netplan_Daemon_Kill_Service_Generator \
                        "${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SERVICE_FPATH}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                else
                    phase="${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SCRIPT_GENERATOR}"
                fi
                ;;
            "${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SCRIPT_GENERATOR}")
                if [[ $(Wpa_Supplicant_Netplan_Daemon_Kill_Script_Generator \
                        "${WLN_WPA_SUPPLICANT_NETPLAN_DAEMON_KILL_SH_FPATH}") == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                else
                    phase="${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_ENABLESTART}"
                fi
                ;;
            "${PHASE_WPASUPPLICANTFUNC_WPA_SUPPLICANT_DAEMON_SERVICE_ENABLESTART}")
                #Remark:
                #   'wpa_supplicant_netplan_daemon_kill.service' is enabled and
                #       started in service 'wpa_supplicant_daemon.service'.
                if [[ $(Service_Enable_And_Start "${WLN_WPA_SUPPLICANT_DAEMON_SRV}" \
                        "${WLN_SYSTEMCTL_START_SERVICE_RETRY_MAX}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                else
                    phase="${PHASE_WPASUPPLICANTFUNC_CONNECTION_STATUS_CHECK}"
                fi
                ;;
            "${PHASE_WPASUPPLICANTFUNC_CONNECTION_STATUS_CHECK}")
                if [[ $(IsConnected_To_Ssid) == false ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_WPASUPPLICANTFUNC_EXIT}"
                ;;
            "${PHASE_WPASUPPLICANTFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}
