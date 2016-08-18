module UzerModule
  module Uzer
    module_function

	def get_tenant user_id
		tenant = nil
		current_user = User.find(user_id)
		if current_user.is_pupil?
		  tenant = current_user.role_obj.location.tenant
		else
		  tenant = current_user.role_obj.tenant
		end
		tenant
	end
  end
end