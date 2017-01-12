class ImageUpload < ActiveRecord::Base
  mount_uploader :file, ImageUploader

  attr_accessor :crop_x, :crop_y, :crop_h, :crop_w, :crop_r


  belongs_to :user

  validate :check_image_size
  private
  def check_image_size
    self.errors[:base] << Common::Locale::i18n(images.errors.invalid_size) if self.file.size > 0.3.megabytes
  end
end
