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

    paper, answer, analysis = Common::File.upload([params[:file_paper], params[:file_answer], params[:file_analysis]])
    result = { :items => [paper.file.current_path, answer.file.current_path, analysis.file.current_path]}
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

    current_quiz_paper = Mongodb::BankPaperPap.new(params["obj_quizprop"])
    current_quiz_paper.save!

    params["arr_items"].each{|item|
      current_quiz_paper.bank_quiz_qizs.build(item)
    }
    current_quiz_paper.bank_quiz_qizs.each{|bqq| bqq.save!}
    
    ######
    # need to consider other related collections 
    ######

    result = { :str_tempid => current_quiz_paper._id.to_s }
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
