#!/bin/bash


# Zum Scannen in die DV Dokumentenablage (pat_nr). 
# Speedpoint GmbH (MR,FW), Stand: Oktober 2013, Version 3 (Xdialog)
#
# DisplayAusgabe.sh wird am Linux Server vorausgesetzt,
# am Windows PC wird Rexserver benoetigt.


# Bitte anpassen:  #############################################################
#
ip="192.168.0.10"                    # IP des WinPC (Rexserver!)
port="6666"                          # Port fuer Rexserver
batch="c:\\david\startscan.bat"      # Batchdatei am WinPC, "c:\\" beachten!!
#
################################################################################














# Ab hier bitte Finger weg!


# Fehler ausgeben, falls aktuelles X Display nicht gefunden wurde:
#
ichbins=`whoami`
if [ ! -e /home/$ichbins/DisplayAusgabe ]; then
   echo ""
   echo "*****************************************************************"
   echo "Scanmodul nicht initialisiert, wurde DisplayAusgabe.sh gestartet?"
   echo "*****************************************************************"
   echo ""
   exit 1
fi


export XAUTHORITY=/home/$ichbins/.Xauthority
export DISPLAY=`cat /home/$ichbins/DisplayAusgabe`


# Und los...


# Welcher Patient ist gerade augerufen?
serverpfad=$DAV_HOME/trpword/pat_nr
pfad=`echo $1 | awk '{printf("%08.f\n",$1)}' \
              | awk -F '' '{printf("%d/%d/%d/%d/%d/%d/%d/%d",$1,$2,$3,$4,$5,$6,$7,$8)}'`
fullpfad=$serverpfad/$2/$pfad
mkdir -p -m 0777 "$fullpfad" > "/dev/null" 2>&1 
 

# Leeres Zwischenziel fuer gescantes PDF anlegen:
link="/home/david/trpword/Patient"
if [ ! -d $link ]; then
   mkdir $link
fi
rm -f $link/* 2>>/dev/null

if [ ! -d $link ]; then
   Xdialog --title "Abbruch" --msgbox "Pat.ordner konnte nicht angelegt werden, bitte Speedpoint anrufen." 6 80
   exit 1
fi


#Batchscan am Windowsrechner starten:
echo "DAVCMD start /min $batch" | netcat $ip $port >/dev/null


# Dokumentennamen erfragen:
Xdialog --cancel-label "Abbruch"            \
        --title "Dokumentennamen eingeben"  \
        --clear                             \
        --inputbox "- Bitte einen Dateinamen (ohne Endung) eingeben: " 20 80 Dokument 2>/tmp/inbox.tmp.$$

if [ $? = 1 ]; then
   rm -f $link/*
   Xdialog --title "Abbruch durch Benutzer" --msgbox "Das Dokument wurde nicht gespeichert." 6 70
   exit 1
fi


# PDF in Dokumentenablage speichern:
docnam=`cat /tmp/inbox.tmp.$$`
docpdf=`echo $docnam | sed 's/ /_/g'`
cp -pf $link/*.pdf $fullpfad/$docpdf.pdf
rm -f $link/*

rm -f /tmp/inbox.tmp.$$

exit 0
