module SwtkRedisModule
  module SwtkRedis
    module_function

    module Prefix
      ImportResult = "/import_results/"
    end

    def set_key k,v
  	  $cache_redis.set k,v
  	end

    def incr_key str
      $cache_redis.incr(str)
    end

    def get_value str
      $cache_redis.get(str)
    end

    def del_keys str
      arr = find_keys str
      $cache_redis.del(*arr)
    end

    def find_keys str
      $cache_redis.keys(str)
    end
  end
end