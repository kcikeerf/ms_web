class Mongodb::PupilPaperQuestionLink
  include Mongoid::Document

  field :pup_uid, type: String
  field :pap_id, type: String

  index({pup_uid: 1}, {background: true})
  index({pap_id: 1}, {background: true})
end
