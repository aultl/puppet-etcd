# etcd - config 

class etcd::config inherits etcd {

  # Configure sudo 
  sudo::user_rule { 'softeng_etcd' :
    user_list => '%softeng',
    runas     => 'etcd',
    command   => 'ALL',
  }
}
