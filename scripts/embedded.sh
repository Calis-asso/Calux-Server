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

#
# Ce script est executé dès la connexion de root
# Il prépare les répertoires 

finish() {
	[[ ! $testtrap ]] && chroot_teardown
	[[ ! $FIN ]] && decompte 5 "Fin dans %s" || clone_complete 
# 	decompte 3 "Fin dans %s"
    clear
# 	umount /media
}

chroot_add_mount() {
# echo "mount $@"
  mount "$@" && CHROOT_ACTIVE_MOUNTS=("$2" "${CHROOT_ACTIVE_MOUNTS[@]}")
}

chroot_maybe_add_mount() {
  local cond=$1; shift
  if eval "$cond"; then
    chroot_add_mount "$@"
  fi
}

mount_setup() {
	CHROOT_ACTIVE_MOUNTS=()
  
	[ ! $testtrap ] && testtrap=1
	if ! mountpoint -q "$DIR_PARTIMAG" ; then 
		(( $NFS )) && chroot_add_mount "$1" "$DIR_PARTIMAG" -o bind || chroot_add_mount "$1" "$DIR_PARTIMAG" -t ext4
	else
		caution "Le répertoire $DIR_PARTIMAG est déjà monté !" 
	fi
}

chroot_teardown() {
  cd
  umount "${CHROOT_ACTIVE_MOUNTS[@]}"
  unset CHROOT_ACTIVE_MOUNTS
[ "$1" == "reset" ] && CHROOT_ACTIVE_MOUNTS=() 
# mount
}


# When complete (Whether successfully or unsuccessfully)
clone_complete() {
		local msg_fin=( "Reboot" "Shutdown" "Recommencer" "Lancer Clonezilla" "Chroot2Calux" "Effacer les fichiers verrous et recommencer" "Installer les mises à jour" "Consulter les log" "Restaurer" "Sauvegarder" )

# 	local msg_fin=( "Reboot" "Shutdown" "Recommencer" "Lancer Clonezilla" "Chroot2Calux" "Effacer les fichiers temporaires et recommencer" "Consulter les log" "Restaurer" "Sauvegarder" "Télécharger la dernière version" )
# 	local msg_fin="Que voulez vous faire ?\n\t1) Reboot\n\t2) Shutdown\n\t3) Recommencer\n\t4) Lancer Clonezilla\n\t5) Chroot2Calux\n\t6) Effacer les fichiers temporaires et recommencer\n\t7) Consulter les log\n\t*) Virtual Console\n\t-> "

	
	OPT=$( rid "Que voulez vous faire ?$( print_menu "${msg_fin[@]}")\n\t-> " )	
	case "$OPT" in
       "1") exit 0 | reboot
            ;;
       "2") exit 0 | shutdown -h 0
            ;;
       "3") 
            clear
            cd
            bash $SCRIPT_CURRENT $NO_ASK $OP $CREATE $ARCH
# 		sleep 5
            ;;
       "4") clonezilla
            ;;
       "5") 
            cd $DIR_PARTIMAG
            bash $SCRIPT2EXEC chroot
            clone_complete
            ;;
       "6") 
    # 		cd /tmp
            msg_n "Effacement des fichiers temporaires" 
            rm $WORK_DIR/done.calux_*
            clone_complete
    # 		bash $0 $NO_ASK $OP $CREATE $ARCH
            ;;
        "7") 
            clear
            cd $DIR_PARTIMAG
            bash $SCRIPT2EXEC maj $CREATE $ARCH
            ;;
       "8") 
    # 		decompte 3 "$LOG_EXE"
            clear
            tail -fn50 $LOG_EXE
            exit $FIN
    # 		loading "Effacement des fichiers temporaires" "Fichiers effacés" rm command_restore calux_command formatpart 
    # 		bash $0 $OP $CREATE $ARCH
            ;;
       "9") 
            clear
            cd
            bash $SCRIPT_CURRENT $NO_ASK restore $CREATE $ARCH
# 		sleep 5
            ;;
       "10") 
            clear
            cd
            bash $SCRIPT_CURRENT $NO_ASK save $CREATE $ARCH
# 		sleep 5
            ;;
