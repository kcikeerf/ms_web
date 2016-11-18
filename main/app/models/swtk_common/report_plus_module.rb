# -*- coding: UTF-8 -*-

require 'thwait'

module ReportPlusModule
  module ReportPlus
    module_function

    # houkoku umareta
    _Default = {
      "basic" => {
        "area" => "",
        "school" => "",
        "grade" => "",
        "classroom" =>"",
        "subject" => "",
        "name" => "",
        "sex" => "",          
        "levelword2" => "",
        "quiz_date" => "",
        "score" => 0
      },
      "config" => {
        "value_ratio" => {
          "knowledge" => 1,
          "skill" => 1,
          "ability" => 1
        }
      },
      "data" => {
        "knowledge"=> {},
        "skill"=> {},
        "ability"=> {}
      },
      "paper_qzps" => [],
      "comment" => {
        "version1.0" => Common::CheckpointCkp::dimesions_loop {
          {
            "self_best" => [],
            "self_worst" => [],
            "self_ability" => [],
            "self_weights_score_average_percent" => 0,
            "self_weights_score_average_percent_level" => "",
            "self_excellent_pupil_number_percent" => 0,
            "self_good_pupil_number_percent" => 0,
            "self_failed_pupil_number_percent" => 0
          }
        }
      }
    }

    # 处理移至前端，此处略过
    # def report_group_info_items target_h, group_type
    #   Common::CheckpointCkp::dimesions_loop {|dimesion|
    #     groups_h = { "group" => {} }
    #     start_index = Common::Report::Group::ListArr.find_index(group_type)
    #     Common::Report::Group::ListArr[start_index..-1].each{|t| 
    #       groups_h["group"][t] = {
    #         "in_group_best" => [],
    #         "in_group_worst" => [],
    #         "in_group_weights_score_average_percent_level" => "",
    #         "in_group_excellent_pupil_number_percent_level" => 0,
    #         "in_group_good_pupil_number_percent_level" => 0,
    #         "in_group_failed_pupil_number_percent_level" => 0
    #       }  
    #     }
    #     target_h[dimesion].merge!(groups_h)
    #   }
    #   return nil
    # end

    PupilHoukoku = _Default.deep_dup
    # _ = report_group_info_items PupilHoukoku['comment']['version1.0'], "pupil"
    KlassHoukoku = _Default.deep_dup
    # _ = report_group_info_items KlassHoukoku['comment']['version1.0'], "klass"
    GradeHoukoku = _Default.deep_dup
    # _ = report_group_info_items GradeHoukoku['comment']['version1.0'], "grade"
    ProjectHoukoku = _Default.deep_dup
    # _ = report_group_info_items ProjectHoukoku['comment']['version1.0'], "project"

    def logger
      Rails.logger
    end

    # def report_nav_menus current_group

    # end

    def report_nav_menus args #user_id, test_id, top_group
      result = [{
        :key => "",
        :label => "",
        :report_url => "",
        :data_type=> "",
        :items => []
      }]
      # target_user = User.where(id: args[:user_id]).first
      target_test = Mongodb::BankTest.where( id: args[:test_id] ).first
      return result unless target_test
      target_tenants = target_test.tenants.sort{|a,b| Common::compare_eng_num_str(a.name,b.name) }
      return result if target_tenants.blank?

      report_url_prefix = "/reports_warehouse/tests/#{args[:test_id]}/#{Common::Report::Group::Project}/"
      report_path_prefix = Common::Report::WareHouse::ReportLocation + report_url_prefix
      report_file_name_regex = /^[0-9].*(.json)$/

      # if target_user.is_project_administrator? && args[:top_group] == Common::Report::Group::Project
      if args[:top_group] == Common::Report::Group::Project
        result = [{
          :key => "root",
          :label => "Project",
          :report_url => report_url_prefix + "#{args[:test_id]}.json",
          :data_type=> Common::Report::Group::Project,
          :items => []
        }]
      end

      report_url_prefix += "#{args[:test_id]}/"
      report_path_prefix += "#{args[:test_id]}/"
      target_tenants.each{|tnt|
        tnt_uid = tnt.uid
        report_tnt_uids = Dir.entries( report_path_prefix + Common::Report::Group::Grade ).find_all{|a| a =~ report_file_name_regex }.map{|a| a.gsub(".json", "")}
        next unless report_tnt_uids.include?(tnt_uid)
        tnt_h = {
          :key => tnt.uid,
          :label => tnt.name_cn,
          :report_url => report_url_prefix + Common::Report::Group::Grade + "/#{tnt.uid}.json",
          :data_type=> Common::Report::Group::Grade.downcase,
          :items => []
        }
        locations = tnt.locations.sort{|a,b| Common::Locale.mysort(Common::Klass::Order[a.classroom],Common::Klass::Order[b.classroom]) }
        locations.each{|loc|
          report_loc_uids = Dir.entries( report_path_prefix + Common::Report::Group::Grade + "/#{tnt.uid}/" + Common::Report::Group::Klass ).find_all{|a| a =~ report_file_name_regex }.map{|a| a.gsub(".json", "")}
          next unless report_loc_uids.include?(loc.uid)
          klass_label = Common::Klass::List.keys.include?(loc.classroom.to_sym) ? Common::Locale::i18n("dict.#{loc.classroom}") : loc.classroom
          loc_h = {
            :key => loc.uid,
            # :label => klass_label + Common::Locale::i18n("page.reports.report"),
            :label => klass_label,
            :report_url => report_url_prefix + Common::Report::Group::Grade + "/#{tnt.uid}/"+ Common::Report::Group::Klass + "/#{loc.uid}.json",
            :data_type=> Common::Report::Group::Klass.downcase,
            :items => []
          }
          pupils = loc.pupils.sort{|a,b| Common::Locale.mysort a.stu_number,b.stu_number}
          pupils.each{|pup|
            report_pup_uids = Dir.entries( report_path_prefix + Common::Report::Group::Grade + "/#{tnt.uid}/" + Common::Report::Group::Klass + "/#{loc.uid}/" + Common::Report::Group::Pupil ).find_all{|a| a =~ report_file_name_regex }.map{|a| a.gsub(".json", "")}
            next unless report_pup_uids.include?(pup.uid)
            pup_h = {
              :key => pup.uid,
              :label => pup.name,
              :report_url => report_url_prefix + Common::Report::Group::Grade + "/#{tnt.uid}/" + Common::Report::Group::Klass + "/#{loc.uid}/" + Common::Report::Group::Pupil + "/#{pup.uid}.json",
              :data_type=> Common::Report::Group::Pupil.downcase,
              :items => []
            }
            loc_h[:items] << pup_h
          }
          tnt_h[:items] << loc_h
        }
        # if target_user.is_project_administrator? && args[:top_group] == Common::Report::Group::Project
        if args[:top_group] == Common::Report::Group::Project.downcase
          result[0][:items] << tnt_h
        else
          result = [tnt_h]
          break
        end
      }
      return result
    end

    # qzp ckp mapping syutoku no tame
    def data_qzps_ckps_mapping test_id,ckp_level
      result = []
      return result if (ckp_level < 1) && test_id.blank?
      target_test = Mongodb::BankTest.where(id: test_id ).first
      target_paper = target_test.bank_paper_pap
      result = target_paper.qzps_checkpoints_mapping ckp_level
      return result
    end

    # ckp qzp mapping syutoku no tame
    def data_ckps_qzps_mapping test_id,ckp_level
      result =  Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      return result if (ckp_level < 1) && test_id.blank?
      target_test = Mongodb::BankTest.where(id: test_id ).first
      target_paper = target_test.bank_paper_pap
      ckps_qzps_mapping = target_paper.associated_checkpoints
      Common::CheckpointCkp.ckp_types_loop {|dimesion|
        result[test_id][dimesion]["base"] = {}
        # matu reberu no mae no subete
        if ckp_level.between?(Common::Report::CheckPoints::DefaultLevelFrom, Common::Report::CheckPoints::DefaultLevelTo)  
          ckp_levels = [*Common::Report::CheckPoints::DefaultLevelFrom..ckp_level]
          mapping_items = data_ckps_qzps_mapping_nakmi_no_kumitate(ckps_qzps_mapping[dimesion], ckp_levels)
          result[test_id][dimesion]["lv_n"] = mapping_items.values[0]["items"]
        end
        # matu reberu
        if ckp_level > Common::Report::CheckPoints::DefaultLevelEnd
          lv_collect = ckps_qzps_mapping[dimesion].find_all{|item| item[:is_entity] == true }
          result[test_id][dimesion]["lv_end"] = lv_collect.map{|item|  # lv_collect loop
            data_ckps_qzps_mapping_nakami_no_kouzou item
          } # lv_collect loop
        end
      }
      return result
    end

    def data_ckps_qzps_mapping_nakmi_no_kumitate target_collect, ckp_level_arr=[], parent={"root"=>{"order"=>"", "items"=>[]}}
      result = parent
      return result if ckp_level_arr.blank?
      target_level = result.values[0]["order"].size/Common::SwtkConstants::CkpStep + 1
      return result unless ckp_level_arr.include?(target_level)
      lv_regex = Regexp.new "^(#{result.values[0]["order"]})[0-z]{#{Common::SwtkConstants::CkpStep}}$"
      current_range = target_collect.find_all{|item| item[:rid] =~ lv_regex }
      current_range.each{|item|
        format_item = data_ckps_qzps_mapping_nakami_no_kouzou item
        result.values[0]["items"] << data_ckps_qzps_mapping_nakmi_no_kumitate(target_collect, ckp_level_arr, format_item)
      }
      return result
    end

    def data_ckps_qzps_mapping_nakami_no_kouzou item
      {
        item[:uid] => {
          "order" => item[:order],
          "rid" => item[:rid],
          "checkpoint" => item[:checkpoint],
          #:advice => item[:advice],
          "items" => []
        }
      }
    end

    def data_hash_naka_no_ckp_o_sagasu target_h, target_ckp_uid, target_ckp_level
      target_ckp = target_h.find{|item| item.keys.include?(target_ckp_uid)}
      return target_ckp unless target_ckp.blank?
      target_ckp_level -= 1
      return nil if target_ckp_level < 1

      next_target_h = target_h.map{|item| item.values[0]["items"]}.flatten
      data_hash_naka_no_ckp_o_sagasu next_target_h, target_ckp_uid, target_ckp_level
    end

    def data_hash_naka_no_level_ckps_o_syutoku target_h, target_ckp_level
      target_ckp_level -= 1
      return target_h if target_ckp_level < 1

      next_target_h = target_h.map{|item| item.values[0]["items"]}.flatten
      data_hash_naka_no_level_ckps_o_syutoku next_target_h, target_ckp_level
    end

    def redis_atai_no_yomidasi_template(_redis_ns, _redis_key_arr, _value_h={}, &block)
      result = nil, {}
      redis_key = Common::SwtkRedis::Prefix::Reports + _redis_key_arr.compact.join("/")
      has_redis_key = Common::SwtkRedis::has_key?(_redis_ns, redis_key)
      if has_redis_key
        begin
          result = JSON.parse(Common::SwtkRedis::get_value(_redis_ns, redis_key))
        rescue Exception => ex
          logger.debug "#{__method__.to_s()}>>>ex.message"
        end
      else
        value_h = yield(_value_h)
        return redis_key, {} if value_h.blank? 
        Common::SwtkRedis::set_key(_redis_ns, redis_key, value_h.to_json)
        result = value_h
      end
      return redis_key, result
    end

    def redis_model_data_yomidasi_template(_redis_ns, _args, &block)
      result = {}
      target_model = _args[:model]
      target_params = _args[:params] #{uid: 12345} | {id: 12345}
      redis_key = Common::SwtkRedis::Prefix::Reports + target_model + "/" + target_params.values[0]
      has_redis_key = Common::SwtkRedis::has_key?(_redis_ns, redis_key)
      if has_redis_key
        begin
          result = JSON.parse(Common::SwtkRedis::get_value(_redis_ns, redis_key))
        rescue Exception => ex
          logger.debug "#{__method__.to_s()}>>>ex.message"
        end
      else
        value_h = yield(_args)
        value_h = {} if value_h.blank?
        Common::SwtkRedis::set_key(_redis_ns, redis_key, value_h.to_json)
        result = value_h
      end
      return result
    end

    def koutiku_method_template(from_where, &block)
      logger.debug(">>>>>>#{from_where}: begin<<<<<<<")
      begin
        yield
      rescue Exception => ex
        logger.debug ">>>Exception!<<<"
        logger.debug ex.message
        logger.debug ex.backtrace
      end
      logger.debug(">>>>>>#{from_where}: end<<<<<<<")
    end

    # houkoku sigoto no siwake
    def sigoto_siwake args
      koutiku_method_template(__method__.to_s()) {
        stage_groups = []
        target_test = Mongodb::BankTest.where(id: args[:test_id]).first
        tenants = target_test.tenants
        tenant_uids = tenants.map{|tnt| tnt.uid }
        locations = tenants.map{|tnt| tnt.locations }.flatten
        loc_uids = locations.map{|loc| loc.uid}

        end_index = Common::Report::Group::ListArr.find_index(args[:top_group].capitalize)
        group_arr = Common::Report::Group::ListArr[1..end_index]

        stage_groups << [
          _job_pair(
            Common::Job::Type::GeneratePupilReports,
            "GeneratePupilReportsJob",
            args[:test_id],
            args[:task_uid], 
            Common::Report::Group::Pupil,
            {:test_id => args[:test_id]})
        ]

        stage_groups << Common::Report::Group::ListArr[1..end_index].map{|group|
          _job_pair(
            Common::Job::Type::GenerateGroupReports,
             "GenerateGroupReportsJob", 
            args[:test_id], 
            args[:task_uid], 
            group,
            {:test_id => args[:test_id]})
        }

        stage_groups << Common::Report::Group::ListArr[0..end_index].map{|group|
          _job_pair(
            "ConstructReportsRound1Job",
            "ConstructReportsRound1Job", 
            args[:test_id], 
            args[:task_uid], 
            group,
            {:test_id => args[:test_id]})
        }

        stage_groups << Common::Report::Group::ListArr[0..end_index].map{|group|
          _job_pair(
            "ConstructReportsRound2Job",
            "ConstructReportsRound2Job", 
            args[:test_id], 
            args[:task_uid], 
            group,
            {:test_id => args[:test_id]})
        }

        Common::Report::Group::ListArr[0..end_index].reverse.each{|group|
          stage_groups << [_job_pair(
            "ConstructReportsRound3Job",
            "ConstructReportsRound3Job", 
            args[:test_id], 
            args[:task_uid], 
            group,
            {:test_id => args[:test_id]})
          ]
        }


        # # gakusei keisan
        # stage_groups << loc_uids.map{|loc_uid|
        #   _job_pair(
        #     Common::Job::Type::GeneratePupilReports,
        #      "GeneratePupilReportsJob", 
        #     target_test.id.to_s, 
        #     args[:task_uid], 
        #     Common::Report::Group::Pupil,
        #     {:loc_uids => [loc_uid]})
        # }

        # # kumi goto ni keisan
        # stage_groups << group_arr.map{|group|
        #   tenant_uids.map{|tenant_uid|
        #     _job_pair(
        #       Common::Job::Type::GenerateGroupReports,
        #        "GenerateGroupReportsJob", 
        #       target_test.id.to_s, 
        #       args[:task_uid], 
        #       group,
        #       {:tenant_uids => [tenant_uid]})
        #   }
        # }.flatten

        # # kumi(gakusei mo) koutiku
        # [*1..3].each{|index|
        #   arr = []
        #   arr = [Common::Report::Group::Pupil, Common::Report::Group::Klass].map{|group_type|
        #     loc_uids.map{|loc_uid|
        #       _job_pair(
        #         Common::Job::Type::ConstructReports,
        #         "ConstructReportsRound#{index}Job",
        #         target_test.id.to_s,
        #         args[:task_uid], 
        #         group_type,
        #         {:loc_uids => [loc_uid]})
        #     }
        #   } + tenant_uids.map{|loc_uid|
        #       _job_pair(
        #         Common::Job::Type::ConstructReports,
        #         "ConstructReportsRound#{index}Job",
        #         target_test.id.to_s,
        #         args[:task_uid], 
        #         Common::Report::Group::Grade,
        #         {:loc_uids => [loc_uid]})
        #   } + [_job_pair(
        #         Common::Job::Type::ConstructReports,
        #         "ConstructReportsRound#{index}Job",
        #         target_test.id.to_s,
        #         args[:task_uid], 
        #         Common::Report::Group::Project)]
        #   if index == 3
        #     stage_groups << arr.reverse.flatten
        #   else
        #     stage_groups << arr.flatten
        #   end
        # }
        return stage_groups

      }
    end

    def _job_pair _job_type, _job_class, _test_id, _task_uid, _group_type, _range_conditions = {}
      job_tracker = JobList.new({
        :name => _job_class + "_#{_group_type}",
        :task_uid => _task_uid,
        :job_type => _job_type,
        :status => Common::Job::Status::NotInQueue,
        :process => 0
      })
      job_tracker.save!
      return {
        :job_class => _job_class,
        :job_params => {
          :job_uid => job_tracker.uid,
          :test_id => _test_id,
          :group_type => _group_type.downcase
        }.merge(_range_conditions)
      }
    end

    # houkoku kumitate no hazime
    def kumitate_no_hazime args
      # job_uid = args[:job_uid] || nil
      is_pupil = is_klass = is_grade = is_project = false
      case args[:group_type]
      when Common::Report::Group::Pupil
        is_pupil = true
        group_key = "_id.pup_uid"
      when Common::Report::Group::Klass
        is_klass = true
        group_key = "_id.loc_uid"
      when Common::Report::Group::Grade
        is_grade = true
        group_key = "_id.tenant_uid"
      when Common::Report::Group::Project
        is_project = true
        group_key = "_id.test_id"
      end

      # 范围Filter处理
      range_filter = {}
      if !args[:pup_uids].blank? && is_pupil
        # 指定学生范围filter
        range_filter[:pup_uid] = {"$in" => args[:pup_uids]}
      elsif !args[:loc_uids].blank? && ( is_pupil || is_klass )
        # 指定班级范围
        range_filter['_id.loc_uid'] = {"$in" => args[:loc_uids]}
      elsif !args[:tenant_uids].blank? && ( is_pupil || is_klass || is_grade )
        # 指定Tenant范围
        range_filter['_id.tenant_uid'] = {"$in" => args[:tenant_uids]}
      elsif !args[:area_rid].blank? && ( is_pupil || is_klass || is_grade || is_project )
        # 指定某一地区
        area_regex = Regexp.new "^#{args[:area_rid]}"
        range_filter['_id.area_rid'] = {"$regex" => area_regex}
      else
        # do nothing
      end

      # test range
      range_filter['_id.test_id'] = args[:test_id]

      # checkpoint level
      ckp_level = args[:ckp_level].blank?? Common::Report::CheckPoints::DefaultLevel : args[:ckp_level].to_i
      order_ckp_level = args[:order_ckp_level].blank?? ckp_level : args[:order_ckp_level]

      # redis cache NameSpace
      redis_ns = Common::SwtkRedis::Ns::Sidekiq

      # paper checkpoint
      # _, papers_ckps_qzps_mapping = redis_atai_no_yomidasi_template(redis_ns, [args[:test_id], "ckps_qzps_mapping"]){
      #   ckps_qzps_mapping = Common::ReportPlus::data_ckps_qzps_mapping(args[:test_id], ckp_level)
      #   ckps_qzps_mapping
      # }
      return redis_ns, args[:test_id], args[:group_type], range_filter, ckp_level, order_ckp_level, group_key#, papers_ckps_qzps_mapping
    end

    # houkoku kumitate no owari syori
    def kumitate_no_owari _redis_ns, _test_id, _reports_in_mem
      # redis o kesu
      report_redis_key_wildcard = Common::SwtkRedis::Prefix::Reports + "tests/#{_test_id}/*"

      # group reports
      #_collect_type_redis_key = job_redis_key + "/#{_collect_type}"

      report_redis_keys = Common::SwtkRedis::find_keys(_redis_ns, report_redis_key_wildcard)
      report_redis_keys.each{|report|
        arr = report.split("/")
        Common::Report::WareHouse::store_report_json(
          Common::Report::WareHouse::ReportLocation + arr[1..-2].join("/"), 
          arr[-1],
          Common::SwtkRedis::get_value(_redis_ns, report)
        )
      }

      _reports_in_mem.each{|k,v|
        arr = k.split("/")
        Common::Report::WareHouse::store_report_json(
          Common::Report::WareHouse::ReportLocation + arr[1..-2].join("/"), 
          arr[-1],
          v.to_json
        )
      }

      # version1.1删除测试所有
      #Common::SwtkRedis::del_keys(_redis_ns, report_redis_key_wildcard)
    end

    # houkoku no kumitate no tame
