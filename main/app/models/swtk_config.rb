class SwtkConfig < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  class << self
    def get_config_value name_str
      item = where(:name => name_str).first
      return nil unless item
      item.value
    end 
  end
end
