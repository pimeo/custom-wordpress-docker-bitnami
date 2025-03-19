WORDPRESS_SALT_URL=https://api.wordpress.org/secret-key/1.1/salt/
WORDPRESS_VOLUME_DIR=wordpress
WORDPRESS_ORIG_DIR=wordpress-orig
MARIADB_VOLUME_DIR=mariadb-data
ACTIVE_USER=$$(whoami)

.PHONY: composer_install update_wp_config install_wordpress_docker_compose start_wordpress_docker_compose cleanup_env_file generate_wordpress_salts_in_env_file generate_wordpress_vars_in_env_file remove_wordress_orig configure_persistent_binded_volumes generate_env_file customize_wordpress

php_debian_install:
	apt install php-common php-cli
	php --version
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
	php composer-setup.php
	php -r "unlink('composer-setup.php');"
	mv composer.phar /usr/local/bin/composer

composer_install: $(WORDPRESS_ORIG_DIR)/composer.json  ## Install composer vendor into wordpress volume directory
	mkdir -p $(WORDPRESS_VOLUME_DIR)
	composer install --working-dir=$(WORDPRESS_ORIG_DIR)
	mkdir -p $(WORDPRESS_VOLUME_DIR)
	rm -fr $(WORDPRESS_VOLUME_DIR)/vendor
	mv $(WORDPRESS_ORIG_DIR)/vendor $(WORDPRESS_VOLUME_DIR)

update_wp_config: $(WORDPRESS_ORIG_DIR)/wp-config.php ## Push wp-config php file into wordress volume directory
	mkdir -p $(WORDPRESS_VOLUME_DIR)
	if [[ -e $(WORDPRESS_VOLUME_DIR)/wp-config.php.bak ]]; then\
		echo "Backup already exists for wp-config.php file";\
		sudo chmod -R 644 $(WORDPRESS_VOLUME_DIR)/wp-config.php.bak;\
		sudo chown bitnami:bitnami $(WORDPRESS_VOLUME_DIR)/wp-config.php.bak;\
	else cp $(WORDPRESS_ORIG_DIR)/wp-config.php $(WORDPRESS_VOLUME_DIR)/wp-config.php.bak;\
	fi
	rm -fv $(WORDPRESS_VOLUME_DIR)/wp-config.php
	cp $(WORDPRESS_ORIG_DIR)/wp-config.php $(WORDPRESS_VOLUME_DIR)
	sudo chmod -R 644 $(WORDPRESS_VOLUME_DIR)/wp-config.php
	sudo chown bitnami:bitnami $(WORDPRESS_VOLUME_DIR)/wp-config.php

install_wordpress_docker_compose: ## Install wordpress with docker compose.
	docker compose up --force-recreate --remove-orphans

start_wordpress_docker_compose: ## Start wordpress with docker compose
	docker compose up --force-recreate --remove-orphans --wait -d

cleanup_env_file: ## Delete .env file in wordpress volume directory
	mkdir -p $(WORDPRESS_VOLUME_DIR)
	if [[ -e $(WORDPRESS_VOLUME_DIR)/.env ]]; then cp $(WORDPRESS_VOLUME_DIR)/.env $(WORDPRESS_VOLUME_DIR)/.env.bak; fi
	rm -fv $(WORDPRESS_VOLUME_DIR)/.env

generate_wordpress_salts_in_env_file: ## Generate wordpress salts variables into .env file in the wordpress volume directory
	mkdir -p $(WORDPRESS_VOLUME_DIR)
	curl -X GET -s -H "Content-Type: application/json" $(WORDPRESS_SALT_URL) > $(WORDPRESS_ORIG_DIR)/salt.txt
	echo "\n\n ### WP CONFIG SALT" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo AUTH_KEY=\"$$(cat $(WORDPRESS_ORIG_DIR)/salt.txt | cut -d "'" -f 4 | awk NR==1)\" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo SECURE_AUTH_KEY=\"$$(cat $(WORDPRESS_ORIG_DIR)/salt.txt | cut -d "'" -f 4 | awk NR==2)\" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo LOGGED_IN_KEY=\"$$(cat $(WORDPRESS_ORIG_DIR)/salt.txt | cut -d "'" -f 4 | awk NR==3)\" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo NONCE_KEY=\"$$(cat $(WORDPRESS_ORIG_DIR)/salt.txt | cut -d "'" -f 4 | awk NR==4)\" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo AUTH_SALT=\"$$(cat $(WORDPRESS_ORIG_DIR)/salt.txt | cut -d "'" -f 4 | awk NR==5)\" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo SECURE_AUTH_SALT=\"$$(cat $(WORDPRESS_ORIG_DIR)/salt.txt | cut -d "'" -f 4 | awk NR==6)\" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo LOGGED_IN_SALT=\"$$(cat $(WORDPRESS_ORIG_DIR)/salt.txt | cut -d "'" -f 4 | awk NR==7)\" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo NONCE_SALT=\"$$(cat $(WORDPRESS_ORIG_DIR)/salt.txt | cut -d "'" -f 4 | awk NR==8)\" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo "### / WP CONFIG SALT" >> $(WORDPRESS_VOLUME_DIR)/.env
	rm -fv $(WORDPRESS_ORIG_DIR)/salt.txt

