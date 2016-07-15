class MonitorsController < ApplicationController
  layout false
  def get_task_status
    params.permit!

    result = { :status=> "success",:process => 0.0,:message =>"" }  

    if params[:task_uid]
      target_task = TaskList.where(uid: params[:task_uid]).first
      target_jobs = target_task.job_lists
      total_count = target_jobs.size
      result[:process] = (total_count == 0)? 0.0 : target_jobs.map{|job| job.process}.sum/total_count
    end
    render common_json_response(200, result)  
  end
end
