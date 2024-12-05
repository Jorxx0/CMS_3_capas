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
