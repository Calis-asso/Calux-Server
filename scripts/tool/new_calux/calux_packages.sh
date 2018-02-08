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

install_package() {
    printf "  -> Installation de %s\n" "$@"
    $sudo apt install -y $@
}


SOFTS2REMOVE="rhythmbox xplayer"
# Les paquet a installer NOTE gcompris n'est pas la version qt mais on l'installe pour le lanceur tout pres...
SOFTS2INSTALL="gcompris gbrainy gweled pychess gnome-sudoku gnome-mines gnome-mahjongg aisleriot clementine gnome-orca pidgin-otr pidgin-bot-sentry pidgin-microblog pidgin-privacy-please audacity clonezilla"
# On commence par mettre à jour la liste des paquets...
apt update 
# puis installer apt-cacher-ng pour gerer les paquets
# Changer l'adresse IP si celle ci ne correspond pas a l'adresse du serveur...

if ! command -v apt-cacher-ng >> /dev/null; then
    install_package apt-cacher-ng 
fi
if ping -c 2 192.168.2.1 >> /dev/null; then
    echo "Acquire::http::proxy \"http://192.168.2.1:3142\";" > /etc/apt/apt.conf.d/02proxy   
else
    ping -c 2 192.168.0.111 >> /dev/null && echo "Acquire::http::proxy \"http://192.168.0.111:3142\";" > /etc/apt/apt.conf.d/02proxy    
fi

# On installe le driver pour virtualbox
! apt search virtualbox-guest-dkms | grep ^i >> /dev/null && install_package "virtualbox-guest-x11 virtualbox-guest-dkms"

##########
#
# Paquets à virer...( CAUTION Y OPTION DANGEROUS !!! ) TODO Lire un fichier !
#
command -v xplayer >> /dev/null && 
printf "  -> Désinstallation de %s\n" "rhythmbox xplayer" && 
apt purge -y $SOFTS2REMOVE 

##########
#
# Mises à jour
#
printf "  -> Mises à jour\n"
apt dist-upgrade -y

##########
#
# Paquets supplémentaires
#
# printf "  -> Mises à jour\n" 
install_package "$SOFTS2INSTALL"

# On associe les fichiers audio avec clementine...
sed -i "s/xplayer.desktop;totem.desktop/clementine.desktop;vlc.desktop/g" /usr/share/applications/defaults.list

