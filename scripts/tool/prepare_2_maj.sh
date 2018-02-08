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

# Ce script prepare l'installation des mises à jour pour Calux avec apt-cache-ng 

install_apt_cacher() {
    echo "   -> Installation de apt-cacher-ng"
    sudo apt install apt-cacher-ng 
}

#CHEZ MOI
IP_SRV="192.168.0.111"
#CALIS
IP_SRV_CALIS="192.168.2.1"
# command -v apt-cacher-ng >> /dev/null && $ACNGOK=1
# On teste sur quel serveur on est
ping -q -c 1 "$IP_SRV" >/dev/null 2>&1
! [[ $? -eq 0 ]] && IP_SRV="$IP_SRV_CALIS" 
# Et on install apt-cacher
ping -q -c 1 "$IP_SRV" >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo "==> Serveur $IP_SRV trouvé !"
    ! command -v apt-cacher-ng >> /dev/null && install_apt_cacher 
    # On lance apt-cacher
    echo "  ->Demarrage de apt-cacher-ng"
#     command -v systemctl >> /dev/null && sudo systemctl restart apt-cacher-ng || 
    sudo /etc/init.d/apt-cacher-ng restart
    # On modifie l'adresse du serveur
    echo "Acquire::http::proxy \"http://$IP_SRV:3142\";" > /tmp/02proxy
    sudo cp /tmp/02proxy /etc/apt/apt.conf.d/02proxy   
fi

# Les MAJ
sudo apt update
sudo apt dist-upgrade $1

[[ -e /etc/apt/apt.conf.d/02proxy ]] && sudo rm /etc/apt/apt.conf.d/02proxy /tmp/02proxy
# On arrete apt-cacher-ng
sudo /etc/init.d/apt-cacher-ng stop
echo "Tapez \"exit\" ou faites \"Ctrl + D\" pour quitter." 
bash 

exit 0
