<?php
/**
 * The base configuration for WordPress
 *
 * @package WordPress
 */

// ** Database settings ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wpdb' );

/** Database username */
define( 'DB_USER', 'wordpress' );

/** Database password */
define( 'DB_PASSWORD', 'ChangeMe123!' );

/** Database hostname */
define( 'DB_HOST', '10.1.0.11' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 */
define('AUTH_KEY',         '~NR-yAo_31ix{-uY5/bwVi8a3FPzBEoJ{6FXYWSD33U?WNc1=f3H>@(*HOX-<$Lu');
define('SECURE_AUTH_KEY',  'MDm ,4>pk;z;Ouk7-SySpbJ06C?C53Ucn$|B|-;{W1T=L+O|(djBiIb^ht*-PG=4');
define('LOGGED_IN_KEY',    'hlWs/fe?#dA6t0-X<xL4[ZYLoeTpc1:Ahz6}gV&F_C+Wo|eaH!?{TYgxBh]6C.t;');
define('NONCE_KEY',        '8Z-O#$P0d=mB|0:bG4Ny^$phDB7R]6+Ai^9,N~ODs=].7zL]_]OYJ`2!V:.)*5R-');
define('AUTH_SALT',        ' F;[n5)^Yl}A nj23aB}+-*[&~!r*Ku(|-TAl#1<_p]9(Xkv,GncL[F8Vl*5x-N7');
define('SECURE_AUTH_SALT', 'c$B|7.xYYw;~(8OI?s+~bV_G7Ix<yr9Rwse+9HEz:AbDP~J@F4-@iG5,pJYc#XXG');
define('LOGGED_IN_SALT',   'I,BBV.p}O>PabgT[V!+8b%e:+y4{Q-zO0N-/*;l]z~T(6/{dk@:;g5z:87[@islI');
define('NONCE_SALT',       'Cre7e=W|6HUs&<j>,O0pT)AP1wvSZdI#,OD8eT+d%p01M6L1%fv>L/(WlM>-ZMiB');

/**#@-*/

/**
 * WordPress database table prefix.
 */
$table_prefix = 'wp_';

/**
 * WordPress debugging mode.
 */
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', '/var/logs/wordpress_debug_log.txt' );

/* Add any custom values between this line and the "stop editing" line. */



/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
