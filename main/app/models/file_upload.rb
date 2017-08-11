class FileUpload < ActiveRecord::Base
  mount_uploader :paper, PaperUploader
  mount_uploader :answer, AnswerUploader
  mount_uploader :analysis, AnalysisUploader
  mount_uploader :single, SingleUploader
  mount_uploader :empty_result, EmptyResultUploader
  mount_uploader :revise_paper, RevisePaperUploader
  mount_uploader :revise_answer, ReviseAnswerUploader
  mount_uploader :paper_structure, PaperStructureUploader
  mount_uploader :combine_checkpoint, CombineCheckpointUploader
  mount_uploader :xlsx_structure, XlsxStructureUploader
  mount_uploader :json_structure, JsonStructureUploader
  mount_uploader :user_base, UserBaseUploader
  mount_uploader :ckps_associated, CkpsAssociatedUploader

end
