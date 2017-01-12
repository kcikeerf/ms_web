# -*- coding: UTF-8 -*-

class Mongodb::OnlineTestGroupGenerator
  include Mongoid::Document

  # 初始化参数
  # online_test_id: 在线测试ID
  # ckp_level: 指标层级
  # 
  def initialize(args)
    logger.info(">>>initialize: begin<<<")
    logger.info("参数:\n#{args}")

    # 测试范围
    @range_filter = { '_id.online_test_id' => args[:online_test_id] }
    # 指标层级
    @ckp_level = args[:ckp_level].blank?? Common::Report::CheckPoints::DefaultLevel : args[:ckp_level].to_i
    @collect_type = "total"
    @base_keys = %Q{
      online_test_id: this._id.online_test_id,
      dimesion: this._id.dimesion,
    }

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
        "Mongodb::OnlineTestReportTotalBaseResult",
        "Mongodb::OnlineTestReportTotalLv1CkpResult",
        "Mongodb::OnlineTestReportTotalLv2CkpResult",
        "Mongodb::OnlineTestReportTotalLvEndCkpResult",
        "Mongodb::OnlineTestReportTotalOrderResult",
        "Mongodb::OnlineTestReportTotalOrderLv1CkpResult",
        "Mongodb::OnlineTestReportTotalOrderLv2CkpResult",
        "Mongodb::OnlineTestReportTotalOrderLvEndCkpResult"
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
    keys_groups = [
      {:source_model => "Mongodb::OnlineTestReportIndividualBaseResult",
       :key => %Q{#{@base_keys}},
       :output => "mongodb_online_test_report_total_base_results"
      },
      {:source_model => "Mongodb::OnlineTestReportIndividualOrderResult",
       :key => %Q{#{@base_keys} order: this._id.order},
       :output =>  "mongodb_online_test_report_total_order_results"
      }
    ]

    if @ckp_level.between?(Common::Report::CheckPoints::DefaultLevelFrom, Common::Report::CheckPoints::DefaultLevelTo)
      @ckp_level.times.each{|index|
        ckp_level = index + 1
        keys_groups += [
          {:source_model => "Mongodb::OnlineTestReportIndividualLv#{ckp_level}CkpResult",
           :key => %Q{#{@base_keys} lv#{ckp_level}_ckp_uid: this._id.lv#{ckp_level}_ckp_uid, lv#{ckp_level}_ckp_order: this._id.lv#{ckp_level}_ckp_order},
           :output => "mongodb_online_test_report_total_lv#{ckp_level}_ckp_results"
          }
        ]
      }
      keys_groups += [
        {:source_model => "Mongodb::OnlineTestReportIndividualOrderLv#{@ckp_level}CkpResult",
         :key => %Q{#{@base_keys} order: this._id.order, lv#{@ckp_level}_ckp_uid: this._id.lv#{@ckp_level}_ckp_uid, lv#{@ckp_level}_ckp_order: this._id.lv#{@ckp_level}_ckp_order},
         :output => "mongodb_online_test_report_total_order_lv#{@ckp_level}_ckp_results"
        }
      ]
    end

    if @ckp_level >= Common::Report::CheckPoints::DefaultLevelEnd
      keys_groups += [
        {:source_model => "Mongodb::OnlineTestReportIndividualLvEndCkpResult",
         :key => %Q{#{@base_keys} lv_end_ckp_uid: this._id.lv_end_ckp_uid, lv_end_ckp_order: this._id.lv_end_ckp_order},
         :output => "mongodb_online_test_report_total_lv_end_ckp_results"
        },
        {:source_model => "OnlineTestReportIndividualOrderLvEndCkpResult",
         :key => %Q{#{@base_keys} order: this._id.order, lv_end_ckp_uid: this._id.lv_end_ckp_uid, lv_end_ckp_order: this._id.lv_end_ckp_order},
         :output => "mongodb_online_test_report_total_order_lv_end_ckp_results"
        }
      ]
    end

    # mapreduce
    map_template = Common::ReportPlus::KumiKeiSanRoundIti[:map]
    reduce_func = Common::ReportPlus::KumiKeiSanRoundIti[:reduce]
    keys_groups.each{|item|
      map_func = map_template.clone % {:key => item[:key]}
      item[:source_model].constantize.where(@range_filter).map_reduce(map_func,reduce_func).out(:reduce => item[:output]).execute
    }
  end

  ######
  def cal_round_1_5
    keys_groups = [
      {:source_model => "Mongodb::OnlineTestReportIndividualBaseResult",
       :key => %Q{#{ @base_keys}},
       :for_pupil_stat_model => "Mongodb::OnlineTestReportTotalBeforeBasePupilStatResult",
       :group_model => "Mongodb::OnlineTestReportTotalBaseResult",
       :ckp_level => "base"
      }
    ]

    if @ckp_level.between?(Common::Report::CheckPoints::DefaultLevelFrom, Common::Report::CheckPoints::DefaultLevelTo)
      @ckp_level.times.each{|index|
        ckp_level = index + 1
        keys_groups += [
          {:source_model => "Mongodb::OnlineTestReportIndividualLv#{ckp_level}CkpResult",
           :key => %Q{#{ @base_keys} lv#{ckp_level}_ckp_uid: this._id.lv#{ckp_level}_ckp_uid, lv#{ckp_level}_ckp_order: this._id.lv#{ckp_level}_ckp_order},
           :for_pupil_stat_model => "Mongodb::OnlineTestReportTotalBeforeLv#{ckp_level}CkpPupilStatResult",
           :group_model => "Mongodb::OnlineTestReportTotalLv#{ckp_level}CkpResult",
           :ckp_level => "lv#{ckp_level}"
          }
        ]
      }
    end

    Common::ReportPlus::online_test_keisan_iti_go_zyunban_no_syori keys_groups, @range_filter, @collect_type
  end

end
