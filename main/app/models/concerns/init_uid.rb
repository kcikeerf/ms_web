module InitUid
  extend ActiveSupport::Concern

  included do
    before_create :init_uid
  end

  private

  def init_uid
    self.uid=Time.now.to_snowflake.to_s
  end

end