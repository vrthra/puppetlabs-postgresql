# PRIVATE CLASS: do not call directly
class postgresql::server::install {
  $ensure       = $postgresql::server::ensure
  $package_name = $postgresql::server::package_name

  $package_ensure = $ensure ? {
    true    => 'present',
    false   => 'absent',
    default => $ensure
  }

  package { 'postgresql-server':
    ensure => $package_ensure,
    name   => $package_name,
    tag    => 'postgresql',
  }
}
