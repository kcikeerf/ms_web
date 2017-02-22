class SkopeRule < ActiveRecord::Base
  belongs_to :skope
  
  def save_ins params
    result = false
    begin
      paramsh = params.clone
      paramsh[:rkey_label] = Common::SkopeRule::DefaultKeyList[params[:rkey]]
      paramsh[:rvalue_label] = Common::SkopeRule::DefaultValueList[params[:rvalue]]

      update_attributes!(paramsh)
      result = true
    rescue Exception => ex
      # do nothing
    ensure
      return result
    end
  end
end
