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

# Configurar WordPress usando WP-CLI
cd /var/www/html/
wp core install --url="http://your_domain" --title="$WP_SITE_TITLE" --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL"

# Personalizar la página de inicio
echo "<h1>Bienvenido a mi sitio WordPress, $YOUR_NAME</h1>" > /var/www/html/index.php

echo "Provisionamiento completado."
