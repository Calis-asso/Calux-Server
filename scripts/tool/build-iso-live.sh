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

fin() {
#   On "tue" le processus de PinguyBuilder
	kill $PID_PB 2> /dev/null
# 	On supprime l'utilisateur du live
#   Et ses droits sudo
	sleep 5 && sudo userdel -r calux
	[[ -e /etc/sudoers.d/casper ]] && sudo rm /etc/sudoers.d/casper
}

launch_Pinguy() {
    sudo -u calux sudo PinguyBuilder backup
}

autologin_lightdm() {
    if ! cat $PINGUY_DIR/PinguyBuilder/dummysys/etc/lightdm/lightdm.conf.d/70-linuxmint.conf | grep -q autologin; then
#         On sauvegarde le fichier original
        sudo cp /etc/lightdm/lightdm.conf.d/70-linuxmint.conf $PINGUY_DIR/PinguyBuilder/dummysys/etc/lightdm/lightdm.conf.d/70-linuxmint.conf.ok
#         On creer une nouvelle copie du fichier
        cp /etc/lightdm/lightdm.conf.d/70-linuxmint.conf /tmp
#         On ajoute ce qu'il faut pour activer la connexion automatique avec lightdm dans notre copie
        echo -e "\nautologin-user=calux\nautologin-user-timeout=5" >> /tmp/70-linuxmint.conf 
#         Et on remplace l'existant
        sudo cp /tmp/70-linuxmint.conf $PINGUY_DIR/PinguyBuilder/dummysys/etc/lightdm/lightdm.conf.d/70-linuxmint.conf
    fi
}

autologin_mdm() {
# Modification de mdm.conf pour se logguer automatiquement en live
# On créer d'abord le nouveau fichier dans /tmp 
# Puis dans la boucle ci dessous, on le copie dans le "fake root" de remastersys ($PINGUY_DIR/PinguyBuilder/dummysys/) 
# Si il existe bien sur...
    sudo cp /etc/mdm/mdm.conf $PINGUY_DIR/PinguyBuilder/dummysys/etc/mdm/mdm.conf.ok
    cat /etc/mdm/mdm.conf | sed "s/\[security\]/TimedLoginEnable=True\n\nTimedLogin=calux\n\nTimedLoginDelay=5\n\n\[security\]/" > /tmp/mdm.conf
#    sudo cp /tmp/mdm.conf /etc/mdm/mdm.conf
    sudo cp /tmp/mdm.conf $PINGUY_DIR/PinguyBuilder/dummysys/etc/mdm/
}

ubi_launcher() {
    sudo sed -i "s/^Exec=.*/Exec=mate-terminal -e \/home\/calux\/Bureau\/CALIS-INIT\/ubilauncher.sh/g" /usr/share/applications/ubiquity.desktop
    sed -i "s/^Exec=.*/Exec=mate-terminal -e \/home\/calux\/Bureau\/CALIS-INIT\/ubilauncher.sh/g" /home/calux/Desktop/ubiquity.desktop
    sudo mv /home/calux/Desktop/ubiquity.desktop /home/calux/Bureau/
    sudo rmdir /home/calux/Desktop/
}
# PinguyBuilder working directory 
PINGUY_DIR="/home/PinguyBuilder"
# Scripts directory to create a calux iso live
REP_SCRIPT="/mnt/IMGS"

[[ ! -e "$REP_SCRIPT" ]] && REP_SCRIPT="/home/user/Bureau/CALIS-INIT" && [[ ! -e "$REP_SCRIPT/files/isolinux" ]] && printf "Impossible de trouver le répertoire des scripts !\n" && exit 1
[[ "$1" == "gtk" ]] && GTK=1

