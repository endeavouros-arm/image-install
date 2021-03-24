# image-install
Install ARM images for select SBC devices.

Currently, this will work on the Odroid N2 / N2+ the Odroid XU4 and the Raspberry Pi 4 series

    
    On a working Linux computer, the faster the better, insert the USB
    card reader containing the micro SD or eMMC card or external USB SSD enclosure
      Odroid N2 and Odroid XU4 the choices are micro SD card or eMMC card
      Raspberry Pi model 4b 4GB ram 64 bit OS is micro SD card only
      Raspberry Pi model 4 series 32 bit OS the choices are micro SD or external USB SSD
     
    IMPORTANT: Make sure ALL apps are closed, especially any file manager such as Thunar.
    
    Open a terminal window, for best results resize the window to 130 x 30 minimum or full screen
    In your home directory, create a Temporary directory
    
    $ mkdir Temp
    $ cd Temp
    $ git clone https://github.com/endeavouros-arm/image-install.git

    $ cd image-install

    $ ls -l

    Check if install-image-V2.X.sh is executable. If not make it executable.

    $ sudo ./install-image-V2.X.sh
    
    When completed, use a file manager to unmount the USB card reader.
