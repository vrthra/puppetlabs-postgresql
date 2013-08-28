# PRIVATE CLASS: do not call directly
class postgresql::server::config {
  $ip_mask_deny_postgres_user = $postgresql::server::ip_mask_deny_postgres_user
  $ip_mask_allow_all_users    = $postgresql::server::ip_mask_allow_all_users
  $listen_addresses           = $postgresql::server::listen_addresses
  $ipv4acls                   = $postgresql::server::ipv4acls
  $ipv6acls                   = $postgresql::server::ipv6acls
  $pg_hba_conf_path           = $postgresql::server::pg_hba_conf_path
  $postgresql_conf_path       = $postgresql::server::postgresql_conf_path
  $manage_redhat_firewall     = $postgresql::server::manage_redhat_firewall
  $pg_hba_conf_defaults       = $postgresql::server::pg_hba_conf_defaults
  $user                       = $postgresql::server::user
  $group                      = $postgresql::server::group
  $version                    = $postgresql::server::version

  File {
    owner => $user,
    group => $group,
  }

  # Prepare the main pg_hba file
  include concat::setup
  concat { $pg_hba_conf_path:
    owner  => 0,
    group  => $group,
    mode   => '0640',
    warn   => true,
    notify => Exec['reload_postgresql'],
  }

  if $pg_hba_conf_defaults {
    Postgresql::Pg_hba_rule {
      database => 'all',
      user => 'all',
    }

    # Lets setup the base rules
    postgresql::pg_hba_rule { 'local access as postgres user':
      type        => 'local',
      user        => $user,
      auth_method => 'ident',
      auth_option => $version ? {
        '8.1'   => 'sameuser',
        default => undef,
      },
      order       => '001',
    }
    postgresql::pg_hba_rule { 'local access to database with same name':
      type        => 'local',
      auth_method => 'ident',
      auth_option => $version ? {
        '8.1'   => 'sameuser',
        default => undef,
      },
      order       => '002',
    }
    postgresql::pg_hba_rule { 'deny access to postgresql user':
      type        => 'host',
      user        => $user,
      address     => $ip_mask_deny_postgres_user,
      auth_method => 'reject',
      order       => '003',
    }

    # ipv4acls are passed as an array of rule strings, here we transform them into
    # a resources hash, and pass the result to create_resources
    $ipv4acl_resources = postgresql_acls_to_resources_hash($ipv4acls, 'ipv4acls', 10)
    create_resources('postgresql::pg_hba_rule', $ipv4acl_resources)

    postgresql::pg_hba_rule { 'allow access to all users':
      type        => 'host',
      address     => $ip_mask_allow_all_users,
      auth_method => 'md5',
      order       => '100',
    }
    postgresql::pg_hba_rule { 'allow access to ipv6 localhost':
      type        => 'host',
      address     => '::1/128',
      auth_method => 'md5',
      order       => '101',
    }

    # ipv6acls are passed as an array of rule strings, here we transform them into
    # a resources hash, and pass the result to create_resources
    $ipv6acl_resources = postgresql_acls_to_resources_hash($ipv6acls, 'ipv6acls', 102)
    create_resources('postgresql::pg_hba_rule', $ipv6acl_resources)
  }

  # We must set a "listen_addresses" line in the postgresql.conf if we
  # want to allow any connections from remote hosts.
  postgresql::config_entry { 'listen_addresses':
    value => "${listen_addresses}",
  }

  # Here we are adding an 'include' line so that users have the option of
  # managing their own settings in a second conf file. This only works for
  # postgresql 8.2 and higher.
  if(versioncmp($postgresql::params::version, '8.2') >= 0) {
    exec { 'create_postgresql_conf_path':
      command => "touch `dirname ${postgresql_conf_path}`/postgresql_puppet_extras.conf",
      path    => '/usr/bin:/bin',
      unless  => "[ -f `dirname ${postgresql_conf_path}`/postgresql_puppet_extras.conf ]"
    }

    postgresql::config_entry{ 'include':
      value => "postgresql_puppet_extras.conf",
      require => Exec['create_postgresql_conf_path'],
    }
  }

}
