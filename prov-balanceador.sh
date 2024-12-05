#!/bin/bash

# Cambiar nombre de host
sudo hostnamectl set-hostname balanceadorjorge

# Actualiza la lista de paquetes
sudo apt-get update

# Instala Apache
sudo apt-get install -y apache2

# Habilita Apache para que se inicie al arrancar el sistema
sudo systemctl enable apache2

# Inicia el servicio de Apache
sudo systemctl start apache2

# Configuración HTTPS del balanceador de carga con certificado autofirmado
<IfModule mod_ssl.c>
    <VirtualHost *:443>
        SSLEngine on
        ServerName wordpressjorge.zapto.org
        
        # Ruta del certificado SSL autofirmado
        SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
        SSLCertificateKeyFile /etc/ssl/certs/ssl-cert-snakeoil.pem
        Include /etc/letsencrypt/options-ssl-apache.conf
        
        # Archivos de log de errores y accesos
        ErrorLog /error.log
        CustomLog /access.log combined
        
        # Configuración del balanceador de carga
        <Proxy balancer://balanceador>
                BalancerMember http://192.168.10.70
                BalancerMember http://192.168.10.71
        </Proxy>
        ProxyPass "/" "balancer://balanceador/"
        ProxyPassReverse "/" "balancer://balanceador/"
        ProxyPreserveHost On
        
        # Encabezados HTTP para asegurar la conexión HTTPS
        RequestHeader set X-Forwarded-Proto "https" env=HTTPS
        RequestHeader set X-Forwarded-Host "wordpressjorge.zapto.org"
    </VirtualHost>
</IfModule>

# Habilita los módulos necesarios para el balanceo de carga
sudo a2enmod proxy
sudo a2enmod proxy_balancer
sudo a2enmod proxy_http
sudo a2enmod lbmethod_byrequests
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod ssl

# Recarga Apache para aplicar los cambios
sudo systemctl restart apache2

# Instala Certbot para la gestión de certificados SSL
sudo apt install certbot python3-certbot-apache -y

echo "Provisionamiento del balanceador de carga completado."
