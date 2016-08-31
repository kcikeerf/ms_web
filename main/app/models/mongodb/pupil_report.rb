# -*- coding: UTF-8 -*-

class Mongodb::PupilReport
  include Mongoid::Document
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  scope :by_pup, ->(pup_uid) { where(pup_uid: pup_uid) }

  field :loc_uid, type: String
  #
  field :province, type: String
  field :city, type: String
  field :district, type: String
  field :school, type: String
  field :grade, type: String
  field :classroom, type: String
  #
  field :pap_uid, type: String
  field :pup_uid, type: String
  field :report_name, type: String
  field :report_json, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  class << self
    def get_list params, pup_uid
      result = []

      # 暂不分页
      # if params[:page].blank? || params[:rows].blank?
      #   params[:page] = Common::SwtkConstants::DefaultPage
      #   params[:rows] = Common::SwtkConstants::DefaultRows
      #   reports = self.by_pup(pup_uid).order("dt_update desc").page(params[:page]).per(params[:rows])
      # else
        reports = self.by_pup(pup_uid).order("dt_update desc")
      # end
      
      result = reports.map{|item|
        pap = Mongodb::BankPaperPap.find(item.pap_uid)
        {
          :paper_heading => pap.heading,
          :report_id => item._id.to_s,
          :dt_update => item.dt_update.strftime("%Y-%m-%d %H:%M")
        }
      }
      return result
    end
  end
end
