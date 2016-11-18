class ReportUrlMapping < ActiveRecord::Base
  self.primary_key = "codes"

  #concerns
  include TimePatch

  before_create :init_uid
  
  private

  def init_uid
    result = ""
    arr = [*'1'..'9'] + [*'A'..'Z'] + [*'a'..'z']
    Common::Report::Url::Length.times{ result << arr.sample}
    self.codes = result
  end

end