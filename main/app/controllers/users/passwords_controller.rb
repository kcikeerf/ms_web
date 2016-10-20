class Users::PasswordsController < Devise::PasswordsController
  layout 'user'
  before_action :validate_auth_number, only: [:create]

  # GET /resource/password/new
  # def new
  #   super
  # end

  #判断验证码、email/mobile是否存在
  def user_captcha_validate
    @login = resource_params[:login]
    self.resource = resource_class.new(login: @login)
    if verify_rucaptcha?
      @is_mobile = resource_class.judge_type(@login) == 'mobile'
      self.resource = resource_class.forgot_password_validate_user(@login)
      return render action: :new unless self.resource.errors.empty?
    else      
      self.resource.errors.add(:base, '您输入的验证码有误，请重新输入') 
      render action: :new
    end

  end

  # POST /resource/password
  def create
    return render json: response_json(500, self.resource.errors.full_messages.first) unless self.resource.errors.empty?
    token = resource.save_token
    render json: response_json(200, token)
    # self.resource = resource_class.send_reset_password_instructions(resource_params)
    # yield resource if block_given?

    # if verify_rucaptcha?(resource) && successfully_sent?(resource)
    #   respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    # else
    #   respond_with(resource)
    # end
    # p verify_rucaptcha?
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  def validate_auth_number
    auth_number = params[:auth_number]
    # @type = params[:type]
    login = resource_params[:login]
    self.resource = resource_class.forgot_password_validate_user(login)
    type = resource_class.judge_type(login)
    if type == 'mobile'
      #sms
      unless Message.check(login, 'forgot_password', auth_number)
        return render json: response_json(500, I18n.t('messages.invalid_mobile'))
      end
    else
      #email
      if $cache_redis.get("password_#{login}") != auth_number
        return render json: response_json(500, I18n.t('messages.invalid_email'))
      end
    end
  end
end
