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

prep__sub() {
    sudo cp ./wifi-powersave-off.service /etc/systemd/system
    echo "---:STATUS: Copied 'wifi-powersave-off.service'"
    sudo cp ./wifi-powersave-off.timer /etc/systemd/system
    echo "---:STATUS: Copied 'wifi-powersave-off.timer'"
    sudo cp ./wifi-powersave-off.sh /usr/local/bin
    echo "---:STATUS: Copied 'wifi-powersave-off.sh'"

    sudo chmod +x /usr/local/bin/wifi-powersave-off.sh
    echo "---:STATUS: Changed permission of 'wifi-powersave-off.sh'"

    sudo systemctl enable wifi-powersave-off.service
    echo "---:STATUS: Enabled 'wifi-powersave-off.service'"
    sudo systemctl start wifi-powersave-off.service
    echo "---:STATUS: Started 'wifi-powersave-off.service'"
}



main__sub() {
    checkIfisRoot__sub

    prep__sub
}



#---EXECUTE MAIN SUBROUTINE
main__sub
