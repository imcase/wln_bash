#!/bin/bash
#---FUNCTIONS
WLN_WifiPowerSave_Handler() {
    #Define constants
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_STOP_DISABLE=1
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_STOP_DISABLE=2
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_CREATE=3
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_CREATE=4
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_SCRIPT_CREATE=5
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_ENABLE_START=6
    local PHASE_WIFIPOWERSAVEOFFFUNC_EXIT=7

    #Define variables
    local phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_STOP_DISABLE}"
    local ret="${REJECTED}"
    
    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_STOP_DISABLE}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_WIFI_POWERSAVE_OFF_SRV}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_WIFI_POWERSAVE_OFF_SERVICE_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_STOP_DISABLE}"
                fi
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_STOP_DISABLE}")
                if [[ $(Service_ShouldBe_Disabled_And_Stopped "${WLN_WIFI_POWERSAVE_OFF_TIMER}" \
                        "${WLN_EMPTYSTRING}" \
                        "${WLN_WIFI_POWERSAVE_OFF_TIMER_FPATH}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_CREATE}"
                fi                
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_CREATE}")
                if [[ $(Wln_WifiPowerSaveOff_Service_Create) == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_CREATE}"
                fi                
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_CREATE}")
                if [[ $(Wln_WifiPowerSaveOff_Timer_Create) == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_SCRIPT_CREATE}"
                fi                
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_SCRIPT_CREATE}")
                if [[ $(Wln_WifiPowerSaveOff_Sh_Create) == "${REJECTED}" ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_ENABLE_START}"
                fi                
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_ENABLE_START}")
                if [[ $(Wln_WifiPowerSaveService_EnableStart) == "${REJECTED}" ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi                

                phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

Wln_WifiPowerSaveOff_Service_Create() {
    #Generate 'wifi-powersave-off.service' filecontent
    local filecontent="#--------------------------------------------------------------------\n"
    filecontent+="# Remarks:\n"
    filecontent+="# 1. In order for the service to run after a reboot\n"
    filecontent+="#		make sure to create a 'symlink'\n"
    filecontent+="#		ln -s /etc/systemd/system/<myservice.service> /etc/systemd/system/multi-user.target.wants/<myservice.service>\n"
    filecontent+="# 2. Reload daemon: systemctl daemon-reload\n"
    filecontent+="# 3. Start Service: systemctl start <myservice.service>\n"
    filecontent+="# 4. Check status: systemctl status <myservice.service>\n"
    filecontent+="#--------------------------------------------------------------------\n"
    filecontent+="[Unit]\n"
    filecontent+="Description=Disable power management for wlan0\n"
    filecontent+="Requires=sys-subsystem-net-devices-wlan0.device\n"
    filecontent+="Wants=${WLN_WIFI_POWERSAVE_OFF_TIMER}\n"
    filecontent+="\n"
    filecontent+="[Service]\n"
    filecontent+="Type=oneshot\n"
    filecontent+="#User MUST BE SET TO 'root'\n"
    filecontent+="User=root\n"
    filecontent+="\n"
    filecontent+="ExecStart=${WLN_WIFI_POWERSAVE_OFF_SH_FPATH} false\n"
    filecontent+="\n"
    filecontent+="[Install]\n"
    filecontent+="WantedBy=multi-user.target"

    #Remove 'wifi-powersave-off.service'
    if [[ $(RemoveFile "${WLN_WIFI_POWERSAVE_OFF_SERVICE_FPATH}") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Write to file
    if [[ $(WriteToFile "${WLN_WIFI_POWERSAVE_OFF_SERVICE_FPATH}" "${filecontent}" "true") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Change permissions
    if [[ $(Chmod "${WLN_WIFI_POWERSAVE_OFF_SERVICE_FPATH}" "${WLN_MOD_644}") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Output
    echo "${ret}"

    return 0;
}

Wln_WifiPowerSaveOff_Timer_Create() {
    #Create 'wifi-powersave-off.timer'
    local filecontent="#--------------------------------------------------------------------\n"
    filecontent+="# Remarks:\n"
    filecontent+="# 1. In order for the service to run after a reboot\n"
    filecontent+="#    make sure to create a 'symlink'\n"
    filecontent+="#    ln -s /etc/systemd/system/<myservice.timer> /etc/systemd/system/timers.target.wants/<myservice.timer>\n"
    filecontent+="# 2. Reload daemon: systemctl daemon-reload\n"
    filecontent+="# 3. Start Service: systemctl start <myservice.timer>\n"
    filecontent+="# 4. Check status: systemctl status <myservice.timer>\n"
    filecontent+="#--------------------------------------------------------------------\n"
    filecontent+="[Unit]\n"
    filecontent+="Description=Run wifi-powersave-off.service every 5 sec (active-state) and 5 sec (idle-state)\n"
    filecontent+="Requires=${WLN_WIFI_POWERSAVE_OFF_SRV}\n"
    filecontent+="\n"
    filecontent+="[Timer]\n"
    filecontent+="#Run on boot after 1 seconds\n"
    filecontent+="OnBootSec=1s\n"
    filecontent+="#Run script every 5 sec when Device is Active\n"
    filecontent+="OnUnitActiveSec=5s\n"
    filecontent+="#Run script every 5 sec when Device is Idle\n"
    filecontent+="OnUnitInactiveSec=5s\n"
    filecontent+="AccuracySec=1s\n"
    filecontent+="\n"
    filecontent+="[Install]\n"
    filecontent+="WantedBy=timers.target"

    #Remove 'wifi-powersave-off.timer'
    if [[ $(RemoveFile "${WLN_WIFI_POWERSAVE_OFF_TIMER_FPATH}") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Write to file
    if [[ $(WriteToFile "${WLN_WIFI_POWERSAVE_OFF_TIMER_FPATH}" "${filecontent}" "true") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Change permissions
    if [[ $(Chmod "${WLN_WIFI_POWERSAVE_OFF_TIMER_FPATH}" "${WLN_MOD_644}") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi
}

Wln_WifiPowerSaveOff_Sh_Create() {
    #Create 'wifi-powersave-off.sh'
    filecontent="#!/bin/bash\n"
    filecontent+="#---INPUT ARGS\n"
    filecontent+="PrintIsAllowed__in=\${1}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---CONSTANTS\n"
    filecontent+="POWER_OFF=\"off\"\n"
    filecontent+="POWER_ON=\"on\"\n"
    filecontent+="STATEGET_DOWN=\"DOWN\"\n"
    filecontent+="STATEGET_UP=\"UP\"\n"
    filecontent+="STATEGET_UNKNOWN=\"UNKNOWN\"\n"
    filecontent+="STATESET_DOWN=\"down\"\n"
    filecontent+="STATESET_UP=\"up\"\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---COLORS CONSTANTS\n"
    filecontent+="WLN_RESETCOLOR=\$'\\\e[0m'\n"
    filecontent+="WLN_ORANGE=\$'\\\e[30;38;5;209m'\n"
    filecontent+="WLN_LIGHTGREY=\$'\\\e[30;38;5;246m'\n"
    filecontent+="WLN_LIGHTGREEN=\$'\\\e[30;38;5;71m'\n"
    filecontent+="WLN_SOFLIGHTRED=\$'\\\e[30;38;5;131m'\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---PHASE CONSTANTS\n"
    filecontent+="PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_POWERSAVE_GET=0\n"
    filecontent+="PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_INTFSTATE=1\n"
    filecontent+="PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_POWERSAVE_SET=2\n"
    filecontent+="PHASE_WIFIPOWERSAVEOFFFUNC_EXIT=3\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---SERVICES CONSTANTS\n"
    filecontent+="WLN_WIFI_POWERSAVE_OFF_TIMER=\"${WLN_WIFI_POWERSAVE_OFF_TIMER}\"\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---VARIABLES\n"
    filecontent+="phase=\${PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_POWERSAVE_GET}\n"
    filecontent+="phase_prev=\${PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_POWERSAVE_GET}\n"
    filecontent+="wifiName=\"${WLN_WLAN0}\"\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---SUBROUTINES\n"
    filecontent+="wifi_state_set() {\n"
    filecontent+="    #CONSTANTS\n"
    filecontent+="    local RETRY_CTR_MAX=10\n"
    filecontent+="\n"
    filecontent+="    #VARIABLES\n"
    filecontent+="    local pid=0\n"
    filecontent+="    local retry_ctr=1\n"
    filecontent+="\n"
    filecontent+="    #Check Wireless interface-state\n"
    filecontent+="    local isState=\`ip link show dev \${wifiName} | grep -o \"state.*\" | cut -d\" \" -f2 2>&1\`\n"
    filecontent+="    if [[ \${isState} == \${STATEGET_DOWN} ]]; then    #interface is down\n"
    filecontent+="        if [[ \${PrintIsAllowed__in} == true ]]; then\n"
    filecontent+="            echo -e \":-->\${WLN_ORANGE}STATUS\${WLN_RESETCOLOR}: \${WLN_LIGHTGREY}\${wifiName}\${WLN_RESETCOLOR} is \${WLN_LIGHTGREEN}\${STATEGET_DOWN}\${WLN_RESETCOLOR}\"\n"
    filecontent+="        fi\n"
    filecontent+="\n"
    filecontent+="        #Loop till retry_ctr < RETRY_CTR_MAX\n"
    filecontent+="        while [[ \${retry_ctr} -le \${RETRY_CTR_MAX} ]]\n"
    filecontent+="        do\n"
    filecontent+="            #Print\n"
    filecontent+="            if [[ \${PrintIsAllowed__in} == true ]]; then\n"
    filecontent+="                echo -e \":-->\${WLN_ORANGE}STATUS\${WLN_RESETCOLOR}: Trying to bring \${WLN_LIGHTGREEN}\${STATEGET_UP}\${WLN_RESETCOLOR} \${WLN_LIGHTGREY}\${wifiName}\${WLN_RESETCOLOR} (\${retry_ctr} out-of \${RETRY_CTR_MAX})\"\n"
    filecontent+="            fi\n"
    filecontent+="\n"
    filecontent+="            #Bring interface up\n"
    filecontent+="            ip link set dev \${wifiName} \${STATESET_UP} 2>&1 > /dev/null\n"
    filecontent+="            #Get PID\n"
    filecontent+="            pid=\$!\n"
    filecontent+="            #Wait for process to finish\n"
    filecontent+="            wait \${pid}\n"
    filecontent+="\n"
    filecontent+="            #Break loop if 'isState' contains data (which means that Status has changed to UP)\n"
    filecontent+="            isState=\`ip link show dev \${wifiName} | grep -o \"state.*\" | cut -d\" \" -f2 2>&1\`\n"
    filecontent+="\n"
    filecontent+="            if [[ \${isState} == \${STATEGET_UNKNOWN} ]]; then    #data found\n"
    filecontent+="                isState=\`ip link show dev \${wifiName} | grep -o \"MULTICAST.*\" | cut -d"\," -f2 2>&1\`\n"
    filecontent+="            fi\n"
    filecontent+="\n"
    filecontent+="            if [[ \${isState} == \${STATEGET_UP} ]]; then    #data found\n"
    filecontent+="                break\n"
    filecontent+="            fi\n"
    filecontent+="\n"
    filecontent+="            #error was found, retry_ctr again\n"
    filecontent+="            retry_ctr=\$((retry_ctr + 1))\n"
    filecontent+="        done\n"
    filecontent+="    else\n"
    filecontent+="        isState=\${STATEGET_UP}\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #State has correctly changed to UP\n"
    filecontent+="    if [[ \${isState} == \${STATEGET_DOWN} ]]; then\n"
    filecontent+="        echo -e \":-->\${WLN_ORANGE}STATUS\${WLN_RESETCOLOR}: \${WLN_SOFLIGHTRED}Failed\${WLN_RESETCOLOR} to bring \${WLN_LIGHTGREEN}\${STATEGET_UP}\${WLN_RESETCOLOR} \${WLN_LIGHTGREY}\${wifiName}\${WLN_RESETCOLOR} (\${retry_ctr} out-of \${RETRY_CTR_MAX})\"\n"
    filecontent+="\n"
    filecontent+="        echo -e \":-->\${WLN_ORANGE}STATUS\${WLN_RESETCOLOR}: \${WLN_SOFLIGHTRED}Failed\${WLN_RESETCOLOR} to set \${WLN_LIGHTGREY}\${wifiName}\${WLN_RESETCOLOR} Powersave to \${WLN_SOFLIGHTRED}\${POWER_OFF}\${WLN_RESETCOLOR}\"\n"
    filecontent+="\n"
    filecontent+="        echo -e \":-->\${WLN_ORANGE}HINT\${WLN_RESETCOLOR}: to FIX this issue, a REBOOT is required...\"\n"
    filecontent+="\n"
    filecontent+="        systemctl stop \${WLN_WIFI_POWERSAVE_OFF_TIMER}\n"
    filecontent+="\n"
    filecontent+="        phase=\${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}\n"
    filecontent+="    else\n"
    filecontent+="        if [[ \${PrintIsAllowed__in} == true ]]; then\n"
    filecontent+="            echo -e \":-->\${WLN_ORANGE}STATUS\${WLN_RESETCOLOR}: \${WLN_LIGHTGREY}\${wifiName}\${WLN_RESETCOLOR} is \${WLN_LIGHTGREEN}\${STATEGET_UP}\${WLN_RESETCOLOR}\"\n"
    filecontent+="        fi\n"
    filecontent+="\n"
    filecontent+="        phase=\${PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_POWERSAVE_SET}\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="wifi_powersave_state_get() {\n"
    filecontent+="    #Get Powersave-state\n"
    filecontent+="    local isPowersaveState=\`iw dev \${wifiName} get power_save | grep -o \"save.*\" | cut -d\" \" -f2 2>&1\`\n"
    filecontent+="    if [[ \${isPowersaveState} == \${POWER_ON} ]]; then\n"
    filecontent+="        if [[ \${PrintIsAllowed__in} == true ]]; then\n"
    filecontent+="            echo -e \":-->\${WLN_ORANGE}STATUS\${WLN_RESETCOLOR}: \${WLN_LIGHTGREY}\${wifiName}\${WLN_RESETCOLOR} Powersave is \${WLN_LIGHTGREEN}\${POWER_ON}\${WLN_RESETCOLOR}\"\n"
    filecontent+="        fi\n"
    filecontent+="\n"
    filecontent+="        #Take action based on the origin of the 'phase'\n"
    filecontent+="        if [[ \${phase_prev} == \${PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_POWERSAVE_SET} ]]; then\n"
    filecontent+="            phase=\${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}\n"
    filecontent+="        else\n"
    filecontent+="            phase=\${PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_INTFSTATE}\n"
    filecontent+="        fi\n"
    filecontent+="    else\n"
    filecontent+="        if [[ \${PrintIsAllowed__in} == true ]]; then\n"
    filecontent+="            echo -e \":-->\${WLN_ORANGE}STATUS\${WLN_RESETCOLOR}: \${WLN_LIGHTGREY}\${wifiName}\${WLN_RESETCOLOR} Powersave is \${WLN_SOFLIGHTRED}\${POWER_OFF}\${WLN_RESETCOLOR}\"\n"
    filecontent+="        fi\n"
    filecontent+="\n"
    filecontent+="        phase=\${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="wifi_powersave_state_set() {\n"
    filecontent+="    #Set powersave-state to off\n"
    filecontent+="    iw dev \${wifiName} set power_save off\n"
    filecontent+="\n"
    filecontent+="    phase_prev=\${PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_POWERSAVE_SET}\n"
    filecontent+="    phase=\${PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_POWERSAVE_GET}\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---MAIN SUBROUTINE\n"
    filecontent+="main__sub() {\n"
    filecontent+="    #Print empty line\n"
    filecontent+="    if [[ \${PrintIsAllowed__in} == true ]]; then\n"
    filecontent+="        echo -e \"\\\r\"\n"
    filecontent+="    fi\n"
    filecontent+="\n"
    filecontent+="    #Go thru phases\n"
    filecontent+="    phase=\${PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_INTFSTATE}\n"
    filecontent+="    while true\n"
    filecontent+="    do\n"
    filecontent+="        case \"\${phase}\" in\n"
    filecontent+="            \${PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_INTFSTATE})\n"
    filecontent+="                wifi_state_set\n"
    filecontent+="                ;;\n"
    filecontent+="            \${PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_POWERSAVE_GET})\n"
    filecontent+="                wifi_powersave_state_get\n"
    filecontent+="                ;;\n"
    filecontent+="            \${PHASE_WIFIPOWERSAVEOFFFUNC_WIFI_POWERSAVE_SET})\n"
    filecontent+="                wifi_powersave_state_set\n"
    filecontent+="                ;;\n"
    filecontent+="            \${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT})\n"
    filecontent+="                break\n"
    filecontent+="                ;;\n"
    filecontent+="        esac\n"
    filecontent+="    done\n"
    filecontent+="\n"
    filecontent+="    #Print empty line\n"
    filecontent+="    if [[ \${PrintIsAllowed__in} == true ]]; then\n"
    filecontent+="        echo -e \"\\\r\"\n"
    filecontent+="    fi\n"
    filecontent+="}\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="\n"
    filecontent+="#---EXECUTE\n"
    filecontent+="main__sub"

    #Remove 'wifi-powersave-off.timer'
    if [[ $(RemoveFile "${WLN_WIFI_POWERSAVE_OFF_SH_FPATH}") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Write to file
    if [[ $(WriteToFile "${WLN_WIFI_POWERSAVE_OFF_SH_FPATH}" "${filecontent}" "true") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi

    #Change permissions
    if [[ $(Chmod "${WLN_WIFI_POWERSAVE_OFF_SH_FPATH}" "${WLN_MOD_755}") == true ]]; then
        ret="${ACCEPTED}"
    else
        ret="${REJECTED}"
    fi
}

Wln_WifiPowerSaveService_EnableStart() {
    #Define constants
    local PHASE_WIFIPOWERSAVEOFFFUNC_DAEMON_RELOAD=1
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_ENABLE=2
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_ENABLE=3
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERIVCE_START=4
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_START=5
    local PHASE_WIFIPOWERSAVEOFFFUNC_EXIT=6

    #Define variables
    local phase="${PHASE_WIFIPOWERSAVEOFFFUNC_DAEMON_RELOAD}"
    local ret="${REJECTED}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_WIFIPOWERSAVEOFFFUNC_DAEMON_RELOAD}")
                SystemctlDaemonReload

                phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_ENABLE}"
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_ENABLE}")
                if [[ $(SystemctlEnableService "${WLN_WIFI_POWERSAVE_OFF_SRV}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_ENABLE}"
                fi
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_ENABLE}")
                if [[ $(SystemctlEnableService "${WLN_WIFI_POWERSAVE_OFF_TIMER}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERIVCE_START}"
                fi
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERIVCE_START}")                
                #Start service
                SystemctlStartService "${WLN_WIFI_POWERSAVE_OFF_SRV}"

                #Check if service is-active
                phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_START}"
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_START}")                
                if [[ $(SystemctlStartService "${WLN_WIFI_POWERSAVE_OFF_TIMER}") == false ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

Wln_WifiPowerSaveService_StopDisable() {
    #Define constants
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_FPATH_CHECK=1
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_STOP=2
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_DISABLE=3
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_FPATH_CHECK=4
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_STOP=5
    local PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_DISABLE=6
    local PHASE_WIFIPOWERSAVEOFFFUNC_EXIT=7

    #Define variables
    local phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_FPATH_CHECK}"
    local ret="${REJECTED}"

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_FPATH_CHECK}")
                if [[ -f "${WLN_WIFI_POWERSAVE_OFF_TIMER_FPATH}" ]]; then
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_STOP}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_FPATH_CHECK}"
                fi
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_STOP}")
                if [[ $(SystemctlStopService "${WLN_WIFI_POWERSAVE_OFF_TIMER}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_DISABLE}"
                fi
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_TIMER_DISABLE}")
                if [[ $(SystemctlDisableService "${WLN_WIFI_POWERSAVE_OFF_TIMER}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_FPATH_CHECK}"
                fi
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_FPATH_CHECK}")
                if [[ -f "${WLN_WIFI_POWERSAVE_OFF_SERVICE_FPATH}" ]]; then
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_STOP}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                fi
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_STOP}")
                if [[ $(SystemctlStopService "${WLN_WIFI_POWERSAVE_OFF_SRV}") == false ]]; then
                    ret="${REJECTED}"

                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                else
                    phase="${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_DISABLE}"
                fi
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_SERVICE_DISABLE}")                
                if [[ $(SystemctlDisableService "${WLN_WIFI_POWERSAVE_OFF_SRV}") == false ]]; then
                    ret="${REJECTED}"
                else
                    ret="${ACCEPTED}"
                fi

                phase="${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}"
                ;;
            "${PHASE_WIFIPOWERSAVEOFFFUNC_EXIT}")
                break
                ;;
        esac
    done

    #Output
    #Remark:
    #   In case both full-paths do not exist, then ret = REJECTED (inital value).
    echo "${ret}"

    return 0;
}