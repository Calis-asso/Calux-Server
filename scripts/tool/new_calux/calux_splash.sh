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

# Ce script doit être executé en root !

# Chemin par défault des fichiers...
[[ -z "$DIR_PLYMOUTH" ]] && DIR_PLYMOUTH="/usr/share/plymouth"
[[ -z "$CALUX_VERSION" ]] && CALUX_VERSION="4.0"

DISTRIB="mint"
LOGO_DISTRIB="$DISTRIB-logo"
[[ ! -e $DIR_PLYMOUTH/themes/$LOGO_DISTRIB ]] && DISTRIB="xubuntu" && LOGO_DISTRIB="logo"

[[ -e $DIR_PLYMOUTH/themes/$DISTRIB-logo ]] && cp -R $DIR_PLYMOUTH/themes/$DISTRIB-logo/ $DIR_PLYMOUTH/themes/calux-logo/
# # Nouveau logo adapté dans REP_CLONEZILLA/IMGS/files/logo.png
cp $DIR_FILES/logo.png $DIR_PLYMOUTH/themes/calux-logo/$LOGO_DISTRIB.png
cp $DIR_FILES/logo.png $DIR_PLYMOUTH/themes/calux-logo/$LOGO_DISTRIB\16.png

cd $DIR_PLYMOUTH/themes/calux-logo/
mv $DISTRIB-logo.plymouth calux-logo.plymouth
mv $DISTRIB-logo.script calux-logo.script
cat calux-logo.plymouth | sed "s/^\(Name=\).*/\1Calux Logo/" | sed "s/$DISTRIB-logo/calux-logo/g" > /tmp/calux-logo.plymouth
cp /tmp/calux-logo.plymouth $DIR_PLYMOUTH/themes/calux-logo/
update-alternatives --install $DIR_PLYMOUTH/themes/default.plymouth default.plymouth $DIR_PLYMOUTH/themes/calux-logo/calux-logo.plymouth 100
# # Calux-logo is in place !
update-alternatives --config default.plymouth <<EOF
1
EOF

# # On change le texte ( qui s'affiche si le logo ne se charge pas ) aussi tant qu'on y est 
sed -i "s/\(title=\).*/\1Calux $CALUX_VERSION/" $DIR_PLYMOUTH/themes/text.plymouth
sed -i "s/^\(Name=\).*/\1Calux Text/" $DIR_PLYMOUTH/themes/text.plymouth
# # On recompile l'initramfs
update-initramfs -u
