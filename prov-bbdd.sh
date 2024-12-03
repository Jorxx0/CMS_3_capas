#!/bin/bash

# Variables
DB_NAME="wordpress"
DB_USER="tiendawp"
DB_PASSWORD="WP1234."
WP_URL="http://wordpress.org/latest.tar.gz"
WP_DIR="/var/www/html"

# Actualizar el sistema
sudo apt-get update -y
sudo apt-get upgrade -y

# Instalar Apache
sudo apt-get install apache2 -y

# Instalar MySQL
sudo apt-get install mysql-server -y

# Instalar PHP y módulos necesarios
sudo apt-get install php libapache2-mod-php php-mysql -y

# Descargar y configurar WordPress
wget -c $WP_URL
tar -xzvf latest.tar.gz
sudo mv wordpress/* $WP_DIR

# Configurar permisos
sudo chown -R www-data:www-data $WP_DIR
sudo chmod -R 755 $WP_DIR

# Crear base de datos para WordPress
sudo mysql -u root -e "CREATE DATABASE $DB_NAME;"
sudo mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

# Configurar archivo wp-config.php
cd $WP_DIR
cp wp-config-sample.php wp-config.php
sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sed -i "s/username_here/$DB_USER/" wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" wp-config.php

# Reiniciar Apache
sudo systemctl restart apache2

echo "Provisionamiento completado. WordPress está instalado y configurado."