# This module creates tablespace. See README.md for more details.
define postgresql::tablespace(
  $location,
  $owner = undef,
  $spcname  = $title)
{
  include postgresql::params

  Postgresql_psql {
    psql_user    => $postgresql::params::user,
    psql_group   => $postgresql::params::group,
    psql_path    => $postgresql::params::psql_path,
  }

  if ($owner == undef) {
    $owner_section = ''
  }
  else {
    $owner_section = "OWNER \"${owner}\""
  }

  $create_tablespace_command = "CREATE TABLESPACE \"${spcname}\" ${owner_section} LOCATION '${location}'"

  file { $location:
    ensure => directory,
    owner  => $postgresql::params::user,
    group  => $postgresql::params::group,
    mode   => '0700',
  }

  postgresql_psql { "Create tablespace '${spcname}'":
    command => $create_tablespace_command,
    unless  => "SELECT spcname FROM pg_tablespace WHERE spcname='${spcname}'",
    require => [Class['postgresql::server'], File[$location]],
  }
}
