#!/bin/bash

		CUST=""					 # Kunde
        	DATE=$(date +"%m-%d")				 # Variable mit dem Datum
        	SENDMAIL=/usr/sbin/sendmail                    	 # Pfad der sendmail binary

        	BDIR="/home/sysadmin/backup"
        	TAR=$CUST"_"$HOSTNAME"_"$DATE".tar"



case "$1" in
-[bB]|-backup)

	if [ "$(id -u)" != "0" ]; then
		echo ""
		echo "+-----------------------------------------------+"
		echo "| Dieses Script muss als root ausgeführt werden |"
		echo "+-----------------------------------------------+"
		echo ""
        	exit 1
	else
		mkdir /home/sysadmin/backup
        	cd $BDIR
        	rm -rf *
        	mkdir bind

        	cp /home/sysadmin/.bashrc $BDIR

		echo "[+] Stoppe ddclient"
		service ddclient stop
        	cp /etc/ddclient.conf $BDIR
		echo "[+] Starte ddclient"
		service ddclient start

		echo "[+] Stoppe DHCP"
		service isc-dhcp-server stop
        	cp /etc/default/isc-dhcp-server $BDIR
        	cp /etc/dhcp/dhcpd.conf $BDIR
        	echo "[+] Starte DHCP"
		service isc-dhcp-server startr

		cp /etc/hostname $BDIR
        	cp /etc/hosts $BDIR
        	cp /etc/network/interfaces $BDIR
        	cp /opt/pandora/iptables.sh $BDIR

		echo "[+] Stoppe postfix"
		service postfix stop
        	cp /etc/postfix/main.cf $BDIR
		echo "[+] Starte postfix"
		service postfix start

                echo "[+] Stoppe ssh-server"
                service ssh stop
        	cp /etc/ssh/sshd_config $BDIR
                echo "[+] Starte ssh-server"
                service ssh start

		cp /opt/shell-login.sh $BDIR
        	cp /etc/sysctl.conf $BDIR

		echo "[+] Stoppe bind"
		service bind9 stop
        	cp /etc/bind/* $BDIR/bind
        	cp /var/lib/bind/bind9-default.md5sum $BDIR
        	cp /var/cache/bind/* $BDIR
		echo "[+] Starte bind"
		service bind9 start

        	tar -vcf /tmp/$TAR *

		scp /tmp/$TAR XXX@XXX:xxx/xxx
	fi
;;

-[rR]|-restore)

	if [ "$(id -u)" != "0" ]; then
                echo ""
                echo "+-----------------------------------------------+"
                echo "| Dieses Script muss als root ausgeführt werden |"
                echo "+-----------------------------------------------+"
                echo ""
		exit 1

	fi

	if [ -z "$2" ]; then
		echo ""
		echo "+-------------------------------------+"
		echo "| Es wurde kein tar-Archiv ausgewählt |"
		echo "+-------------------------------------+"
		echo ""
		exit 2

	elif [[ $2 != *.tar ]]; then
		echo ""
		echo "+-------------------------+"
		echo "| Das ist kein tar-Archiv |"
		echo "+-------------------------+"
		echo ""
		exit 3

	else

		echo "[+] USB-Stick wird gemountet"
		mount /dev/sdb1 /mnt/
		echo "[+] Backup wird kopiert"
		cp /mnt/$2 /home/sysadmin/
		echo "[+] USB-Stick wird geunmountet"
      		umount /mnt/
       	 	cd /home/sysadmin
		echo "[+] Backup wird entpackt"
        	tar -xf $2
	fi
		echo "[+] Dateien werden kopiert"
        	#cp .bashrc /home/sysadmin/

		echo "[+] Stoppe ddclient"
                service ddclient stop
        	cp ddclient.conf /etc/

		echo "[+] Stoppe DHCP"
                service isc-dhcp-server stop
		cp isc-dhcp-server /etc/default/
        	cp dhcpd.conf /etc/dhcp/

		cp hostname /etc/
        	cp hosts /etc/
        	cp interfaces /etc/network/
        	cp iptables.sh /opt/pandora/

                echo "[+] Stoppe postfix"
                service postfix stop
        	cp main.cf /etc/postfix/

		echo "[+] Stoppe ssh-server"
		service ssh stop
        	cp sshd_config /etc/ssh/
        	cp shell-login.sh /opt/
        	cp sysctl.conf /etc/
		sysctl -p /etc/sysctl.conf

                echo "[+] Stoppe bind"
                service bind9 stop
        	cp bind/* /etc/bind/
        	cp bind9-default.md5sum /var/lib/bind/
        	cp managed* /var/cache/bind/

        	chmod +x /opt/pandora/iptables.sh
        	chmod +x /opt/shell-login.sh

	        #bash +x /opt/pandora/iptables.sh

		echo "[+] Das System wurde erfolgreich wiederhergestellt"
		echo ""
		echo "Soll die Pandora neugestartet werden ? [Y/n]"
		read eingabe

		if [[ $eingabe = Y || $eingabe = y || $eingabe = "" ]]; then

		reboot

		else

		exit 4

		fi

exit 0

;;

-[lL]|-list)

		ba=$CUST"_"$HOSTNAME
		mount /dev/sdb1 /mnt/
		echo -e "\e[4mListe aller vorhandenen Backups\e[24m"
		ls /mnt/$ba*
		umount /mnt/

;;

-[cC]|-configure)

		hostname=$(\
		dialog --title "Hostname : /etc/hostname" \
         	--inputbox "Bitte den Namen der Pandora eintragen" 8 50 pandora\
  		3>&1 1>&2 2>&3 3>&- \
)
		interfaces0=$(\
		dialog --title "Interfaces : /etc/network/interfaces" \
		--inputbox "Bitte die IP von eth1 eintragen " 8 40 \
		3>&1 1>&2 2>&3 3>&- \
)
		interfaces1=$(\
		dialog --title "Interfaces : /etc/network/interfaces" \
         	--inputbox "Bitte die Subnetzmaske eintragen " 8 40 255.255.255.0 \
  		3>&1 1>&2 2>&3 3>&- \
)
		dhcp0=$(\
  		dialog --title "DHCP : /etc/dhcp/dhcpd.conf" \
         	--inputbox "Bitte die Netz-ID eintragen" 8 40 \
  		3>&1 1>&2 2>&3 3>&- \
)
		dhcp1=$(\
  		dialog --title "DHCP : /etc/dhcp/dhcpd.conf" \
         	--inputbox "Bitte die Subnetzmaske eintragen " 8 40 255.255.255.0 \
  		3>&1 1>&2 2>&3 3>&- \
)
		dhcp2=$(\
  		dialog --title "DHCP : /etc/dhcp/dhcpd.conf" \
         	--inputbox "Bitte den DNS eintragen " 8 40 \
  		3>&1 1>&2 2>&3 3>&- \
)
		dhcp3=$(\
  		dialog --title "DHCP : /etc/dhcp/dhcpd.conf" \
         	--inputbox "Bitte die Broadcast-Addresse eintragen " 8 50 \
  		3>&1 1>&2 2>&3 3>&- \
)
		dhcp4=$(\
		dialog --title "DHCP : /etc/dhcp/dhcpd.conf" \
         	--inputbox "Bitte den Router eintragen " 8 40 \
  		3>&1 1>&2 2>&3 3>&- \
)
		dhcp5=$(\
  		dialog --title "DHCP : /etc/dhcp/dhcpd.conf" \
         	--inputbox "Bitte die DHCP-range eintragen (z.B. 192.168.0.2 192.168.0.99)" 8 70 \
  		3>&1 1>&2 2>&3 3>&- \
)

		sed -i 10c"$hostname.dyndns.biz" /etc/ddclient.conf

		sed -i 1c"$hostname" /etc/hostname
		sed -i 1c"$hostname.pandora.local $hostname" /etc/hosts

		sed -i 18c"address $interface0" /etc/network/interfaces
		sed -i 19c"netmask $interface1" /etc/network/interfaces

		sed -i 111c"subnet $dhcp0 netmask $dhcp1 {" /etc/dhcp/dhcpd.conf
		sed -i 113c"option domain-name-servers $dhcp2;" /etc/dhcp/dhcpd.conf
		sed -i 114c"option broadcast-address $dhcp3;" /etc/dhcp/dhcpd.conf
		sed -i 115c"option subnet-mask $dhcp1;" /etc/dhcp/dhcpd.conf
		sed -i 116c"option routers $dhcp4;" /etc/dhcp/dhcpd.conf
		sed -i 118c"range $dhcp5;" /etc/dhcp/dhcpd.conf

		sed -i 31c"myhostname = $hostname.reifen.com" /etc/postfix/main.cf
		sed -i 34c"mydestination = $hostname, localhost.localdomain, localhost" /etc/postfix/main.cf

;;

-[hH]|-help)

		clear
		echo -e "\e[1mPandora Backup and Restore\e[21m"
		echo ""
		echo -e "\e[1mNAME\e[21m"
		echo "	almighty - sichern, wiederherstellen und konfigurieren der Pandora"
		echo ""
		echo -e "\e[1mSYNOPSIS\e[21m"
		echo -e "	almighty [-b] [-r \e[4mtar\e[24m] [-h] [-l] [-c]"
		echo ""
		echo -e "\e[1mDESCRIPTION\e[21m"
		echo "	-b : backup"
		echo "		Sichert alle Dateien die wir für eine Wiederherstelung brauchen."
		echo "		Die benötigten Dateien werden nach ~/backup kopiert und anschließend wird daraus ein tar-Archiv erstellt."
		echo "		Nachdem das tar-Archiv erstellt wurde wird es auf einen Backupserver transferiert."
		echo ""
		echo -e "	-r \e[4mtar\e[24m : restore"
		echo "		Entpackt das tar-Archiv und kopiert alle Dateien an ihren entsprechenden Ort."
		echo "		Damit die Wiederherstellung funktioniert muss ein USB-Stick mit der Pandora verbunden werden."
		echo "		Das tar-Archiv muss im root-Verzeichnis des USB-Sticks liegen."
		echo ""
		echo "	-h : help"
		echo "		Zeigt die Hilfeseite an."
		echo ""
		echo "	-l : list"
		echo "		Liste alle alle Backups auf die auf dem USB-Stick sind."
		echo ""
		echo "	-c : configure"
		echo "		Startet den grafischen Assistenten zur Konfiguration der Pandora."
		echo ""
		echo -e "\e[1mEXAMPLE\e[21m"
		echo "	Sichern"
		echo "		almighty -b"
		echo ""
		echo "	Wiederherstellen"
		echo "		almighty -r BACKUP.tar"
		echo ""

;;
esac
