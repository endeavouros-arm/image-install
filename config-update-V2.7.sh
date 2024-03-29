#!/bin/bash

_check_if_root() {
    if [ $(id -u) -ne 0 ]
    then
      printf "\n\n${RED}PLEASE RUN THIS SCRIPT AS ROOT OR WITH SUDO${NC}\n\n"
      exit
    fi
}   # end of function _check_if_root


_enable_wifi() {

    printf "[Match]\nName=wlan*\n\n[Network]\nDHCP=yes\nDNSSEC=no\n" > /etc/systemd/network/wlan.network

    whiptail  --title "EndeavourOS ARM Setup - Enable WiFi"  --yesno --defaultno "             It is always best to use a wired Ethernet connection.\n            But sometimes a wired connection is just not available.\n         Do you want to enable WiFi for the rest of the installation?\n\n" 10 80 15 3>&2 2>&1 1>&3

#    systemctl enable --now netctl.service
#    sleep 4
    case $? in
        0) readarray -t regdom < countrycodes
           domain=$(whiptail --title "EndeavourOS ARM Setup - Regulatory Domain" --menu "\n                 Please choose your WiFi Regulatory Domain.\n You can navigate to different sections with Page Up/Down or the A-Z keys." 30 80 20 \
              "${regdom[@]}" "" \
           3>&1 1>&2 2>&3)
           domain=$(echo $domain | awk '{print $1}')
           old="#WIRELESS_REGDOM=\"$domain\""
           new="WIRELESS_REGDOM=\"$domain\""
           sed -i "s|$old|$new|g" /etc/conf.d/wireless-regdom
           nmtui ;;
        1) clear ;;
    esac
}

_check_internet_connection() {
    printf "\n${CYAN}Checking Internet Connection...${NC}\n\n"
    ping -c 3 endeavouros.com -W 5
    if [ "$?" != "0" ]
    then
       printf "\n\n${RED}No Internet Connection was detected\nFix your Internet Connectin and try again${NC}\n\n"
       exit
    fi
}   # end of function _check_internet_connection

_edit_mirrorlist() {
    local user_confirmation
    local changes
    local mirrors
    local mirror1
    local old
    local new
    local file
    local str

    whiptail  --title "EndeavourOS ARM Setup - mirrorlist"  --yesno "     Mirrorlist uses a Geo-IP based mirror selection and load balancing.\n     Do you wish to override this and choose mirrors near you?\n\n" 8 80 3>&2 2>&1 1>&3
    user_confirmation=$?
    changes=0
    while [ "$user_confirmation" == "0" ]
    do
        tail -n +11 /etc/pacman.d/mirrorlist | grep -e ^"###" -e ^"# S" -e^"  S"  > tmp-mirrorlist
        readarray -t mirrors < tmp-mirrorlist

        mirror1=$(whiptail --cancel-button 'Done' --notags --title "EndeavourOS ARM Setup - Mirror Selection" --menu  \ "Please choose a mirror to enable.\n Only choose lines starting with: \"# Server\" or \"  Server\"\n The chosen item will be toggled between commented and uncommented.\n Note: You can navigate to different sections with Page Up/Down keys.\n When finished selecting, press right arrow key twice" 30 80 18 \
           "${mirrors[0]}" "${mirrors[0]}" \
           "${mirrors[1]}" "${mirrors[1]}" \
           "${mirrors[2]}" "${mirrors[2]}" \
           "${mirrors[3]}" "${mirrors[3]}" \
           "${mirrors[4]}" "${mirrors[4]}" \
           "${mirrors[5]}" "${mirrors[5]}" \
           "${mirrors[6]}" "${mirrors[6]}" \
           "${mirrors[7]}" "${mirrors[7]}" \
           "${mirrors[8]}" "${mirrors[8]}" \
           "${mirrors[9]}" "${mirrors[9]}" \
           "${mirrors[10]}" "${mirrors[10]}" \
           "${mirrors[11]}" "${mirrors[11]}" \
           "${mirrors[12]}" "${mirrors[12]}" \
           "${mirrors[13]}" "${mirrors[13]}" \
           "${mirrors[14]}" "${mirrors[14]}" \
           "${mirrors[15]}" "${mirrors[15]}" \
           "${mirrors[16]}" "${mirrors[16]}" \
           "${mirrors[17]}" "${mirrors[17]}" \
           "${mirrors[18]}" "${mirrors[18]}" \
           "${mirrors[19]}" "${mirrors[19]}" \
           "${mirrors[20]}" "${mirrors[20]}" \
           "${mirrors[21]}" "${mirrors[21]}" \
           "${mirrors[22]}" "${mirrors[22]}" \
           "${mirrors[23]}" "${mirrors[23]}" \
           "${mirrors[24]}" "${mirrors[24]}" \
           "${mirrors[25]}" "${mirrors[25]}" \
           "${mirrors[26]}" "${mirrors[26]}" \
           "${mirrors[27]}" "${mirrors[27]}" \
           "${mirrors[28]}" "${mirrors[28]}" \
           "${mirrors[29]}" "${mirrors[29]}" \
           "${mirrors[30]}" "${mirrors[30]}" \
           "${mirrors[31]}" "${mirrors[31]}" \
           "${mirrors[32]}" "${mirrors[32]}" \
           "${mirrors[33]}" "${mirrors[33]}" \
           "${mirrors[34]}" "${mirrors[34]}" \
           "${mirrors[35]}" "${mirrors[35]}" \
        3>&2 2>&1 1>&3)
        user_confirmation=$?
        if [ "$user_confirmation" == "0" ]; then
           str=${mirror1:0:8}
           case $str in
              "# Server") changes=$((changes+1))
                          old=${mirror1::-12}
                          new=${old/["#"]/" "}
                          sed -i "s|$old|$new|g" /etc/pacman.d/mirrorlist ;;
              "  Server") changes=$((changes+1))
                          old=${mirror1::-12}
                          new=${old/[" "]/"#"}
                          sed -i "s|$old|$new|g" /etc/pacman.d/mirrorlist ;;
                       *) whiptail  --title "EndeavourOS ARM Setup - ERROR"  --msgbox "     You have selected an item that cannot be edited. Please try again.\n     Only select lines that start with \"# Server\" or \"  Server\"\n     Other items are invalid.\n\n" 10 80 3>&2 2>&1 1>&3
           esac
        fi
    done

    if [ $changes -gt 0 ]; then
       sed -i 's|Server = http://mirror.archlinuxarm.org|# Server = http://mirror.archlinuxarm.org|' /etc/pacman.d/mirrorlist
    fi
    file="tmp-mirrorlist"
    if [ -f "$file" ]; then
       rm tmp-mirrorlist
    fi
}   # end of function _edit_mirrorlist


