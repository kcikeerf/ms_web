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
        base_key = "/lastest/#{xue_duan}/#{subject}" 

        redis_key_prefix = base_key + "/#{test_id}"
        if Common::SwtkRedis::has_key?(Common::SwtkRedis::Ns::Cache, redis_key_prefix)
          lastest_json = Common::SwtkRedis::get_value(Common::SwtkRedis::Ns::Cache, redis_key_prefix)
          lastest_data = JSON.parse(lastest_json)
        else
          bank_test = Mongodb::BankTest.where(_id: test_id).first
          lastest_data = {}
          lastest_data["basic"] = {}
          lastest_data["school"] = []
          path = Common::Report::WareHouse::ReportLocation + "reports_warehouse/tests/"
          top_group = bank_test.report_top_group.blank? ? "project" : bank_test.report_top_group
          optional_file = Dir[path + bank_test._id.to_s + '/' + top_group + "/*optional_abstract.json"] #服务器
          # optional_file = Dir[Dir::pwd + path + bank_test._id.to_s + '/' + top_group + "/*optional_abstract.json"] #本地
          optional_file.each do |op|

            target_report_data = File.open(op, 'rb').read
            result = JSON.parse(target_report_data)
            # p result
            result.values[0].each do |school|
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
                "school_name" => lastest_data["basic"]["school"],
                "school_uid" => school[1]["uid"]
              }
              lastest_data["basic"].delete("school")
              school_data["data"] = report_data["data"]
              lastest_data["school"] << school_data
            end
          end
          lastest_data["school"].sort! {|p1,p2| p2["basic"]["school_uid"] <=> p1["basic"]["school_uid"]}
          if lastest_data["basic"].present?
            area_report = Dir[path + bank_test._id.to_s + '/' + top_group + "/" + bank_test._id.to_s + ".json"] #服务器
            # area_report = Dir[Dir::pwd + path + bank_test._id.to_s + '/' + top_group + "/" + bank_test._id.to_s + ".json"] #本地
            area_report.each do |ar|
              area_report_data = File.open(ar, 'rb').read
              area_json_data = JSON.parse(area_report_data)
              lastest_data["basic"]["area_data"] = area_json_data["data"]["knowledge"]["base"]
            end
            Common::SwtkRedis::del_keys Common::SwtkRedis::Ns::Cache, base_key
            Common::SwtkRedis::set_key(Common::SwtkRedis::Ns::Cache, redis_key_prefix , lastest_data.to_json)
          end 
        end
        return lastest_data
      end


      def get_union_test_datail_datagrid xue_duan, union_test_id
        union_test = Mongodb::UnionTest.where(_id: union_test_id).first
        result = {}
        if union_test
          bank_papers = union_test.bank_tests
          result["basic"] = { :bank_union_test_uid => union_test_id }
          bank_tests.each { |bank_test|
            pap = bank_test.bank_paper_pap
            subject_en = Common::Subject.get_subject_en pap.subject
            # bank_test = pap.bank_tests[0]
            test_id = bank_test.id.to_s
            test_ext_data_path = bank_test.ext_data_path
            report_detail = get_test_detail_datagrid xue_duan, pap.subject, test_id
            result[subject_en] = report_detail
            result[subject_en]["basic"]["test_ext_data_path"] = test_ext_data_path
          }
        end
        return result   
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
      #获取局长的报告内容
      params do
      end
      post :get_overall_info do
        target_user = current_user
        target_tenant_ids = target_user.accessable_tenants.map(&:uid).uniq.compact
        target_test_ids = Mongodb::BankTestTenantLink.where(tenant_uid: {"$in" => target_tenant_ids} ).map(&:bank_test_id).uniq.compact
        target_tests = Mongodb::BankTest.where(_id: {"$in" => target_test_ids}).where(test_status: "report_completed")
        # target_pap_ids = Mongodb::BankTest.where(id: {"$in" => target_test_ids} ).map(&:bank_paper_pap_id).uniq.compact
        # target_papers = Mongodb::BankPaperPap.where(id: {"$in" => target_pap_ids}, paper_status: "report_completed").only(:id,:heading,:paper_status,:subject,:quiz_type,:quiz_date,:score, :grade, :union_test_id)
        # target_papers.compact!
        # target_papers.uniq!
        begin          
          # unless target_papers.blank?
            _rpt_type, _rpt_id = Common::Uzer::get_user_report_type_and_id_by_role(target_user)
            paper_info_array = []
            target_tests.each {|bank_test|
              # bank_test = target_pap.bank_tests[0]
              test_id = bank_test._id.to_s
              test_ext_data_path = bank_test.ext_data_path
              rpt_type = _rpt_type || Common::Report::Group::Project
              rpt_id = (_rpt_type == Common::Report::Group::Project)? test_id : _rpt_id
              report_url = Common::Report::get_test_report_url(test_id, rpt_type, rpt_id)
              target_pap = bank_test.bank_paper_pap
              next if target_pap.blank?
              paper_info_hash = {
                :paper_uid => target_pap.id.to_s,
                :quiz_date => target_pap.quiz_date.strftime('%Y/%m/%d'),
                :quiz_type => Common::Locale::i18n("dict.#{target_pap.quiz_type}"),
                :report_url => "/api/v1.2" + report_url,
                :report_version => "00016110",
                :score => target_pap.score,
                :test_ext_data_path => test_ext_data_path,
                :test_id => test_id,
                :union_test_uid => bank_test.union_test_id.to_s,
                :paper_heading => target_pap.heading,
                :subject => target_pap.subject,
                :subject_cn => Common::Locale::i18n("dict.#{target_pap.subject}")
              }
              bank_test_state = bank_test.bank_test_state
              stats =  {}
              stats = {
                  total: bank_test_state.total_num || 0,
                  project: bank_test_state.project_num || 0,
                  grade: bank_test_state.grade_num || 0,
                  klass: bank_test_state.klass_num || 0,
                  pupil: bank_test_state.pupil_num || 0
              }
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
              xue_duan_pap_arr = paper_info_array.select {|pap| pap if pap[:xue_duan] == xue_duan_obj[0]}.sort! {|p1,p2| p2[:quiz_date] <=> p1[:quiz_date]}
              last_union_test_uid = nil
              if xue_duan_pap_arr[0]
                last_union_test_uid = xue_duan_pap_arr[0][:union_test_uid]
              end
              if last_union_test_uid.present?
                union_test_data = get_union_test_datail_datagrid xue_duan_obj[0], last_union_test_uid.to_s
                result["blocks"][xue_duan_en_base] = union_test_data
              else
                result["blocks"][xue_duan_en_base]["basic"] = { :bank_union_test_uid => nil}
                xue_duan_obj[1].each { |subject_obj|
                  if subject_obj[1].present?
                    subject_en = Common::Subject.get_subject_en subject_obj[0]
                    report_detail = get_test_detail_datagrid xue_duan_obj[0], subject_obj[0], subject_obj[1][0][:test_id]
                    result["blocks"][xue_duan_en_base][subject_en] = report_detail
                    result["blocks"][xue_duan_en_base][subject_en]["basic"]["test_ext_data_path"] = subject_obj[1][0]["test_ext_data_path"]
                  end
                }
              end
            } 
            result
          # end
        rescue Exception => e
          p e.backtrace
          error!({code: "e40003", message: I18n.t("api.#{'e40003'}", message: e.message)}, 500)
        end
      end  

    end

  end
end