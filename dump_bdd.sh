#!/bin/bash
# =======================================================
# NAME: dump_bdd.sh
# AUTHOR: Joachim
# DATE: 21/09/19
# MODIFICATION: 31/01/20
# License: UNLICENSE
# VERSION 1
# COMMENTS: Script permettant de faire des dumps de base de données et de les compresser
# =======================================================

# déclaration des variables pour coloriser les outputs
declare -r YL='\e[33m' # Yellow
declare -r RD='\e[31m' # Red
declare -r GN='\e[92m' # Green
declare -r RST="\e[0m" # Reset

# Variable Serveur
SRV_HOSTNAME=$(hostname)
declare -r SRV_TIME=$(date +"%d_%m_%Y")
declare -r SRV_LOG="/var/log/dump.log"
# Variable pour Mysql
declare -r MYSQL_BIN='/usr/bin/mysqldump'
declare -r MYSQL_ROOT_LOGIN='root'
declare -r MYSQL_ROOT_PASS=''
declare -r MYSQL_HOST='localhost'
declare -r MYSQL_DUMP_FOLDER="/backup/db_dump"
declare -r MYSQL_CMD="-u$MYSQL_ROOT_LOGIN -p$MYSQL_ROOT_PASS -h$MYSQL_HOST"
declare -r INDIVIDUAL_DUMP=$2
declare -r MYSQL_EXT='.sql'

trap exit_script SIGINT
if [[ $EUID -ne '0' ]]; then
  echo -e "$RD You must be root ${RST}"
  exit 1
fi

if ! command -v $MYSQL_BIN >/dev/null 2>&1; then
  echo  -e "$RD mysqldump not found ${RST}"
  exit 2
fi

# On test l'écriture dans notre point de montage
if ! touch $MYSQL_DUMP_FOLDER'/testfile'; then
  echo -e "$RD Permission denied ${RST}"
  exit 4
else
  rm "${MYSQL_DUMP_FOLDER}/testfile"
fi

function dump_all_user_created_db() {
  # On récupère en variable le nom des bdd et on enlève du scope les bdd systèmes
DB=$(mysql -u${MYSQL_ROOT_LOGIN} -p${MYSQL_ROOT_PASS} -e 'show databases;'| grep -Ev "(Database|information_schema|mysql|performance_schema|sys)")
  for dbname in $DB
  do
    ${MYSQL_BIN} ${MYSQL_CMD} --single-transaction --databases $dbname > ${MYSQL_DUMP_FOLDER}/${SRV_TIME}'_'${SRV_HOSTNAME}'_'${dbname}${MYSQL_EXT} || echo -e "$RD DUMP KO " >> $SRV_LOG
    echo -e "$GR $dbname has been dump ! ${RST}" | awk '{ print strftime("%H:%M:%S"), $0; }' >> $SRV_LOG
  done
}
function dump_individual() {

  # On vérifie qu'on a un argument en $2
  if [[ $INDIVIDUAL_DUMP == "" ]]; then
    echo -e "$RD no argument found"
    exit 5
  else
    # Dump de la base de données
    ${MYSQL_BIN} ${MYSQL_CMD} --single-transaction --databases "$INDIVIDUAL_DUMP" > ${MYSQL_DUMP_FOLDER}/${SRV_TIME}'_'${SRV_HOSTNAME}'_'${INDIVIDUAL_DUMP}${MYSQL_EXT}
  fi

  if [[ $? -ne '0' ]]; then
    echo -e "$RD Dump KO ! "${RST} >> $SRV_LOG
    exit 6
  else
    # Envoie d'un rapport dans le fichier de log
    echo -e "$GR The database: $INDIVIDUAL_DUMP has been dump "${RST} | awk '{ print strftime("%H:%M:%S"), $0; }' >> $SRV_LOG
  fi
}

function dump_all() {
  DB=$(mysql -u${MYSQL_ROOT_LOGIN} -p${MYSQL_ROOT_PASS} -e 'show databases;')
  echo -e "$YL MYSQLDUMP has been launched !!"
    for dbname in $DB
      do
        ${MYSQL_BIN} ${MYSQL_CMD} --single-transaction --all-databases > ${MYSQL_DUMP_FOLDER}/${SRV_TIME}'_'${SRV_HOSTNAME}'_all'${MYSQL_EXT}
        echo -e "$GR $dbname has been dump ! ${RST} " | awk '{ print strftime("%H:%M:%S"), $0; }' > $SRV_LOG || echo -e "$RD Dump KO "${RST} >> $SRV_LOG
      done
}

function dump_compression () {

  # Fonction permettant de créer une archive d'un dump
  # Je définis mes variables
  save_folder='/backup/dbarchive/'
  n='0'
  nf=$(ls $MYSQL_DUMP_FOLDER | wc -l ) # nf=number of file
  archive_name="${SRV_HOSTNAME}_archive_db_${SRV_TIME}.tar.xz"
  dump_file="${save_folder}${archive_name}"

  # Je verifie que mon dossier de stockage d'archive existe
    if [[ ! -d $save_folder ]]; then
      mkdir $save_folder || echo -e "$RD KO  Can't create folder ${RST}"
    fi
  # Je verifie que l'archive n'existe pas déjà
  if [[ -f "$dump_file" ]]; then
    echo -e "$YL Archive already exist, try tomorrow ! ${RST}"
    exit 8
  fi

  # Création de l'archive si le dossier n'est pas vide  et je change les permission de l'archive
  if [[ $nf -eq $n ]] ; then
    echo -e "$RD KO Folder is empty !! "${RST} >> $SRV_LOG
    exit 9
  else
    echo -e "$YL Archive has been launched !${RST}"
    for file in $MYSQL_DUMP_FOLDER
    do
      tar -cJf $dump_file $file && chmod 400 $dump_file
    done
  fi

  if [[ $? -ne '0' ]]; then
    echo -e "$RD Archive KO" 2>&1 | tee  $SRV_LOG
  else
    echo -e "$GN Archive OK" 2>&1 | tee  $SRV_LOG
    /bin/rm -rf $MYSQL_DUMP_FOLDER
  fi
}

function exit_script() {
  # fonction permettant de gerer les ctrl +c
  echo -e " - $red SIGINT detected (CTRL + C) Exit ! "
  read -n 1 -s -r -p "Press any key to continue ! "
  exit 255
}
function usage() {
  #affiche la page d'aide au commande
  echo
  echo "+------------------------------------------------------------------------------------------------------------------------------------------------------------------+"
  echo "Options:"
  echo "   -a                                  Allow user to dump all databases in mysql"
  echo "   -c,                                 Allow user to create archive from dumped files"
  echo "   -h                                  Show script usage "
  echo "   -n,                                 Allow user to dump only one database need an argument to work"
  echo "   -o,                                 Allow user to dump all databases created by the user"
  echo "   -z,                                 Allow user to dump all DB and create tar from it "
  echo "+------------------------------------------------------------------------------------------------------------------------------------------------------------------+"

  exit 0
}

if [[ $1 == "" ]]; then
  usage
  exit 0
fi

while getopts 'achn:oz' opt
do
  case $opt in
    a) dump_all;;
    c) dump_compression;;
    h) usage;;
    n) dump_individual $OPTARG;;
    o) dump_all_user_created_db;;
    z) dump_all;dump_compression;;
    *) echo "show usage $0 [-h]" >&2
       exit 100;;
  esac
done
