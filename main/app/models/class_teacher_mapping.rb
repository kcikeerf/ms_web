class ClassTeacherMapping < ActiveRecord::Base
	self.primary_key = 'uid'

	#concerns
  include TimePatch
  include InitUid

  belongs_to :location, foreign_key: "loc_uid"
  belongs_to :teacher, foreign_key: "tea_uid"

  scope :by_head_teacher, ->{ where(head_teacher: true) }
  scope :by_tenant, ->(tenant_uid) { where(tenant_uid: tenant_uid) }

  def self.find_or_save_info(teacher, options)
  	options = options.extract!(:loc_uid, :subject, :head_teacher, :tenant_uid)
  	class_teach_mapping = find_by(tea_uid: teacher.id, loc_uid: options[:loc_uid], subject: options[:subject], tenant_uid: options[:tenant_uid])
  	teacher.class_teacher_mappings.build(options).save unless class_teach_mapping
  end

end
