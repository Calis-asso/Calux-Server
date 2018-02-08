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
URL_GCOMPRIS="http://gcompris.net/download/qt/linux/gcompris-qt-0.81-Linux64.sh"

# On desinstalle gcompris de base...
if [[ -e /usr/games/gcompris ]]; then
    # On conserve l'icone et le lanceur
    cp /usr/share/app-install/icons/gcompris.png /usr/share/icons/
    cp /usr/share/applications/gcompris.desktop /tmp/
    sed -i "s/Exec=gcompris/Exec=\/opt\/gcompris-qt-0.81-Linux\/bin\/gcompris-qt.sh/" /tmp/gcompris.desktop
    apt remove -y gcompris gcompris-data gcompris-sound-fr
fi
# Et on installe le nouveau
cd /opt
wget $URL_GCOMPRIS
chmod u+x gcompris-qt-0.81-Linux64.sh
./gcompris-qt-0.81-Linux64.sh

# Et on supprime l'installeur
rm /opt/gcompris-qt-0.81-Linux64.sh

# On reinstalle le lanceur
[[ -e /tmp/gcompris.desktop ]] && cp /tmp/gcompris.desktop /usr/share/applications/gcompris.desktop
# # et on creer un alias pour gcompris
# su -c "echo \"alias gcompris=/opt/gcompris-qt-0.81-Linux/bin/gcompris-qt.sh >> /home/user/.bashrc"
