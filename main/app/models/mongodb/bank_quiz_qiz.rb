# -*- coding: UTF-8 -*-

class Mongodb::BankQuizQiz
  include Mongoid::Document
  include Mongodb::MongodbPatch
  include SwtkLockPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp
=begin
  validates :pap_uid, :tbs_uid, :tpl_id, length:{maximum: 36}
  validates :cat, :type, :levelword2, :levelword, length:{maximum: 50}
  validates :text, length: {maximum: 1000}
  validates :answer, :desc, length: {maximum: 500}

  before_save :format_float
=end

  belongs_to :paper_outline, class_name: "Mongodb::PaperOutline"
  # has_many :bank_quizlogs,  class_name: "Mongodb::BankQuizlog"
  # has_many :bank_qiz_qtgs,  class_name: "Mongodb::BankQizQtg"
  has_many :bank_qizpoint_qzps, class_name: "Mongodb::BankQizpointQzp", dependent: :delete
  has_and_belongs_to_many :bank_paper_paps, class_name: "Mongodb::BankPaperPap"
  has_many :bank_quiz_tag_links, class_name: "Mongodb::BankQuizTagLink", foreign_key: "quiz_uid", dependent: :delete
  has_many :bank_quiz_options, class_name: "Mongodb::BankQuizOption", dependent: :delete

  #field :uid, type: String
  field :subject, type: String
  field :node_uid, type: String
  field :pap_uid, type: String
  field :tbs_uid, type: String
  field :tpl_id, type: String
  field :ext1, type: Integer
  field :ext2, type: Integer
  field :grade, type: String
  field :cat, type: String
  field :type, type: String
  field :optional, type: Boolean
  field :text, type: String
  field :text_is_image, type: Boolean
  field :answer, type: String
  field :answer_is_image, type: Boolean
  field :desc, type: String
  field :score, type: Float
  field :time, type: Float
  field :levelword2, type: String
  field :level, type: Float
  field :levelword, type: String
  field :levelorder, type: Integer
  field :order, type: String #系统顺序
  field :asc_order, type: Integer #递增顺序
  field :custom_order, type: String #自定义顺序
  field :quiz_body, type: String
  field :is_II_quiz, type: Boolean, default: false

  #是否为空
  field :is_empty, type: Boolean, default: false

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime



  def save_quiz params, paper_status=nil
    #params = JSON.parse(params["_json"]) if params["_json"]
    qzp_arr, op_detail = [], []
   
#    begin
      original_qzp_ids = self.bank_qizpoint_qzps.map{|qzp| qzp._id.to_s}
      delete_all_related_qizpoints original_qzp_ids
#      self.bank_qizpoint_qzps=[]
      self.update_attributes({
        :subject => params["subject"] || "",
        :node_uid => params["node_uid"] || "",
        :pap_uid => params["pap_uid"] || "",
        :tbs_uid => params["tbs_uid"] || "",
        :tpl_id => params["tpl_id"] || "",
        :ext1 => params["ext1"] || 0,
        :ext2 => params["ext2"] || 0,
        :grade => params["grade"] || "",
        :cat => params["cat"] || "",
        :type => params["type"] || "",
        :optional => params["optional"] || "",
        :text => params["text"] || "",
        :text_is_image => params["text_is_image"] || "",
        :quiz_body => params["question_body"] || "",
        :is_II_quiz => params["is_II_quiz"] || false,
        :answer => params["answer"] || "",
        :answer_is_image => params["answer_is_image"] || "",
        :desc => params["desc"] || "",
        :score => params["score"] || 0.00,
        :time => params["time"] || 0.00,
        :levelword2 => params["levelword2"] || "",
        :level => params["level"] || 0.00,
        :levelword => params["levelword"] || "",
        :levelorder => params["levelorder"] || "",
#        :order => (params["order"].to_s || '0').ljust(Common::Paper::Constants::OrderWidth, '0')
        :order => params["order"] || "0",
        :asc_order => params["asc_order"] || 0,
        :custom_order => params["custom_order"] || "",
        :paper_outline_id => params["paper_outline_id"] || nil
      })
      self.save!

      if params["quiz_tags"]
        save_quiz_tags params["quiz_tags"]
      end
