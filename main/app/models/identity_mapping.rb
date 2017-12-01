# -*- coding: UTF-8 -*-

class IdentityMapping < ActiveRecord::Base
  before_create :generate_code
  after_create :redis_code

  private
  def generate_code
    loop do 
      self.code = [*('a'..'z')].sample(3).join + [*('0'..'9')].sample(3).join
      break if !$cache_redis.exists('identity_mapping/'+self.test_id+'/'+self.code)
    end
  end

  def redis_code
    Common::SwtkRedis::set_key(Common::SwtkRedis::Ns::Cache,'identity_mapping/'+self.test_id+'/'+self.code, 0)
  end
end
