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

# Ce script doit être executé en root !

# Chemin par défault des fichiers...
[[ -z "$DIR_FILES" ]] && DIR_FILES="/mnt/IMGS/files"
	
printf "  ->Modification des fichiers de GRUB\n"
# Shutdown et Reboot options
! cat /etc/grub.d/40_custom | grep -q "System shutdown" &&
cp -av /etc/grub.d/40_custom /tmp/40_custom && 
echo -e "\n\nmenuentry \"System shutdown\" {\n\techo \"System shutting down...\"\n\thalt\n}" >> /tmp/40_custom &&
echo -e "\n\nmenuentry \"System restart\" {\n\techo \"System rebooting...\"\n\treboot\n}" >> /tmp/40_custom &&
cp /tmp/40_custom /etc/grub.d/40_custom

# Hidden MENU 
cp -av /etc/default/grub /tmp/grub &&
sed -i "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/" /tmp/grub && 
sed -i "s/GRUB_HIDDEN_TIMEOUT=.*/GRUB_HIDDEN_TIMEOUT=5/" /tmp/grub &&
# Bakground
echo "GRUB_BACKGROUND=\"/boot/calisboot.png\"" >> /tmp/grub &&
cp -av /tmp/grub /etc/default/grub

cp $DIR_FILES/syslinux.png /boot/calisboot.png	
chmod -x /etc/grub.d/*memtest*

update-grub

