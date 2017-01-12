class FileUpload < ActiveRecord::Base
  mount_uploader :paper, PaperUploader
  mount_uploader :answer, AnswerUploader
  mount_uploader :analysis, AnalysisUploader
  mount_uploader :single, SingleUploader
  mount_uploader :empty_result, EmptyResultUploader
  mount_uploader :revise_paper, RevisePaperUploader
  mount_uploader :revise_answer, ReviseAnswerUploader

end
