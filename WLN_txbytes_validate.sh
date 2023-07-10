#!/bin/bash
WLN_EnvVarLoad() {
	Wln_current_script_fpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    Wln_current_script_dir=$(dirname ${Wln_current_script_fpath})	#/repo/LTPP3_ROOTFS/development_tools

    ntios_wln_includefunc_filename="ntios_wln_includefunc.sh"
    ntios_wln_includefunc_fpath=${Wln_current_script_dir}/${ntios_wln_includefunc_filename}

    source "${ntios_wln_includefunc_fpath}"
}



#---FUNCTIONS
Ping() {
    #Input args
    local isintf=${1}
    local ipaddr=${2}
    local count=${3}
    local deadline=${4}

    #Define variables
    local exitcode=0
    local ret=false

    #Execute ping
    ping -n -I${isintf} -c "${count}" -w "${deadline}" "${ipaddr}" >/dev/null 2>&1; exitcode=$?

    #Output
    echo "${exitcode}"

    return 0;
}



#---MAIN SUBROUTINE
main__sub() {
    #Load environment variables
    WLN_EnvVarLoad

    #Define variables
    local intf="${WLN_WLAN0}"
    local ipaddr="${WLN_IPV4_LOCALHOST}"
    local count=1
    local deadline=1

    #Validate tx-bytes
    dtxbytes_isnotzero=$(TxBytes_Validate "${intf}" "${ipaddr}" "${NET_PING_COUNT}" "${NET_PING_DEADLINE}" "${WLN_STATISTICS_TXBYTES}")

    #Print output
    echo "$dtxbytes_isnotzero"
}



#---EXECUTE MAIN
main__sub



