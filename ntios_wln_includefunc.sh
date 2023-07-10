#!/bin/bash
#---FUNCTIONS
WLN_EnvVarLoad() {
	Wln_current_script_fpath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    Wln_current_script_dir=$(dirname ${Wln_current_script_fpath})	#/repo/LTPP3_ROOTFS/development_tools

    other_filename="other.sh"
    other_fpath=${Wln_current_script_dir}/${other_filename}
    ntios_net_func_filename="ntios_net_func.sh"
    ntios_net_func_fpath=${Wln_current_script_dir}/${ntios_net_func_filename}
    ntios_wln_activescanfunc_filename="ntios_wln_activescanfunc.sh"
    ntios_wln_activescanfunc_fpath=${Wln_current_script_dir}/${ntios_wln_activescanfunc_filename} 
    ntios_wln_associatefunc_filename="ntios_wln_associatefunc.sh"
    ntios_wln_associatefunc_fpath=${Wln_current_script_dir}/${ntios_wln_associatefunc_filename}
    ntios_wln_autoreconnectonboot_filename="ntios_wln_autoreconnectonboot.sh"
    ntios_wln_autoreconnectonboot_fpath=${Wln_current_script_dir}/${ntios_wln_autoreconnectonboot_filename}
    ntios_wln_types_filename="ntios_wln_types.sh"
    ntios_wln_types_fpath=${Wln_current_script_dir}/${ntios_wln_types_filename}
    ntios_wln_bridgeintffunc_filename="ntios_wln_bridgeintffunc.sh"
    ntios_wln_bridgeintffunc_fpath=${Wln_current_script_dir}/${ntios_wln_bridgeintffunc_filename}
    ntios_wln_unbridgefunc_filename="ntios_wln_unbridgefunc.sh"
    ntios_wln_unbridgefunc_fpath=${Wln_current_script_dir}/${ntios_wln_unbridgefunc_filename}
    ntios_wln_channelfunc_filename="ntios_wln_channelfunc.sh"
    ntios_wln_channelfunc_fpath=${Wln_current_script_dir}/${ntios_wln_channelfunc_filename}
    ntios_wln_disablefunc_filename="ntios_wln_disablefunc.sh"
    ntios_wln_disablefunc_fpath=${Wln_current_script_dir}/${ntios_wln_disablefunc_filename}
    ntios_wln_disassociatefunc_filename="ntios_wln_disassociatefunc.sh"
    ntios_wln_disassociatefunc_fpath=${Wln_current_script_dir}/${ntios_wln_disassociatefunc_filename}
    ntios_wln_dnsmasqfunc_filename="ntios_wln_dnsmasqfunc.sh"
    ntios_wln_dnsmasqfunc_fpath=${Wln_current_script_dir}/${ntios_wln_dnsmasqfunc_filename}
    ntios_wln_domaincodefunc_filename="ntios_wln_domaincodefunc.sh"
    ntios_wln_domaincodefunc_fpath=${Wln_current_script_dir}/${ntios_wln_domaincodefunc_filename}
    ntios_wln_enablefunc_filename="ntios_wln_enablefunc.sh"
    ntios_wln_enablefunc_fpath=${Wln_current_script_dir}/${ntios_wln_enablefunc_filename}
    ntios_wln_exitfunc_filename="ntios_wln_exitfunc.sh"
    ntios_wln_exitfunc_fpath=${Wln_current_script_dir}/${ntios_wln_exitfunc_filename}
    ntios_wln_firmwarefunc_filename="ntios_wln_firmwarefunc.sh"
    ntios_wln_firmwarefunc_fpath=${Wln_current_script_dir}/${ntios_wln_firmwarefunc_filename}
    ntios_wln_hostapdfunc_filename="ntios_wln_hostapdfunc.sh"
    ntios_wln_hostapdfunc_fpath=${Wln_current_script_dir}/${ntios_wln_hostapdfunc_filename}
    ntios_wln_intfstatesctxfunc_filename="ntios_wln_intfstatesctxfunc.sh"
    ntios_wln_intfstatesctxfunc_fpath=${Wln_current_script_dir}/${ntios_wln_intfstatesctxfunc_filename}
    ntios_wln_ipfunc_filename="ntios_wln_ipfunc.sh"
    ntios_wln_ipfunc_fpath=${Wln_current_script_dir}/${ntios_wln_ipfunc_filename}
    ntios_wln_iptablesfunc_filename="ntios_wln_iptablesfunc.sh"
    ntios_wln_iptablesfunc_fpath=${Wln_current_script_dir}/${ntios_wln_iptablesfunc_filename}
    ntios_wln_ipv46forwardingfunc_filename="ntios_wln_ipv46forwardingfunc.sh"
    ntios_wln_ipv46forwardingfunc_fpath=${Wln_current_script_dir}/${ntios_wln_ipv46forwardingfunc_filename}
    ntios_wln_netplanfunc_filename="ntios_wln_netplanfunc.sh"
    ntios_wln_netplanfunc_fpath=${Wln_current_script_dir}/${ntios_wln_netplanfunc_filename}
    ntios_wln_networkstartfunc_filename="ntios_wln_networkstartfunc.sh"
    ntios_wln_networkstartfunc_fpath=${Wln_current_script_dir}/${ntios_wln_networkstartfunc_filename}
    ntios_wln_networkstopfunc_filename="ntios_wln_networkstopfunc.sh"
    ntios_wln_networkstopfunc_fpath=${Wln_current_script_dir}/${ntios_wln_networkstopfunc_filename}
    ntios_wln_propertyinputfunc_filename="ntios_wln_propertyinputfunc.sh"
    ntios_wln_propertyinputfunc_fpath=${Wln_current_script_dir}/${ntios_wln_propertyinputfunc_filename}
    ntios_wln_servicesstatesetfunc_filename="ntios_wln_servicesstatesetfunc.sh"
    ntios_wln_servicesstatesetfunc_fpath=${Wln_current_script_dir}/${ntios_wln_servicesstatesetfunc_filename}
    ntios_wln_softwarefunc_filename="ntios_wln_softwarefunc.sh"
    ntios_wln_softwarefunc_fpath=${Wln_current_script_dir}/${ntios_wln_softwarefunc_filename}
    ntios_wln_subfunc_filename="ntios_wln_subfunc.sh"
    ntios_wln_subfunc_fpath=${Wln_current_script_dir}/${ntios_wln_subfunc_filename}
    ntios_wln_systemctlfunc_filename="ntios_wln_systemctlfunc.sh"
    ntios_wln_systemctlfunc_fpath=${Wln_current_script_dir}/${ntios_wln_systemctlfunc_filename}
    ntios_wln_ufwfunc_filename="ntios_wln_ufwfunc.sh"
    ntios_wln_ufwfunc_fpath=${Wln_current_script_dir}/${ntios_wln_ufwfunc_filename}
    ntios_wln_wepwpafunc_filename="ntios_wln_wepwpafunc.sh"
    ntios_wln_wepwpafunc_fpath=${Wln_current_script_dir}/${ntios_wln_wepwpafunc_filename}
    ntios_wln_wifipowersaveofffunc_filename="ntios_wln_wifipowersaveofffunc.sh"
    ntios_wln_wifipowersaveofffunc_fpath=${Wln_current_script_dir}/${ntios_wln_wifipowersaveofffunc_filename}
    ntios_wln_wpasupplicantfunc_filename="ntios_wln_wpasupplicantfunc.sh"
    ntios_wln_wpasupplicantfunc_fpath=${Wln_current_script_dir}/${ntios_wln_wpasupplicantfunc_filename}
}

