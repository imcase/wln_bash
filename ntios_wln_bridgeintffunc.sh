#!/bin/bash
#---FUNCTIONS
WLN_Bridge_Add_And_BringUp() {
    #Define constants
    local PHASE_BRIDGEINTFFUNC_BRIDGE_CHECK=1
    local PHASE_BRIDGEINTFFUNC_BRIDGE_ADD=10
    local PHASE_BRIDGEINTFFUNC_BRIDGE_BRINGUP=11
    local PHASE_BRIDGEINTFFUNC_BRIDGE_EXIT=12
    
    #Define variables
    local phase="${PHASE_BRIDGEINTFFUNC_BRIDGE_CHECK}"
    local ret=false

    #Start phase
    while true
    do
        case "${phase}" in
            "${PHASE_BRIDGEINTFFUNC_BRIDGE_CHECK}")
                cmd="ls -1 ${WLN_SYS_CLASS_NET_DIR} | grep \"${WLN_BR0}\""
                if [[ $(EvalCmdExec "${cmd}") == "${WLN_BR0}" ]]; then
                    #Update output result
                    ret=true

                    #Goto next-phase
                    phase="${PHASE_BRIDGEINTFFUNC_BRIDGE_EXIT}"
                else
                    #Goto next-phase
                    phase="${PHASE_BRIDGEINTFFUNC_BRIDGE_ADD}"
                fi
                ;;
            "${PHASE_BRIDGEINTFFUNC_BRIDGE_ADD}")
                #Define command
                cmd="brctl addbr ${WLN_BR0}"
                #Execute command
                CmdExec "${cmd}"

                #Goto next-phase
                phase="${PHASE_BRIDGEINTFFUNC_BRIDGE_BRINGUP}"
                ;;
            "${PHASE_BRIDGEINTFFUNC_BRIDGE_BRINGUP}")
                #Define command
                cmd="ip link set dev ${WLN_BR0} ${WLN_UP}"
                #Execute command
                CmdExec "${cmd}"

                #Goto next-phase
                phase="${PHASE_BRIDGEINTFFUNC_BRIDGE_EXIT}"
                ;;
            "${PHASE_BRIDGEINTFFUNC_BRIDGE_EXIT}")
                break
                ;;
        esac
    done

    #Output
    echo "${ret}"

    return 0;
}

WLN_Unbridge_Interfaces() {
    #Define variables
    local ret=false

    #Remove 'wlan.yaml'
    ret=$(RemoveFile "${WLN_WLAN_YAML_FPATH}")

    #Remove interfaces from bridge
    cmd="brctl delif ${WLN_BR0} ${WLN_ETH0}"
    ret=$(CmdExec "${cmd}")

    cmd="brctl delif ${WLN_BR0} ${WLN_ETH1}"
    ret=$(CmdExec "${cmd}")

    cmd="brctl delif ${WLN_BR0} ${WLN_WLAN0}"
    ret=$(CmdExec "${cmd}")

    #Bring interface down
    cmd="ip link set dev ${WLN_BR0} ${WLN_DOWN}"
    ret=$(CmdExec "${cmd}")

    #Remove bridge interface
    cmd="brctl delbr ${WLN_BR0}"
    ret=$(CmdExec "${cmd}")

    #Apply netplan
    cmd="netplan apply"
    ret=$(CmdExec "${cmd}")

    #wait for 3 seconds
    cmd="sleep 3"
    ret=$(CmdExec "${cmd}")  
}

WLN_Bridge_Interfaces() {
    #Define variables
    local ret=false

    #Add bridge interface
    cmd="brctl addbr ${WLN_BR0}"
    ret=$(CmdExec "${cmd}")

    #Bring interface up
    cmd="ip link set dev ${WLN_BR0} ${WLN_UP}"
    ret=$(CmdExec "${cmd}")

    #Add interface to bridge
    cmd="brctl addif ${WLN_BR0} ${WLN_WLAN0}"
    ret=$(CmdExec "${cmd}")

    #Apply netplan
    cmd="netplan apply"
    ret=$(CmdExec "${cmd}")

    #wait for 3 seconds
    cmd="sleep 3"
    ret=$(CmdExec "${cmd}")  
}

WLN_Bridge_Interface_Handler() {
    WLN_Unbridge_Interfaces

    WLN_Bridge_Interfaces
}