class Users::RegistrationsController < Devise::RegistrationsController
# before_action :configure_sign_up_params, only: [:create]
# before_filter :configure_account_update_params, only: [:update]
  layout 'user', only: [:edit, :update] 

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
    # sign_in("user",@user)
    # redirect_to params[:url].presence || root_url
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.for(:sign_up).push(:name, :phone, :role_name, :email)
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.for(:account_update) << :attribute
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  def head_image_upload     
    crop = JSON.parse(params[:avatar_data]) rescue {}
    f_upload = Common::Image.file_upload(current_user, params[:file], crop) 
    if f_upload.errors.blank?
      # current_user.image_upload = f_upload
      render json: response_json(200, {message: 'success'})#:json => {:status=> 200, :message =>"success!"}
    else
      render json: response_json(500, {message: f_upload.errors.full_messages[0]}) #:json => {:status=> 500, :message =>f_upload.errors.full_messages[0]}
    end
  end

  def get_user_password_file
    params.permit!
    if params[:pap_uid]
      current_pap = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
      score_file = ScoreUpload.where(id: current_pap.score_file_id).first
      if score_file
        send_file score_file.usr_pwd_file.current_path,
          filename: score_file.usr_pwd_file.filename,
          type: "application/octet-stream"
      end
    end
  end

end
