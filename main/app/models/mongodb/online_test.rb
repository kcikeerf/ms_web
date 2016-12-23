# -*- coding: UTF-8 -*-

class Mongodb::OnlineTest
  include Mongoid::Document
  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  belongs_to :bank_paper_pap, class_name: "Mongodb::BankPaperPap"

  field :pap_uid, type: String #为了兼容旧版处理，确定旧版处理不需要，删除
  field :name, type: String
  field :quiz_date, type: DateTime
  field :user_id, type: String
  # field :wx_user_id, type: String
  field :report_version, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({_id: 1}, {background: true})

  def wx_users
    links = Mongodb::OnlineTestUserLink.by_online_test(self.id)
    wx_user_ids = links.map(&:wx_user_id)
    WxUser.where(uid: wx_user_ids)
  end
end