#---INCLUDES
WLN_Includes() {
    source "${other_fpath}"
    source "${ntios_wln_activescanfunc_fpath}"
    source "${ntios_wln_associatefunc_fpath}"
    source "${ntios_wln_autoreconnectonboot_fpath}"
    source "${ntios_net_func_fpath}"
    source "${ntios_wln_types_fpath}"
    source "${ntios_wln_bridgeintffunc_fpath}"
    source "${ntios_wln_unbridgefunc_fpath}"
    source "${ntios_wln_channelfunc_fpath}"
    source "${ntios_wln_disablefunc_fpath}"
    source "${ntios_wln_disassociatefunc_fpath}"
    source "${ntios_wln_dnsmasqfunc_fpath}"
    source "${ntios_wln_domaincodefunc_fpath}"
    source "${ntios_wln_enablefunc_fpath}"
    source "${ntios_wln_exitfunc_fpath}"
    source "${ntios_wln_firmwarefunc_fpath}"
    source "${ntios_wln_hostapdfunc_fpath}"
    source "${ntios_wln_intfstatesctxfunc_fpath}"
    source "${ntios_wln_ipfunc_fpath}"
    source "${ntios_wln_iptablesfunc_fpath}"
    source "${ntios_wln_ipv46forwardingfunc_fpath}"
    source "${ntios_wln_netplanfunc_fpath}"
    source "${ntios_wln_networkstartfunc_fpath}"
    source "${ntios_wln_networkstopfunc_fpath}"
    source "${ntios_wln_propertyinputfunc_fpath}"
    source "${ntios_wln_softwarefunc_fpath}"
    source "${ntios_wln_servicesstatesetfunc_fpath}"
    source "${ntios_wln_subfunc_fpath}"
    source "${ntios_wln_systemctlfunc_fpath}"
    source "${ntios_wln_ufwfunc_fpath}"
    source "${ntios_wln_wepwpafunc_fpath}"
    source "${ntios_wln_wifipowersaveofffunc_fpath}"
    source "${ntios_wln_wpasupplicantfunc_fpath}"
}



#---MAIN SUBROUTINE
main__sub() {
    WLN_EnvVarLoad
    WLN_Includes
}



#---EXECUTE MAIN
main__sub