#    def iti_kumigoto_no_kihon_koutiku_kyoutuu_syori _redis_ns, _job_uid, _collect_type, _range_filter, _ckp_level, _order_ckp_level, _group_key
    def iti_kumigoto_no_kihon_koutiku_kyoutuu_syori args
      _redis_ns, _collect_type, _range_filter, _ckp_level, _order_ckp_level, _group_key, _reports_in_mem = 
        args[:redis_ns], args[:collect_type], args[:range_filter], args[:ckp_level], args[:order_ckp_level], args[:group_key], args[:reports_in_mem]

      no_underscore_id_range_filter = {}
      _range_filter.each{|k,v| no_underscore_id_range_filter[k.gsub("_id.","")] = v }

      # kihon
      target_collections = []
      target_collections += [
        {:target_model => "Mongodb::Report#{_collect_type.capitalize}BaseResult", :ckp_level => "base",  :range_filter => _range_filter} 
      ]

      if [Common::Report::Group::Pupil].include?(_collect_type)
        target_collections += Common::Report::Group::ListArr[1..-1].map{|group|
          {:target_model => "Mongodb::Report#{group.capitalize}BeforeBasePupilStatResult", :ckp_level => "base", :model_group=>group.downcase, :range_filter => no_underscore_id_range_filter} 
        }
      else
        target_collections += [
          {:target_model => "Mongodb::Report#{_collect_type.capitalize}BasePupilStatResult", :ckp_level => "base", :range_filter => _range_filter} 
        ]
      end

      target_collections += [
        {:target_model => "Mongodb::Report#{_collect_type.capitalize}OrderResult", :ckp_level => "base"}
      ]

      # kaku level no checkpoint
      if _ckp_level.between?(Common::Report::CheckPoints::DefaultLevelFrom, Common::Report::CheckPoints::DefaultLevelTo)
        _ckp_level.times.each{|index|
          ckp_level = index + 1
          target_collections += [
            {:target_model => "Mongodb::Report#{_collect_type.capitalize}Lv#{ckp_level}CkpResult", :ckp_level => "lv#{ckp_level}", :range_filter => _range_filter} 
          ]
        }
        if [Common::Report::Group::Pupil].include?(_collect_type)
          target_collections += Common::Report::Group::ListArr[1..-1].map{|group|
            {:target_model => "Mongodb::Report#{group.capitalize}BeforeLv#{Common::Report::CheckPoints::DefaultLevelFrom}CkpPupilStatResult", :ckp_level => "lv#{Common::Report::CheckPoints::DefaultLevelFrom}", :model_group=>group.downcase, :range_filter => no_underscore_id_range_filter} 
          }
        else
          target_collections += [
            {:target_model => "Mongodb::Report#{_collect_type.capitalize}Lv#{Common::Report::CheckPoints::DefaultLevelFrom}CkpPupilStatResult", :ckp_level => "lv#{Common::Report::CheckPoints::DefaultLevelFrom}", :range_filter => _range_filter} 
          ]
        end
        # 需检讨如何加，需要每个得分点的指标mapping
        # target_order_level = _order_ckp_level.blank?? _ckp_level : _order_ckp_level
        # target_collections += [
        #   {:target_model => "Mongodb::Report#{_collect_type.capitalize}OrderLv#{target_order_level}CkpResult", :ckp_level => "lv#{target_order_level}"}
        # ]
      end

      # matu level no checkpoint
      if _ckp_level >= Common::Report::CheckPoints::DefaultLevelEnd
        target_collections += [
          {:target_model => "Mongodb::Report#{_collect_type.capitalize}LvEndCkpResult", :ckp_level => "lv_end", :range_filter => _range_filter} 
        ]

        if [Common::Report::Group::Pupil].include?(_collect_type)
          target_collections += Common::Report::Group::ListArr[1..-1].map{|group|
            {:target_model => "Mongodb::Report#{group.capitalize}BeforeLvEndCkpPupilStatResult", :ckp_level => "lv_end", :model_group=>group.downcase, :range_filter => no_underscore_id_range_filter}         
          }
        else
          target_collections += [
            {:target_model => "Mongodb::Report#{_collect_type.capitalize}LvEndCkpPupilStatResult", :ckp_level => "lv_end", :range_filter => _range_filter} 
          ]
        end
        # target_collections += [
        #   {:target_model => "Mongodb::Report#{_collect_type.capitalize}OrderLvEndCkpResult", :ckp_level => "lv_end"}
        # ]
      end

      # 需检讨如何加，需要每个得分点的指标mapping
      # if _order_ckp_level == -1
      #   target_collections += [
      #     {:target_model => "Mongodb::Report#{_collect_type.capitalize}OrderLvEndCkpResult", :ckp_level => "lv_end"}
      #   ]
      # end

      th_arr=[]
      target_collections.each{|collection|
        #th_arr << Thread.new do # Thread
          collection[:target_model].constantize.where(collection[:range_filter]).each{|item|
            if collection[:target_model] =~ /.*Before.*PupilStatResult$/
              collection_item = {}
              temp_attrs_h = item.attributes
              values_h = {
                "weights_score_average_percent" => temp_attrs_h["weights_score_average_percent"],
                "weights_score_average_percent_level" => temp_attrs_h["weights_score_average_percent_level"],
                "#{collection[:model_group]}_rank" => temp_attrs_h["#{collection[:model_group]}_rank"],
                "#{collection[:model_group]}_percentile" => temp_attrs_h["#{collection[:model_group]}_percentile"]
              }
              temp_attrs_h.extract!(*values_h.keys)
              #if Common::Report::Group::ListArr[1..-1].include?(collection[:model_group])
              target_pupil = redis_model_data_yomidasi_template(_redis_ns, {:model=>"Pupil", :params =>{:uid => temp_attrs_h["pup_uid"] }}) {|item|
                obj = item[:model].constantize.where(item[:params]).first
                obj.nil?? nil : obj.attributes
              }
              next unless target_pupil
              target_location = redis_model_data_yomidasi_template(_redis_ns, {:model=>"Location", :params =>{:uid => target_pupil["loc_uid"] }}) {|item|
                obj = item[:model].constantize.where(item[:params]).first
                obj.nil?? nil : obj.attributes
              }
              next unless target_location
              tenant_uid = target_location["tenant_uid"]
              #end
              collection_item["_id.tenant_uid"] = ""#tenant_uid
              temp_attrs_h.each{|k,v| collection_item["_id.#{k}"] = v }

              collection_item["value"] = values_h
            else
              collection_item = item
            end
            dimesion = collection_item["_id.dimesion"]

            # target_redis_key, target_report_h = hokoku_o_toru(_redis_ns, _job_uid, _collect_type, _group_key, collection_item)
            target_redis_key, target_report_h = hokoku_o_toru(_redis_ns, _collect_type, _ckp_level, _group_key, collection_item, _reports_in_mem)
            next if target_redis_key.nil? || target_report_h.blank?

            if collection[:target_model] =~ /.*Order.*Result$/
              # paper_qzps
              qzp_h = target_report_h["paper_qzps"].find{|item|
                item["qzp_order"] == collection_item["_id.order"]
              }
              next if qzp_h.blank?
              qzp_h["value"] = collection_item["value"] 
            else
              # data
              lv_n_regexp = /^(lv)([0-9]{1,})$/
              case collection[:ckp_level]
              when "base"
                target_base = target_report_h["data"][dimesion]["base"]
                target_base.merge!(collection_item["value"])
              when "lv_end"
                target_ckp = target_report_h["data"][dimesion]["lv_end"][collection_item["_id.lv_end_ckp_uid"]]
                target_ckp.merge!(collection_item["value"])
              when lv_n_regexp
                target_ckp_level = collection[:ckp_level].scan(lv_n_regexp).first[1].to_i
                target_ckp_h = target_report_h["data"][dimesion]["lv_n"]
                target_ckp_uid = collection_item["_id.lv#{target_ckp_level}_ckp_uid"]
                target_ckp = data_hash_naka_no_ckp_o_sagasu(target_ckp_h, target_ckp_uid, target_ckp_level)
                target_ckp.values[0].merge!(collection_item["value"])
              else
                # do nothing
              end
            end

            _reports_in_mem[target_redis_key] = target_report_h
            # Common::SwtkRedis::set_key(_redis_ns, target_redis_key, target_report_h.to_json)
          }
        #end # thread end
      }
      #ThreadsWait.all_waits(*th_arr)
    end

