class BankTestsController < ApplicationController

  layout "bank_test"

  before_action :set_bank_test, only: [
    :del_test,
    :show_test,
    :download_page,
    :import_filled_result,
  ]

  #添加测试项目页面
  def new
    @union_test = Mongodb::UnionTest.where(_id: params[:union_test_id]).first
  end

  #获取试卷，后期是获取试卷API
  def get_pap_api
    @papers = Mongodb::BankPaperPap.get_list_api current_user.id
    # @papers, total_count = Mongodb::BankPaperPap.get_list params
    render :json => @papers
  end

  #创建测试
  def create_test
    current_test = Mongodb::BankTest.new

    begin
      params[:user_id] = current_user.id
      current_test.save_test params
      render common_json_response(200, {data: { test_uid: current_test._id.to_s } })
    rescue Exception => ex
      render common_json_response(500, {messages: Common::Locale::i18n("tests.messages.save_test.fail", :message=> "#{ex.message}" )})
    end
  end


  def del_test
    @bank_test.destroy
    redirect_to union_test_path(params[:union_test_id])
    # render :json => @bank_test
  end

  #测试展示
  def show_test
    tenant_uids = current_user.accessable_tenants.map(&:uid)
    @current_test_tenant_list = @bank_test.tenant_list.find_all{|t| tenant_uids.include?(t[:tenant_uid])}.compact

    #报告job_uid
    if @bank_test.test_status == Common::Test::Status::ReportGenerating
      create_report_task = @bank_test.tasks.by_task_type("create_report").first
      create_report_job = create_report_task.job_lists.blank?? nil : create_report_task.job_lists.order({:dt_update => :desc}).first
      @current_create_report_job_uid = create_report_job.uid
    else 
      @current_create_report_job_uid = nil
    end

    #根据关联学校的状态修改测试状态
    case @bank_test.test_status
    when Common::Test::Status::ScoreImporting
      unless @bank_test.tenant_list.map{|a| a[:tenant_status] == Common::Test::Status::ScoreImported}.include?(false)
        @bank_test.update(test_status: Common::Test::Status::ScoreImported)
      end
    else
      #do nothing
    end

    current_pap = @bank_test.bank_paper_pap
    if current_pap
      @result_h = JSON.parse(current_pap.paper_json)
      #此处暂做保留，之后删掉
      @result_h["information"]["test_status"] = @bank_test.test_status
      @result_h["pap_uid"] = current_pap._id.to_s

      @result_h["information"]["create_report_task"] = @bank_test.tasks.by_task_type("create_report").first.uid
      @result_h["information"]["import_result_task"] = @bank_test.tasks.by_task_type("import_result").first.uid
    end

  end

  
  #关联试卷下载
  def download_page
    @paper = @bank_test.bank_paper_pap
    render layout: false
  end

  #导入成绩
  def import_filled_result
    # params.permit!

    # if request.post?
    #   logger.info("====================import result rquest: begin")
    #   result = {:status => 403, :task_uid => ""}

    #   begin
    #     raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => "no file")) if params[:file].blank?
    #     params[:test_id] =  @paper.bank_tests[0].nil?? "" : @paper.bank_tests[0].id.to_s
    #     score_file = Common::Score.upload_filled_result(params)
    #     if score_file
    #       tkc = TkJobConnector.new({
    #         :version => "v1.2",
    #         :api_name => "tests_import_xy_results",
    #         :http_method => "post",
    #         :params => {
    #           :test_id => params[:test_id],
    #           :score_file_id => score_file.id,
    #           :tenant_uid => params[:tenant_uid]
    #         }
    #       })
    #       tkc_flag, tkc_data = tkc.execute
    #       if tkc_flag
    #         status = 200
    #         result = {
    #           :message => "success!"
    #         }
    #       else
    #         status = 500
    #         result = {
    #           :message => I18n.t("scores.messages.error.upload_failed")
    #         }
    #       end
    #     else
    #       status = 500
    #       result = {
    #         :message => I18n.t("scores.messages.error.upload_failed")
    #       }
    #     end
    #   rescue Exception => ex
    #     status = 500
    #     result = {
    #       :message => I18n.t("scores.messages.error.upload_exception")
    #     }
    #     logger.debug ex.message
    #     logger.debug ex.backtrace
    #   end
    #   common_json_response(status, result)
    #   logger.info("====================import score request: end")
    # end
    # render layout: false

    params.permit!
    if request.post?
      raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => "no file")) if params[:file].blank?
      # params[:test_id] = @paper.bank_tests[0].nil?? "" : @paper.bank_tests[0].id.to_s
      score_file = Common::Score.upload_filled_result(params)
      status, result = nil, nil
      if score_file.blank?
        status = 500
        result = {
          :message => I18n.t("scores.messages.error.upload_failed")
        }
      end
      status_code, result = Common::template_tk_job_execution_in_controller(status, result) {
        TkJobConnector.new({
          :version => "v1.2",
          :api_name => "tests_import_xy_results",
          :http_method => "post",
          :params => {
            :test_id => params[:test_uid],
            :score_file_id => score_file.id,
            :tenant_uid => params[:tenant_uid],
            :user_id => current_user.id
          }
        })
      }
      #render common_json_response(status_code, result)
      @result = result.merge({:status => status_code}).to_json
    else
      render layout: false
    end

    # params.permit!
    # if request.post?
    #   result = {
    #     :message => "0"
    #   }
    #   tenant_link = Mongodb::BankTestTenantLink.where(bank_test_id: params[:test_uid],tenant_uid: params[:tenant_uid]).first
      
    #   task = @bank_test.tasks.by_task_type("import_result").first
    #   #1.创建joblist
    #   job = Common::Job::create_job_tracker "ImportResultJob",task.uid

    #   #2.修改BankTestTenantLink状态
    #   tenant_link.update(tenant_status: Common::Test::Status::ScoreImporting,job_uid: job.uid)
    #   @result = result.merge({:status => 200}).to_json
    #   if @bank_test.test_status == Common::Test::Status::New
    #     @bank_test.update(test_status: Common::Test::Status::ScoreImporting)
    #   end
    # else
    #   render layout: false
    # end
  end

  private
    def set_bank_test
      @bank_test = Mongodb::BankTest.find(params[:test_uid])
    end

end