#!/bin/bash

#
#   Ce script initialise les connexions de manière à être opérationel pour reconditionner.
# On utilise l'interface principale Ethernet (a changer selon les besoins) pour le service dnsmasq.*
# 
# 
# Lorsque l'adapateur Ethernet vers USB est connecté, on va se connecter en DHCP et partager le Net sur le sous réseau crée avec dnsmasq
#
# Si on dipose d'une connexion WiFi, on va essayer de se connecter au réseau enregistré avec wpa_passphrase
# inscrit dans /home/$USER2USE/wf_network.conf... 
# Renseignez vous sur wpa-passphrase pour enregistrer votre clé réseau dans le fichier
#
# Si 2 connexions Wifi sont détectées, il faudra indiquer dans le script laquelle on souhaite utiliser...
#
# A CHANGER SELON LES BESOINS :
# 
# CONN_1=enp0s25
# CONN_FAC=wf0
# 
# On trouve les adresses réseau en tapant "ip addr" dans un terminal
# Les interfaces Ethernet on un nom du type "enp?s??" ou "ens?" et anciennement "eth?" avec des chiffres a la place des "?"
# De meme, les interface wifi donne "wlp?s??" et ancienement "wlan?"

# Toutefois, il n'est pas essentiel d'utiliser Internet...
#
#


# Recherche les interfaces reseaux ethernet ou wifi
list_if() {
	IFACES=""
	TFACES=()
	[[ "$1" != "wifi" ]] &&
    # Interfaces ethernet a revoir...	
		for i in $( lspci | grep Ethernet | awk '{print $1}' ); do
			iface=$(echo "enp$((16#$(echo $i | sed "s/\(.*\):.*/\1/" | sed "s/\..*//" ) ))s$((16#$(echo $i | sed "s/.*:\(.*\)\..*/\1/" | sed "s/\..*//" ) ))")
			# j le nombre de connexion...
			j=$((j+1))
			valid_iface[$iface]="$j"
			valid_iface[$j]="dhcpcd@$iface"
			TFACES=( "${TFACES[@]}" "dhcpcd@${iface} $( ip addr | grep $i -A 2 | grep "inet " | awk '{print $2}' | sed "s/\(.*\)/( \1 )/" )")
			IFACES="${IFACES}\t$j) dhcpcd@${iface} $( ip addr | grep $i -A 2 | grep "inet " | awk '{print $2}' | sed "s/\(.*\)/( \1 )/" )\n"
		done
	[[ "$1" != "eth" ]] && 
    # Interfaces wifi
		for i in $( ip addr | grep "^[0-9]: w" | sed "s/^.*: \(.*\):.*/\1/g" ); do
			if [[ "$i" != "lo" ]]; then
				iface=$i
				j=$((j+1))
				valid_iface[$iface]="$j"
				valid_iface[$j]="$iface"
				TFACES=( "${TFACES[@]}" "WiFi: ${iface} $( ip addr | grep $i -A 2 | grep "inet " | awk '{print $2}' | sed "s/\(.*\)/( \1 )/" )")
				IFACES="${IFACES}\t$j) WiFi: ${iface} $( ip addr | grep $i -A 2 | grep "inet " | awk '{print $2}' | sed "s/\(.*\)/( \1 )/" )\n"
			fi
		done
	[[  -z $IFACES ]] && return 1
	return 0
} 


function mount_iso() {
    [[ -e "$PATH_ISOS/$1" ]] && ! mountpoint -q "/home/calux/pxe/$2" && mount -o loop "$PATH_ISOS/$1" "/home/calux/pxe/$2"
# || echo "Impossible de trouver l'iso \"$PATH_ISOS/$1\""
}

function msg_log() {
	echo -e "$@" >> /tmp/log
}

function msg_user() {
# 	[[ ! -z $DISPLAY ]] && sudo -u $USER2USE DISPLAY=:0 notify-send "$@"
	[[ ! -z $DISPLAY ]] && sudo -u $USER2USE DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u $USER2USE)/bus	notify-send "$@"
}

function connect_wifi() {
    if [[ -e $PATH_WIFI ]]; then 
        ps -aux | grep wpa_supplicant | grep -q $CONN_2 && killall wpa_supplicant 
#        nohup wpa_supplicant -i$CONN_FAC -c $PATH_WIFI >> /dev/null &
#        sleep 10
        wpa_supplicant -B -i$CONN_2 -c $PATH_WIFI 
        return 0
    fi
    return 1
}

function wait4dhclient() {
#    TIME_OUT=0
#    while ps -e | grep -q dhclient && [[ $TIME_OUT -lt 10 ]]; do
#        sleep 1
#        TIME_OUT=$((TIME_OUT+1))
#    done
#    [[ $TIME_OUT -eq 10  ]] && echo -e "Impossible d'arreter dhclient\n==>Arret..." && dhclient -r
#    [[ $TIME_OUT -eq 10  ]] && msg_log "Impossible d'arreter dhclient\n==>Arret..." && killall dhclient
    ps -aux | grep dhclient | grep -q $CONN_1 && killall dhclient
}


# Lancer le service quand on retire la clé
[[ -z "$1" ]] && systemctl start sw-conn@remove && exit

# Essaie de deconnecter mon serveur...
mountpoint -q /media/srv && umount /media/srv && MOUNT_SRV=1


declare -A valid_iface

USER2USE=cadm
PATH_UTILS=/home/$USER2USE
PATH_ISOS="$PATH_UTILS/ISOS"
PATH_WIFI="$PATH_UTILS/wf_network.conf"

