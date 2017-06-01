module UzerModule
  module Uzer
    module_function

    PasswdRandLength = 6
    PasswdRandArr = Common::SwtkConstants::NumberArr
    UserNameSperator = ""
    UserNameRandArr = Common::SwtkConstants::AlphabetDownCaseArr
    GuestUserNamePrefix = "guest_"
    WxUserNamePrefix = "wx_"

    UserAccountTitle = {
      :head_teacher => [
          Common::Locale::i18n('activerecord.attributes.user.name'),
          Common::Locale::i18n('activerecord.attributes.user.password'),
          Common::Locale::i18n('dict.classroom'),
          Common::Locale::i18n('dict.name'),
          Common::Locale::i18n('reports.generic_url'),
          Common::Locale::i18n('reports.op_guide')
      ],
      :teacher => [
          Common::Locale::i18n('activerecord.attributes.user.name'),
          Common::Locale::i18n('activerecord.attributes.user.password'),
          Common::Locale::i18n('dict.classroom'),
          Common::Locale::i18n('dict.subject'),
          Common::Locale::i18n('dict.name'),
          Common::Locale::i18n('reports.generic_url'),
          Common::Locale::i18n('reports.op_guide')
      ],
      :pupil => [
          Common::Locale::i18n('activerecord.attributes.user.name'),
          Common::Locale::i18n('activerecord.attributes.user.password'),
          Common::Locale::i18n('dict.classroom'),
          Common::Locale::i18n('dict.name'),
          Common::Locale::i18n('dict.pupil_number'),
          Common::Locale::i18n('reports.generic_url'),
          Common::Locale::i18n('reports.op_guide')
      ],
      :new_user => [
        "UserID",
        "BankTest",
        "UserName",
        "Password"
      ]
    }


    def get_tenant user_id 
      tenant = nil
      current_user = get_user user_id
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

        # 生成URL
    def generate_url
      return Common::SwtkConstants::MyDomain 
    end


    def format_user_name args=[]
      "u" + args.join(Common::Uzer::UserNameSperator)
    end

    # 组装用户名密码行数据
    def format_user_password_row role, item
      row_data = {
        Common::Role::Teacher.to_sym => {
          :username => item[:user_name],
          :password => "",
          :classroom => Common::Klass::List[item[:classroom].to_sym],
          # :subject => Common::Subject::List[item[:subject].to_sym],
          :name => item[:name],
          :report_url => "",
          :op_guide => Common::Locale::i18n('reports.op_guide_details'),
          :tenant_uid => item[:tenant_uid]
        },
        Common::Role::Pupil.to_sym => {
          :username => item[:user_name],
          :password => "",
          :classroom => Common::Klass::List[item[:classroom].to_sym],
          :name => item[:name],
          :stu_number => item[:stu_number],
          :report_url => "",#Common::SwtkConstants::MyDomain + "/reports/new_square?username=",
          :op_guide => Common::Locale::i18n('reports.op_guide_details'),
          :tenant_uid => item[:tenant_uid]
        }
      }
      row_data[Common::Role::Teacher.to_sym][:subject] = Common::Subject::List[item[:subject].to_sym] if item[:subject]
      ret,flag = User.add_user item[:user_name],role, item
      target_username = ""
      if (ret.is_a? Array) && ret.empty?
        row_data[role.to_sym][:password] = Common::Locale::i18n("scores.messages.info.old_user")
        row_data[role.to_sym][:report_url] = self.generate_url
        target_username = ret[0]
        row_data[role.to_sym][:is_old_user] = flag
      elsif (ret.is_a? Array) && !ret.empty?
        row_data[role.to_sym][:password] = ret[1]
        row_data[role.to_sym][:report_url] = self.generate_url
        target_username = ret[0]
        row_data[role.to_sym][:is_old_user] = flag
      else
        row_data[role.to_sym][:password] = Common::Locale::i18n("scores.messages.error.add_user_failed")
      end
      #associate_user_and_pap role, target_username if (ret.is_a? Array)
      return row_data[role.to_sym].values
    end

    def link_user_and_bank_test(username,bank_test_id)
      user = User.where(name: username).first
      bank_test = Mongodb::BankTest.where(_id: bank_test_id).first
      if user.present? && bank_test.present?
        link_params = {
          :bank_test_id => bank_test.id.to_s,
          :user_id => user.id
        }
        target_link = Mongodb::BankTestUserLink.where(link_params)
        if target_link.blank?
          target_link = Mongodb::BankTestUserLink.new(link_params)
          target_link.save!
        end
      end
    end



  end
end