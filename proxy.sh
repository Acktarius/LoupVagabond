#!/bin/bash
#check ilibrewolf is already running
lr=$(ps -e | grep -c librewolf)
if [[ ! ${lr} -eq 0 ]]; then
zenity --warning \
--timeout=15 \
--text="Librewolf is already running,\nyou have to exit first\nbefore running this anonymous instance."
exit
else
#check tor is running
torstatus=$(systemctl is-active tor.service)
if [ ${torstatus} != "active" ]; then
zenity --warning \
--timeout=15 \
--text="tor service is not running.\nOpen a Terminal window (Ctrl+Alt+T) and type : \n\n\t<b>sudo systemctl restart tor</b>"
sleep 1
exit
else
proxychains4 librewolf https://www.qwant.com/ 2> /dev/null
fi
fi
