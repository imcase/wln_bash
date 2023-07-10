#!/bin/bash
WLN_EnvVarLoad() {
	Wln_current_script_fpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    Wln_current_script_dir=$(dirname ${Wln_current_script_fpath})	#/repo/LTPP3_ROOTFS/development_tools

    ntios_wln_includefunc_filename="ntios_wln_includefunc.sh"
    ntios_wln_includefunc_fpath=${Wln_current_script_dir}/${ntios_wln_includefunc_filename}

    source "${ntios_wln_includefunc_fpath}"
}



#---MAIN SUBROUTINE
main__sub() { 
    WLN_EnvVarLoad

    channel=0
    wln_phy_mode="${PL_WLN_PHY_MODE_2G}"
    channel_out=$( Channel_AutoSelect "${channel}" "${wln_phy_mode}" )

    echo "${channel_out}"
}



#---EXECUTE MAIN
main__sub