_enable_paralleldownloads() {
    local user_confirmation
    local numdwn
    local new

    whiptail  --title "EndeavourOS ARM Setup - Parallel Downloads"  --yesno "             By default, pacman has Parallel Downloads disabled.\n             Do you wish to enable Parallel Downloads?\n\n" 8 80 15 3>&2 2>&1 1>&3

    user_confirmation=$?
    if [ "$user_confirmation" == "0" ]; then
       numdwn=$(whiptail --title "EndeavourOS ARM Setup - Parallel Downloads" --menu --notags "           When enabled, Pacman has 5 Parallel Downloads as a default.\n           How many Parallel Downloads do you wish? \n\n" 20 80 10 \
         "2" " 2 Parallel Downloads" \
         "3" " 3 Parallel Downloads" \
         "4" " 4 Parallel Downloads" \
         "5" " 5 Parallel Downloads" \
         "6" " 6 Parallel Downloads" \
         "7" " 7 Parallel Downloads" \
         "8" " 8 Parallel Downloads" \
         "9" " 9 Parallel Downloads" \
         "10" "10 Parallel Downloads" \
       3>&2 2>&1 1>&3)
    fi

    if [[ $numdwn -gt 1 ]]; then
       new="ParallelDownloads = $numdwn"
       sed -i "s|#ParallelDownloads = 5|$new|g" /etc/pacman.conf
    fi
}   # end of function _enable_paralleldownloads

_finish_up() {
    printf "\n\n${CYAN}Near the end of the script, the last pacman hook will display:\n\n${NC}Warn about old perl modules${CYAN}\n\nAt this point there might be a long delay\nThat is OK, please be patient.${NC}\n\n"
    sleep 5
    pacman -Syu --noconfirm
    rm $CONFIG_UPDATE
    if [ -f "countrycodes" ]; then  # if file countrycodes exits, delete it
       rm countrycodes
    fi
    git clone https://github.com/endeavouros-arm/install-script.git
    printf "\n\n${CYAN}Your Device is ready for installation of a Desktop Environment or Windows Manager.\n\nPress Return to reboot.${NC}\n"
    read -n 1 z
    systemctl reboot
}   # end of function _finish_up

######################   Start of Script   #################################
Main() {

      CONFIG_UPDATE="config-update-V2.7.sh"
      # Declare color variables
      GREEN='\033[0;32m'
      RED='\033[0;31m'
      CYAN='\033[0;36m'
      NC='\033[0m' # No Color

   # STARTS HERE
   dmesg -n 1 # prevent low level kernel messages from appearing during the script
   _check_if_root
   _enable_wifi
   _check_internet_connection
   pacman-key --init
   pacman-key --populate archlinuxarm
   pacman -Syy
   pacman -S --noconfirm --needed libnewt   # libnewt necessary for whiptail
   _edit_mirrorlist
   _enable_paralleldownloads
   _finish_up

}  # end of Main

Main "$@"
