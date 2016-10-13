=begin
 require  Rails.root + 'lib/redis/cluster'
  startup_nodes = [
    {:host => "127.0.0.1", :port=>7000},
    {:host => "127.0.0.1", :port=>7001},
    {:host => "127.0.0.1", :port=>7002}
  ]
  max_cached_connections = 5
  $k12ke_rc = RedisCluster.new(startup_nodes, max_cached_connections)
=end

redis_server = 'localhost'
redis_port = 6379
redis_db_num = 0
redis_namespace = "swtk_sidekiq"
url = "redis://#{redis_server}:#{redis_port}/#{redis_db_num}"

$redis = Redis.new(host: redis_server, port: redis_port, db: redis_db_num, namespace: redis_namespace)

=begin
Sidekiq.configure_server do |config|
  config.redis = { url: url, namespace: redis_namespace }
end

Sidekiq.configure_client do |config|
  config.redis = { url: url, namespace: redis_namespace }
end
=end
