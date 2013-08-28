# PRIVATE CLASS: do not call directly
class postgresql::server::initdb {
  $datadir     = $postgresql::server::datadir
  $encoding    = $postgresql::server::charset
  $group       = $postgresql::server::group
  $initdb_path = $postgresql::server::initdb_path
  $user        = $postgresql::server::user
  $locale      = $postgresql::server::locale
  $package_name = $postgresql::server::server_package_name

  # Build up the initdb command.
  #
  # We optionally add the locale switch if specified. Older versions of the
  # initdb command don't accept this switch. So if the user didn't pass the
  # parameter, lets not pass the switch at all.
  $initdb_command = $locale ? {
    undef   => "${initdb_path} --encoding '${encoding}' --pgdata '${datadir}'",
    default => "${initdb_path} --encoding '${encoding}' --pgdata '${datadir}' --locale '${locale}'"
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
}
