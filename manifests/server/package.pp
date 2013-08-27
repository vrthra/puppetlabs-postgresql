class postgresql::server::package (
  $ensure       = $postgresql::server::package_ensure,
  $package_name = $postgresql::server::package_name
) {
  package { 'postgresql-server':
    ensure => $ensure,
    name   => $package_name,
    tag    => 'postgresql',
  }
}
