# CMS_3_capas
 
# WordPress en 3 capas con alta disponibilidad

Curso: Aplicaciones Web
Autor: Jorge López Benito
Fecha de entrega: 6 de diciembre de 2024 0:00 (CET)
Confidencial: Algo Confidencial
Última Edición: 5 de diciembre de 2024 6:07

# Introducción

En este repositorio se encuentra la documentación técnica en la cual se describe el proceso de despliegue de una infraestructura de tres capas para alojar un WordPress en alta disponibilidad y escalabilidad utilizando AWS. La infraestructura incluye balanceo de carga, servidores web, almacenamiento compartido y un servidor de base de datos. Además se utiliza una máquina pivote para acceder a todos los servidores mediante ssh. 

Esta infraestructura garantiza alta disponibilidad mediante balanceo de carga, escalabilidad al permitir añadir más servidores según sea necesario y aislamiento de capas para mejorar la seguridad. 

# Arquitectura de la infraestructura

1. Capa pública con un balanceador de carga Apache, posee de acceso al exterior y a la capa con los servidores web. 
2. Capa privada con dos servidores web Apache y un servidor NFS el cual se encarga de compartir los archivos entre los servidores web. 
3. Capa privada con un servidor MySQL para el almacenamiento de datos. 
4. Capa pública con una máquina pivote para administrar la infraestructura mediante ssh, esto permite mantener un entorno seguro sin exponer las máquinas privadas. 

# Configuración de la infraestructura en AWS

En este caso se ha utlizado la red 192.168.10.0 para la implementación de las siguientes subredes y recursos

- La subred pública, con la dirección de red 192.168.10.0/26.
- La subred privada de Apache y NFS, con la dirección de red 192.168.10.64/26.
- La subred privada de la base de datos, con la dirección de red 192.168.10.128/26.
- La subred pública de la máquina pivote, con la dirección de red 192.168.10.192/26.

## Grupos de seguridad

Se ha creado los siguientes grupos de seguridad:

- Un grupo para la máquina pivote. Permite el tráfico ssh desde internet.
- Un grupo para el servidor NFS. Permite el tráfico desde el balanceador de carga y el pivote.
- Un grupo para los servidores web. Permite el tráfico desde el balanceador de carga y el pivote.
- Un grupo para el servidor de base de datos. Permite el tráfico únicamente desde los servidores web.
- Un grupo para el balanceador. Permite el tráfico HTTP/HTTPS desde internet.

# Implementación de la infraestructura

## Creación de instancias

Las instancias se han creado con las siguiente finalidad

- Balanceador de carga: instancia EC2 configurada con Apache para realizar el balanceo de las solicitudes HTTP/HTTPS.
- Servidores Web: instancias EC2 configuradas con Apache y PHP.
- Servidor NFS: instancia EC2 configurada para proporcionar almacenamiento compartido mediante NFS.
- Servidor de Base de Datos: instancia Ec2 configurada con MySQL.
- Pivote: instancia EC@ con acceso ssh configurado para conectarse al resto de las instancias.

Todas están creadas con una AMI de tipo Ubuntu excepto la máquina pivote, esta está creada con la AMI Amazon Linux

## Configuración de VPC y Subredes

- VPC: configurada con la dirección de red 192.168.10.0/24
- Subred pública: 192.168.10.0/26, para el balanceador.
- Subred privada ApacheNFS: 192.168.10.64/26, para los servidores Apache y NFS.
- Subred privada BBDD: 192.168.10.128/26, para el servidor de base de datos.
- Subred pública pivote: 192.168.10.192/26, para el pivote.

## **Configuración de las tablas de enrutamiento**

Crearemos 3 tablas de enrutamiento diferentes:

- Tabla pública para la subred pública, la cual contiene el balanceador.
- Tabla pivote para la subred pivote, la cual contiene la máquina pivote.
- Tabla privada para las subredes ApacheNFS y BBDD, la cual contiene los servidores web, NFS y MySQL.

## **Configuración de la puerta de enlace de internet**

- Crearemos una gateway de internet y la asociaremos a la VPC que tenemos creada para nuestro CMS.

## **Configuración de las direcciones IP elásticas**

Crearemos las siguientes direcciones IP elásticas

- IP pública para el balanceador
- IP pública para el pivote

## Configuración del par de claves

