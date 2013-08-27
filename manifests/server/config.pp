class postgresql::server::config (
  $postgres_password          = undef,
  $ip_mask_deny_postgres_user = $postgresql::params::ip_mask_deny_postgres_user,
  $ip_mask_allow_all_users    = $postgresql::params::ip_mask_allow_all_users,
  $listen_addresses           = $postgresql::params::listen_addresses,
  $ipv4acls                   = $postgresql::params::ipv4acls,
  $ipv6acls                   = $postgresql::params::ipv6acls,
  $pg_hba_conf_path           = $postgresql::params::pg_hba_conf_path,
  $postgresql_conf_path       = $postgresql::params::postgresql_conf_path,
  $manage_redhat_firewall     = $postgresql::params::manage_redhat_firewall,
  $manage_pg_hba_conf         = $postgresql::params::manage_pg_hba_conf
) inherits postgresql::params {

  File {
    owner => $postgresql::params::user,
    group => $postgresql::params::group,
  }

  if $manage_pg_hba_conf {
    # Create the main pg_hba resource
    postgresql::pg_hba { 'main': }

    Postgresql::Pg_hba_rule {
      database => 'all',
      user => 'all',
    }

    # Lets setup the base rules
    postgresql::pg_hba_rule { 'local access as postgres user':
      type        => 'local',
      user        => $postgresql::params::user,
      auth_method => 'ident',
      auth_option => $postgresql::params::version ? {
        '8.1'   => 'sameuser',
        default => undef,
      },
      order       => '001',
    }
    postgresql::pg_hba_rule { 'local access to database with same name':
      type        => 'local',
      auth_method => 'ident',
      auth_option => $postgresql::params::version ? {
        '8.1'   => 'sameuser',
        default => undef,
      },
      order       => '002',
    }
    postgresql::pg_hba_rule { 'deny access to postgresql user':
      type        => 'host',
      user        => $postgresql::params::user,
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
    $pg_conf_dir = dirname($postgresql_conf_path)
    file { "$pg_conf_dir/postgresql_puppet_extras.conf":
      ensure => present,
    }

    postgresql::config_entry{ 'include':
      value => "postgresql_puppet_extras.conf",
      require => File["$pg_conf_dir/postgresql_puppet_extras.conf"],
    }
  }

}
