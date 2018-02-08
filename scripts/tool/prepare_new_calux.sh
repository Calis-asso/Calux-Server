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

#!/bin/bash

# Pour commencer la personnalisation, on doit copier ce script sur la machine.
# Pour cela on monte le repertoire de script partagé grâce au serveur NFS (dont l'ip est 192.168.2.1)
# Mais il faudra tout d'abord installer le paquet client pour NFS sur la machine (nfs-common)
# sudo apt install nfs-common
# On monte le repertoire dans /mnt
# sudo mount 192.168.2.1:/ /mnt
# Puis lancer le script avec :
# bash /mnt/scripts/calux/tools/prepare_new_calux.sh


# TODO FICHIER PATHS + VARIABLES

# BEGIN functions

add_user() {
#	 On créé les utilisateurs...
	$sudo useradd -m -G cdrom,plugdev,sambashare -s /bin/bash -c $2 $1 &&
	$sudo passwd -d $1 && 
#	 Dossiers Bureau, Musique, Video du dossier personnel...
	$sudo cp -a /home/user/* /home/$1/ && 
	$sudo cp -R /home/user/.config /home/$1/ &&
	$sudo cp -R /home/user/.mozilla /home/$1/ &&
	$sudo sed -i "s/user/$1/" /home/$1/.config/gtk-3.0/bookmarks &&
 	$sudo chown -R $1:$1 /home/$1
}

# END 

# DIR_FILES="/mnt/IMGS/files"
DIR_FILES="$(dirname "$0")/new_calux/desktop/CALIS-INIT/files"
DIR_PLYMOUTH="/usr/share/plymouth"
CALUX_VERSION="4.0"
# SOFTS2INSTALL="gcompris gcompris-sound-fr gbrainy gweled pychess gnome-sudoku gnome-mines gnome-mahjongg aisleriot exaile exaile-plugin-contextinfo audacity gnome-orca pidgin-otr pidgin-bot-sentry pidgin-microblog pidgin-privacy-please"
# Il faut être super user !!!
# sudo="" && (( ! EUID == 0 )) && sudo="sudo "
if (( ! EUID == 0 )); then
    printf "/!\  Vous devez être en root pour continuer...  /!\ \n"
    sudo bash $0 $@
##########
#
# Personnalisation de firefox
#
# Modification de la page d'accueil
# Ajout de ublock Origins en extension
#
    [[ ! -e ~/.mozilla/firefox/calis.default ]] && source $(dirname "$0")/conf_firefox.sh
# on creer un alias pour gcompris
    ! cat .bashrc | grep -q "/opt/gcompris-qt-0.81-Linux/bin/gcompris-qt.sh" && echo "alias gcompris=\"/opt/gcompris-qt-0.81-Linux/bin/gcompris-qt.sh\"" >> ~/.bashrc
# On installe la version FR de gcompris
    [[ ! -e ~/.cache/KDE/gcompris-qt/data2/voices-ogg/voices-ogg/voices-fr.rcc ]] &&
    mkdir -p ~/.cache/KDE/gcompris-qt/data2/voices-ogg/ &&
    cd ~/.cache/KDE/gcompris-qt/data2/voices-ogg/ &&
    wget http://gcompris.net/data2/voices-ogg/voices-fr.rcc
    cd
#     On copie les outils de calux
    cp -R $(dirname "$0")/new_calux/desktop/* ~/Bureau/
    cp $(dirname "$0")/{prepare_2_maj.sh,build-iso-live.sh} ~/Bureau/CALIS-INIT/
    rm ~/Bureau/final_calux3.desktop # Fichier inutile sur calux 4.0
    echo "Copie des outils terminés !"
    exit $?
fi


printf "==> Préparation de la nouvelle %s\n" "Calux"

command -v xplayer >> /dev/null && 
  source $(dirname "$0")/new_calux/calux_packages.sh

printf "  ->Changement des fonctions des touches PgUp et PgDown pour chercher dans l'historique ( terminal feature )\n"			
$sudo sed -i "s/# \(.*\)history-search-backward/\1history-search-backward/g" /etc/inputrc
$sudo sed -i "s/# \(.*\)history-search-forward/\1history-search-forward/g" /etc/inputrc

##########
#
# Configuration de grub
#
if ! cat /etc/default/grub | grep -q /boot/calisboot.png; then	
    source $(dirname "$0")/new_calux/calux_grub.sh
fi

##########
#
# 20171201
# Personalisation du splash screen

if [[ ! -e $DIR_PLYMOUTH/themes/calux-logo/ ]]; then
     source $(dirname "$0")/new_calux/calux_splash.sh
     cd
fi
##########



#######
#
#   PinguyBuilder pour creer des isos
#
if ! command -v PinguyBuilder >> /dev/null; then
    source $(dirname "$0")/new_calux/calux_pinguy.sh
    cd
    #Configuration de PinguyBuilder...
    # Et on personnalise ce qu'on veut...
    cat /etc/PinguyBuilder.conf | 
    sed "s/^\(LIVEUSER=\"\).*/\1calux\"/" | 
    sed "s/^\(LIVECDLABEL=\"\).*/\1Calux live $CALUX_VERSION\"/" | 
    sed "s/^\(CUSTOMISO=\"\).*/\1Calux-live-$CALUX_VERSION.iso\"/" | 
    sed "s/LIVECDURL=.*/LIVECDURL=\"http:\/\/calis-asso.org\"/" >> /tmp/PinguyBuilder.conf 
    cp -v /etc/PinguyBuilder.conf /etc/PinguyBuilder.conf.old 
    cp -v /tmp/PinguyBuilder.conf /etc/PinguyBuilder.conf 
    cp $DIR_FILES/isolinux/* /etc/PinguyBuilder/isolinux/
fi
##########

##########
#
# Gcompris-qt
#
if [[ ! -e /opt/gcompris-qt-0.81-Linux/bin/gcompris-qt.sh ]]; then
    source $(dirname "$0")/new_calux/calux_gcompris.sh
    cd
fi
exit
