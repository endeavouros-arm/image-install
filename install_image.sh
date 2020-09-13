
#! /bin/bash

function partition_OdroidN2() {
parted --script -a minimal $devicename \
mklabel msdos \
unit mib \
mkpart primary 2MiB 258MiB \
mkpart primary 258MiB $devicesize"MiB" \
quit
}

function partition_RPi4() {
parted --script -a minimal $devicename \
mklabel msdos \
unit mib \
mkpart primary 2MiB 151MiB \
mkpart primary 152MiB $devicesize"MiB" \
quit
}

function install_OdroidN2_image() {
wget http://os.archlinuxarm.org/os/ArchLinuxARM-odroid-n2-latest.tar.gz
printf "\n\n${CYAN}Untarring the image...might take a few minutes.${NC}\n"
bsdtar -xpf ArchLinuxARM-odroid-n2-latest.tar.gz -C MP2
mv MP2/boot/* MP1
dd if=MP1/u-boot.bin of=$devicename conv=fsync,notrunc bs=512 seek=1
while true
do
   printf "\n\nIs the target device a eMMC card? [y,n] "
   read answer
   answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
   case $answer in
      [y]* ) sed -i 's/mmcblk0/mmcblk1/g' MP2/etc/fstab
              break
              ;;
       [n]* ) break
              ;;
       * )    printf "\nTry again, Enter [y,n] :\n"
              true="false"
              ;;
   esac
done  
}   # End of function install_OdroidN2_image

function install_RPi4_image() {
wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
printf "\n\n${CYAN}Untarring the image...may take a few minutes.${NC}\n"
bsdtar -xpf ArchLinuxARM-rpi-aarch64-latest.tar.gz -C MP2
printf "\n\n${CYAN}Syncing partitions...may take a few minutes.${NC}\n"
sync
mv MP2/boot/* MP1
sed -i 's/mmcblk0/mmcblk1/g' MP2/etc/fstab
}  # End of function install_RPi4_image

function partition_format() {
finished=1
base_dialog_content="The following storage devices were found\n\n$(lsblk -o NAME,FSTYPE,FSUSED,FSAVAIL,SIZE,MOUNTPOINT)\n\n \
Enter target device name (e.g. /dev/sda):"
dialog_content="$base_dialog_content"
while [ $finished -ne 0 ]
do
    devicename=$(whiptail --title "EndeavourOS ARM Setup - micro SD Configuration" --inputbox "$dialog_content" 25 80 3>&2 2>&1 1>&3)
   exit_status=$?
   if [ $exit_status == "1" ]; then
      return
   fi
   if [[ ${devicename:0:5} != "/dev/" ]]; then 
      dialog_content="Input improperly formatted. Try again.\n\n$base_dialog_content"
   elif [[ ! -b "$devicename" ]]; then  
      dialog_content="Not a block device. Try again.\n\n$base_dialog_content"
   else 
      finished=0
   fi
done    



  ##### Determine data device size in MiB and partition ###
  printf "\n${CYAN}Partitioning, & formatting storage device...${NC}\n"
  devicesize=$(fdisk -l | grep "Disk $devicename" | awk '{print $5}')
  ((devicesize=$devicesize/1048576))
  ((devicesize=$devicesize-1))  # for some reason, necessary for USB thumb drives
  printf "\n${CYAN}Partitioning storage device $devicename...${NC}\n"
#  message="\nPartitioning DATA device $devicename  "
  printf "\ndevicename = $devicename     devicesize=$devicesize\n" >> /root/enosARM.log

 # umount partitions before partitioning and formatting
 lsblk $devicename -o MOUNTPOINT | grep /run/media > mounts
 count=$(wc -l mounts | awk '{print $1}')
 if [ $count -gt 0 ]
 then
    for ((i = 1 ; i <= $count ; i++))
    do
      u=$(awk -v "x=$i" 'NR==x' mounts)
    umount $u
    done
 fi
 rm mounts
 

  if [[ $devicemodel = "OdroidN2" ]]
  then
     partition_OdroidN2
  fi
  if [[ $devicemodel = "RPi4" ]]
  then
     partition_RPi4 
  fi
  
  if [[ ${devicename:5:4} = "nvme" ]]
  then
    partname=$devicename"p"
  else
    partname=$devicename
  fi
  
  
  printf "\npartition name = $devicename\n\n" >> /root/enosARM.log
  printf "\n${CYAN}Formatting storage device $devicename...${NC}\n"
  printf "\n${CYAN}If ${RED}\"/dev/sdx contains a ext4 file system Labelled XXXX\"${CYAN} or similar appears, Enter: y${NC}\n\n\n"
#  message="\nFormatting storage device $mntname   "
  partname1=$partname"1"
  mkfs.vfat -F32 $partname1   2>> /root/enosARM.log
  partname2=$partname"2"
  mkfs.ext4 $partname2   2>> /root/enosARM.log
#  e2label $partname2 ROOT
} # end of function partition_format

#################################################
# beginning of script
#################################################


# Declare following global variables
# uefibootstatus=20
arch="e"
returnanswer="a"
prompt="b"
message="c"
verify="d"
# osdevicename="e"
# sshport=3
username="a"

# Declare color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


# script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# if [[ "$script_directory" == "/home/$USER/"* ]]; then
#   whiptail_installed=$(pacman -Qs libnewt)
#   if [[ "$whiptail_installed" != "" ]]; then 
#      whiptail --title "Error - Cannot Continue" --msgbox "This script is in the $USER user's home folder which will be removed.  \
#      \n\nPlease move it to the root user's home directory and rerun the script." 10 80
#      exit
#   else 
#      printf "${RED}Error - Cannot Continue. This script is in the $USER user's home folder which will be removed. Please move it to the root user's home directory and rerun the script.${NC}\n"
#      exit
#   fi
# fi

##### check to see if script was run as root #####

if [ $(id -u) -ne 0 ]
then
   whiptail_installed=$(pacman -Qs libnewt)
   if [[ "$whiptail_installed" != "" ]]; then 
      whiptail --title "Error - Cannot Continue" --msgbox "Please run this script as root" 8 47
      exit
   else 
      printf "${RED}Error - Cannot Continue. Please run this script with as root.${NC}\n"
      exit
   fi
fi

# Prevent script from continuing if there's any processes running under the alarm user #
# as we won't be able to delete the user later on in the script #

#if [[ $(pgrep -u $USER) != "" ]]; then
#   whiptail_installed=$(pacman -Qs libnewt)
#   if [[ "$whiptail_installed" != "" ]]; then 
#      whiptail --title "Error - Cannot Continue" --msgbox "user $USER still has processes running. Kill #them to continue setup." 8 47
#      exit
#   else 
#      printf "${RED}Error - Cannot Continue. user $USER still has processes running. Kill them to #continue setup.${NC}\n"
#      exit
#   fi
#fi

dmesg -n 1 # prevent low level kernel messages from appearing during the script
# create empty /root/enosARM.log
printf "    LOGFILE\n\n" > /root/enosARM.log


armarch="$(uname -m)"
case "$armarch" in
        armv7*) armarch=armv7h ;;
esac

pacman -S --noconfirm --needed libnewt # for whiplash dialog

devicemodel=$(whiptail --title " SBC type Selection" --menu --notags "            Choose which SBC to install or Press right arrow twice to cancel" 17 100 9 \
         "0" "Odroid N2 or N2+" \
         "1" "Raspberry Pi Model 4b" \
         3>&2 2>&1 1>&3)

   if [[ "$devicemodel" = "" ]]
   then
      printf "\n\n${RED}script aborted..${NC}\n\n" && exit
   else
      case $devicemodel in
         0) devicemodel="OdroidN2" ;;
         1) devicemodel="RPi4" ;;
      esac
  fi

 partition_format  # function to partition and format a micro SD card or eMMC card


mkdir MP1
mkdir MP2
mount $partname1 MP1
mount $partname2 MP2
chown root:root MP1 MP2


 printf "\n${CYAN}Break Point ..Check ownership of MP1 and MP2 should be root root, if not formatting failed\n...Hit any key${NC}\n\n"
 ls -al
 read z

if [ "$devicemodel" = "OdroidN2" ]
then
   install_OdroidN2_image
fi

if [ "$devicemodel" = "RPi4" ]
then
   install_RPi4_image
fi

umount MP1 MP2


rm -rf MP1 MP2
rm ArchLinuxARM*
# cd /root
# rm -rf test

printf "\n\nEnd of script!\n"
printf "\nBe sure to use a file manager to umount the device before removing the USB SD reader\n"

exit

