# etcd - params.pp

class etcd::params {

  # Setup system modifications for Linux and Solaris
  $listen_https     = false
  $client_cert_auth = false

  $user_gcos  = "ETCD User (PUPPET)"
  $user_name  = 'etcd'
  $group_name = 'etcd'
  $user_uid   = '508'
  $user_gid   = '508'
  $home_path  = "/export/home/${user_name}"

  $init_path    = '/etc/systemd/system'
  $service_path = '/opt/etcd_server'
  $cert_path    = '/opt/etcd_server/certs'
  $data_path    = '/opt/etcd_server/data'
}
