**Table des matières**
- [Script dump base de données MySQL](#script-dump-base-de-donn-es-mysql)
  * [Introduction](#introduction)
  * [Utilisation & Arguments](#utilisation---arguments)
  * [Amélioration à venir](#am-lioration---venir)
  * [Codes erreurs](#codes-erreurs)

# Script dump base de données MySQL
*Script pour un projet école*

## Introduction

Script permettant de faire des dumps de base de données MySQL.

## Utilisation & Arguments

`-a`: Permet à l'utilisateur de dump toutes les bases de données MySQL s'appuie sur l'argument `mysqldump --all-databases`
`-c`: Permet de créer une archive des bases de données récemment dump
`-h`: Montre l'aide du script
`-n`: Dump une BDD en particulier, nécéssite un argument exemple `./dump_dbb.sh -n DBNAME`
`-o`: Dump uniquement les bases de données créé par l'administrateur.
`-z`: Dump toutes les bdd et les archives en `tar.xz`

- La variable `MYSQL_ROOT_PASS` doit être complété afin que le script fonctionne

En prérequis, il faut ajouter les droits d'execution sur le script.

```bash
chmod u+x dump_bdd.sh
```



## Amélioration à venir

Suppression de la variable `MYSQL_ROOT_PASS` pour un input utilisateur qui demande le mot de passe qui sera stocké dans un fichier `my.cnf`.

## Codes erreurs
- `exit 1`: Script n'est pas exécute en tant que root
- `exit 2`: Binaire mysqldump manquant
- `exit 4`: On ne peut pas écrire dans le dossier de destination de backup
- `exit 5`: Aucun argument trouvé en utilisant l'option `-n`
- `exit 6`: Erreur sur le dump
- `exit 7`: N'arrive pas à créer le dossier archive  sur le partage NFS s'il n'existe pas.
- `exit 8`: L'archivage a déjà été fait à ce jour
- `exit 9`: Le dossier d'archive est vide, il ne peut pas créer une archive vide
- `exit 255`: SIGTERM détecté
