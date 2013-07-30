#
# Parameters:
#   ['ensure'] - Whether the setting should be present or absent. Default to present.
#   ['value']  - The value of the configuration parameter.
#   ['path']   - The path to the configuration file (optional)
#
# Actions:
# - Creates and manages a postgresql configuration entry.
#
# Sample usage:
#   postgresql::recovery_entry { 'standby_mode':
#     value => 'on',
#   }
#
# See also:
#   http://www.postgresql.org/docs/current/static/config-setting.html
#
define postgresql::recovery_entry (
    $ensure='present',
    $value=undef,
    $path=false
) {

  include '::postgresql::params'

  $target = $path ? {
    false   => "${::postgresql::params::postgresql_recovery_path}",
    default => $path,
  }

  case $name {

    /standby_mode|primary_conninfo|trigger_file|restore_command|archive_cleanup_command/: {
      Pgconf {
        notify => Service['postgresqld'],
      }
    }

    default: {
      Pgconf {
        notify => Exec['reload_postgresql'],
      }
    }
  }


  case $ensure {

    /present|absent/: {
      pgrecovery { $name:
        ensure  => $ensure,
        target  => $target,
        value   => $value,
        require => Package["${::postgresql::params::server_package_name}"],
      }
    }

    default: {
      fail("Unknown value for ensure '${ensure}'.")
    }
  }

}