#         "10") if_majs
#             ;;
#        "9") bash $SCRIPT2EXEC iso-live
#           ;;
	*|"") 
        clear
		cd
		printf "\n\n" 
		msg_n "32" "32" "Déconnectez vous en lancant \"%s\" ou faites \"%s\" pour relancer." "exit" "CTRL + D"
		bash
		exit $FIN
            ;;
   esac
}
ping_srv() {
	if [ ! -e $WORK_DIR/net_ok ]; then
		msg_nn2 "Ping du serveur..." 
		ping -q -c 2 "$IP_SRV" >/dev/null 2>&1
		[ $? -eq 0 ] && NETWORK_UP="ok" || NETWORK_UP="no"
		msg_nn_end "$NETWORK_UP"
		if [ "$NETWORK_UP" == "no" ]; then
			if ! dhclient eth0 2>/dev/null; then
				touch $WORK_DIR/net_ok
			else
				caution "L'interface réseau est peut etre déjà démarrée !"
			fi
		else
			touch $WORK_DIR/net_ok
		fi
	else
		NETWORK_UP="ok"
	fi
}

mount_imgs() {
	if ! mountpoint -q $DIR_PARTIMAG; then
		if [ -b $DIR_SHARE ]; then
			if [[ ! -z $NO_ASK  ]]; then
				LOCAL_MOUNT=1
			else
				ping_srv 
				[[ "$NETWORK_UP" == "ok" ]] && rid_continue "Utiliser le serveur ?" && NFS=1 && DIR_SHARE="$DIR_IMGS" 	
				(( ! $NFS )) && rid_continue "Continuer sur clé USB ?" && LOCAL_MOUNT=1
			fi
		else
			LOCAL_MOUNT=0
		# 	[ "$NETWORK_UP" == "no" ] && ping_srv
		# 	[ "$NETWORK_UP" == "ok" ] && 
			if [[ ! -z $NO_ASK  ]]; then
				NFS=1 && DIR_SHARE="$DIR_IMGS" 
			else
				rid_continue "Utiliser le serveur ?" && NFS=1 && DIR_SHARE="$DIR_IMGS" 
			fi
		fi

	# On monte le repertoire des images
		if (( $NFS )) || (( $LOCAL_MOUNT )); then
			[[ ! -e "$DIR_PARTIMAG" ]] && mkdir "$DIR_PARTIMAG"
			return 0;
# 			mount_setup "$DIR_SHARE" && msg_n "33" "32" "\"%s\" à été monté dans %s" "$DIR_SHARE" "$DIR_PARTIMAG" 
		else	
		# 	FIN=0 
			die "%s" "Aucun répertoire pour l'image n'a été défini !"
		fi
	else 
		caution "Le répertoire $DIR_PARTIMAG est déjà monté !" 
# 		return 0;
	fi
	return 1
}

if_majs() {
    if [[ -e $DIR_PARTIMAG/majs/maj_scripts.sh ]]; then
        if rid_continue "Utiliser les scripts de reconditionnement de calis-asso.org ?"; then
             if bash $DIR_PARTIMAG/majs/maj_scripts.sh; then
                cp -v $DIR_PARTIMAG/majs/embedded.sh $WORK_DIR/
                cp -v $DIR_PARTIMAG/majs/$SCRIPT2EXEC $WORK_DIR/
                cp -v $DIR_PARTIMAG/majs/prepare_2_maj.sh $WORK_DIR/
             
                cp -v $DIR_PARTIMAG/calux_version $WORK_DIR/
                cp -v $DIR_PARTIMAG/calux_create_version $WORK_DIR/
                # Et on relance
                if rid_continue "Lancer la mise à jour ?"; then
                    SCRIPT2EXEC="$WORK_DIR/calux_utils"
                    DIR_PARTIMAG="$WORK_DIR"
                    SCRIPT_CURRENT="$WORK_DIR/embedded.sh"
#                     $WORK_DIR/embedded.sh  
#                     exit $?
                fi
            fi
        fi        
    fi
}


# Fuckin' \"futil\" functions !!!

# END

