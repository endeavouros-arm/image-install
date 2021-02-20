# image-install
Install ARM images for select SBC devices.

Currently, this will work on the Odroid N2 / N2+ the Odroid XU4 the Raspberry Pi 4b and the Raspberry Pi 400

    
    On a working Linux computer, the faster the better, insert the USB
    card reader containing the micro SD or eMMC card or external USB SSD enclosure
      Odroid N2 and Odroid XU4 the choices are micro SD card or eMMC card
      Raspberry Pi model 4b 4 GB ram 64 bit is micro SD card only
      Raspberry Pi model 4b 4 GB/8 GB ram and Raspberry Pi 400 32 Bit the choices are micro SD or USB SSD
     
    IMPORTANT: Make sure ALL apps are closed, especially any file manager such as Thunar.
    
    Open a terminal window, for best results resize the window to 130 x 30 minimum or full screen
    In your home directory, create a Temporary directory
    
    $ mkdir Temp
    $ cd Temp
    $ git clone https://github.com/endeavouros-arm/image-install.git

    $ cd image-install

    $ ls -l

    Check if install-image-V2.3.sh is executable. If not make it executable.

    $ sudo ./install-image-V2.3.sh
    
    When completed, use a file manager to unmount the USB card reader.
