class postgresql::server::passwd (
  $postgres_password = undef
) inherits postgresql::params {
  if ($postgres_password != undef) {
    # NOTE: this password-setting logic relies on the pg_hba.conf being configured
    #  to allow the postgres system user to connect via psql without specifying
    #  a password ('ident' or 'trust' security).  This is the default
    #  for pg_hba.conf.
    $escapedpassword = postgresql_escape($postgres_password)
    exec { 'set_postgres_postgrespw':
      # This command works w/no password because we run it as postgres system user
      command     => "psql -c 'ALTER ROLE \"${postgresql::params::user}\" PASSWORD ${escapedpassword}'",
      user        => $postgresql::params::user,
      group       => $postgresql::params::group,
      logoutput   => true,
      cwd         => '/tmp',
      # With this command we're passing -h to force TCP authentication, which does require
      #  a password.  We specify the password via the PGPASSWORD environment variable.  If
      #  the password is correct (current), this command will exit with an exit code of 0,
      #  which will prevent the main command from running.
      unless      => "env PGPASSWORD='${postgres_password}' psql -h localhost -c 'select 1' > /dev/null",
      path        => '/usr/bin:/usr/local/bin:/bin',
    }
  }
}
