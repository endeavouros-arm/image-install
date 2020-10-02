# image-install
Install ARM images for select SBC devices.

Currently, this will work on the Odroid N2 / N2+ the Odroid XU4 and the Raspberry Pi 4b

    
    On a working x86_64 computer, insert the latest USB EndeavourOS ISO installer.
    Use the USB EndeavourOS ISO because cleaning up directories and files created
    during the flash process is not necessary as the ISO is not persistent.  It is
    also a known safe environment and reduces the chance of borking your daily driver.
    CAUTION: Just make sure you choose the correct storage device to install to.
    
    Boot into the msdos/MBR version of the EndeavourOS installer ISO.
    Insert the USB cardreader containing the micro SD or eMMC card.
    
    IMPORTANT: Make sure ALL apps are closed, especially any file manager such as Thunar.
    
    Open a terminal window, for best results resize the window to 130 x 30 minimum or full screen
    
    $ git clone https://github.com/endeavouros-arm/image-install.git

    $ cd image-install

    $ sudo su

    # ls -l

    Check if install-image.sh is executable. If not make it executable.

    # ./install_image.sh
