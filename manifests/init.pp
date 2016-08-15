# etcd - init.pp

# The "etcd" class configures Linux boxes
# to run the etcd application

class etcd inherits etcd::params {
 
 anchor { 'etcd::begin': }
  -> class { '::etcd::install': }
  -> class { '::etcd::config': }
  -> anchor { 'etcd::end': }

}
