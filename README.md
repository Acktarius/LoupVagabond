# LoupVagabond
installer for Ubuntu users : LibreWolf + tor + proxychains + icon-launcher

## Option 1
go check the release page, and install using deb file.

```bash
# After downloading the .deb file (handles dependencies automatically)
sudo apt install ./loupvagabond_*.deb

# Or alternatively, the two-step method:
# sudo dpkg -i loupvagabond_*.deb
# sudo apt-get install -f  # Only needed if dependencies are missing
```

> **Note**: You might see a warning about "Download is performed unsandboxed" when installing from your Downloads folder. This is normal and not a cause for concern. It's just APT telling you that it couldn't use its sandbox security feature.

### Verifying Package Integrity

Each release includes an MD5 checksum file to verify the integrity of the package:

```bash
# Download both the .deb file and the .md5 file
# Verify the checksum
md5sum -c loupvagabond_*.deb.md5
```

If the verification passes, you'll see "OK" and can proceed with installation.

### Notes on Installation

- When installing, the package will:
  - Back up your existing proxychains4.conf (if any) to /etc/loupvagabond/proxychains4.conf.backup
  - Install its own optimized configuration to /etc/proxychains4.conf
  - Enable and start the Tor service
- When uninstalling, the package will:
  - Restore your original proxychains4.conf from the backup
  - Leave the Tor service enabled (with instructions on how to disable it if desired)
- The main script is installed to /usr/local/bin/loupvagabond

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

---

## For Developers: Releasing a New Version

The project uses GitHub Actions to automatically build a Debian package when a new tag is pushed. To release a new version:

1. Make your changes to the code
2. Push your changes to the main branch
3. Create and push a new tag with a version number:

```bash
git tag v1.0.1
git push origin v1.0.1
```

The GitHub workflow will automatically:
- Build a Debian package with the correct version
- Create a new release with the package attached
- Publish it to the releases page

## Contact
https://discord.gg/ScY8tJUf
