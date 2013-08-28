# This class installs the PL/Perl procedural language for postgresql. See README.md for more details.
class postgresql::plperl(
  $package_name   = $postgresql::params::plperl_package_name,
  $package_ensure = 'present'
) inherits postgresql::params {

  package { 'postgresql-plperl':
    ensure => $package_ensure,
    name   => $package_name,
  }

}
