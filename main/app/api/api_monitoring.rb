# -*- coding: UTF-8 -*-

module ApiMonitoring
  class APIV11 < Grape::API
    version 'v1.1', using: :path #/api/v1.1/<resource>/<action>
    format :json
    prefix "api/".to_sym

    helpers ApiCommonHelper
    helpers ApiAuthHelper

    # params do
    #   use :authenticate
    # end
    resource :monitorings do #monitorings begin

      before do
        set_api_header!
        authenticate_token!
      end

      ###########

      desc '获取测试状态 get /api/v1.1/monitorings/check_status'
      params do
        requires :task_uid, type: String, allow_blank: false
      end
      get :check_status do
        target_task = TaskList.where(uid: params[:task_uid]).first
        if target_task
          target_jobs = target_task.job_lists.order({dt_update: :desc})
          {
            :name => target_task.name,
            :jobs => target_jobs.map{|j|
              {
                :job_uid => j.uid,
                :name => j.name,
                :progress => j.process
              }
            }
          }
        else
          status 404
          message_json("e40004")
        end
      end

      ###########

    end #monitorings end
  end #class end
end #monitoring end