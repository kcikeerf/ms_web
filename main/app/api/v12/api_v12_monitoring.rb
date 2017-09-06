# -*- coding: UTF-8 -*-

module ApiV12Monitoring
  class API < Grape::API
    format :json

    helpers Doorkeeper::Grape::Helpers
    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper

    params do
      use :oauth
    end

    resource :monitorings do #monitorings begin

      before do
        set_api_header
        doorkeeper_authorize!
        authenticate_api_permission current_user.id, request.request_method, request.fullpath        
      end

      ###########

      desc '获取测试状态 post /api/v1.2/monitorings/check_status'
      params do
        requires :task_uid, type: String, allow_blank: false
      end
      post :check_status do
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
          {
            :message => "Not Found"
          }
        end
      end

      ###########

    end #monitorings end
  end #class end
end #monitoring end