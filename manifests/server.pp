# This installs a PostgreSQL server. See README.md for more details.
class postgresql::server (
  $ensure                     = true,
  $postgres_password          = undef,

  $package_name               = $postgresql::params::server_package_name,

  $service_name               = $postgresql::params::service_name,
  $service_provider           = $postgresql::params::service_provider,
  $service_status             = $postgresql::params::service_status,

  $listen_addresses           = $postgresql::params::listen_addresses,
  $ip_mask_deny_postgres_user = $postgresql::params::ip_mask_deny_postgres_user,
  $ip_mask_allow_all_users    = $postgresql::params::ip_mask_allow_all_users,
  $ipv4acls                   = $postgresql::params::ipv4acls,
  $ipv6acls                   = $postgresql::params::ipv6acls,

  $postgresql_conf_path       = $postgresql::params::postgresql_conf_path,
  $pg_hba_conf_path           = $postgresql::params::pg_hba_conf_path,
  $pg_hba_conf_defaults       = $postgresql::params::pg_hba_conf_defaults,

  $datadir                    = $postgresql::params::datadir,

  $user                       = $postgresql::params::user,
  $group                      = $postgresql::params::group,

  $version                    = $postgresql::params::version,

  $needs_initdb               = $postgresql::params::needs_initdb,
  $initdb_path                = $postgresql::params::initdb_path,

  $encoding                   = $postgresql::params::encoding,
  $locale                     = $postgresql::params::locale,

  $manage_firewall            = $postgresql::params::manage_firewall,
  $firewall_supported         = $postgresql::params::firewall_supported
) inherits postgresql::params {
  $pg = 'postgresql::server'

  if ($ensure == 'present' or $ensure == true) {
    # Reload has its own ordering, specified by other defines
    class { "${pg}::reload": }

    anchor { "${pg}::start": }->
    class { "${pg}::install": }->
    class { "${pg}::initdb": }->
    class { "${pg}::config": }->
    class { "${pg}::service": }->
    class { "${pg}::passwd": }->
    class { "${pg}::firewall": }->
    anchor { "${pg}::end": }
  } else {
    anchor { "${pg}::start": }->
    class { "${pg}::firewall": }->
    class { "${pg}::passwd": }->
    class { "${pg}::service": }->
    class { "${pg}::install": }->
    class { "${pg}::initdb": }->
    class { "${pg}::config": }->
    anchor { "${pg}::end": }
  }
}
