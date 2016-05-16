class QuizsController < ApplicationController
  #load_and_authorize_resource
  layout 'user', only: [:quiz_list, :single_quiz, :single_quiz_edit]

  before_action :authenticate_user!, only: [:quiz_list]
  before_action :set_quize, only: [:single_quiz, :single_quiz_edit, :quiz_list]
  before_action :set_quize_difficulty, only: [:single_quiz, :single_quiz_edit]

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
    # @subjects_related_data = BankNodestructure.list_structures
    # @quize_types = BankDicQuizSubject.list_quiztypes
    # @subjects = @subjects_related_data.keys.map{|k| [@subjects_related_data[k]['label'], k]}
    # @difficulties = BankDic.list_difficulty.map{|item| [item["label"], item["sid"]]}
    @quiz = Mongodb::BankQuizQiz.new
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
      result[:str_id]=current_quiz._id
      flash[:notice] = I18n.t("quizs.messages.create.success", :id =>  current_quiz._id)
      result[:status] = 200
      result[:message] = I18n.t("quizs.messages.create.success", :id => current_quiz._id)
    rescue Exception => ex
      result[:status] = 500
      result[:message] = I18n.t("quizs.messages.create.fail", :id => current_quiz._id)
    ensure
      render json: result.to_json
    end

    # result = { :str_id => current_quiz._id.to_s }
    # result_json = Common::Response.exchange_record_id(result.to_json)
    # render :json => Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
  end

  #single quiz edit
  def single_quiz_edit    
    @quiz = Mongodb::BankQuizQiz.find_by(id: params[:str_id])
    @quiz_hash_data = @quiz.quiz_detail
    @tree_data = BankCheckpointCkp.get_ckps   
  end

  # single quiz update
  # params:
  #   uid: selected quiz uid
  #
  def single_quiz_update
    #allow receiving all parameters
    params.permit!
    #response format pre-defined
    result = {"str_id" => nil, :status => "", :message => "" }
    begin
      current_quiz = Mongodb::BankQuizQiz.find_by(id: params[:str_id])
      current_quiz.save_quiz(params)
      result[:str_id]=current_quiz._id
      flash[:notice] = I18n.t("quizs.messages.update.success" , :id => current_quiz._id)
      result[:status] = 200
      result[:message] = I18n.t("quizs.messages.update.success", :id => current_quiz._id)
    rescue Exception => ex
      result[:status] = 500
      result[:message] = I18n.t("quizs.messages.update.fail", :id => current_quiz._id)
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
    result = {"str_id" => nil, :status => "", :message => "" }
    begin
      current_quiz = Mongodb::BankQuizQiz.where(:_id => params["str_id"]).first
      current_id = current_quiz._id.to_s
      current_quiz.destroy_quiz
      flash[:notice] = I18n.t("quizs.messages.delete.success" , :id => current_id)
      result[:status] = 200
      result[:message] = I18n.t("quizs.messages.delete.success", :id => current_id)
    rescue Exception => ex
      result[:status] = 500
      result[:message] = I18n.t("quizs.messages.delete.fail", :id => current_id)
    ensure
      render json: result.to_json
    end
  end

  # get quiz list
  #
  def quiz_list
    params.permit!

    # response format pre-defined
    result = {:status => "", :message => "", :arr_list => []}

    begin
      raise SwtkErrors::ParameterInvalidError.new(I18n.t("quizs.messages.list.invalid_version")) if params[:version] and ( params[:subject].blank? || params[:grade].blank?)
      raise SwtkErrors::ParameterInvalidError.new(I18n.t("quizs.messages.list.invalid_type")) if params[:type] and params[:subject].blank?

      order_h = {:dt_add => "desc"}

      if params[:subject].blank? && params[:grade].blank? && params[:version].blank? && params[:type].blank? && params[:keywords].blank?
        @quizs =  Mongodb::BankQuizQiz.order(order_h).to_a
      else
        cond_s = []
        cond_s << "subject = #{params[:subject]}" if params[:subject]
        cond_s << "grade = #{params[:grade]}" if params[:grade]
        version = params[:version].sub(/\(.*\)/, "") if params[:version]
        volume = params[:version].sub(/.*\(/, "").split(")") if params[:version]
        cond_s << "version =#{version} and volume = #{volume}" if params[:version]
        nodes = BankNodestructure.where(cond_s.join(" and "))
        node_ids = nodes.map{|node| node.uid}

        type_re = /.*#{params[:type]}.*/
        text_re = /.*#{params[:text]}.*/
        answer_re = /.*#{params[:answer]}.*/
        desc_re = /.*#{params[:desc]}.*/
        cond_h = {
          :type => type_re,
          :text => text_re,
          :answer => answer_re,
          :desc => desc_re,
          :node_uid.in => nodes_ids
        }
       @quizs = Mongodb::BankQuizQiz.where(cond_str).order(order_h).to_a
   
      # maybe used in the future
      #result[:status] = 200
      #result[:message] = I18n.t("quizs.messages.list.success")
      end
    rescue SwtkErrors::ParameterInvalidError => ex
      result[:status] = 500
      result[:message] = I18n.t("quizs.messages.list.invalid_params", :message => ex.message)
    rescue Exception => ex
      result[:status] = 500
      result[:message] = I18n.t("quizs.messages.list.fail")
    ensure
      result[:arr_list] = @quizs.map{|quiz| 
        {"uid"=> quiz._id, 
         "text"=> quiz.text, 
         "levelword2"=>quiz.levelword2, 
         "type"=>quiz.type, 
         "type_label"=>I18n.t("dict.#{quiz.type}")
        }
      }
      # render json: result.to_json
    # end


    # result[:arr_list] = qlist.to_a

    # result_json = Common::Response.exchange_record_id(result.to_json)
    # render :text=>Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
    end
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
      target_quiz = Mongodb::BankQuizQiz.find_by(_id: params[:str_rid])
      result[:str_uid] = params[:str_uid]
      result[:obj_quizprop] = target_quiz
      result[:arr_items] = target_quiz.quiz_detail
    rescue Exception => ex
      # do nothing for current 
    end

    result_json = Common::Response.exchange_record_id(result.to_json)
    render :text=>Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
  end

  private

  def set_quize
    @subjects_related_data = BankNodestructure.list_structures
    @quize_types = BankDicQuizSubject.list_quiztypes
    @subjects = @subjects_related_data.keys.map{|k| [@subjects_related_data[k]['label'], k]}
  end

  def set_quize_difficulty
    @difficulties = BankDic.list_difficulty.map{|item| [item["label"], item["sid"]]}
  end

end
