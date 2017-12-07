class PaperTagLink < ActiveRecord::Base

  def paper
    Mongodb::BankPaperPap.where(_id: self.paper_id).first
  end

  def tag
    Mongodb::BankTag.where(_id: tag_id).first
  end

end
