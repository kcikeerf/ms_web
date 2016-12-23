class Mongodb::OnlineTestIndividualGenerator
  include Mongoid::Document


  # 初始化参数
  # online_test_id: 在线测试id, must
  # wx_user_ids: 测试人的微信账户ids, optional
  # ckp_level: 指标层级, optional
  # 
  def initialize(args)
    logger.info(">>>initialize: begin<<<")
    logger.info("参数:\n#{args}")

    #范围处理
    @range_filter = {}
    if !args[:wx_user_ids].blank?
      #指定学生范围
      @range_filter[:wx_user_id] = {"$in" => args[:wx_user_ids]}
    end
    #测试范围
    @range_filter[:online_test_id] = args[:online_test_id]

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
        "Mongodb::OnlineTestReportIndividualBaseResult",
        "Mongodb::OnlineTestReportIndividualLv1CkpResult",
        "Mongodb::OnlineTestReportIndividualLv2CkpResult",
        "Mongodb::OnlineTestReportIndividualLvEndCkpResult",
        "Mongodb::OnlineTestReportIndividualOrderResult",
        "Mongodb::OnlineTestReportIndividualOrderLv1CkpResult",
        "Mongodb::OnlineTestReportIndividualOrderLv2CkpResult",
        "Mongodb::OnlineTestReportIndividualOrderLvEndCkpResult"
    ]

    target_collections.each{|collection|
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
      online_test_id: this.online_test_id,
      wx_user_id: this.wx_user_id,
      dimesion: this.dimesion
    }

    keys_groups = [
      {
        :key => %Q{#{base_keys}},
        :output => "mongodb_online_test_report_individual_base_results"
      },
      # 题顺相关
      { 
        :key => %Q{#{base_keys}, order: this.order},
        :output => "mongodb_online_test_report_individual_order_results"
      }
    ]

    if @ckp_level.between?(Common::Report::CheckPoints::DefaultLevelFrom, Common::Report::CheckPoints::DefaultLevelTo)
      @ckp_level.times.each{|index|
        ckp_level = index + 1
        keys_groups += [
          {
            :key => %Q{#{base_keys}, lv#{ckp_level}_ckp_uid: ckp_uid_arr[#{ckp_level}], lv#{ckp_level}_ckp_order: ckp_order_arr[#{ckp_level}]},
            :output => "mongodb_online_test_report_individual_lv#{ckp_level}_ckp_results"
          }
        ]
      }
      # 题顺相关
      # 只统计指定指标层级的最后一级
      #
      keys_groups += [
        {
          :key => %Q{#{base_keys}, order: this.order, lv#{@ckp_level}_ckp_uid: ckp_uid_arr[#{@ckp_level}], lv#{@ckp_level}_ckp_order: ckp_order_arr[#{@ckp_level}]},
          :output => "mongodb_online_test_report_individual_order_lv#{@ckp_level}_ckp_results"
        }
      ]
    end

    if @ckp_level >= Common::Report::CheckPoints::DefaultLevelEnd
      keys_groups += [
        {
          :key => %Q{#{base_keys}, lv_end_ckp_uid: ckp_uid_arr[ckp_uid_arr.length-1], lv_end_ckp_order: ckp_order_arr[ckp_order_arr.length-1]},
          :output => "mongodb_online_test_report_individual_lv_end_ckp_results"
        },
        # 题顺相关
        {
          :key => %Q{#{base_keys}, order: this.order, lv_end_ckp_uid: ckp_uid_arr[ckp_uid_arr.length-1], lv_end_ckp_order: ckp_order_arr[ckp_order_arr.length-1]},
          :output => "mongodb_online_test_report_individual_order_lv_end_ckp_results"
        }
      ]
    end

    map_template = Common::ReportPlus::KozinKeiSanRoundIti[:map]
    reduce_func = Common::ReportPlus::KozinKeiSanRoundIti[:reduce]
    keys_groups.each{|item|
      map_func = map_template.clone % {:key => item[:key]}
      Mongodb::BankTestScore.where(filter).map_reduce(map_func,reduce_func).out(:reduce => item[:output]).execute
    }
  end
  
end
