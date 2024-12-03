#!/bin/bash

# Variables
DB_HOST="192.168.30.37"
WP_SITE_TITLE="WordPress en tres capas"
WP_ADMIN_USER="adminWP"
WP_ADMIN_PASSWORD="AdminWP1234."
WP_ADMIN_EMAIL="jlopezb20@educarex.es"
YOUR_NAME="Jorge"

# Actualizar el sistema
apt-get update
apt-get upgrade -y

# Instalar Apache
apt-get install apache2 -y

# Instalar PHP y extensiones necesarias
apt-get install php php-mysql libapache2-mod-php -y

# Instalar y configurar NFS
apt-get install nfs-common -y

# Montar la compartición NFS en el directorio del servidor web
echo "192.168.20.36:/var/www/html /var/www/html nfs defaults 0 0" >> /etc/fstab
mount -a

# Configurar Apache para usar el directorio compartido por NFS
cat <<EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Reiniciar Apache
systemctl restart apache2

# Descargar y configurar WordPress
wget -c http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz -C /var/www/html/ --strip-components=1

# Configurar permisos para WordPress
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Crear archivo de configuración de WordPress
cat <<EOF > /var/www/html/wp-config.php
<?php
define('DB_NAME', 'datoswp');
define('DB_USER', 'tiendawp');
define('DB_PASSWORD', 'WP1234.');
define('DB_HOST', '$DB_HOST');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');
\$table_prefix = 'wp_';
define('WP_DEBUG', false);
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}
require_once ABSPATH . 'wp-settings.php';
EOF

# Personalizar la página de inicio
echo "<h1>Bienvenido a mi sitio WordPress, $YOUR_NAME</h1>" > /var/www/html/index.php

echo "Provisionamiento completado."
