class Mongodb::BankQizpointScore
  include Mongoid::Document
  include Mongoid::Timestamps

  # for levels checkpoints
  # dimesion
  # level1 checkpoint: lv1_ckp
  # level2 checkpoint: lv2_ckp
  # level3 checkpoint: lv3_ckp
  # weights
  # 
  include Mongoid::Attributes::Dynamic
  #

#  validates :pap_uid, :qiz_uid, length:{maximum: 36}

  before_save :format_float

  field :loc_uid, type: String
  #
  field :province, type: String
  field :city, type: String
  field :district, type: String
  field :school, type: String
  field :grade, type: String
  field :classroom, type: String
  #   
  field :pup_uid, type: String #pupil id
  field :pap_uid, type: String #paper id
  field :qzp_uid, type: String #qizpoint id
  field :tenant_uid, type: String #tenant id
  field :order, type: String #qizpoint order
  field :real_score, type: Float #real score
  field :full_score, type: Float

  belongs_to :bank_quiz_score, class_name: "Mongodb::BankQuizScore"

  private
  def format_float
    self.real_score = self.real_score.nil?? 0.0:("%.2f" % self.real_score).to_f
  end
end
