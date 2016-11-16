module UzerModule
  module Uzer
    module_function

    PasswdRandLength = 8
    PasswdRandArr = [*'1'..'9']
    UserNameSperator = ""

    def get_tenant user_id 
      tenant = nil
      current_user = get_user
      if current_user.is_project_administrator?
        tenant = nil
      elsif current_user.is_pupil?
        tenant = current_user.role_obj.location.tenant
      else
        tenant = current_user.role_obj.tenant
      end
      tenant
    end

    def get_user user_id
      User.where(id: user_id).first
    end

  end
end