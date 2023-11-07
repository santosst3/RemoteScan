#!/bin/bash

function printheader {
    clear
    echo -------------------------------------------------------------------------------
    echo --------------------------------- REMOTE SCAN ---------------------------------
    echo ----------- Automates remote scanning from a local server using SSH -----------
    echo -------------------------------------------------------------------------------
    echo 
}

function firstuse {
	echo This is the first time you are running this application.
	echo What is the IP address of the server?  
	read ip_address
	varset = 1
	while [varset]
	do
		echo This was the informed IP address of the server:
		echo $ip_address
		echo Is this information correct? 1-yes, 0-no:
		read cond
		if [ "$cond" -eq 1 ]; then
			varset = 0
		fi
	done
	echo $ip_address > .server_address
	sleep 1
	printheader
}

#function scan_photo {}

#function scan_doc {}


# Argument verification
if [ $# -ne 0 ]; # No arguments!
  then
   echo You must provide the name of the system image file you want to edit! 
   exit 1
fi
if [ ! -f "$1" ]; # If the given file name is wrong
  then
   echo The provided file name does not exist! Please, try again.
   exit 1
fi

# First use check
if [ ! -f .server_address ]; then
	firstuse
fi

# Function selection
printheader
echo Which kind of archive do you want to scan? Choose a number 1-2:
echo 1.  Photo    (.jpg file)
echo 2.  Document (.pdf file)
read selection

if [ "$selection" -eq 1 ]; then
    echo Photo scanning selected.
    sleep 1
    scan_photo
elif [ "$selection" -eq 2 ]; then
    echo Document scanning selected.
    sleep 1
    scan_doc
else
    echo Invalid input, try again.
    exit 1
fi

# Mounting the chosen system image
printheader $1 "$chosenvndk"
echo Now we will create a folder to mount the system image.
echo You may need to provide your user password to continue:
sudo rm -rf Extracted_system
mkdir Extracted_system
if [[ $(file $1 | grep sparse) ]]; then
    simg2img $1 EDITED_$1
else
    cp $1 EDITED_$1
fi
e2fsck -y -f EDITED_$1
resize2fs EDITED_$1 3500M
e2fsck -E unshare_blocks -y -f EDITED_$1
sudo mount -o loop,rw EDITED_$1 Extracted_system

# Editing the chosen system image
printheader $1 "$chosenvndk"
echo Would you like to remove the VNDK libs other than the chosen one? 1-yes, anythingelse-no:
read rmlibs
if [ "$rmlibs" -eq 1 ]; then
    if [ -d "Extracted_system/vendor" ]; then  
        sudo find Extracted_system/system/system_ext/apex/ -type d \( -name "com.android.vndk.v*" \! -name "*.$chosenvndk_resumed" \) -exec rm -rf {} \;
        sudo find Extracted_system/system/system_ext/apex/ -type f \( -name "com.android.vndk.v*.apex" \! -name "*.$chosenvndk_resumed.apex" \) -exec rm -rf {} \;
        sudo find Extracted_system/system/lib/ -type d \( -name "vndk-*" \! -name "*$chosenvndk_number" \) -exec rm -rf {} \;
        sudo find Extracted_system/system/lib64/ -type d \( -name "vndk-*" \! -name "*.$chosenvndk_number" \) -exec rm -rf {} \;
    else
        sudo find Extracted_system/system_ext/apex/ -type d \( -name "com.android.vndk.v*" \! -name "*.$chosenvndk_resumed" \) -exec rm -rf {} \;
        sudo find Extracted_system/system_ext/apex/ -type f \( -name "com.android.vndk.v*.apex" \! -name "*.$chosenvndk_resumed.apex" \) -exec rm -rf {} \;
        sudo find Extracted_system/lib/ -type d \( -name "vndk-*" \! -name "*$chosenvndk_number" \) -exec rm -rf {} \;
        sudo find Extracted_system/lib64/ -type d \( -name "vndk-*" \! -name "*.$chosenvndk_number" \) -exec rm -rf {} \;
    fi
    echo Done, those libraries were removed!
fi
echo If you want to add an overlay file to your modded GSI image, put the apk file in this folder.
echo Would you like to add an overlay file? 1-yes, anythingelse-no:
read addoverlay
if [ "$addoverlay" -eq 1 ]; then
    COUNT=0
    for i in "ls -1 treble-overlay-*.apk"
    do
        COUNT=$((COUNT+1))
    done
    if [ "$COUNT" -eq 0 ]; then
        echo No overlay file found!
    elif [ "$COUNT" -eq 1 ]; then
        thefile=$(ls -1 treble-overlay-*.apk)
        if [ -d "Extracted_system/vendor" ]; then  
            sudo cp $thefile Extracted_system/system/product/overlay
            sudo chmod 644 Extracted_system/system/product/overlay/$thefile
            sudo xattr -w security.selinux u:object_r:vendor_overlay_file:s0 Extracted_system/system/product/overlay/$thefile
        else
            sudo cp $thefile Extracted_system/product/overlay
            sudo chmod 644 Extracted_system/product/overlay/$thefile
            sudo xattr -w security.selinux u:object_r:vendor_overlay_file:s0 Extracted_system/product/overlay/$thefile
        fi
        echo Done, overlay included!
    else
        echo There are a lot of overlay files here! Skipping...
    fi
fi

# Creating the new image file
echo Creating new system image file with name EDITED_$1...
sudo umount Extracted_system
sudo e2fsck -f -y EDITED_$1
sudo resize2fs -M EDITED_$1
#sudo chown "$(whoami)" EDITED_$1
sudo rm -rf Extracted_system
echo DONE!! Thanks for using this tool!
