class Message < ActiveRecord::Base

  after_create :send_sms
  validates :mobile, presence: true, format: { with: /\A1\d{10}\z/ }
  validates :content, presence: true
  
	def self.check(mobile, type, auth_number)
		find_by(mobile: mobile, is_valid: true, kinds: type, auth_number: auth_number)
	end


	private

	#发送验证码
	def send_sms
		# return false unless kinds == 'init_profile'
		content = self.content.encode("GB2312")#"你的验证码为#{(0..9).to_a.sample(6).join}".encode("GB2312")

		res = HTTParty.post('http://36.110.168.35:8080/sms_send2.do', body: {corp_id: 'zy0032', corp_pwd: 'mm0027', corp_service: '1069003256075', mobile: mobile, msg_content: content}).body
    update(status: true) if res.split('#').first == '0'
    $cache_redis.set(self.mobile, self.auth_number, ex: 5.minutes)
	end


end
