# This class installs the PL/Perl procedural language for postgresql. See
# README.md for more details.
class postgresql::server::plperl(
  $ensure       = $postgresql::server::ensure,
) {
  $package_name = $postgresql::params::plperl_package_name

  $package_ensure = $ensure ? {
    true    => 'present',
    false   => 'absent',
    default => $ensure
  }

  package { 'postgresql-plperl':
    ensure => $package_ensure,
    name   => $package_name,
  }

}