Para aumentar la seguridad de nuestras instancias, generaremos un par de claves especificas para nuestras máquinas, estas las asociaremos a todas ellas para poder acceder con facilidad sin reducir su seguridad. 

# **5. Scripts de Aprovisionamiento**

Cada instancia se aprovisiona utilizando scripts con el que se instalan los servicios necesarios y configuran los recursos de la instancia. 

## **5.1. Script de Aprovisionamiento del Balanceador de Carga**

```bash
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

```

## **5.2. Script de Aprovisionamiento de los Servidores Web**

```bash
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

```

## **5.3. Script de Aprovisionamiento del Servidor NFS**

```bash
#!/bin/bash

# Actualiza la lista de paquetes disponibles
sudo apt-get update

# Instala el servidor NFS
sudo apt-get install -y nfs-kernel-server

# Crea el directorio compartido
sudo mkdir -p /var/www/compartido

# Cambia el propietario del directorio a nobody:nogroup
sudo chown nobody:nogroup /var/www/compartido

# Añade las configuraciones de exportación NFS para dos IPs
echo "/var/www/compartido 192.168.10.70(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
echo "/var/www/compartido 192.168.10.71(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports

# Reinicia el servidor NFS para aplicar los cambios
sudo systemctl restart nfs-kernel-server

# Descarga la última versión de WordPress
wget -c http://wordpress.org/latest.tar.gz

# Extrae el contenido del archivo descargado en el directorio compartido
tar -xzvf latest.tar.gz -C /var/www/compartido/ --strip-components=1

# Cambia los permisos del directorio compartido
sudo chmod -R 755 /var/www/compartido

# Crea un archivo de configuración vacío para WordPress
sudo touch /var/www/compartido/config.php

# Escribe la configuración de WordPress en el archivo wp-config.php
cat <<EOF > /var/www/compartido/wp-config.php
<?php
/**
 * Configuración base de WordPress
 *
 * Este archivo es usado durante la instalación para crear el archivo wp-config.php.
 * No es necesario usar la interfaz web, puedes copiar este archivo a "wp-config.php"
 * y rellenar los valores.
 *
 * Este archivo contiene las siguientes configuraciones:
 *
 * * Configuración de la base de datos
 * * Claves secretas
 * * Prefijo de la tabla de la base de datos
 * * ABSPATH
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/
 *
 * @package WordPress
 */

// ** Configuración de la base de datos - Puedes obtener esta información de tu proveedor de hosting ** //
/** El nombre de la base de datos de WordPress */
define( 'DB_NAME', 'wordpress_db' );

/** Nombre de usuario de la base de datos */
define( 'DB_USER', 'user_wp' );

/** Contraseña de la base de datos */
define( 'DB_PASSWORD', 'Pass1234.' );

/** Host de la base de datos */
define( 'DB_HOST', '192.168.10.136' );

/** Charset de la base de datos a usar en la creación de tablas. */
define( 'DB_CHARSET', 'utf8mb4' );

/** El tipo de cotejamiento de la base de datos. No cambiar si tienes dudas. */
define( 'DB_COLLATE', '' );

/**#@+
 * Claves únicas de autentificación y salado.
 *
 * Cambia estas claves por frases únicas. Puedes generarlas usando
 * el {@link https://api.wordpress.org/secret-key/1.1/salt/ servicio de claves secretas de WordPress}.
 *
 * Puedes cambiarlas en cualquier momento para invalidar todas las cookies existentes.
 * Esto forzará a todos los usuarios a tener que iniciar sesión nuevamente.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'HJe6_]?Pq%f^b*D#h0{+18QR$iUA-l%+aW2X9:BtYqv#5WcN|*=kddZD^xj[0+ZT' );
define( 'SECURE_AUTH_KEY',  'ioI4s=&blHhSqG~n`9_~^>/` `:c*#HaMRdL{~at`nEPp4!*x>ODZ8kU~-@AvV56' );
define( 'LOGGED_IN_KEY',    '%WK%HeHm+_fhySuM]A=*@d|`UAWS&xgw+,ebd*7!dN*58V5e>~i.e%LXLGF[QyN/' );
define( 'NONCE_KEY',        'gZ(TI/9Qkr%,VGoW(x+ftqPY{RfPTK#fZPUT77?68Ma]{+jK9}<OpeY$+_=f-/b:' );
define( 'AUTH_SALT',        '|*Of]B^7+23b@fn| wIs7fla|st%gUxZmnCTHAhRhcTt.6dD|q}+M)8]b.uL`,3x' );
define( 'SECURE_AUTH_SALT', 'fHCG**2wz=ETM0[I![xyV26zdq(U*79}n%6`RcB*}x,BBP@#12 8/e fQ{f%/}C%' );
define( 'LOGGED_IN_SALT',   'N<;+~ 394>f7.R1YRS:=&/qTZ{H0X&/Ml[gK.|[}|.)H_L7t+K<ps`2r~ZfrnS:6' );
define( 'NONCE_SALT',       'y[M%)M+_(8l3%}DnVw<3T>&&{(j655t~(.zv`?T(X|0qg*!:Blgk-L&!&*>AWv,V' );

