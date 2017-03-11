# -*- coding: UTF-8 -*-

class Mongodb::MobileUserQizpointScore
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

  #field :loc_uid, type: String
  #
  field :province, type: String
  field :city, type: String
  field :district, type: String
  field :school, type: String
  field :grade, type: String
  field :classroom, type: String
  #
  field :pup_uid, type: String
  field :wx_openid, type: String #wechat openid
  field :pap_uid, type: String #paper id
  field :qzp_uid, type: String #qizpoint id
  field :order, type: String #qizpoint order
  field :real_score, type: Float #real score
  field :full_score, type: Float

  def self.save_score params
    target_pap = Mongodb::BankPaperPap.find(params[:pap_uid])
    xue_duan = Common::Grade.judge_xue_duan(target_pap.grade)
  	#qzp_arr = params[:bank_quiz_qizs].map{|qiz| qiz[:bank_qizpoint_qzps]}.flatten
    qzp_arr = params[:bank_quiz_qizs].values.map{|qiz| qiz[:bank_qizpoint_qzps].values}.flatten    
    qzp_arr.each{|qzp|
      qizpoint = Mongodb::BankQizpointQzp.where(_id: qzp[:id]).first
      if qizpoint && !qzp[:result].blank? && !qizpoint.answer.blank?
        test_result = ""
        test_result = qzp[:result].downcase if qzp[:result]
        test_result.strip! if test_result

        qizpoint_answer = qizpoint.answer.nil?? "" : qizpoint.answer.gsub(/<\/?[^>]*>/, "")
        qizpoint_answer.gsub!(/[\\\n]/, "") if qizpoint_answer
        qizpoint_answer.downcase! if qizpoint_answer
        qizpoint_answer.strip! if qizpoint_answer

        if test_result.blank? || qizpoint_answer.blank?
          test_score = 0
        else
          test_score = (test_result == qizpoint_answer) ? qizpoint.score : 0
        end
      else
        test_score = 0
      end
      param_h = {
        :pup_uid => params[:pup_uid] || "",
        :wx_openid => params[:wx_openid] || "",
        :pap_uid => params[:pap_uid] || "",
        :qzp_uid => qizpoint._id.to_s,
        :order => qizpoint.order,
        :real_score => test_score,
        :full_score => qizpoint.score
      }
      node_uid = params[:information][:node_uid] || ""
      ckps = qizpoint.bank_checkpoint_ckps
      ckps.each{|ckp|
        next unless ckp
        if ckp.is_a? BankCheckpointCkp
          lv1_ckp = BankCheckpointCkp.where("node_uid = '#{node_uid}' and rid = '#{ckp.rid.slice(0,3)}'").first
          lv2_ckp = BankCheckpointCkp.where("node_uid = '#{node_uid}' and rid = '#{ckp.rid.slice(0,6)}'").first
        elsif ckp.is_a? BankSubjectCheckpointCkp
          lv1_ckp = BankSubjectCheckpointCkp.where("subject = '#{target_pap.subject}' and category = '#{xue_duan}' and rid = '#{ckp.rid.slice(0,3)}'").first
          lv2_ckp = BankSubjectCheckpointCkp.where("subject = '#{target_pap.subject}' and category = '#{xue_duan}' and rid = '#{ckp.rid.slice(0,6)}'").first
        end
        param_h[:dimesion] = ckp.dimesion
        param_h[:lv1_ckp] = lv1_ckp.checkpoint
        param_h[:lv2_ckp] = lv2_ckp.checkpoint
        param_h[:lv3_ckp] = ckp.checkpoint
        param_h[:weights] = 1#ckp.weights.to_f
        qizpoint_score = self.new(param_h)
        qizpoint_score.save!
      }
  	}
  end

  private
  def format_float
    # self.real_score = self.real_score.nil?? 0.0:("%.2f" % self.real_score).to_f
  end
end
