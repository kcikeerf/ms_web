class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  protect_from_forgery with: :null_session

  before_action :set_locale, :authorize_access, :user_init
  before_action :configure_permitted_parameters, if: :devise_controller? || :manager_controller?

  devise_group :person, contains: [:user, :manager]
  #before_action :authenticate_person!
  before_action do |controller|
    controller_name = controller.class.to_s
    cond1 = (controller_name == "Users::SessionsController" && action_name == "new")
    cond2 = (controller_name == "WelcomesController")
    cond3 = (controller_name == "Managers::SessionsController" && action_name == "new")
    if cond1 || cond2 || cond3
      next
    end

    #authenticate_person!
    if (controller_name =~ /^Managers.*$/) == 0
      authenticate_manager!
      #redirect_to new_manager_session_path unless current_manager
    else
      authenticate_user! unless current_manager
      #redirect_to new_user_session_path unless current_user
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
    User.where(wx_openid: params[:wx_openid]).first
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
    render 'errors/403', status: 403,  layout: 'error'
  end
  
  ########
  #override devise after login path
  def after_sign_in_path_for(resource)
     case resource
     when :user, User
       @redirect_target = root_path
       if current_user.role_obj.is_a? Analyzer
         @redirect_target = my_home_analyzers_path
       elsif current_user.role_obj.is_a? Teacher
         @redirect_target = my_home_teachers_path
       elsif current_user.role_obj.is_a? Pupil
         @redirect_target = my_home_pupils_path
       else
       end
     when :manager, Manager
       managers_mains_path
     else
     end
  end

  #override devise after logout path
  def after_sign_out_path_for(resource)
     case resource
     when :user, User
       p "users logout"
       root_path
     when :manager, Manager
       new_manager_session_path
     else
     end
  end

  def authenticate_manager
    authenticate_manager!
    unless current_manager
      redirect_to new_manager_session_path
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
    {:status => status, :json => data.to_json }
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
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone, :role_name, :email, :password, :remember_me])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :password, :remember_me])
    # devise_parameter_sanitizer.for(:sign_up) do |u|
    #   u.permit(:login, :email, :phone, :password, :password_confirmation,:remember_me)      
    # end
        
    # devise_parameter_sanitizer.for(:account_update) do |u|
    #   u.permit(:login, :email, :phone, :password, :password_confirmation, :current_password)
    # end
  end

end
