class UnionTestsController < ApplicationController
  layout "union_test"

  before_action :set_union_test, only: [:show, :edit, :update]

  def new
    # @union_test = Mongodb::UnionTest.new
  end

  def save_union
    params.permit!
    if params[:id]
      union_test = Mongodb::UnionTest.where(_id: params[:id]).first
    else
      union_test = Mongodb::UnionTest.new
    end
    union_test.current_user_id = current_user.id
    begin
      union_test.save_ins params
      render common_json_response(200, {data: { union_uid: union_test._id.to_s } })
    rescue Exception => ex
      render common_json_response(500, {messages: Common::Locale::i18n("union.messages.save_test.fail", :message => "#{ex.message}" )})
    end
  end

  def show
    @union_test_info = @union_test.u_test_info
    p @union_test
    @current_create_report_job_uid = nil
    if @union_test_info[:task_uid]
      create_report_task = TaskList.where(uid: @union_test_info[:task_uid]).first
      create_report_job = create_report_task.job_lists.blank?? nil : create_report_task.job_lists.order({:dt_update => :desc}).first
      @current_create_report_job_uid = create_report_job.uid
    end
  end

  private
  def set_union_test
    @union_test = Mongodb::UnionTest.where(_id: params[:id]).first
  end
end
