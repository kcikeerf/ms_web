# -*- coding: UTF-8 -*-

class CheckpointSystem < ActiveRecord::Base

  has_many :bank_subject_checkpoint_ckps, foreign_key: 'checkpoint_system_id', dependent: :destroy

  def bank_tests
  	Mongodb::BankTest.where(checkpoint_system_id: self.id)
  end
end
