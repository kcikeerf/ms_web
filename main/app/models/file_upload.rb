class FileUpload < ActiveRecord::Base
  mount_uploader :paper, PaperUploader
  mount_uploader :answer, AnswerUploader
  mount_uploader :analysis, AnalysisUploader
  mount_uploader :single, SingleUploader

end
