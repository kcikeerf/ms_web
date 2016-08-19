class Mongodb::BankCkpQzp
  include Mongoid::Document
  validates :ckp_uid, :qzp_uid, length: {maximum: 36}

  field :ckp_uid, type: String
  field :qzp_uid, type: String
  #标示来源
  field :source_type, type: String
#  field :weights, type: Float

  def save_ckp_qzp qzp_uid=nil, ckp_uid=nil, source_type=nil
    self.ckp_uid = ckp_uid.nil?? nil:ckp_uid
    self.qzp_uid = qzp_uid.nil?? nil:qzp_uid
    self.source_type = source_type.nil?? nil:source_type
    self.save!
    return true
  end 

  def destroy_ckp_qzp
    begin
      self.destroy!
    rescue Exception=>ex
      return false
    end
    return true
  end

end
