# Lives PXE
Ici vous devrez ajouter les dossiers calux, calux3, calux-install, linuxmint-18.3 et ubuntu-mate<br />
\# mkdir /home/calux/pxe/{calux,calux3,calux-install,linuxmint-18.3,ubuntu-mate}<br />
Le script lancant le reconditionnement devrait monter chacune des isos du repertoire ~/ISOS<br />
On pourra alors lancer les systeme en Live via PXE.
<br />
# Clonezilla
On doit aussi télécharger une image de clonezilla<br />
\# mkdir /tmp/clonezilla<br />
\# cd /tmp/clonezilla<br />
\# wget https://osdn.net/frs/redir.php?m=dotsrc\&f=clonezilla%2F68292%2Fclonezilla-live-2.5.2-31-amd64.zip<br />
\# unzip *.zip<br />
Pour copier le noyau, l'initramfs, et le filesystem.squashfs dans notre repertoire racine du serveur pxe<br />
\# cp live/{vmlinuz,initrd.img,filesystem.squashfs} /home/calux/pxe/clonezilla-2.5<br />
Pour ce qui est de l'ancienne version de clonezilla, soit gardez une copie locale, soit retrouver un lien de téléchargement...
# debian installer
Comme pour clonezilla, on va télécharger les fichiers nécessaires et les copier dans notre racine PXE<br />
\# mkdir /tmp/debinstall<br />
\# cd /tmp/debinstall<br />
\### Archive x64<br />
\# wget http://ftp.nl.debian.org/debian/dists/stretch/main/installer-amd64/current/images/netboot/netboot.tar.gz<br />
\# tar -xzf netboot.tar.gz && rm *.tar.gz<br />
\### Archive i686<br />
\# wget http://ftp.nl.debian.org/debian/dists/stretch/main/installer-i386/current/images/netboot/netboot.tar.gz<br />
\# tar -xzf netboot.tar.gz && rm *.tar.gz<br />
\### Et enfin la copie<br />
\# cp -R  debian-installer /home/calux/pxe/<br />