generate_wordpress_vars_in_env_file: ## Generate wordpress credentials and settings variables into .env file in the wordpress volume directory
	mkdir -p $(WORDPRESS_ORIG_DIR)
	echo "### WP CONFIG DATABASE CREDENTIALS" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo DB_HOST=$$(grep WORDPRESS_DATABASE_HOST .env | cut -d'=' -f 2-) >> $(WORDPRESS_VOLUME_DIR)/.env
	echo DB_PORT=$$(grep WORDPRESS_DATABASE_PORT_NUMBER .env | cut -d'=' -f 2-) >> $(WORDPRESS_VOLUME_DIR)/.env
	echo DB_USER=$$(grep WORDPRESS_DATABASE_USER .env | cut -d'=' -f 2-) >> $(WORDPRESS_VOLUME_DIR)/.env
	echo DB_NAME=$$(grep WORDPRESS_DATABASE_NAME .env | cut -d'=' -f 2-) >> $(WORDPRESS_VOLUME_DIR)/.env
	echo DB_PASSWORD=$$(grep WORDPRESS_DATABASE_PASSWORD .env | cut -d'=' -f 2-) >> $(WORDPRESS_VOLUME_DIR)/.env
	echo "### / WP CONFIG DATABASE CREDENTIALS" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo "\n\n ### WP CONFIG" >> $(WORDPRESS_VOLUME_DIR)/.env
	echo WP_HOST_PROTOCOL=$$(grep WORDPRESS_HOST_PROTOCOL .env | cut -d'=' -f 2-) >> $(WORDPRESS_VOLUME_DIR)/.env
	echo WP_HOST_DOMAIN=$$(grep WORDPRESS_HOST_DOMAIN .env | cut -d'=' -f 2-) >> $(WORDPRESS_VOLUME_DIR)/.env
	echo WP_DEBUG=$$(grep WORDPRESS_DEBUG .env | cut -d'=' -f 2-) >> $(WORDPRESS_VOLUME_DIR)/.env
	echo "### WP CONFIG" >> $(WORDPRESS_VOLUME_DIR)/.env

remove_wordress_orig: ## Delete wordpress origin directory
	rm -frv $(WORDPRESS_ORIG_DIR)

create_bitnami_user:
	sudo useradd -u 1001 bitnami || echo "User already exists."
	sudo usermod -G bitnami -a $(ACTIVE_USER)

configure_persistent_binded_volumes: # Create bitnami user to prevent from denied permissions on mounted binded volumes	
	mkdir -p $(WORDPRESS_VOLUME_DIR) 
	sudo chown -R bitnami:bitnami $(WORDPRESS_VOLUME_DIR)
	sudo chmod -R 774 $(WORDPRESS_VOLUME_DIR)
	if [ -d $(MARIADB_VOLUME_DIR) ]; then sudo chown -R bitnami:bitnami $(MARIADB_VOLUME_DIR); fi

generate_env_file: cleanup_env_file generate_wordpress_vars_in_env_file generate_wordpress_salts_in_env_file ## Shortcut command to generate a new .env file in wordpress volume directory
	sudo chmod -R 644 $(WORDPRESS_VOLUME_DIR)/.env

customize_wordpress: configure_persistent_binded_volumes composer_install update_wp_config generate_env_file ## Push custom settings to rule Wordpress via an env-based wp-config file
