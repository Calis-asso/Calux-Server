#!/bin/bash

out() { printf "$1 $2\n" "${@:3}"; }
msg_nn2() { local saut="" ; [ "$1" == "\r" ] && saut="$1" && printf "$saut" >&2 && shift; printf "  -> $1"  "$2" >&2 ; }
error() { out "==> ERROR:" "$@"; } >&2
msg() { out "==>" "$@"; }
msg2() { out "  ->" "$@";}
die() { error "$@"; exit 1; }

caution() { msg "AVERTISSEMENT: $1" "$2"; } >&2
decompte () { local i=$1 _optarg="$4"; shift; [ "$_optarg" == "" ] && _optarg=" "; while [ $i -gt 0 ];do msg_nn2 "\r" "$1" "$i"; sleep 1; i=$((i-1)); done; printf '\r'; printf "==> $2 %s\n" "$_optarg" "$( clear_line "$(($( echo $1 | wc -c )-2))" "$( echo $2 | wc -c )" )" ; }
# To clear a line (used by decompte)
clear_line() { i=0; NB_COLUMS=$1; NB_COLUMS=$((NB_COLUMS-$2)); until [ $i -gt $NB_COLUMS ]; do printf " "; i=$((i+1)); done; }
msg_nn_end() {  out "$1" "$2" "$3" >&2; }

# fin() {
# 	sudo rm /var/cache/apt/archives
# 	sudo mv /var/cache/apt/archives.ok /var/cache/apt/archives
# 		sudo umount $MOUNT_SRV 
# 	if (( $MK_SRV )); then 
# 		rmdir $MOUNT_SRV 
# 	fi
# }



# [ "$0" == "mount_srv_mint" ] && REP_SCRIPT=`pwd` || REP_SCRIPT=`echo $0 | sed 's/mount_srv_mint//g'`

# BEGIN Mount FUNCTIONS
try_2_mount() {
	if ! mountpoint -q $2; then
		printf "==> Mounting %s..." "$DIR_MOUNT" >&2
		! mount $1:/ $2 && return 0 || return 1 
	else
		return 1
	fi
}

ping_srv() {
	if [ ! -e /tmp/net_ok ]; then
		ping -q -c 2 "$IP_SRV" >/dev/null 2>&1
		[ $? -eq 0 ] && NETWORK_UP="ok" || NETWORK_UP="no"
# 		msg_nn_end "$NETWORK_UP"
		if [ "$NETWORK_UP" == "no" ]; then
			return 0
		else
			return 1
			touch /tmp/net_ok
		fi
	else
		NETWORK_UP="ok"
		return 1
	fi
}

launch_clonage() {
	cp $DIR_SCRIPT/src/* $WORK_DIR
# 	cp $SCRIPT_2_FILE $WORK_DIR
	cp $DIR_SCRIPT_CALUX/tool/prepare_2_maj.sh $WORK_DIR
	cp $DIR_SCRIPT_CALUX/tool/build-iso-live.sh $WORK_DIR
	$SCRIPT_2_EXEC 
	return $?
}

#END

NO_ASK=
[[ "$1" == "-y" ]] && NO_ASK="-y" && shift
IP_SRV="$1"
[[ -z $IP_SRV ]] && echo "==> Aucun serveur spécifié !"
shift 
DIR_MOUNT="/media/srv"
DIR_SCRIPT="$DIR_MOUNT/scripts"
DIR_SCRIPT_CALUX="$DIR_SCRIPT/calux"
WORK_DIR="/tmp/tools"
SLEEP_TIME=60

#
# Choix de configuration
# L'architecture par defaut est celle de chez moi...
# TODO INVERSER...
#
SCRIPT_2_EXEC="$DIR_MOUNT/scripts/calux/embedded.sh $NO_ASK $1 $2 $3"
[[ "$IP_SRV" == "192.168.2.1" ]] && SCRIPT_2_EXEC="$DIR_MOUNT/calux/scripts/embedded.sh $NO_ASK $1 $2 $3" &&
DIR_SCRIPT="$DIR_MOUNT/calux/scripts" &&
DIR_SCRIPT_CALUX="$DIR_SCRIPT"
# SCRIPT_2_EXEC="$WORK_DIR/embedded.sh $NO_ASK $1 0"

# # Old stuff...
# ping -q -c 2 "$IP_SRV" >/dev/null 2>&1
# # Maintenant j'appelle ce script avec l'adresse ip du serveur a contacter en parametre...
# [[ $? -gt 0 ]] || IP_SRV="192.168.1.5"
# mountpoint -q $DIR_MOUNT && cp $DIR_MOUNT/scripts/src/* /tmp/ && $SCRIPT_2_EXEC 



# ping_srv
# PID_PING=$?
# # [[ ! $PID_PING -eq 0 ]] && msg_nn2 "Ping du serveur...ok\n"
# while [[ $PID_PING -eq 0 ]]; do
# 	msg_nn2 "\r" "Ping du serveur" 
# 	i=1
# 	until [ $i -gt 3 ]; do
# 		printf "." >&2
# 		sleep 1
# 		i=$((i+1))
# 	done
# 	ping_srv
# 	PID_PING=$?
# # 	echo $PID_PING
# 	if [[ $PID_PING -eq 0 ]]; then
# 	# TODO NetworManager....
# 		printf "no" >&2
# 	else
# 		printf "ok\n" >&2
# 		break
# 	fi
# 	sleep 2
# 	msg_nn2 "\r" "Ping du serveur%s"  "           "
# done
# 

# exit
[[ ! -e "$DIR_MOUNT" ]] && mkdir "$DIR_MOUNT"
[[ ! -e "$WORK_DIR" ]] && mkdir "$WORK_DIR"

# try_2_mount "$IP_SRV" "$DIR_MOUNT"
# PID_MOUNT=$?
# [[ ! $PID_MOUNT -eq 0 ]] && msg_nn2 "Serveur...ok\n"
# df

if mountpoint -q $DIR_MOUNT; then
	launch_clonage
# 	cp $DIR_MOUNT/scripts/src/* /tmp && cp $DIR_MOUNT/scripts/calux/tool/* /tmp && $SCRIPT_2_EXEC 
fi


while ! mountpoint -q $DIR_MOUNT; do
# 	msg_nn2 "\r" "Serveur" 
# 	i=1
# 	until [ $i -gt 3 ]; do
# 		printf "." >&2
# 		sleep 1
# 		i=$((i+1))
# # 		[ ! -e /proc/$PID_PING/fd/2 ] && break;
# 	done
	try_2_mount "$IP_SRV" "$DIR_MOUNT"
	PID_MOUNT=$?
# 	echo $PID_PING
	if [[ $PID_MOUNT -eq 0 ]]; then
	# TODO NetworManager....
		printf "no" >&2
		error "Le serveur n'a pas pu être monté !"
		sleep 5
		exit 1
	else
		printf "ok\n" >&2
		break
	fi
	sleep 2
# 	msg_nn2 "\r" "Serveur%s"  "           "
done

# cp $DIR_MOUNT/scripts/src/* /tmp
# cp $DIR_MOUNT/scripts/calux/tool/* /tmp
# # cp $DIR_MOUNT/scripts/chroot_common.sh /tmp
# $SCRIPT_2_EXEC 

launch_clonage
exit $?

# sleep $SLEEP_TIME 
# cd "$REP_SCRIPT"
# bash $0 $@ &
