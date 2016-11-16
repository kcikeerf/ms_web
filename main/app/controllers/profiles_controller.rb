class ProfilesController < ApplicationController

	layout 'user', only: [:init, :message, :account_binding, :binding_or_unbinding_mobile, :binding_or_unbinding_email, :binding_or_unbinding_mobile_succeed,:binding_or_unbinding_email_succeed, :verified_mobile,:modify_mobile, :modify_mobile_succeed,:modify_email,:verified_email,:modify_email_succeed]
	before_action :authenticate_user!
	before_action :validate_mobile, :validate_email, only: [:init]
  before_action :validate_mobile_in_binding, only: [:binding_or_unbinding_mobile,:verified_mobile,:modify_mobile]
  before_action :validate_email_in_binding, only: [:binding_or_unbinding_email,:verified_email,:modify_email] 

  # 上传头像
  def head_image_upload     
    crop = JSON.parse(params[:avatar_data]) rescue {}
    f_upload = Common::Image.file_upload(current_user, params[:file], crop) 
    if f_upload.errors.blank?
      render common_json_response(200, {message: I18n.t("images.messages.info.success")})
    else
      render common_json_response(500, {message: I18n.t("images.messages.error.failed", cause: f_upload.errors.full_messages[0])})
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
  
  #账号绑定
  def account_binding; end

  #手机绑定/解绑
  def binding_or_unbinding_mobile
    if request.post?

      current_user.phone_validate? ? current_user.update(phone_validate: false) : current_user.update(phone: params[:user][:phone], phone_validate: true)

      redirect_to binding_or_unbinding_mobile_succeed_profile_path
    end
  end

  #绑定/解绑手机成功
  def binding_or_unbinding_mobile_succeed; end

  #手机验证
  def verified_mobile
    redirect_to modify_mobile_profile_path if request.post?
  end

  #修改手机号
  def modify_mobile
    if request.post?
      redirect_to modify_mobile_succeed_profile_path if current_user.update(phone: params[:user][:phone], phone_validate: true)
    end
  end

  #手机号修改成功
  def modify_mobile_succeed; end


  #邮箱绑定/解绑
  def binding_or_unbinding_email
    if request.post?

      current_user.email_validate? ? current_user.update(email_validate: false) : current_user.update(email: params[:user][:email], email_validate: true)

      redirect_to binding_or_unbinding_email_succeed_profile_path
    end
  end

  #绑定/解绑邮箱成功
  def binding_or_unbinding_email_succeed; end
  
  #邮箱验证
  def verified_email
    redirect_to modify_email_profile_path if request.post?
  end

  #修改邮箱
  def modify_email
    if request.post?
      redirect_to modify_email_succeed_profile_path if current_user.update(email: params[:user][:email], email_validate: true)
    end
  end

  #邮箱修改成功
  def modify_email_succeed; end

  private

  #各角色参数限制
  def resource_params
    user = [:name, :phone, :email, :qq]
    return params.require(:project_administrator).permit(:name, user: user) if current_user.is_project_administrator?
    return params.require(:tenant_administrator).permit(:name, user: user) if current_user.is_tenant_administrator?
    return params.require(:analyzer).permit(:name, :subject, user: user) if current_user.is_analyzer?
    return params.require(:teacher).permit(:name, :subject, :school, user: user) if current_user.is_teacher?
    return params.require(:pupil).permit(:name, :subject, :grade, :classroom, :school, user: user) if current_user.is_pupil?

  end
  

  #绑定／解绑手机验证码验证
  def validate_mobile_in_binding
    if request.post?
      mobile_auth_number = params[:mobile_auth_number]
      mobile = params[:user][:phone]
      if !Message.check(mobile, 'init_profile', mobile_auth_number)
        current_user.errors.add(:base, I18n.t('messages.invalid_mobile'))
        #return render action: :binding_or_unbinding_mobile
        return render :action => "#{action_name}"
      end
    end
  end
  
  #绑定／解绑邮箱验证码验证
  def validate_email_in_binding
    if request.post?
      email = params[:user][:email]
      email_auth_number = params[:email_auth_number]
      if $cache_redis.get(email) != email_auth_number
        current_user.errors.add(:base, I18n.t('messages.invalid_email'))
        return render :action => "#{action_name}"
      end
      $cache_redis.del(email)
    end
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
  			if $cache_redis.get(email) != email_auth_number
  				current_user.errors.add(:base, I18n.t('messages.invalid_email'))
         @resource = current_user.role_obj
         return render action: :init
       end
     end
     $cache_redis.del(email)
     @user_params.merge!({email_validate: true})
   end
 end

end
