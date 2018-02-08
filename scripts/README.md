###########################
#
# Procédure de création de la distribution Calux à partir de LinuxMint
#
# 1. Installer une LinuxMint ( XFCE ou Mate (cinnamon à tester...) ) avec un utilisateur ayant pour login "user" et redémarrer sur la distribution fraîchement installée...
# 2. Récupérer l'archive calux-install.tar.gz sur "https://github.com/Calis-asso/tools/blob/master/calux-install.tar.gz"
# 3. 
#    3a) Décompresser l'archive dans /tmp
#    3b) Si vous avez un répertoire contenant les paquets de mint, placez vous juste avant celui-ci ( cf. plus bas )
# 4. Lancer le script avec "bash /tmp/calux-install/calux_create"
# 5. Une fois fini, la distribution sera une LinuxMint modifiée correspondant à nos besoins...
#
###########################

###########################
#
# Concernant les paquets...
# Le script cherche dans le répertoire courant si il existe un dossier portant le nom "packages"
# Si il en trouve un, il le montera dans /var/cache/apt/archives
# Il faut se placer dans le répertoire parent de celui des packages... 
# Exemple : Sur le serveur, le dossier des paquets est /nfs/IMGS/packages, une fois le répertoire /nfs/ monté dans /mnt, on fera :
# cd /mnt/IMGS 
# bash /tmp/calux-install/calux_create
# 
###########################
