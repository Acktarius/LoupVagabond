# LoupVagabond
installer for Ubuntu users : LibreWolf + tor + proxychains + icon-launcher

## Install LibreWolf
follow the instruction here: https://librewolf.net/installation/debian/ 

## needed dependencies : tor + proxychains4
`sudo apt install zenity -y`  
`sudo apt install tor -y`  
`sudo systemctl enable tor`  
`sudo systemctl daemon-reload`  

`sudo apt install proxychains4 -y`  


## download :
`cd /opt`  
`sudo git clone https://github.com/acktarius/loupvagabond.git`  
`cd loupvagabond`  

`sudo cp loupvagabond.desktop /usr/local/share/applications/loupvagabond.desktop`  
`sudo cp proxychains4.conf.temp /etc/proxychains4.conf`
