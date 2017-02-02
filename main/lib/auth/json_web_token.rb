class JsonWebToken
  def self.encode(value)
  	payload = value || {}
    JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
  end

  def self.decode(value)
  	token = value || {}
  	return JWT.decode(token, Rails.application.secrets.secret_key_base, true, { :algorithm => 'HS256' })[0] || {}
  rescue
    nil
  end
end