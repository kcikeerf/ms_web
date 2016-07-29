require  Rails.root + 'lib/redis/cluster'
startup_nodes = [
  {:host => "127.0.0.1", :port=>7000},
  {:host => "127.0.0.1", :port=>7001},
  {:host => "127.0.0.1", :port=>7002}
]
max_cached_connections = 5
$k12ke_rc = RedisCluster.new(startup_nodes, max_cached_connections)
