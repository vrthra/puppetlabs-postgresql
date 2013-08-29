# Define for conveniently creating a role, database and assigning the correct
# permissions. See README.md for more details.
define postgresql::db (
  $user,
  $password,
  $charset    = $postgresql::params::charset,
  $locale     = $postgresql::params::locale,
  $grant      = 'ALL',
  $tablespace = undef,
  $istemplate = false
) {
  include postgresql::params

  postgresql::database { $name:
    charset    => $charset,
    tablespace => $tablespace,
    require    => Class['postgresql::server'],
    locale     => $locale,
    istemplate => $istemplate,
  }

  if ! defined(Postgresql::Role[$user]) {
    postgresql::role { $user:
      password_hash   => $password,
      require         => Postgresql::Database[$name],
    }
  }

  postgresql::database_grant { "GRANT ${user} - ${grant} - ${name}":
    privilege       => $grant,
    db              => $name,
    role            => $user,
    require         => [Postgresql::Database[$name], Postgresql::Role[$user]],
  }

}