/** URL del sitio de WordPress */
define( 'WP_HOME', 'https://wordpressjorge.zapto.org' );
define( 'WP_SITEURL', 'https://wordpressjorge.zapto.org' );

/**#@-*/

/**
 * Prefijo de la tabla de la base de datos de WordPress.
 *
 * Puedes tener múltiples instalaciones en una base de datos si le das a cada una
 * un prefijo único. Solo números, letras y guiones bajos, por favor.
 *
 * En el momento de la instalación, las tablas de la base de datos se crean con el prefijo especificado.
 * Cambiar este valor después de que WordPress esté instalado hará que tu sitio piense
 * que no ha sido instalado.
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/#table-prefix
 */
$table_prefix = 'wp_';

/**
 * Modo de depuración de WordPress.
 *
 * Cambia esto a true para habilitar la visualización de avisos durante el desarrollo.
 * Se recomienda encarecidamente que los desarrolladores de plugins y temas usen WP_DEBUG
 * en sus entornos de desarrollo.
 *
 * Para información sobre otras constantes que se pueden usar para depuración,
 * visita la documentación.
 *
 * @link https://developer.wordpress.org/advanced-administration/debug/debug-wordpress/
 */
define( 'WP_DEBUG', false );

/* Añade cualquier valor personalizado entre esta línea y la línea "stop editing". */

/* Eso es todo, deja de editar! Publicación feliz. */

/** Ruta absoluta al directorio de WordPress. */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

/** Configura las variables de WordPress e incluye los archivos. */
require_once ABSPATH . 'wp-settings.php';

/** Configuración adicional para manejar HTTPS y encabezados de proxy */
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
if (isset($_SERVER['HTTP_X_FORWARDED_HOST'])) {
    $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
}
EOF

# Mensaje de confirmación
echo "Configuración del servidor NFS completada."

```

## **5.4. Script de Aprovisionamiento del Servidor de Base de Datos**

```bash
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
```

# **6. Personalización de WordPress**

Para personalizar WordPress y poder añadir nuestro nombre editaremos la página principal de nuestro sitio, para ello accedemos como administrador del sitio a traves de [este enlace](https://wordpressjorge.zapto.org/wp-login.php) , el usuario es `Jorge` y la contraseña `Jorge1234.` 

Nuestras páginas se encuentran en la sección Pages, accedemos a ellas y pulsamos sobre editar, aquí puedes personalizar a tu gusto el contenido de todas las páginas de nuestro CMS. 

# **7. Seguridad y Restricciones de Acceso**

- Máquina pivote utilizada para acceder de forma segura a todas las máquinas, evitando la necesidad de exponer las subredes privadas a la red pública.

# **8. Conclusión**

El despliegue se completó exitosamente, asegurando alta disponibilidad y escalabilidad del CMS WordPress. Todas las instancias se configuraron utilizando scripts de aprovisionamiento automatizados, lo cual asegura consistencia y reduce la posibilidad de errores manuales. La infraestructura está organizada en capas para mejorar la seguridad y permitir una gestión eficiente del tráfico.

# **9. Repositorio y Acceso**

El código fuente del script de aprovisionamiento se encuentra disponible en el siguiente [repositorio de GitHub](https://github.com/Jorxx0/CMS_3_capas.git). Además, la URL de acceso a la aplicación WordPress es [https://wordpressjorge.zapto.org](https://wordpressjorge.zapto.org), la cual apunta a una IP elástica que se asocia con el balanceador de carga de la capa 1.