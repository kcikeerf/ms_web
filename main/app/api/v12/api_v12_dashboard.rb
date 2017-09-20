# -*- coding: UTF-8 -*-

module ApiV12Dashboard
  class API < Grape::API
    format :json

    helpers Doorkeeper::Grape::Helpers
    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper

    helpers do
      def get_test_detail_datagrid xue_duan, subject, test_id
        lastest_data = {}
        redis_key_prefix = "/lastest/#{xue_duan}/#{subject}/#{test_id}"
        if Common::SwtkRedis::has_key?(Common::SwtkRedis::Ns::Cache, redis_key_prefix)
          lastest_json = Common::SwtkRedis::get_value(Common::SwtkRedis::Ns::Cache, redis_key_prefix)
          lastest_data = JSON.parse(lastest_json)
        else
          bank_test = Mongodb::BankTest.where(_id: test_id).first
          lastest_data = {}
          lastest_data["basic"] = {}
          lastest_data["school"] = []
          path = "/reports_warehouse/tests/"
          top_group = bank_test.report_top_group.blank? ? "project" : bank_test.report_top_group
          optional_file = Dir[Dir::pwd + path + bank_test._id.to_s + '/' + top_group + "/*optional_abstract.json"]
          optional_file.each do |op|

            target_report_data = File.open(op, 'rb').read
            result = JSON.parse(target_report_data)
            # p result
            result["project"].each do |school|
              school_data = {}
              # data = {}

              # base_data =  school[1]["report_data"]["data"]["knowledge"]["base"] if school[1]["report_data"]
              # if base_data
              #   data["diff_degree"] =  base_data["diff_degree"]
              #   data["excellent_percent"] =  base_data["excellent_percent"]
              #   data["excellent_pupil_number"] =  base_data["excellent_pupil_number"]
              #   data["good_percent"] =  base_data["good_percent"]
              #   data["good_pupil_number"] =  base_data["good_pupil_number"]
              #   data["level0_pupil_number"] =  base_data["level0_pupil_number"]
              #   data["level25_pupil_number"] =  base_data["level25_pupil_number"]
              #   data["level25_weights_score_average_percent"] =  base_data["level25_weights_score_average_percent"]
              #   data["level25_weights_score_average_percent_total"] =  base_data["level25_weights_score_average_percent_total"]
              #   data["level50_pupil_number"] =  base_data["level50_pupil_number"]
              #   data["project_median_percent"] =  base_data["project_median_percent"]
              #   data["pupil_number"] =  base_data["pupil_number"]
              #   data["score_average"] =  base_data["score_average"]
              #   data["score_average_percent"] =  base_data["score_average_percent"]
              #   data["total_full_score"] =  base_data["total_full_score"]
              #   data["total_qzp_correct_count"] =  base_data["total_qzp_correct_count"]
              #   data["total_qzp_correct_percent"] =  base_data["total_qzp_correct_percent"]
              #   data["total_qzp_count"] =  base_data["total_qzp_count"]
              #   data["total_real_score"] =  base_data["total_real_score"]
              #   data["score_average"] =  base_data["score_average"]
              #   data["score_average_percent"] =  base_data["score_average_percent"]
              # end
              report_data = school[1]["report_data"].present? ?  school[1]["report_data"] : {"basic" => {}, "data" => {}} 
              lastest_data["basic"] = report_data["basic"]
              school_data["basic"] = {
                "school_name" => lastest_data["basic"]["school"]
              }
              lastest_data["basic"].delete("school")
              school_data["data"] = report_data["data"]
              lastest_data["school"] << school_data
            end
          end
          Common::SwtkRedis::set_key(Common::SwtkRedis::Ns::Cache, redis_key_prefix , lastest_data.to_json)
        end
        return lastest_data
      end

    end


    params do
      use :oauth
    end

    resource :dashboard do #checkpoints begin
      before do
        set_api_header
        doorkeeper_authorize!
        # authenticate_api_permission current_user.id, request.request_method, request.fullpath
      end

      params do
      end
      post :get_overall_info do
        target_user = current_user
        target_tenant_ids = target_user.accessable_tenants.map(&:uid).uniq.compact
        target_test_ids = Mongodb::BankTestTenantLink.where(tenant_uid: {"$in" => target_tenant_ids} ).map(&:bank_test_id).uniq.compact
        target_pap_ids = Mongodb::BankTest.where(id: {"$in" => target_test_ids} ).map(&:bank_paper_pap_id).uniq.compact
        target_papers = Mongodb::BankPaperPap.where(id: {"$in" => target_pap_ids}, paper_status: "report_completed").only(:id,:heading,:paper_status,:subject,:quiz_type,:quiz_date,:score, :grade)
        target_papers.compact!
        target_papers.uniq!
        begin          
          unless target_papers.blank?
            _rpt_type, _rpt_id = Common::Uzer::get_user_report_type_and_id_by_role(target_user)
            paper_info_array = []
            target_papers.each {|target_pap|
              bank_test = target_pap.bank_tests[0]
              test_id = bank_test.id.to_s
              test_ext_data_path = target_pap.bank_tests[0].ext_data_path
              rpt_type = _rpt_type || Common::Report::Group::Project
              rpt_id = (_rpt_type == Common::Report::Group::Project)? test_id : _rpt_id
              report_url = Common::Report::get_test_report_url(test_id, rpt_type, rpt_id)

              paper_info_hash = {
                :paper_uid => target_pap.id.to_s,
                :quiz_date => target_pap.quiz_date.strftime('%Y/%m/%d'),
                :quiz_type => Common::Locale::i18n("dict.#{target_pap.quiz_type}"),
                :report_url => "/api/v1.2" + report_url,
                :report_version => "00016110",
                :score => target_pap.score,
                :test_ext_data_path => test_ext_data_path,
                :test_id => test_id,
                :paper_heading => target_pap.heading,
                :subject => target_pap.subject,
                :subject_cn => Common::Locale::i18n("dict.#{target_pap.subject}")
              }
              bank_test_state = bank_test.bank_test_state
              stats =  {}
              stats = {
                  total: bank_test_state.total_num,
                  project: bank_test_state.project_num,
                  grade: bank_test_state.grade_num,
                  klass: bank_test_state.klass_num,
                  pupil: bank_test_state.pupil_num
              } if bank_test_state
              paper_info_hash[:xue_duan] = Common::Grade.judge_xue_duan target_pap.grade if target_pap.grade
              paper_info_hash[:xue_duan_cn] = Common::Locale::i18n("checkpoints.subject.category.#{ Common::Grade.judge_xue_duan target_pap.grade }") if target_pap.grade
              paper_info_hash[:stats] = stats
              paper_info_array << paper_info_hash
            }
            paper_info_array.sort! {|p1,p2| p2[:quiz_date] <=> p1[:quiz_date]}

            paper_sort_by_date = {}
            paper_sort_lastest = {}
            Common::Grade::XueDuan::List.keys.each {|xue_duan| 
              paper_sort_by_date[xue_duan.to_s] = {}
              paper_sort_lastest[xue_duan.to_s] = {}
              Common::Subject::List.keys.each {|subject|
                paper_sort_by_date[xue_duan.to_s][subject.to_s] = []
                paper_sort_lastest[xue_duan.to_s][subject.to_s] = []
               }
            }
            paper_info_array.each {|paper|
              paper_sort_by_date[paper[:xue_duan]][paper[:subject]] << paper           
              paper_sort_lastest[paper[:xue_duan]][paper[:subject]] << paper  if paper_sort_lastest[paper[:xue_duan]][paper[:subject]].blank?     
            }
            result = {}
            result["result"] = {}
            result["global"] = {}
            result["blocks"] = {}
            paper_sort_by_date.each do |xue_duan_obj|

              stats = {}
              lastest = {}
              xue_duan_en = Common::Grade::XueDuan.get_xue_duan_en xue_duan_obj[0]
              xue_duan_en_report = xue_duan_en + "_report"
              report_list = {}
              total_all, total_lastest = 0,0
              project_all, project_lastest = 0,0
              grade_all, grade_lastest = 0,0
              klass_all, klass_lastest = 0,0
              pupil_all, pupil_lastest = 0,0
              xue_duan_obj[1].each do |subject_obj|
                subject_en = Common::Subject.get_subject_en subject_obj[0]
                report_list[subject_en] = subject_obj[1]
                if subject_obj[1]
                  subject_obj[1].each do |pap| 
                    stats_hash =  pap[:stats] 
                    total_all += stats_hash[:total]
                    project_all += stats_hash[:project]
                    grade_all += stats_hash[:grade]
                    klass_all += stats_hash[:klass]
                    pupil_all += stats_hash[:pupil]
                  end
                  if subject_obj[1][-1]
                    last = subject_obj[1][-1][:stats]
                    # p last
                    total_lastest += last[:total]
                    project_lastest += last[:project]
                    grade_lastest += last[:grade]
                    klass_lastest += last[:klass]
                    pupil_lastest += last[:pupil]
                  end
                end
                # report_list
              end
              overall = {
                total: total_all,
                project: project_all,
                grade: grade_all,
                klass: klass_all,
                pupil: pupil_all
              }
              lastest = {
                total: total_lastest,
                project: project_lastest,
                grade: grade_lastest,
                klass: klass_lastest,
                pupil: pupil_lastest
              }
              stats["overall"] = overall
              stats["lastest"] = lastest
              result["blocks"][xue_duan_en_report] = {}
              result["blocks"][xue_duan_en_report]["stats"] = stats
              result["blocks"][xue_duan_en_report]["report_list"] = report_list
            end
            paper_sort_lastest.each { |xue_duan_obj|
              xue_duan_en = Common::Grade::XueDuan.get_xue_duan_en xue_duan_obj[0]
              xue_duan_en_base = xue_duan_en + "_base"
              result["blocks"][xue_duan_en_base] = {}
              base_list = {}
              xue_duan_obj[1].each { |subject_obj|
                if subject_obj[1].present?
                  subject_en = Common::Subject.get_subject_en subject_obj[0]
                  report_detail = get_test_detail_datagrid xue_duan_obj[0], subject_obj[0], subject_obj[1][0][:test_id]
                  result["blocks"][xue_duan_en_base][subject_en] = report_detail
                end
              }
            } 
            result
          end
        rescue Exception => e
          error!({code: "e40003", message: I18n.t("api.#{e40003}", message: e.message)}, 500)
        end
      end  

    end

  end
end