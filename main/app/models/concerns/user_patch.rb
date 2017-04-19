module UserPatch
  extend ActiveSupport::Concern

  included do
    attr_accessor :current_user_id
  end
end
