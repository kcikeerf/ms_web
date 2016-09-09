module PaperModule
  module Paper
    module_function

    QuizType = {
      #数学
      :shu_xue =>{
        :dan_xiang_xuan_ze_ti => "单项选择题",
        :tian_kong_ti => "填空题",
        :pan_duan_ti => "判断题",
        :ji_suan_ti => "计算题",
        :cao_zuo_ti => "操作题",
        :ying_yong_ti => "应用题",
        :jie_da_ti => "解答题",
        :tan_suo_gui_lv_ti => "探索规律题",
        :tan_jiu_ti => "探究题"
      },
      #英语
      :ying_yu => {
        :ting_li_li_jie => "听力理解",
        :dan_xiang_xuan_ze => "单项选择",
        :wan_xing_tian_kong => "完形填空",
        :yue_du_li_jie => "阅读理解",
        :ci_yu_yun_yong => "词语运用",
        :bu_quan_dui_hua => "补全对话",
        :shu_mian_biao_da => "书面表达"
      }
    }

    Difficulty = {
      #难度
      :rong_yi => "容易",
      :jiao_yi => "较易",
      :zhong_deng => "中等",
      :jiao_nan => "较难",
      :kun_nan => "困难"
    }

    Subject_ckp_type = 'from_subject'
    Node_ckp_type = 'from_node'

    module Constants
      OrderWidth = 5
    end

    module Status
      None = "none"
      New = "new"
      Editting = "editting"
      Editted = "editted"
      Analyzing = "analyzing" 
      Analyzed = "analyzed"
      ScoreImporting = "score_importing"
      ScoreImported = "score_imported"
      ReportGenerating = "report_generating"
      ReportCompleted = "report_completed"
    end

    def quiz_order(x,y)
      x_arr = destruct_order x
      y_arr = destruct_order y

      if x_arr[0] != y_arr[0]
        return x_arr[0] <=> y_arr[0]
      else
        return x_arr[1] <=> y_arr[1]
      end
    end

    def destruct_order orderStr
      return ["",""] if orderStr.blank?
      reg = /\(([0-9].*?)\)/
      md = reg.match(orderStr)
      quiz_order = orderStr.sub(/\(.*/,"")
      quiz_order = quiz_order.blank?? 0:quiz_order.to_i
      qizpoint_order = md.blank?? 0:md[1].to_i
      return [quiz_order,qizpoint_order]
    end
  end
end