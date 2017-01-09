class UserMailer < ApplicationMailer

	def send_auth_number(email)
		@email = email
		@auth_number = (0..9).to_a.sample(6).join

		$cache_redis.set(email, @auth_number, ex: 30.minutes)
		
    mail(to: email, subject: '甄学网验证邮件')
	end

	def forgot_password(email)
		@auth_number = (0..9).to_a.sample(6).join

		$cache_redis.set("password_#{email}", @auth_number, ex: 30.minutes)
		
    mail(to: email, subject: '甄学网忘记密码邮件')
	end
end
