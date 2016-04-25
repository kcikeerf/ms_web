class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  #protect_from_forgery with: :exception
  skip_before_filter :verify_authenticity_token # for test


  def authenticate_active_admin_user!
    authenticate_user!
#    unless current_user.role?(:admin)
#      flash[:alert] = "You are not authorized to access this resource!"
#      redirect_to root_path
#    end
  end

end
