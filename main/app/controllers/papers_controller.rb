class PapersController < ApplicationController

  layout "zhengjuan"

  before_action :set_paper, only: [:download, :download_page, :get_saved_paper, :import_filled_score, :submit_paper, :save_analyze,:submit_analyze, :get_empty_score_file]
  before_action do
    check_resource_tenant(@paper) if @paper
  end
  # type1 upload a quiz
  # params: file_paper:[file]
  # params: file_answer:[file]
  # params: file_analysis:[file]
  def paper_answer_upload
    # allow receiving all parameters  
    params.permit!

    # response format pre-defined
    result = {
     :orig_file_id => nil,
     :paper_html => nil,
     :answer_html => nil,
    }

    f_uploaded = Common::PaperFile.multiple_upload({
      :paper => params[:doc_path], 
      :answer => params[:answer_path]
    })
    result[:orig_file_id] = f_uploaded.id
    result[:paper_html] = Common::Wc::convert_doc_through_wc(f_uploaded.paper.current_path)
    result[:answer_html] = Common::Wc::convert_doc_through_wc(f_uploaded.answer.current_path)

    render :json => result.to_json
  end

  def new
    render "zhengjuan"
  end

  def get_paper
    params.permit!

    if params[:pap_uid].blank?
      current_pap = Mongodb::BankPaperPap.new
    else
      current_pap = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
    end

    #Version1.1版默认是一个试卷对应一个测试，之后对改成1对多
    @current_test = current_pap.bank_tests[0]
    render "zhengjuan"
  end

  # 
  # 
  def save_paper
    params.permit!

    result = response_json
  
    if params[:pap_uid].blank?
      current_pap = Mongodb::BankPaperPap.new
    else
      current_pap = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
    end
    begin
      current_pap.current_user_id = current_user.id
      current_pap.save_pap(params)
      result = response_json(200, {pap_uid: current_pap._id.to_s})
    rescue Exception => ex
      result = response_json(500, {messages: I18n.t("papers.messages.save_paper.fail", :message=> "#{ex.message}")})
    end
    render :json => result
  end

  def get_saved_paper
    params.permit!

    result = response_json
    
    if !params[:pap_uid].blank?
      current_pap = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
      result_h = JSON.parse(current_pap.paper_json)
      result_h["information"]["paper_status"] = current_pap.paper_status
      result_h["pap_uid"] = current_pap._id.to_s
      result = response_json(200, result_h.to_json)
    else
      result = response_json(500)
    end
    render :json => result
  end

  def submit_paper
    params.permit!

    result = response_json

    if params[:pap_uid]
      #@paper = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
      begin
        #current_pap.current_user_id = current_user.id
        @paper.submit_pap params
        @paper.generate_empty_score_file

        result = response_json(200, {pap_uid: @paper._id.to_s})
        #result = response_json(200, {messages: I18n.t("papers.messages.submit_paper.success", current_pap.heading)})
      rescue Exception => ex
        result = response_json(500, {messages: I18n.t("papers.messages.submit_paper.fail", :heading => ex.message)})
      end
    else
      result = response_json(500)
    end
    render :json => result
  end
 
  def save_analyze
    params.permit!

    result = response_json

    if params[:pap_uid]
      #current_pap = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
      if @paper.save_ckp params
        result = response_json(200, {messages: I18n.t("papers.messages.save_analyze.success", @paper.heading)})
      else
        result = response_json(500, {messages: I18n.t("papers.messages.save_analyze.fail", @paper.heading)})
      end
    else
      result = response_json(500)
    end 
    render :json => result  
  end

  def get_saved_analyze
    params.permit!

    result = response_json
 
    if params[:pap_uid]
      #current_pap = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
      result = response_json(200, @paper.analyze_json.to_json)
    else
      result = response_json(500)
    end
    render :json => result
  end

  def submit_analyze
    params.permit!

   
    result = response_json

    if params[:pap_uid]
      #current_pap = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
      if @paper.submit_ckp params
        result = response_json(200, {messages: I18n.t("papers.messages.submit_analyze.success", @paper.heading)})
      else
        result = response_json(500, {messages: I18n.t("papers.messages.submit_analyze.fail", @paper.heading)})
      end
    else
      result = response_json(500)
    end

    render :json => result
  end

  def get_empty_score_file
    params.permit!

    if params[:pap_uid]
      #@paper = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
      score_file = ScoreUpload.where(id: @paper.score_file_id).first
      if score_file
        send_file score_file.empty_file.current_path,
          filename: score_file.empty_file.filename,
          type: "application/octet-stream"
      end
    end
  end

  #下载试卷的相关文件
  def download
    type = params[:type]

    return render nothing: true unless %w{paper answer revise_paper revise_answer empty_file filled_file usr_pwd_file}.include?(type)
    need_deal_types = %w{revise_paper revise_answer}
    is_xlsx = %w{empty_file filled_file usr_pwd_file}.include?(type)

    file = is_xlsx ? ScoreUpload.find(@paper.score_file_id) : FileUpload.find(@paper.orig_file_id)
    
    file_name = @paper.download_file_name(type) + (is_xlsx ? '.xlsx' : '.doc')
    # 旧接口注释掉
    #file_name = @paper.paper_name(type) + (is_xlsx ? '.xlsx' : '.doc')

    if need_deal_types.include?(type)
      head_html =<<-EOF
        <h2>#{@paper.heading}</h2>
        <h3>#{@paper.subheading}</h3>
       
        <p style="text-align:center">
          <span>（考试时长：</span><span style="color:#0000ff">#{@paper.quiz_duration}分钟</span><span>    卷面分值：</span><span style="color:#0000ff">#{@paper.score}</span>)
        </p>      
      EOF
      case type
      when "revise_paper"
        if file.revise_paper.blank? || !File.exists?(file.revise_paper.current_path)
          file = Common::PaperFile.generate_docx_by_html(file, head_html + @paper.paper_html, "#{@paper.id}_paper", type)
        end
      when "revise_answer"
        if file.revise_answer.blank? || !File.exists?(file.revise_answer.current_path)
          file = Common::PaperFile.generate_docx_by_html(file, head_html + @paper.answer_html, "#{@paper.id}_answer", type)
        end
      end
    end

    file_path = file.send(type.to_sym).current_path

    # file = FileUpload.find(@paper.orig_file_id)
    # head_html =<<-EOF
    #   <h2>#{@paper.heading}</h2>
    #   <h3>#{@paper.subheading}</h3>
     
    #   <p style="text-align:center">
    #     <span>（考试时长：</span><span style="color:#0000ff">#{@paper.quiz_duration}分钟</span><span>    卷面分值：</span><span style="color:#0000ff">#{@paper.score}</span>)
    #   </p>      
    # EOF

    send_file file_path, filename: file_name, disposition: 'attachment'
  end

  def download_page
    render layout: false
  end

  #上传成绩表
  def import_filled_score
    params.permit!

    if request.post?
      logger.info("====================import score: begin")
      result = {:status => 403, :task_uid => ""}

      begin
        # this part will delete after merge with master
        @paper = Mongodb::BankPaperPap.find(params[:pap_uid])
        @paper.current_user_id = current_user.id

        score_file = Common::Score.upload_filled_score({score_file_id: @paper.score_file_id, filled_file: params[:file]})
        if score_file
          task_name = format_report_task_name @paper.heading, Common::Task::Type[:import_score]
          new_task = TaskList.new(
            name: task_name,
            pap_uid: @paper._id.to_s)
          new_task.save!
          
          Thread.new do
            ImportScoreJob.perform_later({
              :task_uid => new_task.uid,
              :pap_uid => params[:pap_uid]
            }) 
          end
          status = 200
          result[:status] = status
          result[:task_uid] = new_task.uid
        else
          status = 500
          result[:status] = status
          result[:message] = I18n.t("scores.messages.error.upload_failed")
        end
      rescue Exception => ex
        status = 500
        result[:status] = status
        result[:message] = I18n.t("scores.messages.error.upload_exception")
        @result = result.to_json
        logger.debug ">>>ex.message<<<"
        logger.debug ex.message
        logger.debug ">>>ex.backtrace<<<"
        logger.debug ex.backtrace
      end
      @result = result.to_json
      logger.info("====================import score: end")
    end
    render layout: false
  end

  private

  def set_paper
    @paper = Mongodb::BankPaperPap.find(params[:pap_uid])
    @paper.current_user_id = current_user.id
  end

end
