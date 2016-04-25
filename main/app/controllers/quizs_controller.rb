class QuizsController < ApplicationController
  #load_and_authorize_resource

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

    f_uploaded = Common::File.upload({:paper => params[:file_paper], :answer => params[:file_answer], :analysis => params[:file_analysis]})
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

    current_quiz_paper = Mongodb::Bank.new(params["obj_quizprop"])
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

  # type2 save a single quiz
  # params: 
  #
  def quiz_create_type2save
    # allow receiving all parameters  
    params.permit!

    # response format pre-defined
    result = { :str_id => nil }

    current_quiz = Mongodb::BankQuizQiz.new
=begin
({
      :pap_uid => params[:pap_uid],
      :tbs_uid => params[:tbs_uid],
      :tpl_id => params[:tpl_id],
      :ext1 => params[:ext1],
      :ext2 => params[:ext2],
      :cat => params[:cat],
      :type => params[:type],
      :text => params[:text],
      :answer => params[:answer],
      :desc => params[:desc],
      :score => params[:score],
      :time => params[:time],
      :levelword2 => params[:levelword2],
      :level => params[:level],
      :levelword => params[:levelword],
      :levelorder => params[:levelorder]
    })
=end
    current_quiz.save_quiz(params)

    #params["arr_items"].each{|item|
    #  current_quiz_paper.bank_quiz_qizs.build(item)
    #}
    #current_quiz_paper.bank_quiz_qizs.each{|bqq| bqq.save!}



    ######
    # need to consider other related collections 
    ######

    result = { :str_id => current_quiz._id.to_s }
    result_json = Common::Response.exchange_record_id(result.to_json)
    render :text=>Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
  end


  # get quiz paper list
  #
  def quiz_list
    # response format pre-defined
    result = {:arr_list => []}

    qlist = Mongodb::BankPaperPap.all()
    result[:arr_list] = qlist.to_a

    result_json = Common::Response.exchange_record_id(result.to_json)
    render :text=>Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
  end

  # get a quiz paper
  # params: str_id
  #
  def quiz_get
    # allow receiving all parameters
    params.permit!

    # response format pre-defined
    result = {:str_id => nil, :obj_quizprop => nil, :arr_items => nil }

    begin
      target_quiz_paper = Mongodb::BankPaperPap.find_by(_id: params[:str_id])
      result[:str_id] = params[:str_id]
      result[:obj_quizprop] = target_quiz_paper
      result[:arr_items] = target_quiz_paper.bank_quiz_qizs
    rescue Exception => ex
      # do nothing for current 
    end

    result_json = Common::Response.exchange_record_id(result.to_json)
    render :text=>Common::Response.format_response_json(result_json,Common::Response.get_callback_type(params))
  end

end
