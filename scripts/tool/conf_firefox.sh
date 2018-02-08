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

# Ce script creer une configuration personnalisé pour firefox
# ATTENTION On ne doit avoir qu'un seul profil dans le dossier de firefox !
#

# Decommentez et modifiez si souhaité
# DIR_FILES="/mnt/IMGS/files"
[[ -z $DIR_FILES ]] && printf "DIR_FILES n'est pas définie !\n" && exit

HOME_PAGE="https://www.qwant.com/" # Page accueil
MOZ_PROF=~/.mozilla/firefox/calis.default # Emplacement du profil

printf "==> Modification du profil initial\n"

# if [[ ! -e .mozilla/firefox/profiles.ini ]]; then 
printf "==> Firefox va maintenant s'ouvrir pour s'initialiser !\n"
printf "  -> Importez les favoris depuis le menu marque page et activer la barre personnelle !\n"
#     sleep 5
cp $DIR_FILES/mf_ext/*json ~/Bureau/
firefox
#     sleep 2
# fi
# On renomme le profil
mv ~/.mozilla/firefox/*.default $MOZ_PROF
while [[ ! -e ~/.mozilla/firefox/profiles.ini ]]; do sleep 1; done
sed -i "s/Path=.*/Path=calis.default/" ~/.mozilla/firefox/profiles.ini

# Page d'accueil
printf "  -> Modification de la page d'accueil\n"
if [[ -e $MOZ_PROF/prefs.js ]] && cat $MOZ_PROF/prefs.js | grep -q "\"browser.startup.homepage\""; then
    sed -i "s/\(browser.startup.homepage\", \"\).*\(\"\)/\1${HOME_PAGE//\//\\\/}\2/" $MOZ_PROF/prefs.js
else
    echo "user_pref(\"browser.startup.homepage\", \"$HOME_PAGE\");" >> $MOZ_PROF/prefs.js
fi

rm ~/Bureau/*.json
# uBlock Origins
printf "  -> Ajout de uBlock Origins\n"
[[ ! -e $MOZ_PROF/extensions ]] && mkdir $MOZ_PROF/extensions
[[ ! -e $MOZ_PROF/extensions/uBlock0\@raymondhill.net.xpi ]] && cp $DIR_FILES/mf_ext/*.xpi $MOZ_PROF/extensions

# Modification de l'interface
sed -i "s/\\\\\"customizableui-special-spring1\\\\\",//g" $MOZ_PROF/prefs.js
sed -i "s/customizableui-special-spring2/search-container/" $MOZ_PROF/prefs.js
# \"search-container\",

printf "==> La personnalisation de firefox est terminée !\n"
