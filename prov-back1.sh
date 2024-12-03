#!/bin/bash

# Variables
DB_HOST="192.168.30.37"
DB_NAME="datoswp"
DB_USER="tiendawp"
DB_PASSWORD="WP1234."
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
apt-get install php php-mysql libapache2-mod-php nfs-common -y

# Instalar y configurar NFS
apt-get install nfs-common -y
sudo mkdir -p /var/www/html/wordpress
# Montar la compartición NFS en el directorio del servidor web
echo "192.168.20.36:/var/www/html/wordpress /var/www/html/wordpress nfs defaults 0 0" >> /etc/fstab
mount -a

# Descargar y configurar WordPress
cd /var/www/html/
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
mv wordpress/* .
rm -rf wordpress latest.tar.gz

# Configurar archivo wp-config.php
cat <<EOF > /var/www/html/wp-config.php
<?php
define('DB_NAME', '$DB_NAME');
define('DB_USER', '$DB_USER');
define('DB_PASSWORD', '$DB_PASSWORD');
define('DB_HOST', '$DB_HOST');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');
\$table_prefix = 'wp_';
define('WP_DEBUG', false);
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
EOF

# Configurar permisos
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Configurar Apache para usar NFS
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

# Personalizar la página de inicio (para verificar que el sitio esté funcionando)
echo "<h1>Bienvenido a mi sitio WordPress, $YOUR_NAME</h1>" > /var/www/html/index.php

echo "Provisionamiento completado."
