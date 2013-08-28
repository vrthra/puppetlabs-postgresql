# This installs a PostgreSQL server. See README.md for more details.
class postgresql::server (
  $ensure                     = true,
  $package_ensure             = 'present',
  $postgres_password          = undef,
  $package_name               = $postgresql::params::server_package_name,
  $service_name               = $postgresql::params::service_name,
  $service_provider           = $postgresql::params::service_provider,
  $service_status             = $postgresql::params::service_status,
  $ip_mask_deny_postgres_user = $postgresql::params::ip_mask_deny_postgres_user,
  $ip_mask_allow_all_users    = $postgresql::params::ip_mask_allow_all_users,
  $listen_addresses           = $postgresql::params::listen_addresses,
  $ipv4acls                   = $postgresql::params::ipv4acls,
  $ipv6acls                   = $postgresql::params::ipv6acls,
  $pg_hba_conf_path           = $postgresql::params::pg_hba_conf_path,
  $postgresql_conf_path       = $postgresql::params::postgresql_conf_path,
  $manage_firewall            = $postgresql::params::manage_redhat_firewall,
  $pg_hba_conf_defaults       = $postgresql::params::pg_hba_conf_defaults,
  $datadir                    = $postgresql::params::datadir,
  $user                       = $postgresql::params::user,
  $group                      = $postgresql::params::group,
  $version                    = $postgresql::params::version,
  $needs_initdb               = $postgresql::params::needs_initdb,
  $firewall_supported         = $postgresql::params::firewall_supported
) inherits postgresql::params {

  anchor {
    'postgresql::server::start': ;
    'postgresql::server::end': ;
  }

  # This gets signalled by configuration defines, to avoid doing a full service
  # restart.
  exec { 'reload_postgresql':
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    command     => "service ${service_name} reload",
    onlyif      => $service_status,
    refreshonly => true,
  }

  # TODO: fix me
  if ($ensure == 'absent' or $ensure == 'stopped' or $ensure == false) {
    class { 'postgresql::server::install': }
    class { 'postgresql::server::service': }

    file { $datadir:
      ensure  => absent,
      recurse => true,
      force   => true,
    }

    Anchor['postgresql::server::start']->
    Class['postgresql::server::service']->
    Class['postgresql::server::install']->
    File[$datadir]->
    Anchor['postgresql::server::end']
  } else {

    class { 'postgresql::server::install': }
    class { 'postgresql::server::config': }
    class { 'postgresql::server::service': }
    class { 'postgresql::server::passwd': }

    if ($needs_initdb) {
      include postgresql::server::initdb

      Anchor['postgresql::server::start']->
      Class['postgresql::server::install']->
      Class['postgresql::server::initdb']->
      Class['postgresql::server::config']->
      Class['postgresql::server::service']->
      Class['postgresql::server::passwd']->
      Anchor['postgresql::server::end']
    }
    else  {
      Anchor['postgresql::server::start']->
      Class['postgresql::server::install']->
      Class['postgresql::server::config']->
      Class['postgresql::server::service']->
      Class['postgresql::server::passwd']->
      Anchor['postgresql::server::end']
    }

  }

  # TODO: get rid of hard-coded port
  if ($manage_firewall and $firewall_supported) {
    include firewall

    firewall { '5432 accept - postgres':
      port   => '5432',
      proto  => 'tcp',
      action => 'accept',
    }
  }
}
