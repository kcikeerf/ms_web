# -*- coding: UTF-8 -*-

module Tenants
  class API < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/wx".to_sym

    helpers ApiHelper

    resource :tenants do
      
      before do
        set_api_header
        #authenticate!
      end

      ###########
      
      desc '获取当前用户所在租户的年级班级列表 post /api/wx/v1.1/tenants/grade_klass_list' # grade_class_list begin
      params do
        optional :grade, type: String, allow_blank: true
      end
      post :grade_klass_list do
        result = {}
  
        if current_user.is_project_administrator?
          target_tenants = current_user.role_obj.tenants
        else
          target_tenants = [current_user.tenant]
        end

        target_tenants.map{|tnt|
          result = [{
              "name" => tnt.name,
              "name_cn" => tnt.name_cn,
              "grades_klasses" => tnt.grades_klasses
          }]
        }
        result

      end # grade_class_list end

      ###########

      desc '获取当前用户的班级的学生列表 post /api/wx/v1.1/tenants/klass_pupil_list' # grade_class_list begin
      params do
        optional :klass_uids, type: String, allow_blank: false
      end
      post :klass_pupil_list do
        # result = {}
  
        # if current_user.is_project_administrator?
        #   target_tenants = current_user.role_obj.tenants
        # else
        #   target_tenants = [current_user.tenant]
        # end

        # target_tenants.map{|tnt|
        #   result = [{
        #       "name" => tnt.name,
        #       "name_cn" => tnt.name_cn,
        #       "grades_klasses" => tnt.grades_klasses
        #   }]
        # }
        # result

      end # grade_class_list end

      ###########

    end 

  end # class end
end # tenants end