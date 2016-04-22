class FileUpload < ActiveRecord::Base
  mount_uploader :file, FileUploader

end
