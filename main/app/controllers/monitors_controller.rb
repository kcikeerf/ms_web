class MonitorsController < ApplicationController
  layout false
  def get_task_status
    params.permit!

    result = { :status=> "success",:name=> "",:jobs => [],:message =>"" }  

    target_task = TaskList.where(uid: params[:task_uid]).first
    if target_task
      target_jobs = target_task.job_lists.order({dt_update: :desc})

      result[:name] = target_task.name
      result[:jobs] = target_jobs.map{|j|
        {
          :job_uid => j.uid,
          :name => j.name,
          :progress => j.process
        }
      }

      # total_count = target_jobs.size
      # result[:name] = target_task.name
      # result[:process] = (total_count == 0)? 0.0 : target_jobs.map{|job| job.process}.sum/total_count
    end
    render common_json_response(200, result)  
  end
end
