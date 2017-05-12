# -*- coding: UTF-8 -*-

class CheckpointSystem < ActiveRecord::Base
  self.primary_key = 'rid'

  has_many :bank_subject_checkpoint_ckps, foreign_key: 'checkpoint_system_rid', class_name: "BankSubjectCheckpointCkp"

  before_create :set_rid
  #validates :rid, presence: true, uniqueness: true

  scope :xy_default, -> { where(sys_type: "xy_default") }

  class << self

    #描述
    #根据选取的sys_type 返回对应的ckp_system
    #参数 ckp_system_type
    #返回 
    #包含id，name的hash数组
    def get_system_with_type params
      result = []
      checkpoint_systems = where(sys_type: params[:ckp_system_type])

      #return result if checkpoint_systems.blank?
      checkpoint_systems.each {|ckp_sys|
        ckp_sys_hash = {}
        ckp_sys_hash[:rid] = ckp_sys.rid
        ckp_sys_hash[:name] = ckp_sys.name
        result << ckp_sys_hash
      }
      return result
    end
    
  end

  #更新或保存指标体系
  def save_ckp_system params
    paramh = {
      :name => params[:name],
      :rid => params[:rid],
      :is_group => params[:is_group] || nil,
      :sys_type =>  params[:sys_type] || "",
      :version => params[:version] || "",
      :desc => params[:desc] || "",
    }
    update_attributes(paramh)
    #save!      
  end

  def bank_tests
    Mongodb::BankTest.where(checkpoint_system_rid: self.rid)
  end

  private

  def set_rid
      self.rid = BankRid.get_new_bank_rid self.class.all, "", "100" if self.rid.blank?
  end
end