# REPERTOIRE DU PARTAGE DE L'IMAGE DISK ( clé USB avec une partition avec le label "calux-install" )
DIR_SHARE="/dev/disk/by-label/calux-install"
# Repertoire des images sur le serveur distant
DIR_IMGS="/media/srv/calux/IMGS"
DIR_PARTIMAG="/home/partimag"
WORK_DIR="/tmp/tools"
SCRIPT2EXEC="calux_utils"
SCRIPT_CURRENT="$0"

#...or NFS )
NFS=0
FIN=0
NO_ASK=
[[ "$1" == "-y" ]] && NO_ASK="-y" && shift
#TYPE OPERATION ( SAVE / RESTORE )
OP=$1
testtrap=0
CREATE=$2
NET=$( [ -e $WORK_DIR/net.ok ] && cat $WORK_DIR/net.ok || echo "0" )
# DIR_SCR="$(dirname $0)"
# [ ! -e futil ] && busybox tftp -g -r clonezilla/futil -l /tmp/futil $IP_SRV || cp futil /tmp/futil
ARCH=$3

# cp $DIR_SCR/futil $DIR_SHARE
# pwd
[[ ! -e $DIR_PARTIMAG ]] && mkdir $DIR_PARTIMAG;
cd $DIR_PARTIMAG
# BEGIN TODO la  CLE USB a besoin de ca ????
[[ -e src/futil ]] && cp src/* $WORK_DIR
[[ -e calux/tool/prepare_2_maj.sh ]] && cp calux/tool/prepare_2_maj.sh $WORK_DIR
[[ -e calux/tool/build-iso-live.sh ]] && cp calux/tool/build-iso-live.sh $WORK_DIR
# END TODO
# [[ -e chroot_common.sh ]] && cp chroot_common.sh /tmp 
[[ ! -e $WORK_DIR/futil ]] && echo "Le fichier $WORK_DIR/futil n'existe pas !" && exit
# [[ ! -e /tmp/chroot_common.sh ]] && echo "Le fichier /tmp/chroot_common.sh n'existe pas !" && exit
source $WORK_DIR/futil 
# pwd
# ls
# source futil 
# ls 
# sleep 30
# echo "WTF" && exit
trap 'finish' EXIT

is_root "$@"

msg_n "32" "32"  "Bienvenue dans le clonage de %s via %s" "Calux 4.0" "Clonezilla"
# msg_nn2 "Ping du serveur..." &&
# && msg_nn_end "$NETWORK_UP"	
mount_imgs && mount_setup "$DIR_SHARE" && msg_n "33" "32" "\"%s\" à été monté dans %s" "$DIR_SHARE" "$DIR_PARTIMAG" 
# if_majs
# copie de ce fichier afin de créer l'iso de clonezilla useless sur Arch
# cp $0 /home/partimag/embedded-iso.sh
# copie de ce fichier afin de créer une install toute "fresh"
[[ ! -e $WORK_DIR/embedded.sh ]] && cp $0 $WORK_DIR/embedded.sh
[[ "$OP" == "" ]] && OP="restore"

# La version de clonezilla fournie par mint ne colle pas avec les outils 
# donc j'ai pris la version derniere de clonezilla et récupéré ce qu'il fallait...
[[ "$( cat /etc/hostname )" == "calux-live" ]] && msg_nn2 "33" "32" "Copie des fichiers \"%s\" dans %s..." "files/clonezilla-3.0.4/*" "/usr/sbin" && cp files/clonezilla-3.0.4/* /usr/sbin && msg_nn_end "ok"
###
# TODO Ajouter le choix de l'image !
###
# (( CREATE )) && bash calux_create $OP  || 
# bash calux_utils $OP
cd $DIR_PARTIMAG
# pwd
# ls
bash $SCRIPT2EXEC $NO_ASK $OP $CREATE $3
FIN=$?
# sleep 5
# [[ $FIN -gt 0 ]] && sleep 5
case $FIN in 
	0) msg_n "32" "32" "Clonage terminé !"  && FIN=1 ;;
	1) exit 1 ;;
	2) FIN=1 
esac
# if [[ $FIN -eq 0 ]]; then 
# 	msg_n "Clonage terminé !"  
# 	FIN=1 
# else
# 	[[ $FIN -eq 2 ]] && FIN=1 || exit 1
# fi
# finish $FIN
# sleep 10
