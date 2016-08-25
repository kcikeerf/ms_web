class PapersController < ApplicationController

  layout "zhengjuan"

  before_action :set_paper, only: [:download, :download_page, :import_filled_score, :submit_paper, :save_analyze,:submit_analyze, :get_empty_score_file]

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
    result[:paper_html] = Common::PaperFile.get_doc_file_content_as_html(f_uploaded.paper.current_path)
    result[:answer_html] = Common::PaperFile.get_doc_file_content_as_html(f_uploaded.answer.current_path)

    render :json => result.to_json
#    respond_to do |format|
#      format.json { render json: result.to_json }
#    end
#    result_json = Common::Response.exchange_record_id(result.to_json)
#    render :text=>Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
  end

  def new
    render "zhengjuan"
  end

  def get_paper
    params.permit!

    if params[:pap_uid].blank?
      current_pap = Mongodb::BankPaperPap.new
    else
      current_pap = Mongodb::BankPaperPap.where(_id: params[:pap_uid])
    end

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
      current_pap.save_pap(current_user.id, params)
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

  # def upload_filled_score_file
  #   params.permit!

  #   result = response_json

  #   if params[:pap_uid]
  #     current_pap = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
  #     params[:score_file_id] = current_pap.score_file_id
  #     score_file = Common::Score.upload_filled_score params
  #     if score_file
  #       # analyze filled score file
  #       str = current_pap.analyze_filled_score_file score_file
  #       result = response_json(200, {data: str})
  #     end
  #   end

  #   render :json => result
  # end

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

  def download
    type = params[:type]

    return render nothing: true unless %w{paper answer revise_paper revise_answer empty_file filled_file usr_pwd_file}.include?(type)
    need_deal_types = %w{revise_paper revise_answer}
    is_xlsx = %w{empty_file filled_file usr_pwd_file}.include?(type)

    file = is_xlsx ? ScoreUpload.find(@paper.score_file_id) : FileUpload.find(@paper.orig_file_id)
    
    file_name = @paper.paper_name(type) + (is_xlsx ? '.xlsx' : '.doc')

    if need_deal_types.include?(type)
      head_html =<<-EOF
        <h2>#{@paper.heading}</h2>
        <h3>#{@paper.subheading}</h3>
       
        <p style="text-align:center">
          <span>（考试时长：</span><span style="color:#0000ff">#{@paper.quiz_duration}分钟</span><span>    卷面分值：</span><span style="color:#0000ff">#{@paper.score}</span>)
        </p>      
      EOF
      file = Common::PaperFile.generate_docx_by_html(file, head_html + @paper.paper_html, "#{@paper.id}_paper", type) if file.revise_paper.current_path.blank?
      file = Common::PaperFile.generate_docx_by_html(file, head_html + @paper.answer_html, "#{@paper.id}_answer", 'revise_answer') if file.revise_answer.current_path.blank?
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

    # case type
    # when 'paper'
    #   file_name = "#{paper_name}试题.doc"
    #   file_path = file.paper.current_path
    # when 'answer'
    #   file_name = "#{paper_name}答案.doc"
    #   file_path = file.answer.current_path
    # when 'revise_paper'
    #   file = Common::PaperFile.generate_docx_by_html(file, head_html + @paper.paper_html, "#{@paper.id}_paper", 'revise_paper') if file.revise_paper.current_path.blank?
    #   file_name = "#{paper_name}修正后试题.doc"
    #   file_path = file.revise_paper.current_path     
    # when 'revise_answer'
    #   file = Common::PaperFile.generate_docx_by_html(file, head_html + @paper.answer_html, "#{@paper.id}_answer", 'revise_answer') if file.revise_answer.current_path.blank?
    #   file_name = "#{paper_name}修正后答案.doc"
    #   file_path = file.revise_paper.current_path
    # when 'empty_score'
    #   score_file = ScoreUpload.find(@paper.score_file_id)
    #   file_name = "空成绩表.xlsx"
    #   file_path = score_file.empty_file.current_path
    # when 'pupils_score'
    #   score_file = ScoreUpload.find(@paper.score_file_id)
    #   file_name = "学生成绩表.xlsx"
    #   file_path = score_file.filled_file.current_path
    # when 'user_info'
    #   score_file = ScoreUpload.find(@paper.score_file_id)
    #   file_name = "学生用户名密码.xlsx"
    #   file_path = score_file.usr_pwd_file.current_path
    # end

    send_file file_path, filename: file_name, disposition: 'attachment'
  end

  def download_page
    render layout: false
  end

  def import_filled_score
    logger.info("======================import score: begin")
    @result = I18n.t('papers.messages.upload_score.fail')
    if request.post?# && remotipart_submitted? 
      score_file = Common::Score.upload_filled_score({score_file_id: @paper.score_file_id, filled_file: params[:file]})
      if score_file
        begin
          # analyze filled score file
          str = @paper.analyze_filled_score_file score_file# rescue nil  
          @result = I18n.t('papers.messages.upload_score.success') unless str.nil?
          @paper.update(paper_status: Common::Paper::Status::ScoreImported)
        rescue Exception => ex
          logger.debug(">>>>>>>>>>>>>>>>>>Exception When Import Filled Score!")
          logger.debug(ex.message)
          logger.debug(ex.backtrace)
        end
      end
    end
    logger.info("======================import score: end")
   render layout: false
  end

  private

  def set_paper
    @paper = Mongodb::BankPaperPap.find(params[:pap_uid])
    @paper.current_user_id = current_user.id
  end

end
