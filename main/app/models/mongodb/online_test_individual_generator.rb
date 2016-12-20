class Mongodb::OnlineTestIndividualGenerator
  include Mongoid::Document


  # 初始化参数
  # test_id: 测试id, must
  # pup_uids: 学生id, optional
  # loc_uids: 班级id, optional
  # tenant_uids: Tenant id, optional
  # area_rids: 地区rids, optional
  # ckp_level: 指标层级
  # 
  def initialize(args)
    logger.info(">>>initialize: begin<<<")
    logger.info("参数:\n#{args}")

    #范围处理
    @range_filter = {}
    if !args[:pup_uids].blank?
      #指定学生范围
      @range_filter[:pup_uid] = {"$in" => args[:pup_uids]}
    elsif !args[:loc_uids].blank?
      #指定班级范围
      @range_filter[:loc_uid] = {"$in" => args[:loc_uids]}
    elsif !args[:tenant_uids].blank?
      #指定Tenant范围
      @range_filter[:tenant_uid] = {"$in" => args[:tenant_uids]}
    elsif !args[:area_rid].blank?
      #指定某一地区
      area_regex = Regexp.new "^{#{args[:area_rid]}"
      @range_filter[:area_rid] = {"$regexp" => area_regex}
    else
      # do nothing
    end
    #测试范围
    @range_filter[:test_id] = args[:test_id]
    # raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => "")) if @range_filter.empty?

    @ckp_level = args[:ckp_level].blank?? Common::Report::CheckPoints::DefaultLevel : args[:ckp_level].to_i 

    logger.debug(">>>initialize: end<<<")
  end

  def clear_old_data
    logger.debug(">>>clear old data: begin<<<")

    # 删除中间结果
    old_range_filter = {}
    @range_filter.each{|k,v|
      old_range_filter["_id.#{k}"] = v
    }

    target_collections = [
      "Mongodb::ReportPupilBaseResult",
      "Mongodb::ReportPupilLv1CkpResult",
      "Mongodb::ReportPupilLv2CkpResult",
      "Mongodb::ReportPupilLvEndCkpResult",
      "Mongodb::ReportPupilOrderResult",
      "Mongodb::ReportPupilOrderLv1CkpResult",
      "Mongodb::ReportPupilOrderLv2CkpResult",
      "Mongodb::ReportPupilOrderLvEndCkpResult"
    ]
    target_collections.each{|collection|
      # p "#{collection}:  #{(collection.constantize.last.attributes['_id'].is_a? Hash) if collection.constantize.last}, #{old_range_filter}, #{collection.constantize.where(old_range_filter).count}"
      collection.constantize.where(old_range_filter).destroy_all
    }

    logger.debug(">>>clear old data: end<<<")
  end

  def when_completed
    logger.debug(">>>>>>completed: begin<<<<<<<")
    #
    #  to be implemented
    #
    logger.debug ">>>>>>>completed: end<<<<<<<"
  end


  #
  # 聚合计算: 开始
  #
  def cal_round_1
    filter = @range_filter
    base_keys = %Q{
      test_id: this.test_id,
      pap_uid: this.pap_uid,
      area_uid: this.area_uid,
      area_rid: this.area_rid,
      tenant_uid: this.tenant_uid,
      loc_uid: this.loc_uid,
      pup_uid: this.pup_uid,
      dimesion: this.dimesion
    }

    keys_groups = [
      {:key => %Q{#{base_keys}},
       :output => "mongodb_report_pupil_base_results"
      },
      {:key => %Q{#{base_keys}, order: this.order},
       :output => "mongodb_report_pupil_order_results"
      }
    ]

    if @ckp_level.between?(Common::Report::CheckPoints::DefaultLevelFrom, Common::Report::CheckPoints::DefaultLevelTo)
      @ckp_level.times.each{|index|
        ckp_level = index + 1
        keys_groups += [
          {:key => %Q{#{base_keys}, lv#{ckp_level}_ckp_uid: ckp_uid_arr[#{ckp_level}], lv#{ckp_level}_ckp_order: ckp_order_arr[#{ckp_level}]},
           :output => "mongodb_report_pupil_lv#{ckp_level}_ckp_results"
          },

        ]
      }
      keys_groups += [
        {:key => %Q{#{base_keys}, order: this.order, lv#{@ckp_level}_ckp_uid: ckp_uid_arr[#{@ckp_level}], lv#{@ckp_level}_ckp_order: ckp_order_arr[#{@ckp_level}]},
        :output => "mongodb_report_pupil_order_lv#{@ckp_level}_ckp_results"
        }
      ]
    end

    if @ckp_level >= Common::Report::CheckPoints::DefaultLevelEnd
      keys_groups += [
        {:key => %Q{#{base_keys}, lv_end_ckp_uid: ckp_uid_arr[ckp_uid_arr.length-1], lv_end_ckp_order: ckp_order_arr[ckp_order_arr.length-1]},
         :output => "mongodb_report_pupil_lv_end_ckp_results"
        },
        {:key => %Q{#{base_keys}, order: this.order, lv_end_ckp_uid: ckp_uid_arr[ckp_uid_arr.length-1], lv_end_ckp_order: ckp_order_arr[ckp_order_arr.length-1]},
         :output => "mongodb_report_pupil_order_lv_end_ckp_results"
        }
      ]
    end

    map_template = %Q{
      function(){
        var ckp_uid_arr = this.ckp_uids.split("/");
        var ckp_order_arr = this.ckp_order.split("/");
        var ckp_weights = this.ckp_weights.split("/");

        var full_weights_score = this.full_score*ckp_weights[ckp_weights.length-1];
        var real_weights_score = this.real_score*ckp_weights[ckp_weights.length-1];
        var is_correct = (full_weights_score == real_weights_score) ? 1:0;

        var weights_score_average_percent = real_weights_score/full_weights_score;
        var weights_score_average_percent_level = '#{Common::Report::ScoreLevel::Label::LevelNone}';
        if( 0.0 <= weights_score_average_percent && weights_score_average_percent < #{Common::Report::ScoreLevel::Level60} ){
          weights_score_average_percent_level = "#{Common::Report::ScoreLevel::Label::Level0}";
        } else if (#{Common::Report::ScoreLevel::Level60}<= weights_score_average_percent && weights_score_average_percent < #{Common::Report::ScoreLevel::Level85}){
          weights_score_average_percent_level = "#{Common::Report::ScoreLevel::Label::Level60}";
        } else if (#{Common::Report::ScoreLevel::Level85} <= weights_score_average_percent && weights_score_average_percent <= 1.0){
          weights_score_average_percent_level = "#{Common::Report::ScoreLevel::Label::Level85}";
        }

        var base_values = {
          total_full_score: this.full_score,
          total_real_score: this.real_score,
          total_full_weights_score: full_weights_score,
          total_real_weights_score: real_weights_score,
          qzp_count: 1,
          qzp_correct_count: is_correct,
          score_average_percent: this.real_score/this.full_score,
          weights_score_average_percent: weights_score_average_percent,
          weights_score_average_percent_level: weights_score_average_percent_level
        };

        emit({%{key}}, base_values);
      }
    }

    reduce_func = %Q{
      function(key,values){
        var result = {
          total_full_score: 0,
          total_real_score: 0,
          total_full_weights_score: 0,
          total_real_weights_score: 0,
          qzp_count: 0,
          qzp_correct_count: 0,
          score_average_percent: 0,
          weights_score_average_percent: 0,
          weights_score_average_percent_level: ""
        };

        values.forEach(function(value){
          result.total_full_score += value.total_full_score;
          result.total_real_score += value.total_real_score;
          result.total_full_weights_score += value.total_full_weights_score;
          result.total_real_weights_score += value.total_real_weights_score;
          result.qzp_count += value.qzp_count;
          result.qzp_correct_count += value.qzp_correct_count;
        });
        result.score_average_percent = result.total_real_score/result.total_full_score;
        result.weights_score_average_percent = result.total_real_weights_score/result.total_full_weights_score;

        if( 0.0 <= result.weights_score_average_percent && result.weights_score_average_percent < #{Common::Report::ScoreLevel::Level60} ){
          result.weights_score_average_percent_level = "#{Common::Report::ScoreLevel::Label::Level0}";
        } else if (#{Common::Report::ScoreLevel::Level60}<= result.weights_score_average_percent && result.weights_score_average_percent < #{Common::Report::ScoreLevel::Level85}){
          result.weights_score_average_percent_level = "#{Common::Report::ScoreLevel::Label::Level60}";
        } else if (#{Common::Report::ScoreLevel::Level85} <= result.weights_score_average_percent && result.weights_score_average_percent <= 1.0){
          result.weights_score_average_percent_level = "#{Common::Report::ScoreLevel::Label::Level85}";
        }
               
        return result;
      }
    }

    keys_groups.each{|item|
      map_func = map_template.clone % {:key => item[:key]}
      Mongodb::BankTestScore.where(filter).map_reduce(map_func,reduce_func).out(:reduce => item[:output]).execute
    }
  end
  
end
