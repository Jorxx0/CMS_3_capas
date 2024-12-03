#!/bin/bash

# Actualizar el sistema
sudo apt-get update -y
sudo apt-get upgrade -y

# Instalar Apache
sudo apt-get install apache2 -y

# Habilitar y iniciar el servicio de Apache
sudo systemctl enable apache2
sudo systemctl start apache2

# Instalar utilidades necesarias para NFS
sudo apt-get install nfs-common -y

# Crear el directorio para montar el sistema de archivos NFS
sudo mkdir -p /mnt/nfs_share

# Montar el sistema de archivos NFS
sudo mount <192.168.20.36>:</var/www/html> /mnt/nfs_share

# Añadir la entrada en fstab para montar el NFS en el arranque
echo "<NFS_SERVER_IP>:<NFS_SHARE_PATH> /mnt/nfs_share nfs defaults 0 0" | sudo tee -a /etc/fstab

# Instalar el cliente de base de datos
sudo apt-get install mysql-client -y

# Configurar el acceso a la base de datos (reemplazar <DB_SERVER_IP>, <DB_USER> y <DB_PASSWORD> con los valores correctos)
# Nota: Esto es solo un ejemplo, la configuración real puede variar según la base de datos utilizada
echo "[client]
host=<DB_SERVER_IP>
user=<DB_USER>
password=<DB_PASSWORD>" | sudo tee -a ~/.my.cnf

# Reiniciar Apache para aplicar cambios
sudo systemctl restart apache2

echo "Provisionamiento completado con éxito."
# Descargar la última versión de WordPress
wget https://wordpress.org/latest.tar.gz -P /tmp

# Extraer WordPress
tar -xzf /tmp/latest.tar.gz -C /tmp

# Copiar los archivos de WordPress al directorio de Apache
sudo cp -r /tmp/wordpress/* /mnt/nfs_share/

# Establecer los permisos adecuados
sudo chown -R www-data:www-data /mnt/nfs_share/
sudo chmod -R 755 /mnt/nfs_share/

# Crear el archivo de configuración de WordPress
sudo cp /mnt/nfs_share/wp-config-sample.php /mnt/nfs_share/wp-config.php

# Configurar la base de datos en wp-config.php (reemplazar <DB_NAME>, <DB_USER>, <DB_PASSWORD>, <DB_HOST> con los valores correctos)
sudo sed -i "s/database_name_here/<DB_NAME>/g" /mnt/nfs_share/wp-config.php
sudo sed -i "s/username_here/<DB_USER>/g" /mnt/nfs_share/wp-config.php
sudo sed -i "s/password_here/<DB_PASSWORD>/g" /mnt/nfs_share/wp-config.php
sudo sed -i "s/localhost/<DB_HOST>/g" /mnt/nfs_share/wp-config.php

# Reiniciar Apache para aplicar cambios
sudo systemctl restart apache2

echo "WordPress instalado con éxito."