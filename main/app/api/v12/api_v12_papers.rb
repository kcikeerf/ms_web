# -*- coding: UTF-8 -*-

module ApiV12Papers
  class API < Grape::API
    format :json

    helpers Doorkeeper::Grape::Helpers
    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper

    params do
      use :oauth
    end

    resource :papers do #checkpoints begin
      before do
        set_api_header
        doorkeeper_authorize!
      end

      ##########
      # desc '"获取某个指标体系的checkpoint_system list" post /api/v1.3/papers/paper_answer_upload' # get_ckp_type_system begin
      # params do
      #   requires :doc_path, type: File
      #   requires :answer_path, type: File
      #   optional :analysis, type: File
      # end
      # post :paper_answer_upload do
      #   result = {
      #     :orig_file_id => nil,
      #     :paper_html => nil,
      #     :answer_html => nil,
      #   }

      #   f_uploaded = Common::PaperFile.multiple_upload({
      #     :paper => params[:doc_path], 
      #     :answer => params[:answer_path]
      #   })
      #   result[:orig_file_id] = f_uploaded.id
      #   #result[:paper_html] = Common::Wc::convert_doc_through_wc(f_uploaded.paper.current_path)
      #   #result[:answer_html] = Common::Wc::convert_doc_through_wc(f_uploaded.answer.current_path)
      #   result[:paper_html] =  Common::PaperFile.get_doc_file_content_as_html(f_uploaded.paper.current_path)
      #   result[:answer_html] = Common::PaperFile.get_doc_file_content_as_html(f_uploaded.answer.current_path)
      #   result
      # end # paper_answer_upload end
      
      # desc '"获取试卷" post /api/v1.3/papers/save_paper' # save_paper begin
      # params do
      #   requires :pap_uid, type: String
      #   optional :orig_file_id, type: Integer
      #   requires :paper_html, type: String
      #   requires :answer_html, type: String
      #   optional :paper, type: JSON
      #   optional :bank_quiz_qizs, type: Array 
      # end
      # post :save_paper do

      #   if params[:pap_uid].blank?
      #     current_pap = Mongodb::BankPaperPap.new
      #   else
      #     current_pap = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
      #   end
      #   begin
      #     current_pap.current_user_id = current_user.id
      #     current_pap.save_pap_plus(params)
      #     result  = {data: { pap_uid: current_pap._id.to_s }}
      #   rescue Exception => ex
      #     result = {status: 500, data: {messages: Common::Locale::i18n("papers.messages.save_paper.fail", :message => "#{ex.message}" )}}
      #   end
      #   return result
      # end

      # desc '"获取试卷" post /api/v1.3/papers/get_saved_paper' # save_paper begin
      # params do
      #   requires :pap_uid, type: String
      # end
      # post :get_saved_paper do   
      #   if !params[:pap_uid].blank?
      #     begin
      #       current_pap = Mongodb::BankPaperPap.get_pap params[:pap_uid]
      #       if current_pap
      #         result_h = JSON.parse(current_pap.paper_json)
      #         #此处暂做保留，之后删掉
      #         result_h["information"]["paper_status"] = current_pap.paper_status
      #         result_h["pap_uid"] = current_pap._id.to_s
      #         status = 200
      #         result = {status: 200, data: result_h}

      #       else
      #         error!({messages: Common::Locale::i18n("papers.messages.get_paper.paper_not_found")}, 404)
      #       end
      #     rescue Exception => ex 
      #       error!({messages: Common::Locale::i18n("papers.messages.get_paper.fail")}, 500)
      #       # result = {status: 500, data: Common::Locale::i18n("papers.messages.get_paper.fail")}
      #     end
      #   end
      #   result
      # end

      # desc '"提交试卷" post /api/v1.3/papers/submit_paper' # submit_paper begin
      # params do
      #   requires :pap_uid, type: String
      #   optional :orig_file_id, type: Integer
      #   requires :paper_html, type: String
      #   requires :answer_html, type: String
      #   requires :paper, type: Hash do
      #   end
      #   optional :bank_quiz_qizs, type: Array 
      #   requires :test, type: Hash
      #   optional :bank_node_catalogs, type: String
      # end
      # post :submit_paper do 
      #   begin
      #       #current_pap.current_user_id = current_user.id
      #       @paper = Mongodb::BankPaperPap.find(params[:pap_uid])
      #       @paper.current_user_id = current_user.id
      #       @paper.submit_pap_plus params
      #       @paper.generate_empty_score_file
      #       result = {data: {pap_uid: @paper._id.to_s}}
      #   rescue Exception => ex
      #     error!({messages: I18n.t("papers.messages.submit_paper.fail", :heading => ex.message)}, 500)
      #   end
      # end

      # desc '"提交试卷" post /api/v1.3/papers/save_analyze' # save_analyze begin
      # params do
      #   requires :pap_uid, type: String
      #   requires :paper, type: Hash 
      #   optional :bank_quiz_qizs, type: Array 
      # end
      # post :save_analyze do
      #   @paper = Mongodb::BankPaperPap.find(params[:pap_uid])
      #   begin
      #     @paper.save_ckp params
      #     result = {status: 200, messages: I18n.t("papers.messages.save_analyze.success", heading: @paper.heading)}
      #   rescue Exception => e
      #     result = error!({messages: I18n.t("papers.messages.save_analyze.fail", @paper.heading)},500)
      #   end
      # end

      # desc '"提交试卷" post /api/v1.3/papers/submit_analyze' # submit_analyze begin
      # params do
      #   requires :pap_uid, type: String
      #   requires :paper, type: Hash 
      #   optional :bank_quiz_qizs, type: Array 
      # end
      # post :submit_analyze do
      #   @paper = Mongodb::BankPaperPap.find(params[:pap_uid])
      #   begin
      #     @paper.submit_ckp_plus params
      #     result = {status: 200, messages: I18n.t("papers.messages.submit_analyze.success", heading: @paper.heading)}
      #   rescue Exception => e
      #     result = error!({messages: I18n.t("papers.messages.save_analyze.fail", @paper.heading)},500)
      #   end
      # end #submit_analyze end

      # desc '"文件下载" post /api/v1.3/papers/download' # submit_analyze begin
      # params do 
      #   requires :pap_uid, type: String
      #   requires :type, type: String, values: %w{paper answer revise_paper revise_answer empty_file empty_result filled_file usr_pwd_file}
      # end
      # post :download do
      #   @paper = Mongodb::BankPaperPap.find(params[:pap_uid])

      #   type = params[:type]
      #   return render nothing: true unless %w{paper answer revise_paper revise_answer empty_file empty_result filled_file usr_pwd_file}.include?(type)
       
      #   #修正试卷，修正答案需要进一步处理
      #   # 
      #   if %w{revise_paper revise_answer}.include?(type)
      #     head_html =<<-EOF
      #       <h2>#{@paper.heading}</h2>
      #       <h3>#{@paper.subheading}</h3>
           
      #       <p style="text-align:center">
      #         <span>（考试时长：</span><span style="color:#0000ff">#{@paper.quiz_duration}分钟</span><span>    卷面分值：</span><span style="color:#0000ff">#{@paper.score}</span>)
      #       </p>      
      #     EOF
      #     file = FileUpload.find(@paper.orig_file_id)  

      #     case type
      #     when "revise_paper"
      #       if file.revise_paper.blank? || !File.exists?(file.revise_paper.current_path)
      #         file = Common::PaperFile.generate_docx_by_html(file, head_html + @paper.paper_html, "#{@paper.id}_paper", type)
      #       end
      #     when "revise_answer"
      #       if file.revise_answer.blank? || !File.exists?(file.revise_answer.current_path)
      #         file = Common::PaperFile.generate_docx_by_html(file, head_html + @paper.answer_html, "#{@paper.id}_answer", type)
      #       end
      #     end
      #   end
      #   ###

      #   #文件对象
      #   file = nil
      #   if %w{filled_file usr_pwd_file empty_file}.include?(type)
      #     if @paper.score_file_id
      #       file = ScoreUpload.find(@paper.score_file_id) 
      #     else
      #       file = @paper.bank_tests[0].score_uploads.by_tenant_uid(params[:tenant_uid]).first
      #     end
      #   elsif %w{paper answer revise_paper revise_answer empty_result}.include?(type)
      #     file = FileUpload.find(@paper.orig_file_id)
      #   else
      #     # do nothing
      #   end

      #   #文件后缀名
      #   suffix = ""
      #   if %w{filled_file usr_pwd_file empty_file empty_result}.include?(type)
      #     suffix = ".xlsx"
      #   elsif %w{paper answer revise_paper revise_answer}.include?(type)
      #     suffix = ".doc"
      #   else
      #     # do nothing
      #   end

      #   #文件名，文件路径
      #   # file_name = params[:file_name] + suffix
      #   # file_path = file.send(type.to_sym).current_path
      #   file.send(type.to_sym)
      # end      

      # desc '"大纲列表" post /api/v1.3/papers/outline_list' # submit_analyze begin
      # params do
      #   requires :pap_uid, type: String
      # end
      # post :outline_list do
      #   @paper = Mongodb::BankPaperPap.find(params[:pap_uid])
      #   @paper.outline_list
      # end

      desc '"试卷指标题mapping" post /api/v1.2/papers/ckps_qzps_mapping' # submit_analyze begin
      params do
        requires :pap_uid, type: String
      end
      post :ckps_qzps_mapping do
        paper = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
        paper.associated_checkpoints
      end

      desc "获取试题列表"
      params do
        optional :page, type: Integer
        optional :rows, type: Integer
        optional :keyword, type: String
        optional :grade, type: String
        optional :category, type: String
      end
      get :get_list do
        papers = Mongodb::BankPaperPap.get_list_plus params
        result = {data: papers}
        if papers
          message_json_data("i00000", result)
        else
          error!(message_json("e40000"),500)
        end
      end

      desc "获取试题列表"
      params do
        optional :page, type: Integer
        optional :rows, type: Integer
        optional :keyword, type: String
        optional :grade, type: String
        optional :category, type: String
      end
      get :get_count do
        # total_count = Mongodb::BankPaperPap.get_count params
        # papers = Mongodb::BankPaperPap.get_list_plus params
        total_count = Mongodb::BankPaperPap.get_count params
        result = {total_count: total_count}
        if total_count
          message_json_data("i00000", result)
        else
          error!(message_json("e40000"),500)
        end
      end
        

      
      desc "获取试题信息信息"
      params do
        requires :pap_uid, type: String
      end
      get :detail do
        paper = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
        if paper
          result = {
            :paper_structure => JSON.parse(paper.paper_json)
          }
          message_json_data("i00000", result)
        else
          error!(message_json("e40000"),500)
        end 
      end

      desc "获取试卷详细信息"
      params do        
      end
      get :stat do
        subject_data = Common::Subject::List.keys.map {|subject|
          count =  Mongodb::BankPaperPap.by_subject(subject).count
          {Common::Locale::i18n("dict.#{subject}") => count } if count > 0
        }.compact!
        subject_code = {}
        subject_data.each {|s| subject_code.merge!(s)}
        result = {:stat => {
                    :total => Mongodb::BankPaperPap.count,
                    :by_status => {
                      :available => Mongodb::BankPaperPap.available.count,
                      :unavailable => Mongodb::BankPaperPap.unavailable.count,
                    },
                    :by_subject => subject_code
                    }
                  }
        if result[:stat][:total] > 0
          message_json_data("i00000", result)
        else
          error!(message_json("e40000"),500)
        end            
      end

      desc '删除试卷.'
      params do
        requires :pap_uid, type: String, desc: '试卷ID.'
      end
      delete ':pap_uid' do
        # authenticate!
        paper = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first
        if paper.present?
          if paper.destroy
            message_json("i43000")
          else
            error!(message_json("e43500"),500)
          end
        else
          error!(message_json("e43404"),404)
        end
      end
    end
  end
end