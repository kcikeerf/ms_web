# -*- coding: UTF-8 -*-

module ReportsWarehouse
  class API < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/wx".to_sym

    helpers ApiHelper
    helpers SharedParamsHelper

    resource :reports_warehouse do
      before do
        set_api_header
        authenticate!
      end

      #
      desc ''
      params do
        use :authenticate
      end
      post '*any_path' do
        target_file_path = request.fullpath.to_s.split("/api/wx/v1.1")[1]
        target_user = current_user
        if !params[:any_path].blank? && File.exist?(target_file_path)
          path_arr = params[:any_path].split("/")
          current_group = nil

          # 在线测试
          if path_arr.include?("online_tests")
            if path_arr.include?(Common::OnrineTest::Group::Individual)
              current_group = Common::OnrineTest::Group::Individual
              group_ids = [current_wx_user.id]
            elsif path_arr.include?(Common::OnrineTest::Group::Total)
              current_group = Common::OnrineTest::Group::Total
              group_ids = current_wx_user.online_tests.map{|item| item.id.to_s}
            end
          # 一般测试
          else
            path_h = {}
            generic_re = /[0-9a-zA-Z]{1,}\.json$/
            nav_re = /(nav\.json)$/
            ckps_qzps_mapping_re = /(ckps_qzps_mapping\.json)$/
            qzps_ckps_mapping_re = /(qzps_ckps_mapping\.json)$/
            paper_info_re = /(paper_info\.json)$/

            Common::Report::Group::ListArr.map{|item| path_h[item] = {:value => nil, :allowed_file_regx => [generic_re]} }
            # 学生
            if target_user.is_pupil?
              # current_group = Common::Report::Group::Pupil
              # group_ids = [target_user.pupil.uid]

              start_index = Common::Report::Group::ListArr.find_index(Common::Report::Group::Pupil)
              
              path_h[Common::Report::Group::Pupil][:value] = [target_user.role_obj.uid]
              path_h[Common::Report::Group::Klass][:value] = [target_user.role_obj.location.uid]
              path_h[Common::Report::Group::Grade][:value] = [target_user.tenant.uid]
              target_papers = target_user.role_obj.papers
              path_h[Common::Report::Group::Project][:value] = Mongodb::BankTest.where(bank_paper_pap_id: {"$in" => target_papers.only(:_id).map{|a| a._id.to_s }}).map{|item| item.id.to_s}
              path_h[Common::Report::Group::Project][:value] += target_user.bank_tests.map{|item| item.id.to_s}
              path_h[Common::Report::Group::Project][:allowed_file_regx] += [paper_info_re]

            # 教师
            elsif target_user.is_teacher?
              # current_group = Common::Report::Group::Grade
              # group_ids = [target_user.tenant.uid]

              start_index = Common::Report::Group::ListArr.find_index(Common::Report::Group::Pupil)

              path_h[Common::Report::Group::Pupil][:value] = target_user.role_obj.pupils.map{|item| item.uid}
              path_h[Common::Report::Group::Klass][:value] = target_user.tenant.locations.map{|item| item.uid}
              path_h[Common::Report::Group::Klass][:allowed_file_regx] += [nav_re]
              path_h[Common::Report::Group::Grade][:value] = [target_user.tenant.uid]
              path_h[Common::Report::Group::Grade][:allowed_file_regx] += [nav_re] 
              target_papers = target_user.role_obj.papers
              path_h[Common::Report::Group::Project][:value] = Mongodb::BankTest.where(bank_paper_pap_id: {"$in" => target_papers.only(:_id).map{|a| a._id.to_s }}).map{|item| item.id.to_s}
              path_h[Common::Report::Group::Project][:value] += target_user.accessable_locations.map{|loc| loc.bank_tests.map{|t| t.id.to_s if t } if loc }.flatten.compact.uniq
              path_h[Common::Report::Group::Project][:allowed_file_regx] += [paper_info_re]

            # 分析员
            elsif target_user.is_analyzer?
              # current_group = Common::Report::Group::Grade
              # group_ids = [target_user.tenant.uid]

              start_index = Common::Report::Group::ListArr.find_index(Common::Report::Group::Grade)

              path_h[Common::Report::Group::Klass][:allowed_file_regx] += [nav_re] 
              path_h[Common::Report::Group::Grade][:value] = [target_user.tenant.uid]
              path_h[Common::Report::Group::Grade][:allowed_file_regx] += [nav_re] 
              target_papers = target_user.role_obj.papers
              path_h[Common::Report::Group::Project][:value] = Mongodb::BankTest.where(bank_paper_pap_id: {"$in" => target_papers.only(:_id).map{|a| a._id.to_s }}).map{|item| item.id.to_s}
              path_h[Common::Report::Group::Project][:allowed_file_regx] += [paper_info_re]

            # 租户管理员
            elsif target_user.is_tenant_administrator?
              # current_group = Common::Report::Group::Grade
              # group_ids = [target_user.tenant.uid]

              start_index = Common::Report::Group::ListArr.find_index(Common::Report::Group::Grade)

              path_h[Common::Report::Group::Klass][:allowed_file_regx] += [nav_re]
              path_h[Common::Report::Group::Grade][:value] = [target_user.tenant.uid]
              path_h[Common::Report::Group::Grade][:allowed_file_regx] += [nav_re] 
              target_papers = target_user.tenant.papers
              path_h[Common::Report::Group::Project][:value] = Mongodb::BankTest.where(bank_paper_pap_id: {"$in" => target_papers.only(:_id).map{|a| a._id.to_s }}).map{|item| item.id.to_s}
              path_h[Common::Report::Group::Project][:value] += target_user.accessable_tenants.map{|tnt| tnt.bank_tests.map{|t| t.id.to_s if t } if tnt }.flatten.compact.uniq
              path_h[Common::Report::Group::Project][:allowed_file_regx] += [paper_info_re] 
            # 项目管理员
            elsif target_user.is_project_administrator?
              # current_group = Common::Report::Group::Project
              # group_ids = target_user.bank_tests.map{|item| item.id.to_s }

              start_index = Common::Report::Group::ListArr.find_index(Common::Report::Group::Project)

              path_h[Common::Report::Group::Klass][:allowed_file_regx] += [nav_re]
              path_h[Common::Report::Group::Grade][:allowed_file_regx] += [nav_re]
              target_papers = target_user.role_obj.papers
              path_h[Common::Report::Group::Project][:value] = Mongodb::BankTest.where(bank_paper_pap_id: {"$in" => target_papers.only(:_id).map{|a| a._id.to_s }}).map{|item| item.id.to_s}
              path_h[Common::Report::Group::Project][:value] += target_user.accessable_tenants.map{|tnt| tnt.bank_tests.map{|t| t.id.to_s if t } if tnt }.flatten.compact.uniq
              path_h[Common::Report::Group::Project][:allowed_file_regx] += [paper_info_re, nav_re]
            elsif target_user.is_area_administrator?

              start_index = Common::Report::Group::ListArr.find_index(Common::Report::Group::Project)

              path_h[Common::Report::Group::Klass][:allowed_file_regx] += [nav_re]
              path_h[Common::Report::Group::Grade][:allowed_file_regx] += [nav_re]
              target_papers = target_user.accessable_tenants.map{|tnt| tnt.papers.only(:_id) }.flatten.uniq.compact
              path_h[Common::Report::Group::Project][:value] = Mongodb::BankTest.where(bank_paper_pap_id: {"$in" => target_papers.map{|a| a._id.to_s }}).map{|item| item.id.to_s}
              path_h[Common::Report::Group::Project][:value] += target_user.role_obj.area.bank_tests.map{|t| t.id.to_s if t }.flatten.compact.uniq
              path_h[Common::Report::Group::Project][:allowed_file_regx] += [paper_info_re, nav_re]
            end
          end
          

          # if !((path_arr&["nav", "ckps_qzps_mapping", "qzps_ckps_mapping", "paper_info"]).size > 0)
            # 检查Group ID
            target_groups = Common::Report::Group::ListArr[start_index..-1]
            kaku_group_check_flags = target_groups.map{|group|
              group_index_in_path = path_arr.find_index(group)
              group_id = group_index_in_path.nil?? nil : path_arr[group_index_in_path + 1]
              group_index_in_path.nil?? true : (path_h[group][:value].include?(group_id) && path_h[group][:allowed_file_regx].map{|item| item.match(path_arr[-1]+".json").blank? }.include?(false) )
            }
            # group_id = path_arr[group_index_in_path + 1]
            # if group_ids.compact.include?(group_id)
            unless kaku_group_check_flags.uniq.include?(false)
              data = File.open(target_file_path, 'rb').read
              data.force_encoding(Encoding::UTF_8)
            else
              #status 401
              { status: 401, message: "Access not allowed!" }
            end
          # elsif ((path_arr&["nav", "ckps_qzps_mapping", "qzps_ckps_mapping", "paper_info"]).size > 0)
          #   data = File.open(target_file_path, 'rb').read
          #   data.force_encoding(Encoding::UTF_8)
          # else
          #   status 404
          #   { message: Common::Locale::i18n("swtk_errors.object_not_found", :message => request.fullpath.to_s ) }
          # end
        else
            status 404
            { message: Common::Locale::i18n("swtk_errors.object_not_found", :message => request.fullpath.to_s ) }
        end
      end
    end
  end
end