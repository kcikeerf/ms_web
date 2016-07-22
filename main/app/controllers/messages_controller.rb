class MessagesController < ApplicationController

	#发送手机绑定验证码
	def send_sms_auth_number
		mobile = params[:mobile]
		auth_number = (0..9).to_a.sample(6).join
		content = "#{I18n.t('messages.bind_auth_number')}#{auth_number}"

		
		return send_sms(mobile, content, 'init_profile', auth_number)
	end

	#发送忘记密码短信
	def send_sms_forgot_password
		mobile, type = params[:mobile]
		auth_number = (0..9).to_a.sample(6).join
		content = "#{I18n.t('messages.password_auth_number')}#{auth_number}"

		return send_sms(mobile, content, 'forgot_password', auth_number)
	end

	#发送邮箱绑定邮件
	def send_email_auth_number
		email = params[:email]
		send_email(email) do 
			UserMailer.send_auth_number(email).deliver
		end
	end

	#发送忘记密码邮件
	def send_email_forgot_password
		email = params[:email]
		send_email(email) do 
			UserMailer.forgot_password(email).deliver_later
		end
	end

	
	def send_email(email)
		email_count_key = "#{email}_count"
		return render json: response_json(500, I18n.t('messages.email_not_send')) if ($redis.get(email_count_key).try(:to_i) || 0) >= 50

		yield
		$redis.incr(email_count_key)
		$redis.expire(email_count_key, 1.hours)
       
		render json: response_json(200, I18n.t('messages.email_send_success'))
	end

	def send_sms(mobile, content, type, auth_number)
		key = "#{type}_#{mobile}"
		return render json: response_json(500, I18n.t('messages.send_limit')) if ($redis.get(key).try(:to_i) || 0) >= 10

		message = Message.create(mobile: mobile, content: content, auth_number: auth_number, kinds: type)
		return render json: response_json(500, message.errors.full_messages[0])  if message.errors.size > 0

		$redis.incr(key)
		$redis.expire(key, 1.hours)
		render json: response_json(200, I18n.t('messages.sms_send_success'))
	end


end