#!/bin/bash

# Variables
SHARED_DIR="/var/www/html"

# Actualizar el sistema
apt-get update
apt-get upgrade -y

# Instalar y configurar NFS
apt-get install nfs-kernel-server -y

# Crear el directorio compartido
mkdir -p $SHARED_DIR
chown -R www-data:www-data $SHARED_DIR
chmod -R 755 $SHARED_DIR

# Configurar la exportación NFS
echo "$SHARED_DIR 192.168.20.35(rw,sync,no_subtree_check)" >> /etc/exports

# Reiniciar el servicio NFS
exportfs -ra
systemctl restart nfs-kernel-server

echo "Configuración del servidor NFS completada."
