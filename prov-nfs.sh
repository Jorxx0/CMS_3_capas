#!/bin/bash

# Variables
NFS_SERVER="192.168.20.36"
NFS_SHARE="/var/www/html/wordpress"
CLIENTS=("192.168.20.34" "192.168.20.35")

# Instalar paquetes del servidor NFS
sudo apt-get update
sudo apt-get install -y nfs-kernel-server

# Crear directorio de compartición NFS
sudo mkdir -p $NFS_SHARE
sudo chown nobody:nogroup $NFS_SHARE
sudo chmod 777 $NFS_SHARE

# Descargar y configurar WordPress en el servidor NFS
wget -c http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
sudo mv wordpress/* $NFS_SHARE

# Configurar permisos
sudo chown -R nobody:nogroup $NFS_SHARE
sudo chmod -R 755 $NFS_SHARE

# Crear archivo de configuración de WordPress
cat <<EOF | sudo tee $NFS_SHARE/wp-config.php
<?php
define('DB_NAME', 'datoswp');
define('DB_USER', 'tiendawp');
define('DB_PASSWORD', 'WP1234.');
define('DB_HOST', '192.168.30.37');
EOF

# Configurar exportaciones NFS
echo "$NFS_SHARE ${CLIENTS[0]}(rw,sync,no_root_squash,no_subtree_check) ${CLIENTS[1]}(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports

# Exportar la compartición NFS
sudo exportfs -a

# Reiniciar el servidor NFS
sudo systemctl restart nfs-kernel-server

# Montar la compartición NFS en cada cliente
for CLIENT in "${CLIENTS[@]}"; do
    ssh $CLIENT "sudo mount $NFS_SERVER:$NFS_SHARE /var/www/html/wordpress"
done

echo "El servidor y los clientes NFS han sido configurados exitosamente."
