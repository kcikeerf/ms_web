class Tenant < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  def save_tenant
=begin
  	paramh = {
      :number =>
      :name
      :name_en
      :name_cn
      :name_abbrev
      :moto
      :type
      :address
      :email
      :phone
      :web
      :build_at
      :comment
      :area_uid
    }
=end
  end

  def self.get_school_numbers
    return Tenant.all.map{|t| t.number}.uniq.compact
  end

  def self.generate_school_number
    result = ""

    existedSchNumbers = self.get_school_numbers
    while existedSchNumbers.include?(result) || result.blank?
      arr = [*'1'..'9'] + [*'A'..'Z'] + [*'a'..'z']
      Common::School::NumberLength.times{ result << arr.sample}
    end
    return result
  end

end
