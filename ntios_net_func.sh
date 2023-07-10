#!/bin/bash
#---FUNCTIONS
NET_PropertyInput() {
    #NET-OBJECT
    net_eth0_dhcp="false"
    net_eth0_ip="172.31.1.9"
    net_eth0_netmask="24"
    net_eth0_dns1="${NET_GOOGLE_DNSV4_8888}"
    net_eth0_dns2="172.31.1.254"
    net_eth0_gatewayip="${net_eth0_dns2}"

    net_eth0_dhcpv6="false"
    net_eth0_ipv6="2023:172:31:1::9"
    net_eth0_netmaskv6="64"
    net_eth0_dns1v6="${NET_GOOGLE_DNSV6_8888}"
    net_eth0_dns2v6="2023:172:31:1::254"
    net_eth0_gatewayipv6="${net_eth0_dns2v6}"

    net_eth1_dhcp="true"
    net_eth1_ip=${WLN_EMPTYSTRING}
    net_eth1_netmask=${WLN_EMPTYSTRING}
    net_eth1_dns1=${WLN_EMPTYSTRING}
    net_eth1_dns2=${WLN_EMPTYSTRING}
    net_eth1_gatewayip=${WLN_EMPTYSTRING}

    net_eth1_dhcpv6="true"
    net_eth1_ipv6=${WLN_EMPTYSTRING}
    net_eth1_netmaskv6=${WLN_EMPTYSTRING}
    net_eth1_dns1v6=${WLN_EMPTYSTRING}
    net_eth1_dns2v6=${WLN_EMPTYSTRING}
    net_eth1_gatewayipv6=${WLN_EMPTYSTRING}
}

NetplanYamlGenerator() {
    #***ntios version of this function already exist***

    local eth0_yaml_content="network:\n"
    eth0_yaml_content+="${WLN_TWOSPACES}version: 2\n"
    eth0_yaml_content+="${WLN_TWOSPACES}renderer: networkd\n"
    eth0_yaml_content+="${WLN_TWOSPACES}ethernets:\n"
    eth0_yaml_content+="${WLN_FOURSPACES}eth0:\n"
    if [[ ${net_eth0_dhcp} == true ]]; then
        eth0_yaml_content+="${WLN_SIXSPACES}dhcp4: ${net_eth0_dhcp}\n"
    else
        eth0_yaml_content+="${WLN_SIXSPACES}addresses: [${net_eth0_ip}/${net_eth0_netmask}]\n"
        eth0_yaml_content+="${WLN_SIXSPACES}nameservers:\n"
        eth0_yaml_content+="${WLN_EIGHTSPACES}addresses: [${net_eth0_dns1}, ${net_eth0_dns2}]\n"
        eth0_yaml_content+="${WLN_SIXSPACES}routes:\n"
        eth0_yaml_content+="${WLN_EIGHTSPACES}- to: ${NET_IPV4_ANYROUTE}\n"
        eth0_yaml_content+="${WLN_TENSPACES}via: ${net_eth0_gatewayip}\n"
        eth0_yaml_content+="${WLN_TENSPACES}metric: ${NET_METRIC_0}\n"
    fi
    if [[ ${net_eth0_dhcpv6} == true ]]; then
        eth0_yaml_content+="${WLN_SIXSPACES}dhcp6: ${net_eth0_dhcpv6}\n"
    else
        eth0_yaml_content+="${WLN_SIXSPACES}addresses: [${net_eth0_ipv6}/${net_eth0_netmaskv6}]\n"
        eth0_yaml_content+="${WLN_SIXSPACES}nameservers:\n"
        eth0_yaml_content+="${WLN_EIGHTSPACES}addresses: [${net_eth0_dns1v6}, ${net_eth0_dns2v6}]\n"
        eth0_yaml_content+="${WLN_SIXSPACES}routes:\n"
        eth0_yaml_content+="${WLN_EIGHTSPACES}- to: ${NET_IPV6_ANYROUTE}\n"
        eth0_yaml_content+="${WLN_TENSPACES}via: ${net_eth0_gatewayipv6}\n"
        eth0_yaml_content+="${WLN_TENSPACES}metric: ${NET_METRIC_10}\n"
    fi

    local eth1_yaml_content="network:\n"
    eth1_yaml_content+="${WLN_TWOSPACES}version: 2\n"
    eth1_yaml_content+="${WLN_TWOSPACES}renderer: networkd\n"
    eth1_yaml_content+="${WLN_TWOSPACES}ethernets:\n"
    eth1_yaml_content+="${WLN_FOURSPACES}eth1:\n"
    if [[ ${net_eth1_dhcp} == true ]]; then
        eth1_yaml_content+="${WLN_SIXSPACES}dhcp4: true\n"
    else
        eth1_yaml_content+="${WLN_SIXSPACES}addresses: [${net_eth1_ip}/${net_eth1_netmask}]\n"
        eth1_yaml_content+="${WLN_SIXSPACES}nameservers:\n"
        eth1_yaml_content+="${WLN_EIGHTSPACES}addresses: [${net_eth1_dns1}, ${net_eth1_dns2}]\n"
        eth1_yaml_content+="${WLN_SIXSPACES}routes:\n"
        eth1_yaml_content+="${WLN_EIGHTSPACES}- to: ${NET_IPV4_ANYROUTE}\n"
        eth1_yaml_content+="${WLN_TENSPACES}via: ${net_eth1_gatewayip}\n"
        eth1_yaml_content+="${WLN_TENSPACES}metric: ${NET_METRIC_0}\n"
    fi
    if [[ ${net_eth1_dhcp} == true ]]; then
        eth1_yaml_content+="${WLN_SIXSPACES}dhcp6: ${net_eth1_dhcpv6}\n"
    else
        eth1_yaml_content+="${WLN_SIXSPACES}addresses: [${net_eth1_ipv6}/${net_eth1_netmaskv6}]\n"
        eth1_yaml_content+="${WLN_SIXSPACES}nameservers:\n"
        eth1_yaml_content+="${WLN_EIGHTSPACES}addresses: [${net_eth1_dns1v6}, ${net_eth1_dns2v6}]\n"
        eth1_yaml_content+="${WLN_SIXSPACES}routes:\n"
        eth1_yaml_content+="${WLN_EIGHTSPACES}- to: ${NET_IPV6_ANYROUTE}\n"
        eth1_yaml_content+="${WLN_TENSPACES}via: ${net_eth1_gatewayipv6}\n"
        eth1_yaml_content+="${WLN_TENSPACES}metric: ${NET_METRIC_10}\n"
    fi

    #Combine eth0_yaml_content and eth1_yaml_content
    local net_yaml_content="${eth0_yaml_content}"
    net_yaml_content+="${eth1_yaml_content}"

    #Remove '*.yaml'
    #Remark:
    #   variable 'ret' is used here to suppress the 'echo "${ret}"' of the function.
    local ret=$(RemoveFile "${WLN_NET_YAML_FPATH}")

    #Write to file
    #Remark:
    #   variable 'ret' is used here to suppress the 'echo "${ret}"' of the function.
    ret=$(WriteToFile "${WLN_NET_YAML_FPATH}" "${net_yaml_content}" "true")
}

NetplanApply() {
    local ret=$(CmdExec "${WLN_NETPLAN_APPLY}")
}
NET_apply() {
    #Generate '*.yaml'
    NetplanYamlGenerator

    #Netplay apply
    #Remark:
    #   Commented out netplan apply here, because later on netplan will be applied in 'WLN_Netplan_Handler'
    # NetplanApply
}

NET_Property_Netplan_Handler() {
    NET_PropertyInput

    NET_apply
}
