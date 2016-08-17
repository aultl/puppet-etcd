# etcd - node config

define etcd::node (
  $client_port      = '2379', 
  $peer_port        = '2380', 
  $listen_https     = false, 
  $use_iptables     = 'no', 
  $ssl_cert         = undef, 
  $ssl_key          = undef, 
  $client_cert_auth = false,
  $trusted_ca_file  = undef,
  $service_path     = $etcd::params::service_path,
  $data_dir         = $etcd::params::data_dir,
  $user_name        = $etcd::params::user_name,
  $cluster_name     = '',
  $cluster_state    = 'new',
  $inital_cluster   = '',
) {

  # validate cluster_state
  validate_array_member($cluster_state, ['new','existing'])

  if ( size($cluster_name) > 1 ) {
    # make sure our cluster name is actually a string
    validate_string($cluster_name)

    # if the user specified a cluster_name, we should know the other members
    validate_hash($initial_cluster)

    # create a cluster token for safety
    $cluster_token = sha1_sum($cluter_name)
  }

  # Do we want to use SSL certs? 
  # TODO: allow different certs for client use and peer use;
  #       as configured now they are the same.
  if ( $listen_https ) { #<-- it is a bool because its not a fact!
    if ( !is_string($ssl_cert) or !is_string($ssl_key) ) {
      fail("Node ${fqdn} is missing a cert and/or key file in the ${module_name} configuration!")
    }

    # Make sure cert directory exists
    file { 'etcd_cert_dir':
      ensure => present,
      path   => $etcd::params::cert_path,
      mode   => '644',
      owner  => $etcd::params::user_name,
      group  => $etcd::params::group_name,
    }

    # install key file
    file { 'etcd_cert_file':
      ensure  => present,
      path    => "${etcd::params::cert_path}/${ssl_cert}",
      mode    => '640',
      source  => "puppet:///modules/${module_name}/certs/${ssl_cert}",
      owner   => $etcd::params::user_name,
      group   => $etcd::params::group_name,
      require => File['etcd_cert_dir'],
    }

    # install cert file
    file { 'etcd_key_file':
      ensure => file,
      path   => "${etcd::params::cert_path}/${ssl_key}",
      mode   => '640',
      source => "puppet:///modules/${module_name}/certs/${ssl_key}",
      owner  => $etcd::params::user_name,
      group  => $etcd::params::group_name,
      require => File['etcd_cert_dir'],
    }

    # Do we want to enforce client certificates?
    if ( $client_cert_auth ) { #<-- it is a bool because its not a fact!
      if ( !is_string($trusted_ca_file) ) {
        fail("Node ${fqdn} is missing a trusted ca file for client_cert_auth in the ${module_name} configuration!")
      }

      # install trusted ca file
      file { 'etcd_trusted_ca_file':
        ensure  => present,
        path    => "${etcd::params::cert_path}/${trusted_ca_file}",
        mode    => '640',
        source  => "puppet:///modules/${module_name}/certs/${trusted_ca_file}",
        owner   => $etcd::params::user_name,
        group   => $etcd::params::group_name,
        require => File['etcd_cert_dir'],
      }
    }
  }

  # Configure systemd
  file { 'etcd_init_script':
    ensure  => file,
    name    => "${etcd::params::init_path}/etcd.service",
    mode    => '644',
    content => template("${module_name}/etcd.service"),
    owner   => 'root',
    group   => 'root',
  }

  service { 'etcd_service' :
    ensure  => running,
    enable  => true,
    name    => 'etcd.service',
    require => [ File['etcd_init_script'], Package['oracle-jdk'] ],
  }

  # Configure iptables
  if ( $etcd::params::use_iptables == 'yes' ) {
    # etcd client communication port
    iptables::rule { 'etcd_requests' :
      action   => 'accept',
      dport    => "${client_port}",
      chain    => 'RH-Firewall',
      protocol => 'tcp',
      state    => 'new',
    }

    # etcd peer communication port
    iptables::rule { 'etcd_sync' :
      action  => 'accept',
      dport   => "${peer_port}",
      chain    => 'RH-Firewall',
      protocol => 'tcp',
      state    => 'new',
    }
  }
}
