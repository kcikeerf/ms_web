class Mongodb::BankCkpQzp
  include Mongoid::Document
#  include MongoMapper::Document
  include Tenacity

#  auto_increment!

#  field :id2, type: Integer, Default: ->{ :nid }

#  field :nid, type: Integer

  validates :ckp_uid, :qzp_uid, length: {maximum: 36}

  before_save :format_weights

  field :ckp_uid, type: String
  field :qzp_uid, type: String
  field :weights, type: Float

  belongs_to :bank_qizpoint_qzp
  t_belongs_to :bank_checkpoint_ckp , class_name: "BankCheckpointCkp", foreign_key: "ckp_uid"

  def save_ckp params
    self.ckp_uid = params["ckp_uid"].nil?? nil:params["ckp_uid"]
    self.qzp_uid = params["qzp_uid"].nil?? nil:params["qzp_uid"]
    self.weights = params["weights"].nil?? nil:params["weights"]
    self.save!
    return true
  end 

  private 
  def format_weights
    self.weights = self.weights.nil?? 0.0:("%.2f" % self.weights).to_f
  end
end
