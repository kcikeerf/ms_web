class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  protect_from_forgery with: :null_session

  before_action :set_locale, :authorize_access, :user_init
  before_action :configure_permitted_parameters, if: :devise_controller?# || :manager_controller?

  devise_group :person, contains: [:user, :manager]
  #before_action :authenticate_person!
  before_action do |controller|
    controller_name = controller.class.to_s
    cond1 = (controller_name == "Users::SessionsController" && action_name == "new")
    cond2 = (controller_name == "WelcomesController")
    if cond1 || cond2
      next
    end

    #authenticate_person!
    if (controller_name =~ /^Wx.*$/) != 0
      authenticate_user!
      if current_user.is_demo && !(%w(/checkpoints/get_tree_data_by_subject /papers /reports_warehouse /users/login /users/logout).any? {|s| request.original_url.include?(s)})
        redirect_to root_path
      end
    end
  end
 
  ######
  # wechat use
  #
  def wx_set_api_header
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = 'GET, POST, PUT, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = 'x-requested-with,Content-Type, Authorization'    
  end

  def wx_authenticate!
    render common_json_response(401, I18n.t("wx_users.messages.warn.invalid_wx_user")) unless wx_current_user
  end

  def wx_current_user
    params.permit!
    result = nil

    target_user = User.where(name: params[:user_name]).first
    target_wx_user = WxUser.where(:wx_openid => params[:wx_openid]).first
    if target_wx_user && target_user
      if target_wx_user.binded_user? target_user.name
        result = target_user
      end
    end
    return result
  end
  #######

#   def authenticate_active_admin_user!
#     authenticate_user!
# #    unless current_user.role?(:admin)
# #      flash[:alert] = "You are not authorized to access this resource!"
# #      redirect_to root_path
# #    end
#   end

  def authorize_access
    # authorize!(action_name.to_sym, "#{controller_name}_controller".camelcase.constantize)
  end

  rescue_from CanCan::AccessDenied do |exception|
    render 'errors/error_403', status: 403,  layout: 'error'
  end
  
  #use in controller
  def current_tenant
    tenant = nil
    if current_user.is_project_administrator?
      tenant = nil
    elsif current_user.is_pupil?
      tenant = current_user.role_obj.location.tenant
    else
      tenant = current_user.role_obj.tenant
    end
    tenant
  end

  def check_resource_tenant obj
    obj_tenant_uid = (obj && obj.tenant)? obj.tenant.uid : nil
    #若资源无所属Tenant，则为真即不抛出错误
    return true unless obj_tenant_uid

    flag = false
    if current_user.is_project_administrator?
      #项目管理员的可访问中的Tenant之一
      flag = current_user.role_obj.tenant_ids.include?(obj_tenant_uid)
    else
      flag = (current_tenant.uid == obj_tenant_uid) if current_tenant
    end

    unless flag
      render 'errors/error_403', status: 403,  layout: 'error'
    end
  end
    
  ########
  #override devise after login path
  def after_sign_in_path_for(resource)
    case resource
    when :user, User
     # if current_user.role_obj.is_a? Analyzer
     #   @redirect_target = my_home_analyzers_path
     # elsif current_user.role_obj.is_a? Teacher
     #   @redirect_target = my_home_teachers_path
     # elsif current_user.role_obj.is_a? Pupil
     #   @redirect_target = my_home_pupils_path
     # else
     #   @redirect_target = root_path
     # end
      if request.referer.include?("/users/login")
        super
      else
        stored_location_for(resource) || request.referer || root_path
      end
    else
    end
  end

  #override devise after logout path
  def after_sign_out_path_for(resource)
     case resource
     when :user, User
       root_path
     else
     end
  end

  #######

  def response_json(status=403, data={})
    {status: status}.merge(data: data).to_json
  end

  def response_json_by_obj(is_success, obj)
    is_success ? response_json(200) : response_json(500, message: obj.errors.full_messages.first)
  end

  def common_json_response(status =403, data={})
    result = data.to_json unless data.is_a? String
    {:status => status, :json => result }
  end

  def reponse_json_only(data={})
    result = data.to_json unless data.is_a? String
    {:json => result}
  end

  def format_report_task_name prefix, job_type
    prefix + "#" + job_type
  end

  #format errors from model
  def format_error ins
    ins.errors.nil?? "" : ins.errors.messages.map{|k,v| "#{k}:#{v.uniq[0]}"}.join("<br>")
  end

  private 

  def user_init
    @login_user = User.new
  end
  # set swtk app locale, so can get the suitable labels 
  #
  def set_locale
    I18n.locale = extract_locale_from_request
  end

  def deal_label(key, arr)
    arr.delete(nil)
    arr.map {|m| [I18n.t("#{key}.#{m}"), m] }
  end

  # get locale according to conditions which are ordered by priority
  #
  def extract_locale_from_request
    # locale defined in parameters
    return params[:locale] if params[:locale]
    # get locale from subdomains
    parsed_locale = request.subdomains.first
    return parsed_locale if I18n.available_locales.map(&:to_s).include?(parsed_locale)
    # get locale from http header
    return request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first if request.env['HTTP_ACCEPT_LANGUAGE']
    # get default locale
    return I18n.default_locale
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone, :role_name, :email, :password, :password_confirmation,:remember_me])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :password, :remember_me])
    # devise_parameter_sanitizer.for(:sign_up) do |u|
    #   u.permit(:login, :email, :phone, :password, :password_confirmation,:remember_me)      
    # end
        
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :phone, :role_name, :email, :password, :password_confirmation,:remember_me])
  end

end
