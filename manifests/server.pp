class postgresql::server (
  $ensure           = true,
  $package_name     = $postgresql::params::server_package_name,
  $package_ensure   = 'present',
  $service_name     = $postgresql::params::service_name,
  $service_provider = $postgresql::params::service_provider,
  $service_status   = $postgresql::params::service_status,
  $config_hash      = {},
  $datadir          = $postgresql::params::datadir
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

  if ($ensure == 'absent' or $ensure == 'stopped' or $ensure == false) {
    class { 'postgresql::server::package': ensure => absent }
    class { 'postgresql::server::service': ensure => stopped }
    file { $datadir:
      ensure  => absent,
      recurse => true,
      force   => true,
    }
    Anchor['postgresql::server::start'] ->
    Class['postgresql::server::service'] -> Class['postgresql::server::package'] -> File[$datadir] ->
    Anchor['postgresql::server::end']
  } else {
    class { 'postgresql::server::package': }
    $config_class = {
      'postgresql::server::config' => $config_hash,
    }
    create_resources( 'class', $config_class )
    class { 'postgresql::server::service': }
    class { 'postgresql::server::passwd': }

    if ($postgresql::params::needs_initdb) {
      include postgresql::server::initdb
      Anchor['postgresql::server::start'] ->
      Class['postgresql::server::package'] -> Class['postgresql::server::initdb'] -> Class['postgresql::server::config'] -> Class['postgresql::server::service'] -> Class['postgresql::server::passwd'] ->
      Anchor['postgresql::server::end']
    }
    else  {
      Anchor['postgresql::server::start'] ->
      Class['postgresql::server::package'] -> Class['postgresql::server::config'] -> Class['postgresql::server::service'] -> Class['postgresql::server::passwd'] ->
      Anchor['postgresql::server::end']
    }

  }

  # TODO: get rid of hard-coded port
  if ($manage_redhat_firewall and $firewall_supported) {
    class { 'firewall': }
    exec { 'postgresql-persist-firewall':
      command     => $persist_firewall_command,
      refreshonly => true,
    }

    Firewall {
      notify => Exec['postgresql-persist-firewall']
    }

    firewall { '5432 accept - postgres':
      port   => '5432',
      proto  => 'tcp',
      action => 'accept',
    }
  }

}
