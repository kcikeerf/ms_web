class Mongodb::BankCkpQzp
  include Mongoid::Document
#  include MongoMapper::Document
#  include Tenacity
#  include MongoMysqlRelations

#  auto_increment!

#  field :id2, type: Integer, Default: ->{ :nid }

#  field :nid, type: Integer

  validates :ckp_uid, :qzp_uid, length: {maximum: 36}
  validates :ckp_uid, uniqueness: {scope: :qzp_uid, message: "already existed."}

#  before_save :format_weights

  field :ckp_uid, type: String
  field :qzp_uid, type: String
#  field :weights, type: Float

#  belongs_to :bank_qizpoint_qzp, class_name: "Mongodb::BankQizpointQzp", foreign_key: "qzp_uid"
#  t_belongs_to :bank_checkpoint_ckp , class_name: "BankCheckpointCkp", foreign_key: "ckp_uid"
#  to_mysql_belongs_to :bank_checkpoint_ckp , :foreign_key => "ckp_uid"
#  belongs_to :bank_qizpoint_qzp, class_name: "Mongodb::BankQizpointQzp", foreign_key: "qzp_uid"

  def save_ckp qzp_uid=nil,params
    target_ckp = BankCheckpointCkp.where(rid: params[:rid]).first
    self.ckp_uid = target_ckp.blank?? nil:target_ckp
    self.qzp_uid = qzp_uid.nil?? nil:qzp_uid
 #   self.weights = params["weights"].nil?? nil:params["weights"]
    self.save!
    return true
  end 

#  private 
#  def format_weights
#    self.weights = self.weights.nil?? 0.0:("%.2f" % self.weights).to_f
#  end
end
