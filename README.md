# image-install
Install ARM images

Install base-install images for select SBC devices

    
    On a working x86_64 computer, insert the latest USB EndeavourOS ISO installer. Use the USB EndeavourOS ISO because
    cleaning up directories and files created during the flash process is not necessary as the ISO is not persistent.
    It is also a known safe environment and eliminates any chance of borking your daily driver machine.
    
    Boot into the msdos/MBR version of the EndeavourOS installer ISO.  Insert the USB cardreader containing the micro SD or eMMC card.
    
    Make a temporary folder in the liveuser home directory.

    Change Directory to the folder you just made

    $ git clone https://github.com/endeavouros-arm/image-install.git

    Change Directory to image-install

    $ sudo su

    # ls -l

    Check if install-image.sh is executable. If not make it executable.

    # ./install_image.sh