=begin
      params["bank_qizpoint_qzps"].each_with_index{|bqq, index|
        qiz_point = Mongodb::BankQizpointQzp.new
        qiz_point.save_qizpoint bqq
        self.bank_qizpoint_qzps.push(qiz_point)
        if bqq["bank_checkpoint_ckps"]
          bqq["bank_checkpoint_ckps"].each{|bcc|
            ckp = Mongodb::BankCkpQzp.new
      ckp.save_ckp_qzp qiz_point._id, bcc["uid"]
            #self.bank_qizpoint_qzps[index].bank_ckp_qzp = ckp
    }
        end

      } unless params["bank_qizpoint_qzps"].blank?
=end
      if params["bank_qizpoint_qzps"]
        qzp_arr = save_all_qzps self,params, paper_status
      end

      if params["option_details"]
        op_detail = save_quiz_option params
      end

      return qzp_arr, op_detail
#    rescue Exception => ex
#      return false
#    end
  end

  def save_all_qzps quiz, params, status
    result = []
    params["bank_qizpoint_qzps"].each_with_index{|bqq, index|
      # 算出得分点的递增题顺
      qzp_index = params["qizpoint_order_arr"].find_index(bqq["order"])
      bqq[:asc_order] = qzp_index.blank?? 0 : qzp_index + 1

      qiz_point = Mongodb::BankQizpointQzp.new
      qiz_point.save_qizpoint bqq
      result << qiz_point._id.to_s
      quiz.bank_qizpoint_qzps.push(qiz_point)
      unless bqq["bank_checkpoints_ckps"].blank?
        if status == Common::Paper::Status::Analyzing
          save_qzp_all_ckps qiz_point,bqq#["bank_checkpoints_ckps"]
        end
      end
    }
    return result
  end

  def save_quiz_option params
    result = []
    self.bank_quiz_options.delete_all
    params["option_details"].each_with_index {|option,index|
      qop = Mongodb::BankQuizOption.new
      qop.save_quiz_option option
      result <<  qop._id.to_s
      self.bank_quiz_options.push(qop)
    }
    return result
  end

  def save_qzp_all_ckps qiz_point, params
    params["bank_checkpoints_ckps"].each{|bcc|
      ckp = Mongodb::BankCkpQzp.new
      ckp.save_ckp_qzp qiz_point._id.to_s, bcc["uid"], bcc["ckp_source"]
    }
  end

  def save_quiz_tags tags_str
    bank_quiz_tag_links.destroy_all
    tag_arr = tags_str.split("|")
    tag_arr.each { |str|
      tag = Mongodb::BankTag.where(content: str).first
      unless tag
        tag = Mongodb::BankTag.new(content: str)
        tag.save
      end
      Mongodb::BankQuizTagLink.new.save_ins self._id.to_s, nil, tag._id.to_s
    }
  end

  def destroy_quiz
    begin
      delete_all_related_qizpoints self.bank_qizpoint_qzps.map{|qzp| qzp._id.to_s}
