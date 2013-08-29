# Define for creating database roles or users, see README.md for more
# information
#
# DEPRECATED: this resource will be removed in the future, use
# 'postgresql::role' instead.
define postgresql::database_user(
  $password_hash    = false,
  $createdb         = false,
  $createrole       = false,
  $db               = $postgresql::params::user,
  $superuser        = false,
  $replication      = false,
  $connection_limit = '-1',
  $user             = $title
) {
  notice('The defined resource \'postgresql::database_user\' will be deprecated in the future, use \'postgresql::role\' instead')
  postgresql::role { $user:
    db               => $db,
    password_hash    => $password_hash,
    login            => true,
    createdb         => $createdb,
    superuser        => $superuser,
    createrole       => $createrole,
    replication      => $replication,
    connection_limit => $connection_limit,
  }
}
