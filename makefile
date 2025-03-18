WORDPRESS_SALT_URL=https://api.wordpress.org/secret-key/1.1/salt/

.PHONY: composer_install update_wp_config launch_wordpress_docker_compose cleanup_env_file generate_wordpress_salts_in_env_file generate_wordpress_vars_in_env_file remove_wordress_orig configure_persistent_binded_volumes generate_env_file customize_wordpress install

php_debian_install:
	apt install php-common php-cli
	php --version
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
	php composer-setup.php
	php -r "unlink('composer-setup.php');"
	mv composer.phar /usr/local/bin/composer

composer_install: wordpress-orig/composer.json  ## Install composer vendor into wordpress_data directory
	mkdir -p wordpress_data
	composer install --working-dir=wordpress-orig
	mkdir -p wordpress_data
	rm -fr wordpress_data/vendor
	mv wordpress-orig/vendor wordpress_data

update_wp_config: wordpress-orig/wp-config.php ## Push wp-config php file into wordress_data directory
	mkdir -p wordpress_data
	if [[ -e wordpress_data/wp-config.php.bak ]]; then echo "Backup already exists for wp-config.php file"; else cp wordpress_data/wp-config.php wordpress_data/wp-config.php.bak; fi
	rm -fv wordpress_data/wp-config.php
	cp wordpress-orig/wp-config.php wordpress_data

launch_wordpress_docker_compose: ## Install wordpress with docker compose then stop docker compose after a delay of 60 seconds
	docker compose up --wait --force-recreate --remove-orphans -d
	sleep 120
	docker compose stop

cleanup_env_file: ## Delete .env file in wordpress_data directory
	mkdir -p wordpress-orig
	rm -f wordpress_data/.env

generate_wordpress_salts_in_env_file: ## Generate wordpress salts variables in wordpress_data/.env file
	mkdir -p wordpress-orig
	curl -X GET -s -H "Content-Type: application/json" $(WORDPRESS_SALT_URL) > wordpress-orig/salt.txt
	echo "\n\n ### WP CONFIG SALT" >> wordpress_data/.env
	echo AUTH_KEY=\"$$(cat wordpress-orig/salt.txt | cut -d "'" -f 4 | awk NR==1)\" >> wordpress_data/.env
	echo SECURE_AUTH_KEY=\"$$(cat wordpress-orig/salt.txt | cut -d "'" -f 4 | awk NR==2)\" >> wordpress_data/.env
	echo LOGGED_IN_KEY=\"$$(cat wordpress-orig/salt.txt | cut -d "'" -f 4 | awk NR==3)\" >> wordpress_data/.env
	echo NONCE_KEY=\"$$(cat wordpress-orig/salt.txt | cut -d "'" -f 4 | awk NR==4)\" >> wordpress_data/.env
	echo AUTH_SALT=\"$$(cat wordpress-orig/salt.txt | cut -d "'" -f 4 | awk NR==5)\" >> wordpress_data/.env
	echo SECURE_AUTH_SALT=\"$$(cat wordpress-orig/salt.txt | cut -d "'" -f 4 | awk NR==6)\" >> wordpress_data/.env
	echo LOGGED_IN_SALT=\"$$(cat wordpress-orig/salt.txt | cut -d "'" -f 4 | awk NR==7)\" >> wordpress_data/.env
	echo NONCE_SALT=\"$$(cat wordpress-orig/salt.txt | cut -d "'" -f 4 | awk NR==8)\" >> wordpress_data/.env
	echo "### / WP CONFIG SALT" >> wordpress_data/.env
	rm -f wordpress-orig/salt.txt

generate_wordpress_vars_in_env_file: ## Generate wordpress credentials and settings variables in wordpress_data/.env file
	mkdir -p wordpress-orig
	echo "### WP CONFIG DATABASE CREDENTIALS" >> wordpress_data/.env
	echo DB_HOST=$$(grep WORDPRESS_DATABASE_HOST .env | cut -d'=' -f 2-) >> wordpress_data/.env
	echo DB_PORT=$$(grep WORDPRESS_DATABASE_PORT_NUMBER .env | cut -d'=' -f 2-) >> wordpress_data/.env
	echo DB_USER=$$(grep WORDPRESS_DATABASE_USER .env | cut -d'=' -f 2-) >> wordpress_data/.env
	echo DB_NAME=$$(grep WORDPRESS_DATABASE_NAME .env | cut -d'=' -f 2-) >> wordpress_data/.env
	echo DB_PASSWORD=$$(grep WORDPRESS_DATABASE_PASSWORD .env | cut -d'=' -f 2-) >> wordpress_data/.env
	echo "### / WP CONFIG DATABASE CREDENTIALS" >> wordpress_data/.env

	echo "\n\n ### WP CONFIG" >> wordpress_data/.env
	echo WP_HOST_PROTOCOL=$$(grep WP_HOST_PROTOCOL .env | cut -d'=' -f 2-) >> wordpress_data/.env
	echo WP_HOST_DOMAIN=$$(grep WORDPRESS_HOST_PROTOCOL .env | cut -d'=' -f 2-) >> wordpress_data/.env
	echo WP_DEBUG=$$(grep WORDPRESS_DEBUG .env | cut -d'=' -f 2-) >> wordpress_data/.env
	echo "### WP CONFIG" >> wordpress_data/.env

remove_wordress_orig: ## Delete wordpress-orig directory
	rm -fr wordpress-orig

configure_persistent_binded_volumes: # Create bitnami user to prevent from denied permissions on mounted binded volumes
	sudo useradd -u 1001 bitnami
	mkdir -p {wordpress_data,mariadb_data}
	sudo chown -R bitnami:bitnami wordpress_data
	sudo chown -R bitnami:bitnami mariadb_data

generate_env_file: cleanup_env_file generate_wordpress_vars_in_env_file generate_wordpress_salts_in_env_file ## Shortcut command to generate a new .env file in wordpress_data directory
customize_wordpress: composer_install update_wp_config generate_env_file ## Push custom settings to rule Wordpress via an env-based wp-config file

install: launch_wordpress_docker_compose customize_wordpress
