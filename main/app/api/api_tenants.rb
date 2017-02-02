# -*- coding: UTF-8 -*-

module ApiTenants
  class APIV11 < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/".to_sym

    helpers ApiCommonHelper
    helpers ApiAuthHelper

    resource :tenants do
      
      before do
        set_api_header!
        @current_user = current_user
      end

      ###########
      
      desc '获取当前用户所在租户的年级班级列表 post /api/v1.1/tenants/grade_klass_list' # grade_class_list begin
      params do        
        optional :grade, type: String, allow_blank: true
      end
      get :grade_klass_list do
        result = []
  
        # 获取当前用户的租户对象及班级范围
        target_tenants = @current_user.accessable_tenants
        accessable_loc_uids = @current_user.accessable_locations.map(&:uid)

        # 返回年级班级信息
        target_tenants.map{|tnt|
          result << {
            "name" => tnt.name,
            "name_cn" => tnt.name_cn,
            "tenant_uid" => tnt.uid,
            "grades_klasses" => tnt.grades_klasses({:grade => params[:grade], :loc_uids => accessable_loc_uids} )
          }
        }
        result

      end # grade_class_list end

      ###########

      desc '获取当前用户的班级的学生列表 post /api/wx/v1.1/tenants/klass_pupil_list' # grade_class_list begin
      params do
        optional :klass_uids, type: Array, allow_blank: false
      end
      get :klass_pupil_list do
        result = []
  
        # 获取当前用户的班级可访问范围
        accessable_loc_uids = @current_user.accessable_locations.map(&:uid)
        target_loc_uids = accessable_loc_uids&params[:klass_uids]

        target_loc_uids.map{|loc_uid|
          target_location = Location.where(uid: loc_uid).first
          next unless target_location
          result << {
            "name" => target_location.classroom,
            "name_cn" => Common::Klass::List[target_location.classroom.to_sym],
            "pupils" => target_location.pupils.sort{|a,b| 
                a.stu_number <=> b.stu_number 
              }.map{|item| 
                {
                  "user_name" => item.user.name,
                  "name" => item.name,
                  "pup_uid" => item.uid,
                  "stu_number" => item.stu_number
                }
              }
          }
        }

        result

      end # grade_class_list end

      ###########

    end 

  end # class end
end # tenants end
