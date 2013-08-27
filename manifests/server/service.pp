class postgresql::server::service (
  $ensure           = 'running',
  $service_name     = $postgresql::server::service_name,
  $service_provider = $postgresql::server::service_provider,
  $service_status   = $postgresql::server::service_status
) {
  $enable = $ensure ? {
    'running' => true,
    'stopped' => false,
    default => $ensure
  }
  service { 'postgresqld':
    ensure    => $ensure,
    name      => $service_name,
    enable    => $enable,
    provider  => $service_provider,
    hasstatus => true,
    status    => $service_status,
  }
}
