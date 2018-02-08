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

function mount_root() {
    sudo mount "$1" "$2"
}

function change_hostname() {
    sudo sed -i "s/ubuntu/calux/g" $TARGET_DIR/etc/hostname
    sudo sed -i "s/ubuntu/calux/g" $TARGET_DIR/etc/hosts
}


echo "==> Lancement de ubiquity"
sudo sh -c ubiquity -b gtk_ui

SRC_DIR="$(dirname "$0")"
DIR_FILES="$SRC_DIR/../"
PART2WORK="/dev/sda1"
# ls $SRC_DIR;
# ls $DIR_FILES;

# WORK_DIR="/tmp/tools"
TARGET_DIR="/target"

# source $SRC_DIR/doexec
source $SRC_DIR/chroot_common.sh
[[ ! -e $TARGET_DIR ]] && sudo mkdir $TARGET_DIR
if ! mountpoint -q "$TARGET_DIR"; then
    mount_root $PART2WORK $TARGET_DIR 
    [[ $? != 0 ]] && PART2WORK="/dev/sda2" && mount_root $PART2WORK $TARGET_DIR 
    echo "Partition $PART2WORK montée dans $TARGET_DIR !"
fi

# Initialisation de la partition cible pour effectuer un chroot
init_chroot "$TARGET_DIR" 

# Copie des fichiers à executer sur la nouvelle installation
cp $SRC_DIR/calux_grub.sh $TARGET_DIR/tmp
cp $DIR_FILES/syslinux.png $TARGET_DIR/tmp
lix_chroot "$TARGET_DIR" "DIR_FILES=/tmp; source /tmp/calux_grub.sh"

# Suppression de l'utilisateur "calux"...
# ... autologin lightdm/mdm
[[ -e $TARGET_DIR/etc/lightdm/lightdm.conf.d/70-linuxmint.conf.ok ]] && sudo mv $TARGET_DIR/etc/lightdm/lightdm.conf.d/70-linuxmint.conf.ok $TARGET_DIR/etc/lightdm/lightdm.conf.d/70-linuxmint.conf
[[ -e $TARGET_DIR/etc/mdm/mdm.conf.ok ]] && sudo mv $TARGET_DIR/etc/mdm/mdm.conf.ok $TARGET_DIR/etc/mdm/mdm.conf

# ... autorisation pour sudo
[[ -e $TARGET_DIR/etc/sudoers.d/casper ]] && sudo rm $TARGET_DIR/etc/sudoers.d/casper

# ... dossier personnel et l'utilisateur
lix_chroot "$TARGET_DIR" "id -u calux >> /dev/null && sudo userdel -r calux && echo \"Suppression de l'utilisateur calux live\""

# Changement du nom de l'odinateur ubuntu => calux
cat $TARGET_DIR/etc/hostname | grep -q ubuntu && change_hostname


chroot_teardown "reset"
sudo umount $TARGET_DIR


echo "L'installation est terminée !"
echo "Tapez \"exit\" ou faites \"Ctrl + D\" pour fermer la fenetre"
bash
exit;
