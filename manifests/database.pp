# Define for creating a database. See README.md for more details.
define postgresql::database(
  $dbname   = $title,
  $owner = $postgresql::params::user,
  $tablespace = undef,
  $charset  = $postgresql::params::charset,
  $locale   = $postgresql::params::locale,
  $istemplate = false
) {
  include postgresql::params

  # Set the defaults for the postgresql_psql resource
  Postgresql_psql {
    psql_user    => $postgresql::params::user,
    psql_group   => $postgresql::params::group,
    psql_path    => $postgresql::params::psql_path,
  }

  # Optionally set the locale switch. Older versions of createdb may not accept
  # --locale, so if the parameter is undefined its safer not to pass it.
  if ($postgresql::params::version != '8.1') {
    $locale_option = $locale ? {
      undef   => '',
      default => "--locale=${locale}",
    }
    $public_revoke_privilege = 'CONNECT'
  } else {
    $locale_option = ''
    $public_revoke_privilege = 'ALL'
  }

  $createdb_command_tmp = "${postgresql::params::createdb_path} --owner='${owner}' --template=template0 --encoding '${charset}' ${locale_option} '${dbname}'"

  if($tablespace == undef) {
    $createdb_command = $createdb_command_tmp
  }
  else {
    $createdb_command = "${createdb_command_tmp} --tablespace='${tablespace}'"
  }

  postgresql_psql { "Check for existence of db '${dbname}'":
    command => 'SELECT 1',
    unless  => "SELECT datname FROM pg_database WHERE datname='${dbname}'",
    require => Class['postgresql::server']
  } ~>

  exec { $createdb_command :
    refreshonly => true,
    user        => $postgresql::params::user,
    logoutput   => on_failure,
  } ~>

  # This will prevent users from connecting to the database unless they've been
  #  granted privileges.
  postgresql_psql {"REVOKE ${public_revoke_privilege} ON DATABASE \"${dbname}\" FROM public":
    db          => $postgresql::params::user,
    refreshonly => true,
  }

  Exec [ $createdb_command ] ->

  postgresql_psql {"UPDATE pg_database SET datistemplate = ${istemplate} WHERE datname = '${dbname}'":
    unless => "SELECT datname FROM pg_database WHERE datname = '${dbname}' AND datistemplate = ${istemplate}",
  }
}
