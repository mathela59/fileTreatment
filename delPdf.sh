#!/bin/bash
DIRSRC=apicryptweda2
DIRARCHIVES=archives_apicrypt2
DIRSCANNER=$DIRSRC/COURRIER_a_envoyer
DIRDOUBLON=$DIRSRC/NE_PAS_ENVOYER/TXTissuPDF
DIRERROR=$DIRSRC/erreur_a_traiter
CURRENTDATE=$(date -I)
echo "Verification des dossiers"
if [ ! -d "$DIRSCANNER" ]; then
        echo "Creation du dossier scanner";
        mkdir -p "$DIRSCANNER"
fi
if [ ! -d "$DIRDOUBLON" ]; then
        echo "Creation du dossier Doublons";
        mkdir -p "$DIRDOUBLON"
fi
if [ ! -d "$DIRERROR" ]; then
        echo "Creation du dossier Erreurs";
        mkdir -p "$DIRERROR"
fi
echo "Verification terminée --- Let's Go !!"
read gobble
echo "Suppression des espaces dans les noms de fichiers"
OLDWD=$( pwd )
cd $DIRSRC
find ./ -name "* *" -exec rename 's/ /_/g' "{}" \;
echo "Terminé"

echo "Traitement des doublons Textes qui existent deja en PDF (Fichier extrait automatiquement d'un pdf)"
LIST="$(grep -r -Ei 'automatiquement extrait depuis un document PDF' "$DIRSRC/*.Txt" | cut -c13- |sed -e "s/ /_/g" | sed -e "s/_matches//g")"

for fichier in $LIST
do
        BASE=$( basename $fichier )
        DIRSRC=$( dirname $fichier )
        echo "Deplacement du fichier $BASE du repertoire $DIRSRC vers le répertoire $DIRDOUBLON/$CURRENTDATE"
        mv $fichier "$DIRDOUBLON/$CURRENTDATE/$BASE"
done
echo "Terminé"

echo "Traitement des courriers textes contenant : cher confrere, cher confreres, consoeur, etc ..."
LIST="$(grep -r -Eil 'cher Confrere|chere Consœur|cher confrére|cher confrère|cher ami' $DIRSRC/*.Txt)"
for fichier in $LIST
do
        FILENAME=$( basename $fichier )
        echo "Deplacement du fichier $FILENAME vers $DIRSCANNER/$CURRENTDATE"
        INIT=$(echo "$DIRSRC/$FILENAME" )
        DEST=$(echo "$DIRSCANNER/$CURRENTDATE/$FILENAME" )
#       echo "$INIT --- $DEST"
        mv $INIT $DEST
done
echo "Terminé"

echo "Conversion des fichiers texte en PDF dans le dossier scanner"
cd $DIRSRC
for FILE in $( ls *.Txt )
do
        IFS=':'
        cp $FILE $FILE.save
        file --mime-encoding $FILE
        iconv -c -t utf-8 $FILE -o $FILE
        pandoc $FILE -o $(basename $FILE .txt | sed -e "s/.Txt//g" )-auto.pdf
        retour=$?
        if [ $retour = 0 ]
        then
                rm $FILE $FILE.save
        else
                echo "ERREUR dans le traitement du fichier $FILE"
                mv $FILE.save $DIRERROR/$FILE.error
                rm $FILE
        fi

done
echo "Terminé"
