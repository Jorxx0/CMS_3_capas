#!/bin/bash

# Cambiar nombre de host
sudo hostnamectl set-hostname apache1jorge

# Actualizar lista de paquetes
sudo apt-get update

# Instalar Apache, PHP y módulos necesarios
sudo apt install apache2 php8.3 php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-xmlrpc php-zip php-soap php-intl nfs-common -y

# Crear directorio compartido y asignar permisos
sudo mkdir -p /var/www/compartido
sudo chown -R nobody:nogroup /var/www/compartido

# Montar directorio compartido desde servidor NFS
sudo mount 192.168.10.69:/var/www/compartido /var/www/compartido

# Habilitar módulos de Apache necesarios
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod ssl

# Configurar sitio por defecto de Apache
cat <<EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
        DocumentRoot /var/www/compartido
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        <Directory /var/www/compartido>
          Options FollowSymlinks
          AllowOverride All
          Require all granted
        </Directory>
        SetEnvIf X-Forwarded-Proto "https" HTTPS=on
</VirtualHost>
EOF

# Deshabilitar sitio por defecto y habilitar nueva configuración
sudo a2dissite 000-default
sudo a2ensite 000-default

# Añadir entrada en fstab para montar NFS en el arranque
sudo echo "192.168.10.69:/var/www/compartido    /var/www/compartido   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" >> /etc/fstab

# Reiniciar Apache para aplicar cambios
sudo systemctl restart apache2
