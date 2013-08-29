# Define for granting permissions to roles. See README.md for more details.
define postgresql::grant (
  $role,
  $db,
  $privilege   = undef,
  $object_type = 'database',
  $object_name = $db,
  $psql_db     = $postgresql::params::user,
  $psql_user   = $postgresql::params::user
) {
  $group     = $postgresql::params::group
  $psql_path = $postgresql::params::psql_path

  ## Munge the input values
  $_object_type = upcase($object_type)
  $_privilege   = upcase($privilege)

  ## Validate that the object type is known
  validate_string($_object_type,
    #'COLUMN',
    'DATABASE',
    #'FOREIGN SERVER',
    #'FOREIGN DATA WRAPPER',
    #'FUNCTION',
    #'PROCEDURAL LANGUAGE',
    #'SCHEMA',
    #'SEQUENCE',
    'TABLE',
    #'TABLESPACE',
    #'VIEW',
  )

  ## Validate that the object type's privilege is acceptable
  case $_object_type {
    'DATABASE': {
      validate_string($_privilege,'CREATE','CONNECT','TEMPORARY','TEMP','ALL',
        'ALL PRIVILEGES')
      $unless_function = 'has_database_privilege'
      $on_db = $psql_db
    }
    'TABLE': {
      validate_string($_privilege,'SELECT','INSERT','UPDATE','REFERENCES',
        'ALL','ALL PRIVILEGES')
      $unless_function = 'has_table_privilege'
      $on_db = $db
    }
    default: {
      fail("Missing privilege validation for object type ${_object_type}")
    }
  }

  # TODO: this is a terrible hack; if they pass "ALL" as the desired privilege,
  #  we need a way to test for it--and has_database_privilege does not
  #  recognize 'ALL' as a valid privilege name. So we probably need to
  #  hard-code a mapping between 'ALL' and the list of actual privileges that
  #  it entails, and loop over them to check them.  That sort of thing will
  #  probably need to wait until we port this over to ruby, so, for now, we're
  #  just going to assume that if they have "CREATE" privileges on a database,
  #  then they have "ALL".  (I told you that it was terrible!)
  $unless_privilege = $_privilege ? {
    'ALL'   => 'CREATE',
    default => $_privilege,
  }
  postgresql_psql { "GRANT ${_privilege} ON ${_object_type} \"${object_name}\" TO \"${role}\"":
    db         => $on_db,
    psql_user  => $psql_user,
    psql_group => $group,
    psql_path  => $psql_path,
    unless     => "SELECT 1 WHERE ${unless_function}('${role}', '${object_name}', '${unless_privilege}')",
    require    => Class['postgresql::server']
  }
}
