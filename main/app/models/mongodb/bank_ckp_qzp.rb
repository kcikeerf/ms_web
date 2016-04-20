class Mongodb::BankCkpQzp
  include Mongoid::Document
#  include MongoMapper::Document

#  auto_increment!

#  field :id2, type: Integer, Default: ->{ :nid }

#  field :nid, type: Integer

  validates :ckp_uid, :qzp_uid, length: {maximum: 36}

  before_save :format_weights

  field :ckp_uid, type: String
  field :qzp_uid, type: String
  field :weights, type: Float

  belongs_to :bank_qizpoint_qzp

  private 
  def format_weights
    self.weights = self.weights.nil?? 0.0:("%.2f" % self.weights).to_f
  end
end
