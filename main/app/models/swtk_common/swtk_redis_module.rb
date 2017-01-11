module SwtkRedisModule
  module SwtkRedis
    module_function

    module Config
      ExpireTime = "21600" # 6 hours
    end

    module Prefix
      ImportResult = "/import_results/"
      GenerateReport = "/generate_reports/"
      Reports = "/reports_warehouse/"
    end

    module Ns
      Sidekiq = :sidekiq_redis
      Cache = :cache_redis
    end

    def current_redis ns
      case ns
      when :sidekiq_redis
        $sidekiq_redis
      else
        $cache_redis
      end
    end

    def set_key ns,k,v
  	  current_redis(ns).set k,v
      current_redis(ns).expire k, Config::ExpireTime
  	end

    def get_value_set_if_none ns, k, v
      if has_key?(k)
        get_value ns,k
      else
        set_key ns, k, v
      end
    end

    def incr_key ns,str
      current_redis(ns).incr(str)
    end

    def get_value ns,str
      current_redis(ns).get(str)
    end

    def has_key? ns,str
      current_redis(ns).exists(str)
    end

    def del_keys ns,str
      arr = find_keys ns,str
      return [] if arr.blank?
      current_redis(ns).del(*arr)
    end

    def find_keys ns,str
      current_redis(ns).keys(str)
    end

  end
end