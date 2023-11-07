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
	varset=1
	while [ $varset -eq 1 ]
	do
		echo This was the informed IP address of the server: $ip_address
		echo Is this information correct? 1-yes, 0-no:
		read cond
		if [ "$cond" -eq 1 ]; then
			varset=0
		else
			echo What is the IP address of the server?  
			read ip_address
		fi
	done
	echo What user on the server would you like to connect to?  
	read remote_user
	varset=1
	while [ "$varset" -eq 1 ]
	do
		echo This was the informed user: $ remote_user
		echo Is this information correct? 1-yes, 0-no:
		read cond
		if [ "$cond" -eq 1 ]; then
			varset=0
		else
			echo What user on the server would you like to connect to?  
			read remote_user
		fi
	done
	echo $ip_address > .server_address
	echo $remote_user > .remote_user
	sleep 1
	printheader
}

function scan_photo {
	rm scan.jpg || true
	echo Starting scan job at $remote_user@$ip_address
	ssh $remote_user@$ip_address 'scanimage -p -o scan.jpg'
	scp $remote_user@$ip_address:/home/$remote_user/scan.jpg .
	echo Scan job completed! Output file: scan.jpg
	echo Thanks for using this tool!
	exit
}

function scan_doc {
	rm scan.pdf || true
	mkdir temp_scan
	cd temp_scan
	count=1
	echo Starting scan job at $remote_user@$ip_address
	while [ $count -ne 0 ]
	do
		ssh $remote_user@$ip_address 'scanimage -p -o scan.pdf'
		scp $remote_user@$ip_address:/home/$remote_user/scan.pdf .
		open scan.pdf
		echo Do you want to add the scanned page to the document? 1-yes, 0-no:
		read cond
		if [ "$cond" -eq 1 ]; then
			mv scan.pdf scan_$count.pdf
			echo Do you want to scan a new page of the document? 1-yes, 0-no:
			read cond
			if [ "$cond" -eq 1 ]; then
				count=$(expr $count + 1)
			else
				count=0
			fi
		else
			echo The document will be scanned again in 3 seconds
			sleep 3
		fi
	done
	pdfunite scan_*.pdf output.pdf
	cd ..
	mv temp_scan/output.pdf scan.pdf
	rm -rf temp_scan
	echo Scan job completed! Output file: scan.pdf
	echo Thanks for using this tool!
	exit
}


# Argument verification
if [ $# -ne 0 ]; # No arguments!
  then
   echo You should not provide any argument to the script. 
   exit 1
fi

# First use check
if [ ! -f .server_address ]; then
	firstuse
fi

ip_address=$( cat .server_address )
remote_user=$( cat .remote_user )

# Function selection
printheader
echo Which kind of archive do you want to scan? Choose a number 1-2:
echo 1.  Photo    \(.jpg file\)
echo 2.  Document \(.pdf file\)
read selection

if [ "$selection" -eq 1 ]; then
    echo Photo scanning selected.
    sleep 1
    scan_photo
elif [ "$selection" -eq 2 ]; then
    echo Document scanning selected.
    sleep 1
    printheader
    scan_doc
else
    echo Invalid input, try again.
    exit 1
fi

