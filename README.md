# RemoteScan
Automates remote scanning from a local server using SSH.

## Remote scanning? Why?
I configured a Raspberry Pi Zero to configure a printer server for my HP all-in-one printer. Although the printer server works out of the box, the scan feature through the server does not work. However, I could use the scanner through SSH and retrieve the resultant file using `scp`.
The program in this repo automates the steps for scanning and downloading the files from the server, plus some exciting features for scanning documents.

## Prerequisites
- Local scanning capability with the command `scanimage`;
- Remote-host authentication using a public SSH key.