CONN_1=enp0s25
CONN_2=usb0
# Connexion alternative si usb0 n'existe pas...
CONN_FAC=wf0

if ! ip ad | grep -q $CONN_1; then
    msg_log "==> ERREUR : L'interface Ethernet $CONN_1 n'existe pas !\nChanger la valeur de \"CONN_1\" dans /home/$USER2USE/switch_connexion.sh"
    msg_user "L'interface Ethernet $CONN_1 n'existe pas !" "Changer la valeur de \"CONN_1\" dans /home/$USER2USE/switch_connexion.sh"
    exit 1;
fi
if ! ip ad | grep -q $CONN_2; then
    CONN_2=$CONN_FAC
fi
if ! ip ad | grep -q $CONN_2; then
    ! list_if "wifi" && unset CONN_2 && msg_log "==> ERREUR : Aucune interface WiFi trouvée !"
    if [[ ! -z ${valid_iface[2]} ]]; then
        msg_user "Veuillez choisir manuellement une connexion WiFi !"
    else
        CONN_2="${valid_iface[1]}"
        CONN_FAC="${valid_iface[1]}"
    fi
fi

# A la connexion de l'adaptateur 
if [[ "$1" == "add" ]]; then
    msg_log "==> Initialisation..."
	# On réinitialise les connexions de base (wifi,ethernet...)
	systemctl is-active dhcpcd -q && systemctl stop dhcpcd
	systemctl is-active dhcpcd@$CONN_1 -q && systemctl stop dhcpcd
	systemctl is-active NetworkManager -q && systemctl stop NetworkManager
#	killall nm-applet
    command -v dhclient >> /dev/null && wait4dhclient
    # Reinitialisation de $CONN_1 
	ip link set down dev $CONN_1
    # On supprime toute les adresses IP
    ip addr flush dev $CONN_1
	# On lance l'ip statique sur la carte interne  (ens5) pour le pxe
	ip addr add 192.168.2.1/24 dev $CONN_1
	ip link set up dev $CONN_1
	# Et on relance le service...
	systemctl restart dnsmasq

    # On monte les ISOS qui nous intéresse
    mount_iso "ubuntu-mate-16.04.1-desktop-amd64.iso" "ubuntu-mate"
    mount_iso "linuxmint-18.3-mate-32bit.iso" "linuxmint-18.3"
    mount_iso "calux-latest.iso" "calux"
    mount_iso "calux3-latest.iso" "calux3"
    mount_iso "calux4-install.iso" "calux-install"

	# Reprise de la connexion sur usb ou en wifi
    if [[ ! -z $CONN_2 ]]; then
        msg_user "Reprise de la connexion Internet sur $CONN_2"
        msg_log "  -> Reprise de la connexion Internet sur $CONN_2"
        if  [[ "$CONN_2" == "$CONN_FAC" ]]; then 
            msg_log "  -> Demarrage de la connexion wifi..."
            if connect_wifi; then 
                msg_log "  -> Attribution d'une adresse ip..."
                ! command -v dhclient >> /dev/null && systemctl restart dhcpcd@$CONN_2 || dhclient $CONN_2
            else
                msg_user "Aucun réseau trouvé !" "Creer votre fichier de configuration pour un réseau wifi avec \"wpa_passphrase SSID > wf_network.conf\" puis taper votre code wifi..."
            fi
        else
            msg_log "  -> Attribution d'une adresse ip..."
	        ! command -v dhclient >> /dev/null && systemctl restart dhcpcd@$CONN_2 || dhclient $CONN_2
        fi
	    # On cree une regle iptables pour partager la connexion Internet de usb0 vers ens5
	    iptables -t nat -A POSTROUTING -o $CONN_2  -j MASQUERADE
	    iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	    iptables -A FORWARD -i $CONN_1 -o $CONN_2 -j ACCEPT
	    # Sauvegarde (est reinitialisé apres chaque reboot)	
    #	iptables-save > /etc/iptables/iptables.rules

        sysctl net.ipv4.ip_forward=1 >> /dev/null

    fi

# 	systemctl is-active apt-cacher-ng -q && systemctl start apt-cacher-ng
	# Le message pour notify-send
	MSG_NS="Connexion(s) prêtes pour reconditionner !"
	msg_log "==> $MSG_NS"
	# Si on deconnecte ...
else
	if [[ ! -z $CONN_2 ]]; then
        msg_log "==> Arret de la connexion sur \"$CONN_2\""
        ! command -v dhclient >> /dev/null && systemctl stop dhcpcd@$CONN_2 || dhclient -r $CONN_2
    fi

	# Et on stop le service...
	systemctl stop dnsmasq
    # On efface l'ip fixe de $CONN_1
    ip addr del 192.168.2.1/24 dev $CONN_1
    # On arrete wpa_supplicant sur $CONN_FAC
    ps -aux | grep wpa_supplicant | grep -q $CONN_FAC && killall wpa_supplicant 
	# On relance les services de connexion
	systemctl is-enabled NetworkManager -q && systemctl restart NetworkManager
	systemctl is-enabled dhcpcd -q && systemctl restart dhcpcd
	systemctl is-enabled dhcpcd@$CONN_1 -q && systemctl restart dhcpcd@$CONN_1
#		sudo -u $USER2USE DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus	 -b nm-applet
	MSG_NS="==> Connexions réinitialisées !"
	msg_log "  -> Lancement de NetworkManager\n$MSG_NS"

fi
# Et on avertit l'utiliisateur !!!
msg_user "$MSG_NS"

(( MOUNT_SRV )) && mount 192.168.1.5:/ /media/srv
exit 0
