## Objectifs du projet

- Ce dépôt reprend le super travail de Bitnami sur Wordpress/Nginx, en y ajoutant la possibilité de modifier dynamiquement certaines variables du fichier `wp-config.php` à partir d'un fichier `.env` auto-généré pour le projet.
- Il permet de supporter le https dans une configuration de reverse proxy.
- Il permet de modifier les configurations nginx, php-fpm et php. 
- Un ensemble de commandes makefile permettent de simplifier certaines actions d'installation et de configuration du projet.

Ce projet est à utiliser avec docker-compose.

## Table of contents

- [Objectifs du projet](#objectifs-du-projet)
- [Table of contents](#table-of-contents)
- [Arborescence originale](#arborescence-originale)
- [Requirements](#requirements)
  - [Debian distribution](#debian-distribution)
  - [Macos](#macos)
- [Project installation](#project-installation)
  - [Standard installation](#standard-installation)
  - [Customize Wordpress configurations](#customize-wordpress-configurations)
    - [Variables d'environnements](#variables-denvironnements)
    - [Fichiers de configuration bitnami](#fichiers-de-configuration-bitnami)
    - [Utiliser son propre fichier wp-config.php](#utiliser-son-propre-fichier-wp-configphp)
- [Acces](#acces)
- [Administration](#administration)
- [Update protocol and host in mariadb database](#update-protocol-and-host-in-mariadb-database)
- [Troubleshooting](#troubleshooting)
  - [Problème de permissions sur les répertoires wordpress et mariadb](#problème-de-permissions-sur-les-répertoires-wordpress-et-mariadb)
- [Todolist](#todolist)


## Arborescence originale
```
tree -L 3
.
├── README.md
├── bitnami
│   ├── nginx
│   │   └── nginx.conf
│   ├── php
│   │   └── php.ini
│   └── php-fpm
│       └── www.conf
├── docker-compose.yml
├── docker-compose.yml.bak
├── makefile
├── wordpress-orig
│   ├── composer.json
│   ├── composer.lock
│   └── wp-config.php
└── wordpress
    ├── vendor
    │   ├── autoload.php
    │   ├── composer
    │   ├── graham-campbell
    │   ├── phpoption
    │   ├── symfony
    │   └── vlucas
    ├── wp-config.php
    ├── wp-config.php.bak
    └── wp-content
        ├── index.php
        ├── languages
        ├── plugins
        ├── themes
        ├── upgrade
        └── uploads
```

## Requirements


### Debian distribution

```
apt update
apt install build-essential
```

### Macos

```
xcode-select --install
```

## Project installation

### Standard installation

```sh
cp .env.example .env # Complete variables with credentials
docker compose up --wait --force-recreate --remove-orphans -d
```

### Customize Wordpress configurations

#### Variables d'environnements

| Variables    | Default | Accepted values |
| -------- | ------- | ------- |
| WORDPRESS_HOST_PROTOCOL | http | http, https |
| WORDPRESS_HOST_DOMAIN | (empty) | Ip or domain or subdomain. It serves $_SERVER['HTTP_HOST'] if empty. |
| WORDPRESS_DEBUG | false | true, false |


#### Fichiers de configuration bitnami

Il est possible de modifier les configurations de php, nginx et php-fpm, situés dans le répertoire `bitnami`. Il faut stopper et redémarrer les containers pour prendre en compte les changements.

#### Utiliser son propre fichier wp-config.php

```sh
make customize_wordpress
```

Attention, le fichier `.env` est auto-généré et écrasera les valeurs du précédent fichier. Pensez à faire une sauvegarde avant de lancer la commande.

## Acces

```
http://localhost/
https://localhost/
```

## Administration

```
http://localhost/wp-admin
user: user
password: bitnami
```

## Update protocol and host in mariadb database

```sh
docker exec -it wordpress_docker_db_2 mariadb -u user -p  # password set in .env file
use wordpress_database;

# Ensure url need to be changed
SELECT option_name, option_value FROM wp_options WHERE option_name in ('home', 'siteurl');


# Queries to apply to replace the new url
UPDATE wp_options SET option_value = replace(option_value, 'http://oldurl.com', 'https://newurl.com') WHERE option_name = 'home' OR option_name = 'siteurl';
UPDATE wp_posts SET guid = replace(guid, 'http://oldurl.com','https://newurl.com');
UPDATE wp_posts SET post_content = replace(post_content, 'http://oldurl.com', 'https://newurl.com'); 
UPDATE wp_postmeta SET meta_value = replace(meta_value,'http://oldurl.com','https://newurl.com');
exit
```

## Troubleshooting

### Problème de permissions sur les répertoires wordpress et mariadb

Error: `cp: cannot create regular file '/bitnami/wordpress/wp-config.php': Permission denied`

Lancer les commandes suivantes pour créer un utilisateur bitnami ayant la capacité de pouvoir écrire dans le répertoire. Il est recommandé d'ajouter l'utilisateur actif de la session dans le groupe bitnami pour pouvoir modifier des fichiers.


```sh
make create_bitnami_user
make configure_persistent_binded_volumes
```


## Todolist
- [ ] Improve README documentation.