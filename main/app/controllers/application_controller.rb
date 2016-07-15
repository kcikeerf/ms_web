class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  protect_from_forgery with: :null_session

  before_action :set_locale, :authorize_access, :user_init
  before_action :configure_permitted_parameters, if: :devise_controller?

  ######
  # wechat use
  #
  def wx_authenticate!
    render common_json_response(401, I18n.t("wx_users.messages.warn.invalid_wx_user")) unless wx_current_user
  end

  def wx_current_user
    params.permit!
    User.where(wx_token: params[:wx_token]).first
  end
  #######

  def authenticate_active_admin_user!
    authenticate_user!
#    unless current_user.role?(:admin)
#      flash[:alert] = "You are not authorized to access this resource!"
#      redirect_to root_path
#    end
  end
  def authorize_access
    # authorize!(action_name.to_sym, "#{controller_name}_controller".camelcase.constantize)
  end

  rescue_from CanCan::AccessDenied do |exception|
    render 'errors/403', status: 403,  layout: 'error'
  end

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
    # devise_parameter_sanitizer.for(:sign_up) do |u|
    #   u.permit(:login, :email, :phone, :password, :password_confirmation,:remember_me)      
    # end
        
    # devise_parameter_sanitizer.for(:account_update) do |u|
    #   u.permit(:login, :email, :phone, :password, :password_confirmation, :current_password)
    # end
  end

end
