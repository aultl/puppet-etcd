# etcd - install

class etcd::install inherits etcd {
  include jtv_root::params

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  # Create group for the etcd account
  group { 'group_etcd':
    name       => $etcd::params::group_name,
    gid        => $etcd::params::user_gid,
    ensure     => present,
  }

  user { 'user_etcd':
    name       => $etcd::params::user_name,
    comment    => 'Etcd User (PUPPET)',
    home       => $etcd::params::home_path,
    managehome => 'true',
    ensure     => present,
    shell      => '/bin/bash',
    uid        => $etcd::params::user_uid,
    membership => 'minimum',
    gid        => $etcd::params::group_name,
    require    => File[$jtv_root::params::supporthome_dir], # <-- from jtv_root module
  }

  # Install etcd package
  package { 'jtv-etcd' :
    ensure  => present,
    require => [ User['etcd'], Repo['jtv-apps'] ],
  }

  # Ensure the etcd service home directory exists
  file { 'etcd_service_dir':
    ensure => directory,
    name   => $etcd::params::service_path,
    mode   => '0755',
    owner  => $etcd::params::user_name,
    group  => $etcd::params::group_name,
    require => File[$jtv_root::params::support_dir], # <-- from jtv_root module
  }

  # Ensure the etcd data directory exists
  file { 'etcd_data_dir':
    ensure  => directory,
    name    => $etcd::params::data_path,
    mode    => '0755',
    owner   => $etcd::params::user_name,
    group   => $etcd::params::group_name,
    require => File['etcd_service_dir'],
  }

}
