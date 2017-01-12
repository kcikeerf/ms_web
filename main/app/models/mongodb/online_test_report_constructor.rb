# -*- coding: UTF-8 -*-
#

class Mongodb::OnlineTestReportConstructor
  include Mongoid::Document

  # 初始化参数
  # online_test_id: 在线测试ID, must
  # group_type: Group类型
  # wx_user_ids[String Array]: 测试人ID, optional
  # ckp_level[Integer]: 指标层级
  # order_ckp_level[Ineger Array]: 题顺层级 
  #   1) 0, ckp_level < 1 
  #   2) -1, lv_end ckp
  #   3) other, 同ckp_level
  #
  def initialize(args)
    Common::ReportPlus::koutiku_method_template(__method__.to_s()) {
      logger.info("参数:\n#{args}")

      # 参数检查
      #
      if( args[:online_test_id].blank? ||
          args[:group_type].blank? || 
          !Common::OnrineTest::Group::List.include?(args[:group_type].downcase)
        )
        raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
      end

      # 实例参数
      # @redis_ns: redis缓存Namespace
      # @test_id: test ID
      # 
      @redis_ns, @online_test_id, collect_type, range_filter, ckp_level, order_ckp_level, group_key = 
        Common::ReportPlus::online_test_kumitate_no_hazime(args)

      p "Mongodb::OnlineTestReportConstructor 1>>>>>>>#{Common::ReportPlus::online_test_kumitate_no_hazime(args)}" 

      @reports_in_mem = {}

      @common_params_h = { 
        :redis_ns => @redis_ns,
        :collect_type => collect_type, 
        :range_filter => range_filter, 
        :ckp_level => ckp_level,
        :order_ckp_level => order_ckp_level,
        :group_key => group_key,
        :reports_in_mem => @reports_in_mem
      }
    }
  end

  # 结束处理
  def owari
    Common::ReportPlus::koutiku_method_template(__method__.to_s()) {
      Common::ReportPlus::online_test_kumitate_no_owari(@redis_ns, @online_test_id, @reports_in_mem)
    }
  end

  # 组装
  #
  def online_test_iti_koutiku
    Common::ReportPlus::koutiku_method_template(__method__.to_s()) {
      p "Mongodb::OnlineTestReportConstructor 2 online_test_iti_koutiku>>>>>>>#{@common_params_h}" 
      Common::ReportPlus::online_test_iti_koutiku_kyoutuu_syori(@common_params_h)
    }
  end
end
