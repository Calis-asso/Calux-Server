#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Ce script finalise l'installation de calux en supprimant tous ce qui n'est plus utile...
	
install_apt_cacher() {
    echo "   -> Installation de apt-cacher-ng"
    apt install apt-cacher-ng 
}



# Supprime l'utilisateur creer pour les lives...	
id -u calux >> /dev/null && sudo userdel -r calux && echo "Suppression de l'utilisateur calux live"
# Desactive la connexion automatique de l'utilisateur live
[[ -e /etc/lightdm/lightdm.conf.d/70-linuxmint.conf ]] && cat /etc/lightdm/lightdm.conf.d/70-linuxmint.conf | grep -q autologin && sudo mv /etc/lightdm/lightdm.conf.d/70-linuxmint.conf.ok /etc/lightdm/lightdm.conf.d/70-linuxmint.conf
[[ -e /etc/mdm/mdm.conf ]] && cat /etc/mdm/mdm.conf | grep -q TimedLoginEnable && sudo mv /etc/mdm/mdm.conf.ok /etc/mdm/mdm.conf
[[ -e /etc/sudoers.d/casper ]] && sudo rm /etc/sudoers.d/casper
#
#	SUPPRESSION module virtualbox & 
#
apt search virtualbox-guest-dkms | grep -q ^i &&
sudo apt remove virtualbox-guest-dkms virtualbox-guest-x11 virtualbox-guest-utils squashfs-tools ubiquity-frontend-debconf discover aufs-tools dpkg-dev plymouth-x11 clonezilla partclone apt-cacher-ng gparted &&
echo "Desinstallation du module virtualbox et d'autres..."

command -v PinguyBuilder >> /dev/null && sudo dpkg -r PinguyBuilder && 

apt search gparted | grep -q ^i &&
sudo apt remove gparted
apt search apt-cacher-ng | grep -q ^i &&
sudo apt remove apt-cacher-ng &&
# sudo dpkg -r PinguyBuilder && 
# echo "Desinstallation de gparted..."

sudo apt autoremove 
echo "Desinstallation de tout les paquets inutiles et perimes"
# sudo apt autoclean

#
#	CORBEILLE / MINIATURES
#
rm -r -f $HOME/.local/share/Trash/*/* 
echo "Nettoyage de la corbeille"
rm $HOME/.cache/thumbnails/*/*
echo "Nettoyage des miniatures"

#
#	SUPPRESSION Recent documents
#
rm $HOME/.local/share/recently-used.xbel
echo "Suppression de ~/.local/share/recently-used.xbel"

cd 
rmdir ~/Desktop
rm -R ~/Bureau/CALIS-INIT
rm ~/Bureau/final_calux.desktop
rm ~/Bureau/maj_calux.desktop
[[ -e /etc/apt/apt.conf.d/02proxy ]] && sudo rm /etc/apt/apt.conf.d/02proxy    

#
#	BASH_HISTORY ~ & #
#
# sudo history -c
# echo "Suppression de /root/.bash_history"

history -c
echo "Suppression de ~/.bash_history"
echo "Nettoyage terminé !"
echo "Tapez \"exit\" ou faites \"Ctrl + D\" pour quitter." 
bash 
exit 0
