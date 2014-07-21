#!/bin/bash

# Zum Scannen in einen pat_nr Pat.ordner. Basierend auf patordner.sh
# Speedpoint GmbH (MR,FW), Stand: Juli 2014, Version 3

# Bitte anpassen:    ###########################################################
#
ip="192.168.0.20"                    # IP des WinPC (Rexserver!)
port="6666"                          # Port fuer Rexserver
batch="c:\\david\startscan.bat"      # Batchdatei am WinPC, "c:\\" beachten!!
#
#
# Unterordner-Abfrage, in dem die Scandateien gespeichert werden sollen:
# -----------------------------------------------------------------------
# - wenn Unterordner-Abfrage nicht erwünscht (Scan-Dokumente werden direkt im Patordner gespeichert):
#   scanfilesubdir="" setzen (nichts)
# - wenn Abfrage erwünscht:
#   - Default-Vorschlag in der Abfrage (kann in Abfrage überschrieben werden): 
#     scanfilesubdir=DEFAULTORDNER-NAMEN      z.B. scanfilesubdir="Scan"
#   - leere Abfrage ohne Vorschlag:
#     scanfilesubdir="LEER"                   alles groß schreiben!
scanfilesubdir="LEER"
#
#
################################################################################

# Und los...

function abfrage ()
{
# Übergabewerte
typ=$1     # fnam oder dirnam
dirdefault=$2
[ "$typ" = "fnam" ] && dtext="Dokumentnamen" || dtext="Unterordner-Namen"
eingabeloop=1
while [ $eingabeloop = 1 ]; do
   eingabeloop=0
   if [ "$ostype" = "suse" ]; then
      eingabe=`kdialog --inputbox "Bitte den $dtext eingeben:" "$dirdefault"`
      retval=$?
   else
      /usr/bin/Xdialog --title "Scanmodul" --inputbox "Bitte den $dtext eingeben:" 0 0 "$dirdefault"  2>/tmp/scaninputbox.tmp.$$ 
      retval=$?
      eingabe=`cat /tmp/scaninputbox.tmp.$$`
      rm -f /tmp/scaninputbox.tmp.$$
   fi
   if [ $retval = 1 ]; then
      rm -f $link/*
      if [ "$ostype" = "suse" ]; then
         kdialog --error "ABBRUCH, Dokument wurde nicht gespeichert."
      else
         /usr/bin/Xdialog --title "Scanmodul" --msgbox "ABBRUCH, Dokument wurde nicht gespeichert." 0 0
      fi
      exit 1
   fi

   # Test auf leere Eingabe
   eingabe=`echo $eingabe|sed 's/ //g'`
   if [ "$eingabe" = "" ]; then
      if [ "$ostype" = "suse" ]; then
         kdialog --yesno "Falsche Eingabe: Kein $dtext eingegeben. Eingabe wiederholen?"
         retval=$?
      else
         /usr/bin/Xdialog --title "Scanmodul" --yesno "Falsche Eingabe: Kein $stext eingegeben. Eingabe wiederholen?" 0 0
         retval=$?
      fi
      if [ $retval = 1 ]; then
         if [ "$ostype" = "suse" ]; then
            kdialog --error "ABBRUCH, Dokument wurde nicht gespeichert."
         else
            /usr/bin/Xdialog --title "Scanmodul" --msgbox "ABBRUCH, Dokument wurde nicht gespeichert." 0 0
         fi
         exit 1
      else
         eingabeloop=1
      fi
   fi
done
}


# welches Betriebssystem?
[ "`cat /etc/issue|fgrep "Scientific"`" ]  && ostype="sl" || ostype="suse"

# evtl. Leerzeichen aus Unterordnernamen entfernen
scanfilesubdir=`echo $scanfilesubdir|sed 's/ /_/g'`
# falls Unterordnernamen nur ein Leerzeichen enthält (falscher Eintrag)
[ "$scanfilesubdir" = "_" ] && scanfilesubdir=""

# Welcher Patient ist gerade augerufen?
serverpfad=$DAV_HOME/trpword/pat_nr
pfad=`echo $1 | awk '{printf("%08.f\n",$1)}' \
              | awk -F '' '{printf("%d/%d/%d/%d/%d/%d/%d/%d",$1,$2,$3,$4,$5,$6,$7,$8)}'`

# Leeres Zwischenziel fuer gescantes PDF anlegen:
link="/home/david/trpword/Patient"
if [ ! -d $link ]; then
   mkdir $link
fi
rm -f $link/* 2>>/dev/null

if [ ! -d $link ]; then
   if [ "$ostype" = "suse" ]; then
      kdialog --sorry "Pat.ordner konnte nicht angelegt werden, bitte Speedpoint anrufen."
   else
      /usr/bin/Xdialog --title "Scanmodul" --msgbox "Pat.ordner konnte nicht angelegt werden, bitte Speedpoint anrufen." 0 0
   fi
   exit 1
fi

#Batchscan am Windowsrechner starten:
echo "DAVCMD start /min $batch" | netcat $ip $port >/dev/null

# Dokumentennamen erfragen:
abfrage "fnam"
docnam=$eingabe

# Subdirectory  erfragen:
if [ "$scanfilesubdir" = "" ]; then
   # kein Abfragedialog, direkt im Patordner speichern
   fullpfad=$serverpfad/$2/$pfad
else
   [ "$scanfilesubdir" = "LEER" ] && scanfilesubdir=""
   abfrage "dirnam" $scanfilesubdir
   subdirnam=$eingabe
   # falls vorhanden das / am Anfang abschneiden
   [ "`echo $subdirnam|cut -c1`" = "/" ] && subdirnam=`echo $subdirnam|cut -c2-`
   # falls vorhanden das / am Ende abschneiden
   [ "`echo $subdirnam|rev|cut -c1`" = "/" ] && subdirnam=`echo $subdirnam|sed 's/.$//'`
   # Leerzeichen durch _ ersetzen
   scanfilesubdir=`echo $subdirnam | sed 's/ /_/g'`
   fullpfad=$serverpfad/$2/$pfad/$scanfilesubdir

   # Subdirectory anlegen
   mkdir -p -m 0777 "$fullpfad" > "/dev/null" 2>&1 

   if [ ! -d $fullpfad ]; then
      if [ "$ostype" = "suse" ]; then
         kdialog --sorry "Unterordner >$scanfilesubdir< konnte nicht angelegt werden, bitte Speedpoint anrufen."
      else
         /usr/bin/Xdialog --title "Scanmodul" --msgbox "Unterordner >$scanfilesubdir< konnte nicht angelegt werden, bitte Speedpoint anrufen." 0 0
      fi
      exit 1
   fi
fi

# PDF speichern:
docpdf=`echo $docnam | sed 's/ /_/g'`
cp -pf $link/*.pdf $fullpfad/$docpdf.pdf
rm -f $link/*
# Überprüfen
if [ ! -e $fullpfad/$docpdf.pdf ]; then
   if [ "$ostype" = "suse" ]; then
      kdialog --sorry "Das Dokument konnte nicht im Patordner gespeichert werden, bitte Speedpoint anrufen."
   else
      /usr/bin/Xdialog --title "Scanmodul" --msgbox "Das Dokument konnte nicht im Patordner gespeichert werden, bitte Speedpoint anrufen." 0 0
   fi
   exit 1
fi

exit 0
