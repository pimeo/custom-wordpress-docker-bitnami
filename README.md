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
└── wordpress_data
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

## Installation


### Standard installation

```
docker compose up --wait --force-recreate --remove-orphans -d
```

### Personnaliser Wordpress

#### Fichiers de configuration bitnami

Il est possible de modifier les configurations de php, nginx et php-fpm, situés dans le répertoire `bitnami`. Il faut stopper et redémarrer les containers pour prendre en compte les changements.

#### Utiliser son propre wp-config.php

```
make customize_wordpress
```

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