# On copie nos fichiers du menu syslinux 
sudo cp $REP_SCRIPT/files/isolinux/* /etc/PinguyBuilder/isolinux/

if ! id -u calux >> /dev/null; then
    echo "Creation de l'utilisateur calux"
    # Création de l'utilisateur calux qui sera notre utilisateur principal en live...
    # on le supprime à la fin du script avec "trap" ...
    # sudo useradd -r -G cdrom,plugdev,sambashare,adm,sudo,lpadmin -s /bin/bash -c "Live session user" calux
    sudo useradd -u 1042 -G cdrom,plugdev,sambashare,adm,sudo,lpadmin -s /bin/bash -c "Live session user" calux
    sudo cp -R /home/user/ /home/calux
    sudo chown -R calux:calux /home/calux/
fi
echo "calux  ALL=(ALL) NOPASSWD: ALL" > /tmp/casper
sudo sed -i "s/user/calux/" /home/calux/.config/gtk-3.0/bookmarks

# On installe les éléments nécessaire à l'installeur graphique...
! apt search ubiquity-frontend-gtk | grep -q ^i && sudo apt install ubiquity-frontend-gtk

# On lance PinguyBuilder en "background" ( avec le & )
# Et on récupère le PID
if [[ -z $GTK ]]; then
    sudo cp /tmp/casper /etc/sudoers.d/
    launch_Pinguy > /tmp/PinguyBuilding &2>&1 
    PID_PB=$!
else   
    PinguyBuilder-gtk >/dev/null &2>&1 
    PID_PB=$!
fi

trap "fin" EXIT

printf "  -> PinguyBuilder ($PID_PB) is running, type \"tail -fn 50 /tmp/PinguyBuilding\" in another terminal to see what's happenning...\r"
while kill -0 $PID_PB 2> /dev/null; do
	[[ -e /home/calux/Desktop/ubiquity.desktop ]] && [[ ! -e /home/calux/Bureau/ubiquity.desktop ]] && ubi_launcher
	[[ -e $PINGUY_DIR/PinguyBuilder/dummysys/etc/lightdm/lightdm.conf.d/70-linuxmint.conf ]] && ! cat $PINGUY_DIR/PinguyBuilder/dummysys/etc/lightdm/lightdm.conf.d/70-linuxmint.conf | grep -q autologin && autologin_lightdm
	[[ -e $PINGUY_DIR/PinguyBuilder/dummysys/etc/sudoers.d ]] && [[ ! -e $PINGUY_DIR/PinguyBuilder/dummysys/etc/sudoers.d/casper ]] && sudo cp /tmp/casper $PINGUY_DIR/PinguyBuilder/dummysys/etc/sudoers.d/casper
	[[ -e /usr/lib/syslinux/modules/bios/ ]] && [[ ! -e $PINGUY_DIR/PinguyBuilder/ISOTMP/isolinux/poweroff.c32 ]] && [[ -e $PINGUY_DIR/PinguyBuilder/ISOTMP/isolinux ]] && sudo cp /usr/lib/syslinux/modules/bios/{chain.c32,poweroff.c32,reboot.c32} $PINGUY_DIR/PinguyBuilder/ISOTMP/isolinux/
	
# 	CALUX v3.0 mdm et poweroff.com
	[[ -e $PINGUY_DIR/PinguyBuilder/dummysys/etc/mdm/mdm.conf ]] && ! cat $PINGUY_DIR/PinguyBuilder/dummysys/etc/mdm/mdm.conf | grep -q TimedLoginEnable && autologin_mdm
	[[ -e /usr/lib/syslinux/poweroff.com ]] && [[ ! -e $PINGUY_DIR/PinguyBuilder/ISOTMP/isolinux/poweroff.com ]] && [[ -e $PINGUY_DIR/PinguyBuilder/ISOTMP/isolinux ]] && sudo cp /usr/lib/syslinux/{chain.c32,poweroff.com,reboot.c32} $PINGUY_DIR/PinguyBuilder/ISOTMP/isolinux/

	sleep 10
done
printf "==> PinguyBuilder ($PID_PB) has finished !\n"

# On desinstalle les éléments nécessaire à l'installeur graphique...
apt search ubiquity-frontend-gtk | grep -q ^i && sudo apt remove ubiquity-frontend-gtk

exit 0
