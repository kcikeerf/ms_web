class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  #protect_from_forgery with: :exception
  skip_before_filter :verify_authenticity_token # for test

  before_action :set_locale

  def authenticate_active_admin_user!
    authenticate_user!
#    unless current_user.role?(:admin)
#      flash[:alert] = "You are not authorized to access this resource!"
#      redirect_to root_path
#    end
  end

  private 
  # set swtk app locale, so can get the suitable labels 
  #
  def set_locale
    I18n.locale = extract_locale_from_request
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

end
