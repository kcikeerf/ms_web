module SwtkRedisModule
  module SwtkRedis
    module_function

    module Prefix
      ImportResult = "/import_results/"
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
  	end

    def incr_key ns,str
      current_redis(ns).incr(str)
    end

    def get_value ns,str
      current_redis(ns).get(str)
    end

    def del_keys ns,str
      arr = find_keys ns,str
      current_redis(ns).del(*arr)
    end

    def find_keys ns,str
      current_redis(ns).keys(str)
    end
  end
end