#      self.bank_qizpoint_qzps = []
      self.destroy
    rescue Exception => ex
      logger.debug(ex.message)
      logger.debug(ex.backtrace)
      return false
    end
    return true
  end


  def quiz_base_info
    result = {}
    result[:uid] = self._id.to_s
    result[:text] = self.text
    result[:answer] = self.answer
    result[:cat_cn] = Common::Locale::i18n("dict.#{self.cat}")
    result[:levelword] = Common::Locale::i18n("dict.#{self.levelword2}")
    result[:order] = self.order
    result[:custom_order] = self.custom_order.present? ? self.custom_order : nil
    result[:asc_order] = self.asc_order.present? ? self.asc_order : nil
    result[:score] = self.score
    return result
  end

  #
  # get quiz all details 
  #
  def quiz_detail
    result ={}
    qzps = self.bank_qizpoint_qzps
    node = BankNodestructure.where(:uid => self.node_uid).first
    result[:subject] = node.subject
    result[:grade]= node.grade
    result[:version] = node.version + "("+ node.volume + ")"
    result[:text] = self.text
    result[:node_uid] = node.uid
    result[:answer] = self.answer
    result[:desc] =self.desc
    result[:levelword2]=self.levelword2
    result[:bank_qizpoint_qzps] = qzps.map{|qzp|
      { 
        "type" => qzp.type,
        "type_label" => Common::Locale::i18n("dict.#{qzp.type}"),
        "answer" => qzp.answer,
        "desc" => qzp.desc,
        "score" => qzp.score,
        "bank_checkpoint_ckps" => qzp.bank_checkpoint_ckps.map{|bcc|
           {
             "dimesion" => bcc.dimesion,
             "rid" => bcc.rid,
             "uid" => bcc.uid,
             "checkpoint" => bcc.checkpoint,
             "desc" => bcc.desc
           }
        }
      }
    } 
    result
  end

  def bank_tag_ids
    bank_quiz_tag_links.map(&:tag_uid)
  end

  def bank_tags
    Mongodb::BankTag.where({id: {"$in" => bank_tag_ids }})
  end

  def detail_info
    result ={}
    qzps = self.bank_qizpoint_qzps
    result[:quiz_uid] = self._id.to_s
    result[:subject] = self.subject
    # result[:grade]= self.grade
    result[:text] = self.text
    result[:answer] = self.answer
    result[:desc] = self.desc
    result[:levelword2] = self.levelword2
    result[:quiz_body] = self.quiz_body
    result[:is_II_quiz] = self.is_II_quiz
    result[:quiz_options] = bank_quiz_options.map {|op|
      {
        uid: op._id.to_s,
        content: op.content,
        is_answer: op.is_answer
      }
    }
    result[:bank_qizpoint_qzps] = qzps.map{|qzp|
      { 
        "type" => qzp.type,
        "type_label" => Common::Locale::i18n("dict.#{qzp.type}"),
        "answer" => qzp.answer,
        "desc" => qzp.desc,
        "score" => qzp.score,
        "bank_checkpoint_ckps" => qzp.bank_checkpoint_ckps.map{|bcc|
           {
             "dimesion" => bcc.dimesion,
             "rid" => bcc.rid,
             "uid" => bcc.uid,
             "checkpoint" => bcc.checkpoint,
             "desc" => bcc.desc
           }
        }
      }
    } 
    result
  end

  # def exercise
  #   content = {
  #     uid: self._id.to_s,
  #     text: self.text,
  #     order:  self.order,
  #     custom_order: self.custom_order,
  #     ckps: {
  #       knowledge: [],
  #       skill: [],
  #       ability: []
  #     }
  #   }
  #   answer = {
  #     uid: self._id.to_s,
  #     answer: [],
  #     order:  self.order,
  #     custom_order: self.custom_order
  #   }
  #   qzps = self.bank_qizpoint_qzps
  #   qzps.each { |qzp|
  #     answer[:answer] << qzp.answer 
  #     result_ckp = qzp.level1_levle2_info.deep_symbolize_keys
  #     content[:ckps][:knowledge] += result_ckp[:knowledge] if result_ckp[:knowledge]
  #     content[:ckps][:skill] += result_ckp[:skill] if result_ckp[:skill]
  #     content[:ckps][:ability] += result_ckp[:ability] if result_ckp[:ability]
  #   }
  #   return content, answer
  # end

  def exercise
    result ={}
    qzps = self.bank_qizpoint_qzps
    result[:quiz_uid] = self._id.to_s
    result[:subject] = self.subject
    # result[:grade]= self.grade
    result[:text] = self.text
    result[:answer] = self.answer
    result[:quiz_cat] = self.cat.present? ? self.cat : "other"
    result[:quiz_cat_cn] = self.cat.present? ? Common::Locale::i18n("dict.#{self.cat}") : Common::Locale::i18n("dict.other")
    result[:desc] = self.desc
    result[:levelword2] = self.levelword2
    result[:bank_qizpoint_qzps] = qzps.map{|qzp|
      { 
        "type" => qzp.type,
        "type_label" => Common::Locale::i18n("dict.#{qzp.type}"),
        "answer" => qzp.answer,
        "desc" => qzp.desc,
        "score" => qzp.score,
        "bank_checkpoint_ckps" => qzp.level1_levle2_info_plus
      } if qzp.present?
    } 
    return result.deep_stringify_keys
  end


  private 

  def delete_all_related_qizpoints ids
    ids.each{|id|
      qzp = Mongodb::BankQizpointQzp.where(:_id => id)
      ckp_qzps = Mongodb::BankCkpQzp.where(:qzp_uid => id)
      ckp_qzps.each{|ckp_qzp|
        ckp_qzp.destroy_ckp_qzp
      }
      qzp.destroy
    }
  end

  def format_float
    # self.score = self.score.nil?? 0.0:("%.2f" % self.score).to_f
    self.time = self.time.nil?? 0.0:("%.2f" % self.time).to_f
    self.level = self.level.nil?? 0.0:("%.2f" % self.level).to_f
  end
  
end
