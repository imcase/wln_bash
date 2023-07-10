#!/bin/bash
#---SUBROUTINES
checkIfisRoot__sub()
{
    #Define Local variables
    local currUser=`whoami`

    #Check if user is 'root'
    if [[ ${currUser} != "root" ]]; then   #not root
        echo -e ""
        echo "***USER IS NOT SUDO OR ROOT"
        echo "***Please run script with 'sudo'"
        echo -e ""

        exit 99
    fi
}



unprep__sub() {
    sudo systemctl stop wifi-powersave-off.service
    echo "---:STATUS: Stopped 'wifi-powersave-off.service'"
    sudo systemctl disable wifi-powersave-off.service
    echo "---:STATUS: Disabled 'wifi-powersave-off.service'"

    sudo rm /etc/systemd/system/wifi-powersave-off.service
    echo "---:STATUS: Removed 'wifi-powersave-off.service'"
    sudo rm /etc/systemd/system/wifi-powersave-off.timer
    echo "---:STATUS: Removed 'wifi-powersave-off.timer'"
    sudo rm /usr/local/bin/wifi-powersave-off.sh
    echo "---:STATUS: Removed 'wifi-powersave-off.sh'"

    
}



main__sub() {
    checkIfisRoot__sub

    unprep__sub

}



#---EXECUTE MAIN SUBROUTINE
main__sub
