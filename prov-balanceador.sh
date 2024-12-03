#!/bin/bash

# Actualiza la lista de paquetes
sudo apt-get update

# Instala Apache
sudo apt-get install -y apache2

# Habilita Apache para que se inicie al arrancar el sistema
sudo systemctl enable apache2

# Inicia el servicio de Apache
sudo systemctl start apache2

# Configura el balanceador de carga en Apache
cat <<EOL | sudo tee /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ProxyPreserveHost On

    <Proxy "balancer://mycluster">
        BalancerMember http://192.168.10.34
        BalancerMember http://192.168.10.35
    </Proxy>

    ProxyPass / balancer://mycluster/
    ProxyPassReverse / balancer://mycluster/
</VirtualHost>
EOL

# Habilita los módulos necesarios para el balanceo de carga
sudo a2enmod proxy
sudo a2enmod proxy_balancer
sudo a2enmod proxy_http
sudo a2enmod lbmethod_byrequests

# Recarga Apache para aplicar los cambios
sudo systemctl reload apache2

echo "Provisionamiento del balanceador de carga completado."