#    def ni_kumigoto_no_comment_koutiku_kyoutuu_syori _redis_ns, _job_uid, _collect_type, _range_filter, _ckp_level, _order_ckp_level, _group_key
    def ni_kumigoto_no_comment_koutiku_kyoutuu_syori args
      _redis_ns, _collect_type, _range_filter, _ckp_level, _order_ckp_level, _group_key, _reports_in_mem = 
        args[:redis_ns], args[:collect_type], args[:range_filter], args[:ckp_level], args[:order_ckp_level], args[:group_key], args[:reports_in_mem]

      # kihon
      target_collections = [
        {:target_model => "Mongodb::Report#{_collect_type.capitalize}BaseResult", :ckp_level => "base"} 
      ]

      # kaku level no checkpoint
      if _ckp_level.between?(Common::Report::CheckPoints::DefaultLevelFrom, Common::Report::CheckPoints::DefaultLevelTo)
        target_collections += [
          {:target_model => "Mongodb::Report#{_collect_type.capitalize}Lv#{_ckp_level}CkpResult", :ckp_level => "lv#{_ckp_level}"}
        ]
      end

      # matu level no checkpoint
      if _ckp_level >= Common::Report::CheckPoints::DefaultLevelEnd
        target_collections += [
          {:target_model => "Mongodb::Report#{_collect_type.capitalize}LvEndCkpResult", :ckp_level => "lv_end"}
        ]
      end

      #gakusei kozin no houkoku zentai no comment
      th_arr = []
      target_collections.each{|collection|
        #th_arr << Thread.new do # Thread
          collection[:target_model].constantize.where(_range_filter).each{|collection_item|
            target_redis_key, target_report_h = hokoku_o_toru(_redis_ns, _collect_type, _ckp_level, _group_key, collection_item, _reports_in_mem)
            next if target_redis_key.nil? || target_report_h.blank?

            dimesion = collection_item["_id.dimesion"]
            temp_dimesion_h = target_report_h["data"][dimesion]
            temp_comment_dimesion_h = target_report_h["comment"]["version1.0"][dimesion]
            lv_n_regexp = /^(lv)([0-9]{1,})$/

            case collection[:ckp_level]
            when "base"
              target_ckp_arr = [{"base" => temp_dimesion_h["base"]}]
              target_ckp_level = 1 
            when "lv_end"
              target_ckp_arr = temp_dimesion_h["lv_end"]
              target_ckp_level = 1
            when lv_n_regexp
              target_ckp_arr = temp_dimesion_h["lv_n"]
              target_ckp_level = _ckp_level
            else
              target_ckp_arr = [{}]
              target_ckp_level = 0
            end

            ckp_level_value_h= Common::ReportPlus::data_hash_naka_no_level_ckps_o_syutoku target_ckp_arr, target_ckp_level 
            level_value_max = ckp_level_value_h.map{|v| v.values[0]["weights_score_average_percent"]}.max
            level_value_min = ckp_level_value_h.map{|v| v.values[0]["weights_score_average_percent"]}.min

            # best checkpoint 
            temp_comment_dimesion_h["self_best"] = 
              ckp_level_value_h.find_all{|v| v.values[0]["weights_score_average_percent"] == level_value_max }.
              map{|v| {"ckp_uid" => v.keys[0], "checkpoint"=> v.values[0]["checkpoint"]}}
            # worst checkpoint
            temp_comment_dimesion_h["self_worst"] = 
              ckp_level_value_h.find_all{|v| v.values[0]["weights_score_average_percent"] == level_value_min }.
              map{|v| {"ckp_uid" => v.keys[0], "checkpoint"=> v.values[0]["checkpoint"]}}
            
            temp_comment_dimesion_h["self_weights_score_average_percent"] = temp_dimesion_h["base"]["weights_score_average_percent"]
            temp_comment_dimesion_h["self_weights_score_average_percent_level"] = Common::Locale::i18n("reports.#{temp_dimesion_h["base"]["weights_score_average_percent_level"]}")

            unless [Common::Report::Group::Pupil].include?(_collect_type)
              temp_comment_dimesion_h["self_excellent_pupil_number_percent"] = temp_dimesion_h["base"]["excellent_percent"] #collection_item["value.excellent_percent"]
              temp_comment_dimesion_h["self_good_pupil_number_percent"] = temp_dimesion_h["base"]["good_percent"] #collection_item["value.good_percent"]
              temp_comment_dimesion_h["self_failed_pupil_number_percent"] = temp_dimesion_h["base"]["failed_percent"] #collection_item["value.failed_percent"]
            end

            _reports_in_mem[target_redis_key] = target_report_h
            #Common::SwtkRedis::set_key(_redis_ns, target_redis_key, target_report_h.to_json)
          }
        #end
      }
      #ThreadsWait.all_waits(*th_arr)
    end

    # def san_kumikan_no_data_koukan_koutiku_kyoutuu_syori args
    #   _redis_ns, _collect_type, _range_filter, _ckp_level, _order_ckp_level, _group_key, _reports_in_mem = 
    #     args[:redis_ns], args[:collect_type], args[:range_filter], args[:ckp_level], args[:order_ckp_level], args[:group_key], args[:reports_in_mem]

    #   # kihon
    #   target_collections = [
    #     {:target_model => "Mongodb::Report#{_collect_type.capitalize}BaseResult", :ckp_level => "base"} 
    #   ]

    #   # kaku level no checkpoint
    #   if _ckp_level.between?(Common::Report::CheckPoints::DefaultLevelFrom, Common::Report::CheckPoints::DefaultLevelTo)
    #     target_collections += [
    #       {:target_model => "Mongodb::Report#{_collect_type.capitalize}Lv#{_ckp_level}CkpResult", :ckp_level => "lv#{_ckp_level}"}        ]
    #   end

    #   # matu level no checkpoint
    #   if _ckp_level >= Common::Report::CheckPoints::DefaultLevelEnd
    #     target_collections += [
    #       {:target_model => "Mongodb::Report#{_collect_type.capitalize}LvEndCkpResult", :ckp_level => "lv_end"}
    #     ]
    #   end

    #   #gakusei kozin no houkoku zentai no comment
    #   target_collections.each{|collection|
    #     collection[:target_model].constantize.where(_range_filter).each{|collection_item|
    #       target_redis_key, target_report_h = hokoku_o_toru(_redis_ns, _collect_type, _ckp_level, _group_key, collection_item, _reports_in_mem)
    #       next if target_redis_key.nil? || target_report_h.blank?

    #       dimesion = collection_item["_id.dimesion"]
    #       temp_dimesion_h = target_report_h["data"][dimesion]
    #       temp_comment_dimesion_h = target_report_h["comment"]["version1.0"][dimesion]
    #       lv_n_regexp = /^(lv)([0-9]{1,})$/

    #       case collection[:ckp_level]
    #       when "base"
    #         target_ckp_arr = [{"base" => temp_dimesion_h["base"]}]
    #         target_ckp_level = 1 
    #       when "lv_end"
    #         target_ckp_arr = temp_dimesion_h["lv_end"]
    #         target_ckp_level = 1
    #       when lv_n_regexp
    #         target_ckp_arr = temp_dimesion_h["lv_n"]
    #         target_ckp_level = _ckp_level
    #       else
    #         target_ckp_arr = [{}]
    #         target_ckp_level = 0
    #       end

    #       ckp_level_value_arr= Common::ReportPlus::data_hash_naka_no_level_ckps_o_syutoku target_ckp_arr, target_ckp_level 
    #       #irai suru kumi
    #       group_arr_start_index = Common::Report::Group::ListArr.find_index(_collect_type.downcase)
    #       group_arr_start_index += 1
    #       group_arr = []
    #       group_arr = Common::Report::Group::ListArr[group_arr_start_index..-1] if group_arr_start_index < Common::Report::Group::ListArr.size

    #       #kumi goto no zyouhou
    #       group_arr.each{|group|
    #         next if _collect_type.downcase == group
    #         case group
    #         when Common::Report::Group::Pupil
    #           group_key = "_id.pup_uid"
    #         when Common::Report::Group::Klass
    #           group_key = "_id.loc_uid"
    #         when Common::Report::Group::Grade
    #           group_key = "_id.tenant_uid"
    #         when Common::Report::Group::Project
    #           group_key = "_id.test_id"
    #         end

    #         group_redis_key, group_report_h = hokoku_o_toru(_redis_ns, group, _ckp_level, group_key, collection_item, _reports_in_mem)
    #         next if group_report_h.blank?
    #         group_temp_dimesion_h = group_report_h["data"][dimesion]

    #         case collection[:ckp_level]
    #         when "base"
    #           target_ckp_arr = [{"base" => group_temp_dimesion_h["base"]}]
    #         when "lv_end"
    #           target_ckp_arr = group_temp_dimesion_h["lv_end"]
    #         when lv_n_regexp
    #           target_ckp_arr = group_temp_dimesion_h["lv_n"]
    #         else
    #           target_ckp_arr = [{}]
    #         end

    #         group_ckp_level_value_arr= Common::ReportPlus::data_hash_naka_no_level_ckps_o_syutoku target_ckp_arr, target_ckp_level  
    #         diff_arr = []
    #         ckp_level_value_arr.each_with_index{|ckp_h, index|
    #           diff_arr << ckp_h.merge(group_ckp_level_value_arr[index]){|_, l, r| 
    #             l.merge(r){|_, x, y| 
    #               if ( x.is_a?(Numeric) && y.is_a?(Numeric) ) 
    #                 x - y 
    #               else
    #                 x #checkpoint no tame
    #               end
    #             }
    #           }
    #         }
    #         diff_value_max = diff_arr.map{|v| v.values[0]["weights_score_average_percent"]}.max
    #         diff_value_min = diff_arr.map{|v| v.values[0]["weights_score_average_percent"]}.min

    #         # group ni kurabete yoi checkpoint
    #         temp_comment_dimesion_h["group"][group.downcase]["in_group_best"] = 
    #           diff_arr.find_all{|v| (diff_value_max > 0 && v.values[0]["weights_score_average_percent"] == diff_value_max) }.
    #           map{|v| {"ckp_uid" => v.keys[0], "checkpoint"=> v.values[0]["checkpoint"]}}

    #         # group ni kurabete warui checkpoint
    #         temp_comment_dimesion_h["group"][group.downcase]["in_group_worst"] = 
    #           diff_arr.find_all{|v| (diff_value_min < 0 && v.values[0]["weights_score_average_percent"] == diff_value_min) }.
    #           map{|v| {"ckp_uid" => v.keys[0], "checkpoint"=> v.values[0]["checkpoint"]}}

    #         # group ni kurabete heikin no reberu
    #         # hikaku taisyo in "base"
    #         temp_data_base_compare_objs = ["weights_score_average_percent", "excellent_percent", "good_percent", "failed_percent"]
    #         temp_data_base_compare_objs.each{|obj|
    #           temp_comment_dimesion_h["group"][group.downcase]["in_group_#{obj}_level"] = 
    #             get_values_compare_label(temp_dimesion_h["base"][obj], group_temp_dimesion_h["base"][obj])
    #         }
    #       }

    #       _reports_in_mem[target_redis_key] = target_report_h
    #       # Common::SwtkRedis::set_key(_redis_ns, target_redis_key, target_report_h.to_json)
    #     }
    #   }
    # end

    def get_values_compare_label value1, value2
      value1 = value1 || 0
      value2 = value2 || 0
      if value1 < value2 
        return Common::Locale::i18n("reports.lower_than")
      elsif value1 == value2
        return Common::Locale::i18n("reports.equal_to")
      else
        return Common::Locale::i18n("reports.higher_than")
      end
    end

    # houkoku hash no syutoku
    # _redis_ns: reids NameSpace
    # _job_uid: JOB ID
    # _collect_type: Collection Type
    # _group_key: Group Type
    # _item: 对象
    #
    # def hokoku_o_toru _redis_ns, _job_uid, _collect_type, _group_key, _item
    def hokoku_o_toru _redis_ns, _collect_type, _ckp_level, _group_key, _item, _reports_in_mem
      begin
        #传入参数检查
        if(_redis_ns.blank? || 
           # _job_uid.blank? || 
           _collect_type.blank? ||
           _group_key.blank? || 
           _item.blank? || 
           _item[_group_key].blank?)
          return nil, {} 
        end
        collect_type = _collect_type.downcase

        # 报告
        report_redis_key_arr = redis_bread_crumbs(collect_type, _item)

        # [
        #   "tests",
        #   _item["_id.test_id"], 
        #   collect_type, 
        #   tenant_uid,  
        #   _item[_group_key]]
        report_key = Common::SwtkRedis::Prefix::Reports + report_redis_key_arr.join("/")
        report_h = _reports_in_mem[report_key] || {}
        if report_h.blank?
        #report_redis_key, report_h = redis_atai_no_yomidasi_template(_redis_ns, report_redis_key_arr) {
          tenant_uid = ["project"].include?(collect_type)? "project" : _item['_id.tenant_uid']
          # target_test = Mongodb::BankTest.where(id: _item["_id.test_id"]).first
          # return nil, {} unless target_test
          #target_tenant = Tenant.where(uid: tenant_uid).first
          target_tenant = redis_model_data_yomidasi_template(_redis_ns, {:model=>"Tenant", :params =>{:uid => tenant_uid }}) {
            obj = Tenant.where(uid: tenant_uid).first
            obj.nil?? nil : obj.attributes
          }
          #return nil, {} unless target_tenant

          # /tests/测试id/paper_info
          _, _ = redis_atai_no_yomidasi_template(_redis_ns, ["tests", _item["_id.test_id"].to_s, "paper_info"]){
            target_test = Mongodb::BankTest.where(id: _item["_id.test_id"]).first
            return {} unless target_test
            target_pap = target_test.bank_paper_pap
            return {} unless target_pap
            paper_h = JSON.parse(target_pap.paper_json)
            paper_h["information"]
          }

          # /tests/测试id/ckps_qzps_mapping
          _, qzps_ckps_mapping_arr = redis_atai_no_yomidasi_template(_redis_ns, ["tests", _item["_id.test_id"].to_s, "qzps_ckps_mapping"]){
            qzps_ckps_mapping = Common::ReportPlus::data_qzps_ckps_mapping(_item["_id.test_id"], _ckp_level)
            qzps_ckps_mapping
          }
          return nil, {} if qzps_ckps_mapping_arr.blank?

          # /tests/测试id/ckps_qzps_mapping
          _, ckps_qzps_mapping_h = redis_atai_no_yomidasi_template(_redis_ns, ["tests", _item["_id.test_id"].to_s, "ckps_qzps_mapping"]){
            ckps_qzps_mapping = Common::ReportPlus::data_ckps_qzps_mapping(_item["_id.test_id"], _ckp_level)
            ckps_qzps_mapping
          }
          return nil, {} if ckps_qzps_mapping_h.blank?

          # /tests/测试id/grade/租户uid/basic_info     
          basic_info_redis_key_arr = [
            "tests", 
            _item["_id.test_id"].to_s, 
            "grade", 
            tenant_uid.to_s, 
            "basic_info"]
          _, basic_info_h = redis_atai_no_yomidasi_template(_redis_ns, basic_info_redis_key_arr ) {
            #
            target_test = Mongodb::BankTest.where(id: _item["_id.test_id"]).first
            target_area = Area.where(uid: _item["_id.area_uid"]).first
            # target_tenant = Tenant.where(uid: tenant_uid).first
            return nil, {} if target_test.nil? || target_area.nil? || (!["project"].include?(collect_type) && target_tenant.blank? )

            value_h = {}
            value_h["test_name"] = target_test.name
            if ["project"].include?(collect_type)
              value_h["school"] = Common::Locale::i18n("common.none")
            else
              value_h["school"] = target_tenant.blank?? Common::Locale::i18n("common.none") : target_tenant["name_cn"]
            end
            value_h["area"] = target_area.pcd_h.values.map{|a| a[:name_cn] if !a[:name_cn].blank?}.compact.join("/")
            value_h["grade"] = Common::Locale::i18n("dict.#{target_test.bank_paper_pap.grade}")
            value_h["subject"] = Common::Locale::i18n("dict.#{target_test.bank_paper_pap.subject}")
            value_h["term"] = Common::Locale::i18n("dict.#{target_test.bank_paper_pap.term}")
            value_h["quiz_type"] = Common::Locale::i18n("dict.#{target_test.bank_paper_pap.quiz_type}")
            value_h["quiz_date"] = Common::Locale::i18n("dict.#{target_test.bank_paper_pap.quiz_date.strftime('%Y-%m-%d')}")
            value_h["levelword2"] = Common::Locale::i18n("dict.#{target_test.bank_paper_pap.levelword2}")

            value_h
          }
          return nil, {} if basic_info_h.blank?

          #
          value_h = "Common::ReportPlus::#{collect_type.capitalize}Houkoku".constantize.deep_dup
          #
          value_h["basic"]["test_name"] = basic_info_h["test_name"]
          value_h["basic"]["area"] = basic_info_h["area"]
          value_h["basic"]["school"] = basic_info_h["school"] 
          value_h["basic"]["grade"] = basic_info_h["grade"]
          value_h["basic"]["subject"] = basic_info_h["subject"]
          value_h["basic"]["term"] = basic_info_h["term"]
          value_h["basic"]["quiz_type"] = basic_info_h["quiz_type"]
          value_h["basic"]["quiz_date"] = basic_info_h["quiz_date"]
          value_h["basic"]["levelword2"] = basic_info_h["levelword2"]
          # 
          if ["pupil"].include?(collect_type)
            # pupil = Pupil.where(uid: _item["_id.pup_uid"]).first
            pupil = redis_model_data_yomidasi_template(_redis_ns, {:model=>"Pupil", :params =>{:uid => _item["_id.pup_uid"] }}) {
              obj = Pupil.where(uid: _item["_id.pup_uid"]).first
              obj.nil?? nil : obj.attributes
            }
            value_h["basic"]["classroom"] = Common::Klass::klass_label(pupil["classroom"])
            value_h["basic"]["name"] = pupil["name"]
            value_h["basic"]["sex"] = Common::Locale::i18n("dict.#{pupil["sex"]}")
          end
          #
          value_h["data"] = ckps_qzps_mapping_h[_item["_id.test_id"]]
          value_h["paper_qzps"] = qzps_ckps_mapping_arr

          # 导航更新
          sort_key = nil
          case collect_type
          when Common::Report::Group::Project
            sort_key = _item["_id.test_id"]
            parent_group = "test"
            label_str = value_h["basic"]["test_name"] 
          when Common::Report::Group::Grade
            sort_key = target_tenant["name"]
            parent_group = "project"
            label_str = value_h["basic"]["school"]
          when Common::Report::Group::Klass
            target_location = redis_model_data_yomidasi_template(_redis_ns, {:model=>"Location", :params =>{:uid => _item["_id.loc_uid"] }}) {|item|
              obj = Location.where(uid: _item["_id.loc_uid"]).first
              obj.nil?? nil : obj.attributes
            }
            sort_key = target_location["classroom"]
            parent_group = "grade"
            label_str = Common::Locale::i18n("dict.#{sort_key}")
          when Common::Report::Group::Pupil
            # pupil = redis_model_data_yomidasi_template(_redis_ns, {:model=>"Pupil", :params =>{:uid => _item["_id.pup_uid"] }}) {
            #   obj = item[:model].constantize.where(uid: _item["_id.pup_uid"]).first
            #   obj.nil?? nil : obj.attributes
            # }
            sort_key = pupil["stu_number"]
            parent_group = "klass"
            label_str = "#{pupil["name"]}(#{pupil["stu_number"]})"
          end
          report_nav_item = [sort_key, { :label => label_str, :report_url => Common::SwtkRedis::Prefix::Reports + report_redis_key_arr.join("/")+".json" }]
          report_nav_redis_key_arr = report_redis_key_arr[0..-3] + ["nav"]
          report_nav_redis_key, report_nav_h = redis_atai_no_yomidasi_template(_redis_ns, report_nav_redis_key_arr) {
            {}
          }
          if report_nav_h.blank?
            report_nav_h = { parent_group => [report_nav_item]}
          else
            report_nav_h[parent_group] = Common::insert_item_to_arr_with_order(collect_type, report_nav_h[parent_group], report_nav_item)
          end
          Common::SwtkRedis::set_key(_redis_ns, report_nav_redis_key, report_nav_h.to_json)

          report_h = value_h
        end
        return nil, {} if report_h.blank?

        #返回报告redis key, data hash
        return report_key, report_h
      rescue Exception => ex
        p ex.message
        logger.debug ex.message
        raise ex
      end
    end

    def redis_bread_crumbs collect_type, item
      result = []
      start_index = Common::Report::Group::ListArr.find_index(collect_type.downcase)
      return result unless start_index
      result << [ "tests", item["_id.test_id"] ]
      group_arr = Common::Report::Group::ListArr[start_index..-1]
      group_arr.reverse.map{|group|
        uid = nil
        case group
        when Common::Report::Group::Project
          uid = item["_id.test_id"]
        when Common::Report::Group::Grade
          uid = item["_id.tenant_uid"]
        when Common::Report::Group::Klass
          uid = item["_id.loc_uid"]
        when Common::Report::Group::Pupil
          uid = item["_id.pup_uid"]
        end
        result << [ group.downcase, uid ]
      }
      return result.flatten
    end

  end
end