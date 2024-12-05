# Cambiar nombre de host
sudo hostnamectl set-hostname balanceadorjorge

# Actualizar lista de paquetes
sudo apt update -y

# Instalar servidor MySQL
sudo apt install mysql-server -y

# Configurar MySQL para permitir conexiones remotas
sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Reiniciar servicio MySQL para aplicar cambios
sudo systemctl restart mysql

# Cambiar a usuario root
sudo su

# Ingresar a la consola de MySQL como usuario root
mysql -u root

# Crear base de datos para WordPress
CREATE DATABASE wordpress_db;

# Aplicar cambios de privilegios
FLUSH PRIVILEGES;

# Crear usuario para WordPress con acceso desde una subred específica
CREATE USER 'user_wp'@'192.168.10.%' IDENTIFIED BY 'Pass1234.';

# Conceder todos los privilegios al usuario creado sobre la base de datos de WordPress
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'user_wp'@'192.168.10.%';

# Aplicar cambios de privilegios
FLUSH PRIVILEGES;

# Salir de la consola de MySQL
exit

# Reiniciar servicio MySQL para asegurar que todos los cambios se apliquen
sudo systemctl restart mysql