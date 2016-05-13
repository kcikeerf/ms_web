class QuizsController < ApplicationController
  #load_and_authorize_resource
  layout 'user', only: [:quiz_list, :single_quiz]

  before_action :authenticate_user!, only: [:quiz_list]

  def new
    data = BankNodestructure.list_structures
    @data = data
  end

  # single file upload
  #
  def single_quiz_file_upload
    # allow receiving all parameters  
    params.permit!

    # response format pre-defined

#    result = {
#     :str_tempid => nil,
#     :result_str => nil
#    }

#    f_uploaded = Common::File.single_upload({:str_tempid => params[:str_tempid], :type=>params[:type], :file => params[:file]})
    f_uploaded = Common::File.single_upload({:file => params[:file]})
#    result[:str_tempid] = f_uploaded.id
#    case params[:type]
#    when "question"
#      result[:result_str] = Common::File.get_doc_file_content_as_html(f_uploaded.paper.current_path)
#    when "answer"
#      result[:result_str] = Common::File.get_doc_file_content_as_html(f_uploaded.answer.current_path)
#    end
     result = ""
     result = Common::File.get_doc_file_content_as_html(f_uploaded.single.current_path)

#    respond_to do |format|
#      format.json { render json: result.to_json }
#    end
#    result_json = Common::Response.exchange_record_id(result.to_json)
#    render :text=>Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
     render :text => result
  end

  # type1 upload a quiz
  # params: file_paper:[file]
  # params: file_answer:[file]
  # params: file_analysis:[file]
  def quiz_create_type1upload
    # allow receiving all parameters  
    params.permit!

    # response format pre-defined
    result = { 
     :str_tempid => nil,
     :str_quiz => nil,
     :str_answer => nil,
     :obj_analysis => nil
    }

    f_uploaded = Common::File.multiple_upload({:paper => params[:doc_path], :answer => params[:answer_path], :analysis => params[:xls_path]})
    result[:str_tempid] = f_uploaded.id
    result[:str_quiz] = Common::File.get_doc_file_content_as_html(f_uploaded.paper.current_path)
    result[:str_answer] = Common::File.get_doc_file_content_as_html(f_uploaded.answer.current_path)
    result[:obj_analysis] = Common::File.get_excel_file_content(f_uploaded.analysis.current_path) 

#    respond_to do |format|
#      format.json { render json: result.to_json }
#    end
    result_json = Common::Response.exchange_record_id(result.to_json)
    render :text=>Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
  end
   

  # type1 save a quiz
  # params: obj_quizprop
  # params: arr_items
  # params: str_tempid
  #
  def quiz_create_type1save
    # allow receiving all parameters  
    params.permit!

    # response format pre-defined
    result = { :str_tempid => nil }

    current_quiz_paper = Mongodb::BankQuizQiz.new(params["obj_quizprop"])
    current_quiz_paper.save!

    #params["arr_items"].each{|item|
    #  current_quiz_paper.bank_quiz_qizs.build(item)
    #}
    #current_quiz_paper.bank_quiz_qizs.each{|bqq| bqq.save!}

        

    ######
    # need to consider other related collections 
    ######

    result = { :str_id => current_quiz_paper._id.to_s }
    result_json = Common::Response.exchange_record_id(result.to_json)
    render :text=>Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
  end

  #single quiz
  def single_quiz
    @subjects_related_data = BankNodestructure.list_structures
    @quize_types = BankDicQuizSubject.list_quiztypes
    @subjects = @subjects_related_data.keys.map{|k| [@subjects_related_data[k]['label'], k]}
    @difficulties = BankDic.list_difficulty.map{|item| [item["label"], item["sid"]]}
    @tree_data = {'knowledge' => {}, 'skill' => {}, 'ability' => {}}
  end

  # type2 save a single quiz
  # params: 
  #
  def single_quiz_save
    # allow receiving all parameters  
    params.permit!
    # response format pre-defined
    result = { :str_id => nil, :status => "", :message => "" }

    begin
      current_quiz = Mongodb::BankQuizQiz.new
      current_quiz.save_quiz(params)
      flash[:notice] = I18n.t("quizs.messages.create.success" , :uid: current_quiz.uid)
      result[:status] = 200
      result[:message] = I18n.t("quizs.messages.create.success", :uid : current_quiz.uid)
    rescue Exception => ex
      result[:status] = 500
      result[:message] = I18n.t("quizs.messages.create.success", :uid : current_quiz.uid)
    ensure
      render json: result.to_json
    end

    # result = { :str_id => current_quiz._id.to_s }
    # result_json = Common::Response.exchange_record_id(result.to_json)
    # render :json => Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
  end

  # single quiz update
  # params:
  #   uid: selected quiz uid
  #
  def single_quiz_update
    #allow receiving all parameters
    params.permit!
    #response format pre-defined
    result = {"str_uid" => nil, :status => "", :message => "" }
    begin
      current_quiz = Mongodb::BankQuizQiz.where("uid = ? ", params["str_rid"]).first
      current_quiz.save_quiz(params)
      flash[:notice] = I18n.t("quizs.messages.update.success" , uid: current_quiz.uid)
      result[:status] = 200
      result[:message] = I18n.t("quizs.messages.update.success", :uid : current_quiz.uid)
    rescue Exception => ex
      result[:status] = 500
      result[:message] = I18n.t("quizs.messages.update.success", :uid : current_quiz.uid)
    ensure
      render json: result.to_json
    end
  end

  # single quiz delete
  # params:
  #   uid: select quiz uid
  #
  def single_quiz_delete
    #allow receiving all parameters
    params.permit!
    #response format pre-defined
    result = {"str_uid" => nil, :status => "", :message => "" }
    begin
      current_quiz = Mongodb::BankQuizQiz.where("uid = ? ", params["str_rid"]).first
      current_quiz.destroy!
      flash[:notice] = I18n.t("quizs.messages.delete.success" , uid: current_quiz.uid)
      result[:status] = 200
      result[:message] = I18n.t("quizs.messages.delete.success", :uid : current_quiz.uid)
    rescue Exception => ex
      result[:status] = 500
      result[:message] = I18n.t("quizs.messages.delete.success", :uid : current_quiz.uid)
    ensure
      render json: result.to_json
    end
  end

  # get quiz list
  #
  def quiz_list
    # response format pre-defined
    result = {:arr_list => []}

    @quizs = Mongodb::BankQuizQiz.order(id: :desc).to_a
    # result[:arr_list] = qlist.to_a

    # result_json = Common::Response.exchange_record_id(result.to_json)
    # render :text=>Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
  end

  # get a quiz
  # params: str_id
  #
  def quiz_get
    # allow receiving all parameters
    params.permit!

    # response format pre-defined
    result = {:str_uid => nil, :obj_quizprop => nil, :arr_items => nil }

    begin
      target_quiz = Mongodb::BankQuizQiz.find_by(_id: params[:str_uid])
      result[:str_uid] = params[:str_uid]
      result[:obj_quizprop] = target_quiz
      result[:arr_items] = target_quiz.quiz_detail
    rescue Exception => ex
      # do nothing for current 
    end

    result_json = Common::Response.exchange_record_id(result.to_json)
    render :text=>Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
  end

end
