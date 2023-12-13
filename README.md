# LoupVagabond
installer for Ubuntu users : LibreWolf + tor + proxychains + icon-launcher

## Option 1
go check the release page, and install using deb file.

## Install LibreWolf
follow the instruction here: https://librewolf.net/installation/debian/ 

## needed dependencies : tor + proxychains4
`sudo apt install zenity -y`  
`sudo apt install tor -y`  
`sudo systemctl enable tor`  
`sudo systemctl daemon-reload`  

`sudo apt install proxychains4 -y`  


## download this repository and complete install:
`cd /opt`  
`sudo git clone https://github.com/acktarius/loupvagabond.git`  
`cd loupvagabond`  

`sudo cp loupvagabond.desktop ~/.local/share/applications/loupvagabond.desktop`  
`sudo cp loupvagabond.svg ~/.icons/loupvagabond.svg`  
`sudo cp proxychains4.conf.temp /etc/proxychains4.conf`
