#!/bin/bash
#Get my PID
mypid=$$



#---ENVIRONMENT FUNCTIONS
WLN_EnvVarLoad() {
	Wln_current_script_fpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    Wln_current_script_dir=$(dirname ${Wln_current_script_fpath})	#/repo/LTPP3_ROOTFS/development_tools

    ntios_wln_includefunc_filename="ntios_wln_includefunc.sh"
    ntios_wln_includefunc_fpath=${Wln_current_script_dir}/${ntios_wln_includefunc_filename}

    source "${ntios_wln_includefunc_fpath}"
}


#---SUBROUTINE
test() {
    filecontent="#!/bin/bash\n"
    filecontent+="#---Input args\n"

    echo -e "${filecontent}" > /tmp/output.log

    sed -i 's/\ \\ $/\ \\/g' /tmp/output.log
}



#---MAIN SUBROUTINE
main__sub() {
    #---LOAD ENVIRONMENT VARIABLES
    WLN_EnvVarLoad
 


    #***IMPORTANT*** Add Set of Commands to '/etc/sudoers'
    Sudoers_Allow_SetOfCmds "${mypid}"



    #---STRUCTURE: INIT
    WLN_IntfStates_Ctx_Init_Handler



    #---TEST: WLN_activescan
    local ssid="${WLN_EMPTYSTRING}"
    local wln_scanresultssid="${WLN_EMPTYSTRING}"
    local wln_scanresultbssid="${WLN_EMPTYSTRING}"
    local wln_scanresultbssmode="${PL_WLN_BSS_MODE_UNKNOWN}"
    local wln_scanresultchannel=0
    local wln_scanresultrssi=0
    local wln_scanresultwpainfo="${WLN_EMPTYSTRING}"
    local ret="${REJECTED}"

    #Get the results when 'ssid' is an Empty String
    ret=$(WLN_activescan "${ssid}")
    wln_scanresultssid=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultssid")
    wln_scanresultbssid=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultbssid")
    wln_scanresultbssmode=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultbssmode")
    wln_scanresultchannel=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultchannel")
    wln_scanresultrssi=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultrssi")
    wln_scanresultwpainfo=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultwpainfo")

    echo "ssid>${ssid}"
    echo "ret>${ret}"
    echo "wln_scanresultssid>${wln_scanresultssid}<"
    echo "wln_scanresultbssid>${wln_scanresultbssid}<"
    echo "wln_scanresultbssmode>${wln_scanresultbssmode}<"
    echo "wln_scanresultchannel>${wln_scanresultchannel}<"
    echo "wln_scanresultrssi>${wln_scanresultrssi}<"
    echo "wln_scanresultwpainfo>${wln_scanresultwpainfo}<"

    echo -e "\r"
    echo -e "\r"

    #Get results when 'ssid' is a specific value
    ssid="hond_5G"
    ret=$(WLN_activescan "${ssid}")
    wln_scanresultssid=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultssid")
    wln_scanresultbssid=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultbssid")
    wln_scanresultbssmode=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultbssmode")
    wln_scanresultchannel=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultchannel")
    wln_scanresultrssi=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultrssi")
    wln_scanresultwpainfo=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultwpainfo")

    echo "ssid>${ssid}"
    echo "ret>${ret}"
    echo "wln_scanresultssid>${wln_scanresultssid}<"
    echo "wln_scanresultbssid>${wln_scanresultbssid}<"
    echo "wln_scanresultbssmode>${wln_scanresultbssmode}<"
    echo "wln_scanresultchannel>${wln_scanresultchannel}<"
    echo "wln_scanresultrssi>${wln_scanresultrssi}<"
    echo "wln_scanresultwpainfo>${wln_scanresultwpainfo}<"

    echo -e "\r"
    echo -e "\r"

    #Get results when 'ssid' is a specific value
    ssid="Tiger"
    ret=$(WLN_activescan "${ssid}")
    wln_scanresultssid=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultssid")
    wln_scanresultbssid=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultbssid")
    wln_scanresultbssmode=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultbssmode")
    wln_scanresultchannel=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultchannel")
    wln_scanresultrssi=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultrssi")
    wln_scanresultwpainfo=$(WLN_intfstates_ctx_retrievedata "${WLN_INTFSTATES_CTX_DAT_FPATH}" "WLN_intfstates_ctx__scanresultwpainfo")

    echo "ssid>${ssid}"
    echo "ret>${ret}"
    echo "wln_scanresultssid>${wln_scanresultssid}<"
    echo "wln_scanresultbssid>${wln_scanresultbssid}<"
    echo "wln_scanresultbssmode>${wln_scanresultbssmode}<"
    echo "wln_scanresultchannel>${wln_scanresultchannel}<"
    echo "wln_scanresultrssi>${wln_scanresultrssi}<"
    echo "wln_scanresultwpainfo>${wln_scanresultwpainfo}<"
}



#---EXECUTE MAIN
main__sub
