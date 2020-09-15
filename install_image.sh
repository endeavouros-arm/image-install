
#! /bin/bash

function partition_OdroidN2() {
   parted --script -a minimal $devicename \
   mklabel msdos \
   unit mib \
   mkpart primary fat32 2MiB 258MiB \
   mkpart primary 258MiB $devicesize"MiB" \
   quit
}

function partition_RPi4() {
   parted --script -a minimal $devicename \
   mklabel msdos \
   unit mib \
   mkpart primary fat32 2MiB 258MiB \
   mkpart primary 258MiB $devicesize"MiB" \
   quit
}

function partition_OdroidXU4() {
   parted --script -a minimal $devicename \
   mklabel msdos \
   unit mib \
   mkpart primary 2MiB $devicesize"MiB" \
   quit
}

function install_OdroidN2_image() {
   wget http://os.archlinuxarm.org/os/ArchLinuxARM-odroid-n2-latest.tar.gz
   printf "\n\n${CYAN}Untarring the image...might take a few minutes.${NC}\n"
   bsdtar -xpf ArchLinuxARM-odroid-n2-latest.tar.gz -C MP2
   mv MP2/boot/* MP1
   dd if=MP1/u-boot.bin of=$devicename conv=fsync,notrunc bs=512 seek=1

   # for Odroid N2 ask if storage device is micro SD or eMMC
   whiptail  --title "EndeavourOS ARM Setup"  --yesno "                   Is the target device an eMMC card?" 7 80 
   user_confirmation="$?"
   if [ $user_confirmation == "0" ]
   then
      sed -i 's/mmcblk1/mmcblk0/g' MP2/etc/fstab
   fi    
}   # End of function install_OdroidN2_image

function install_RPi4_image() {
   wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
   # wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-4-latest.tar.gz
   printf "\n\n${CYAN}Untarring the image...may take a few minutes.${NC}\n"
   bsdtar -xpf ArchLinuxARM-rpi-aarch64-latest.tar.gz -C MP2
   # bsdtar -xpf ArchLinuxARM-rpi-4-latest.tar.gz -C MP2
   printf "\n\n${CYAN}Syncing partitions...may take a few minutes.${NC}\n"
   sync
   mv MP2/boot/* MP1
   sed -i 's/mmcblk0/mmcblk1/g' MP2/etc/fstab
}  # End of function install_RPi4_image

function install_OdroidXU4_image() {
   wget http://os.archlinuxarm.org/os/ArchLinuxARM-odroid-xu3-latest.tar.gz
   printf "\n\n${CYAN}Untarring the image...might take a few minutes.${NC}\n"
   bsdtar -xpf ArchLinuxARM-odroid-xu3-latest.tar.gz -C MP1
   cd MP1/boot
   sh sd_fusing.sh $devicename
   cd ../..   
}   # End of function install_OdroidN2_image

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
      printf "\nScript aborted by user\n\n"
      exit
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
   case $devicemodel in
       OdroidN2)  partition_OdroidN2 ;;
       OdroidXU4) partition_OdroidXU4 ;;
       RPi4)      partition_RPi4 ;;
   esac
   printf "\npartition name = $devicename\n\n" >> /root/enosARM.log
   printf "\n${CYAN}Formatting storage device $devicename...${NC}\n"
   printf "\n${CYAN}If \"/dev/sdx contains a ext4 file system Labelled XXXX\" or similar appears, Enter: y${NC}\n\n\n"
   case $devicemodel in
      OdroidN2 | RPi4) partname1=$devicename"1"
                       mkfs.fat $partname1   2>> /root/enosARM.log
                       partname2=$devicename"2"
                       mkfs.ext4 $partname2   2>> /root/enosARM.log ;;
      OdroidXU4)       partname1=$devicename"1"
                       mkfs.ext4 $partname1  2>> /root/enosARM.log ;;
   esac
} # end of function partition_format

#################################################
# beginning of script
#################################################

# Declare color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


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

dmesg -n 1 # prevent low level kernel messages from appearing during the script
# create empty /root/enosARM.log
printf "    LOGFILE\n\n" > /root/enosARM.log


armarch="$(uname -m)"
case "$armarch" in
        armv7*) armarch=armv7h ;;
esac

pacman -S --noconfirm --needed libnewt # for whiplash dialog

devicemodel=$(whiptail --title " SBC type Selection" --menu --notags "            Choose which SBC to install or Press right arrow twice to cancel" 17 100 4 \
         "0" "Odroid N2 or N2+" \
         "1" "Odroid XU4" \
         "2" "Raspberry Pi Model 4b" \
         3>&2 2>&1 1>&3)

if [[ "$devicemodel" = "" ]]
  then
     printf "\n\nScript aborted by user..${NC}\n\n" && exit
  else
     case $devicemodel in
         0) devicemodel="OdroidN2" ;;
         1) devicemodel="OdroidXU4" ;;
         2) devicemodel="RPi4" ;;
     esac
fi


partition_format  # function to partition and format a micro SD card or eMMC card


case $devicemodel in
   OdroidN2 | RPi4)  mkdir MP1
                     mkdir MP2 
                     mount $partname1 MP1
                     mount $partname2 MP2 ;;
   OdroidXU4)        mkdir MP1
                     mount $partname1 MP1 ;;
esac

case $devicemodel in
   OdroidN2)  install_OdroidN2_image ;;
   OdroidXU4) install_OdroidXU4_image ;;
   RPi4)      install_RPi4_image ;;
esac

printf "\n\nAlmost done! Just a couple of minutes more for the last step.\n\n"
case $devicemodel in
   OdroidN2 | RPi4) umount MP1 MP2
                    rm -rf MP1 MP2 ;;
   OdroidXU4)       umount MP1
                    rm -rf MP1 ;;
esac

rm ArchLinuxARM*

printf "\n\nEnd of script!\n"
printf "\nBe sure to use a file manager to umount the device before removing the USB SD reader\n"

printf "\nThe default user is alarm with the password alarm\n"
printf "The default root password is root\n\n\n"

exit

