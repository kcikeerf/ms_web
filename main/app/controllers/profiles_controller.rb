class ProfilesController < ApplicationController

	layout 'user', only: [:init, :message]
	before_action :authenticate_user!
	before_action :validate_mobile, :validate_email, only: [:init]

  # 上传头像
	def head_image_upload     
    crop = JSON.parse(params[:avatar_data]) rescue {}
    f_upload = Common::Image.file_upload(current_user, params[:file], crop) 
    if f_upload.errors.blank?
      render json: response_json(200, {message: 'success'})#:json => {:status=> 200, :message =>"success!"}
    else
      render json: response_json(500, {message: f_upload.errors.full_messages[0]}) #:json => {:status=> 500, :message =>f_upload.errors.full_messages[0]}
    end
  end

  # 完善个人资料
  def init
  	#return redirect_to root_path if current_user.init_profile
    @resource ||= current_user.role_obj
   
    if request.post?
      
      @user_params.merge!({init_profile: true})

      redirect_to "/#{@resource.class.to_s.pluralize.downcase}/my_home" if @resource.update(@obj_params) && current_user.update(@user_params)
    end
  end

  # 消息
  def message
    
  end

  # 保存用户的个人信息
  def save_info
    obj_params = resource_params
    user_params = obj_params.delete(:user)
    current_user.update(user_params) unless user_params.blank?
    current_user.role_obj.update(obj_params)
  end

  private

  def resource_params
    user = [:name, :phone, :email, :qq]
    return params.require(:analyzer).permit(:name, :subject, user: user) if current_user.is_analyzer?
    return params.require(:teacher).permit(:name, :subject, :school, user: user) if current_user.is_teacher?
    return params.require(:pupil).permit(:name, :subject, :grade, :classroom, :school, user: user) if current_user.is_pupil?

  end

  # 验证手机
  def validate_mobile
  	if request.post?
  		@obj_params = resource_params
	  	@user_params = @obj_params.delete(:user)

	  	mobile_auth_number = params[:mobile_auth_number]
	    mobile = @user_params[:phone]

	    if mobile_auth_number.present? && mobile.present?
	    	if !Message.check(mobile, 'init_profile', mobile_auth_number)
	    		current_user.errors.add(:base, I18n.t('messages.invalid_mobile'))
	    		@resource = current_user.role_obj
	    		return render action: :init
	    	end
	    	@user_params.merge!({phone_validate: true})
	    end
	  end
  end

  # 验证邮箱
  def validate_email
  	if request.post?
  		email = @user_params[:email]
  		email_auth_number = params[:email_auth_number]

  		if email.present? && email_auth_number.present?
  			if $redis.get(email) != email_auth_number
  				current_user.errors.add(:base, I18n.t('messages.invalid_email'))
	    		@resource = current_user.role_obj
	    		return render action: :init
  			end
  		end
  		$redis.del(email)
  		@user_params.merge!({email_validate: true})
  	end
  end

end
