class postgresql::server::initdb(
  $datadir     = $postgresql::params::datadir,
  $encoding    = $postgresql::params::charset,
  $group       = $postgresql::params::group,
  $initdb_path = $postgresql::params::initdb_path,
  $user        = $postgresql::params::user
) inherits postgresql::params {
  # Build up the initdb command.
  #
  # We optionally add the locale switch if specified. Older versions of the
  # initdb command don't accept this switch. So if the user didn't pass the
  # parameter, lets not pass the switch at all.
  $initdb_command = $postgresql::params::locale ? {
    undef   => "${initdb_path} --encoding '${encoding}' --pgdata '${datadir}'",
    default => "${initdb_path} --encoding '${encoding}' --pgdata '${datadir}' --locale '${postgresql::params::locale}'"
  }

  # This runs the initdb command, we use the existance of the PG_VERSION file to
  # ensure we don't keep running this command.
  exec { 'postgresql_initdb':
    command   => $initdb_command,
    creates   => "${datadir}/PG_VERSION",
    user      => $user,
    group     => $group,
    logoutput => on_failure,
  }

  # If we manage the package (which is user configurable) make sure the
  # package exists first.
  if defined(Package[$postgresql::params::server_package_name]) {
    Package[$postgresql::params::server_package_name]->
      Exec['postgresql_initdb']
  }
}
