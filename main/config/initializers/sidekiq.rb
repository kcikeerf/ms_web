redis_server = Rails.application.secrets.redis_server
redis_port = Rails.application.secrets.redis_port
redis_db_num = Rails.application.secrets.redis_db_num
redis_namespace = Rails.application.secrets.redis_namespace

url = "redis://#{redis_server}:#{redis_port}/#{redis_db_num}"

$redis = Redis.new(host: redis_server, port: redis_port, db: redis_db_num, namespace: redis_namespace)

Sidekiq.configure_server do |config|
  config.redis = { url: url, namespace: redis_namespace }
end

Sidekiq.configure_client do |config|
  config.redis = { url: url, namespace: redis_namespace }
end
