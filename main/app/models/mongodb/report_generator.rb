# -*- coding: UTF-8 -*-

require 'thwait'

class Mongodb::ReportGenerator
  include Mongoid::Document

  #attr_accessor :province, :city, :district, :school, :grade, :classroom, :pap_uid
  #attr_accessor :ckps_qzps,:paper

  def initialize(args)
    logger.debug("=====initialization: begin!=====")
    logger.debug(args)
    #location
    @province = args[:province]
    @city = args[:city]
    @district = args[:district]
    @school = args[:school]
    @pap_uid = args[:pap_uid]
    @area = I18n.t("area.#{@province}") + I18n.t("area.#{@city}") + I18n.t("area.#{@district}")
#    @ckps_qzps = args[:ckps_qzps]

    @paper = Mongodb::BankPaperPap.where(_id: @pap_uid).first
    @school_label = @paper.school
    @paper.update(paper_status: Common::Paper::Status::ReportGenerating)
    paper_h = JSON.parse(@paper.paper_json)
    paper_h["task_uid"] = args[:task_uid]
    @paper.update(paper_json: paper_h.to_json)

    @ckps_qzps = @paper.get_pap_ckps_qzp_mapping
=begin
    #计算各类得分率,平均分,及总分
    cal_total_average_percent_scores
    #添加班级年级平均分到cal_total_average_percent_scores统计结果
    add_avg_col
    #计算标准方差,分化度
    cal_standard_deviation_difference
    #计算各分数段人数
    cal_each_level_pupil_number
    #计算班级整体三维指标情况
    cal_quiz_comments_dimesion
=end
    logger.debug("=====initialization: completed!=====")
  end

  def when_completed
    @paper.update(paper_status: Common::Paper::Status::ReportCompleted)
    logger.debug(@paper.paper_status)
  end

  # class reports
  def construct_gra_cls_charts
    logger.info "construct class all charts"

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.pup_uid' => nil,
      '_id.grade' => {'$exists' => true },
      '_id.dimesion' => {'$exists' => true },
      '_id.lv1_ckp' => {'$exists' => true }
    }

    Mongodb::ReportTotalAvgResult.where(filter).each{|item|
      #
      #grade
      #
      if !item[:_id].keys.include?("classroom")

        grade_report, report_h = get_grade_report_hash item
        lv1_ckp_key = item[:_id][:lv1_ckp].to_sym
        dimesion = item[:_id][:dimesion]

        report_h["charts"]["#{dimesion}_3lines"]["grade_average_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:average_percent])

        grade_report.report_json = report_h.to_json
        grade_report.save
      end

      #
      #classroom
      #
      if item[:_id].keys.include?("classroom")

        klass_report, report_h = get_class_report_hash item
        lv1_ckp_key = item[:_id][:lv1_ckp].to_sym
        dimesion = item[:_id][:dimesion]

        #if(item[:_id][:dimesion] == "knowledge")
        report_h["charts"]["#{dimesion}_all_lines"]["grade_average_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])
        report_h["charts"]["#{dimesion}_all_lines"]["class_average_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:average_percent])
        report_h["charts"]["#{dimesion}_gra_cls_avg_diff_line"][lv1_ckp_key] = convert_2_full_mark(item[:value][:average_percent] - item[:value][:gra_dim_lv1_avg_percent])
        # elsif(item[:_id][:dimesion] == "skill")
        #   report_h["charts"]["#{dimesion}_all_lines"]["grade_average_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])
        #   report_h["charts"]["#{dimesion}_all_lines"]["class_average_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:average_percent])
        #   report_h["charts"]["#{dimesion}_gra_cls_avg_diff_line"][lv1_ckp_key] = convert_2_full_mark(item[:value][:average_percent] - item[:value][:gra_dim_lv1_avg_percent])
        # elsif(item[:_id][:dimesion] == "ability")
        #   report_h["charts"]["ability_all_lines"]["grade_average_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])
        #   report_h["charts"]["ability_all_lines"]["class_average_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:average_percent])
        #   report_h["charts"]["ability_gra_cls_avg_diff_line"][lv1_ckp_key] = convert_2_full_mark(item[:value][:average_percent] - item[:value][:gra_dim_lv1_avg_percent])
        # end
        # not consider the level2 checkpoint at version 1.0
        #elsif(item[:id].keys.include?("lv2_ckp"))

        klass_report.report_json = report_h.to_json
        klass_report.save
      end
    }
 
    Mongodb::ReportStandDevDiffResult.where(filter).each{|item|
      #
      #grade
      #
      if !item[:_id].keys.include?("classroom")

        grade_report, report_h = get_grade_report_hash item
        lv1_ckp_key = item[:_id][:lv1_ckp].to_sym
        dimesion = item[:_id][:dimesion]

        report_h["charts"]["#{dimesion}_3lines"]["grade_median_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:median_percent])
        report_h["charts"]["#{dimesion}_3lines"]["grade_diff_degree"][lv1_ckp_key] = convert_2_full_mark(item[:value][:diff_degree])
        report_h["charts"]["#{dimesion}_med_avg_diff"][lv1_ckp_key] = convert_2_full_mark(item[:value][:median_percent] - item[:value][:average_percent])

        grade_report.report_json = report_h.to_json
        grade_report.save
      end

      #
      #classroom
      #
      if item[:_id].keys.include?("classroom")

        klass_report, report_h = get_class_report_hash item
        lv1_ckp_key = item[:_id][:lv1_ckp]
        dimesion = item[:_id][:dimesion]

        #if(item[:_id].keys.include?("lv1_ckp"))
          
          #if(item[:_id][:dimesion] == "knowledge")
        report_h["charts"]["#{dimesion}_all_lines"]["class_median_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:median_percent])
        report_h["charts"]["#{dimesion}_all_lines"]["diff_degree"][lv1_ckp_key] = convert_2_full_mark(item[:value][:diff_degree])
        report_h["charts"]["#{dimesion}_cls_mid_gra_avg_diff_line"][lv1_ckp_key] = convert_2_full_mark(item[:value][:median_percent] - item[:value][:gra_dim_lv1_avg_percent])
          # elsif(item[:_id][:dimesion] == "skill")
          #   report_h["charts"]["skill_all_lines"]["class_median_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:median_percent])
          #   report_h["charts"]["skill_all_lines"]["diff_degree"][lv1_ckp_key] = convert_2_full_mark(item[:value][:diff_degree])
          #   report_h["charts"]["skill_cls_mid_gra_avg_diff_line"][lv1_ckp_key] = convert_2_full_mark(item[:value][:median_percent] - item[:value][:gra_dim_lv1_avg_percent])
          
          # elsif(item[:_id][:dimesion] == "ability")
          #   report_h["charts"]["ability_all_lines"]["class_median_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:median_percent])
          #   report_h["charts"]["ability_all_lines"]["diff_degree"][lv1_ckp_key] = convert_2_full_mark(item[:value][:diff_degree])
          #   report_h["charts"]["ability_cls_mid_gra_avg_diff_line"][lv1_ckp_key] = convert_2_full_mark(item[:value][:median_percent] - item[:value][:gra_dim_lv1_avg_percent])
          # end
        # not consider the level2 checkpoint at version 1.0
        #elsif(item[:id].keys.include?("lv2_ckp"))
        #end
        klass_report.report_json = report_h.to_json
        klass_report.save
      end
    }
  end

  def construct_grade_dimesion_disperse_chart
    logger.info "construct grade dimesion disperse chart"

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => nil,
      '_id.pup_uid' => nil,
      '_id.dimesion' => {'$exists' => true },
      '_id.lv2_ckp' => {'$exists' => true }
    }

    Mongodb::ReportTotalAvgResult.where(filter).each{|item|
      #
      #grade
      #
      grade_report, report_h = get_grade_report_hash item
      lv2_ckp_key = item[:_id][:lv2_ckp].to_sym
      dimesion = item[:_id][:dimesion]

      report_h["charts"]["dimesion_disperse"][dimesion][lv2_ckp_key] = convert_2_full_mark(item[:value][:average_percent])

      grade_report.report_json = report_h.to_json
      grade_report.save
    }
  end

  def construct_each_level_pupil_number
    logger.info "construct class each level number"

    grade_filter = {
      '_id.pap_uid' => @pap_uid,
#      '_id.grade' => @paper.grade,
      '_id.classroom' => nil,
      '_id.lv1_ckp' => nil,
      '_id.lv2_ckp' => nil
    }

    #用于学生的报告
    grade_value_h = {}
    grade_records = Mongodb::ReportEachLevelPupilNumberResult.where(grade_filter)
    grade_records.each{|item|
      grade = item[:_id][:grade]
      if item[:_id].keys.include?('dimesion')
        dimesion = item[:_id][:dimesion]
      else
        dimesion = "total"
      end
      grade_value_h[grade]=grade_value_h[grade] || {}
      grade_value_h[grade][dimesion] = {
        "failed_pupil_percent" => convert_2_hundred(item[:value][:failed_percent]),
        "good_pupil_percent" => convert_2_hundred(item[:value][:good_percent]),
        "excellent_pupil_percent" => convert_2_hundred(item[:value][:excellent_percent])
      }
    }

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.pup_uid' => nil,
      '_id.lv2_ckp' => nil
    }

    Mongodb::ReportEachLevelPupilNumberResult.where(filter).each{|item|
      #grade
      #
      if item[:_id].keys.include?('dimesion') && item[:_id].keys.include?("lv1_ckp")

        grade_report, report_h = get_grade_report_hash item
        dimesion = item[:_id][:dimesion]
        lv1_ckp_key = item[:_id][:lv1_ckp]

        result_h = {
          "failed_pupil_percent" => convert_2_hundred(item[:value][:failed_percent]),
          "good_pupil_percent" => convert_2_hundred(item[:value][:good_percent]),
          "excellent_pupil_percent" => convert_2_hundred(item[:value][:excellent_percent])
        }

        if !item[:_id].keys.include?("classroom")
          report_h["each_level_number"]["grade_#{dimesion}"][lv1_ckp_key] = result_h
        else
          klass = I18n.t("dict.#{item[:_id][:classroom]}")
          ["failed_pupil_percent", "good_pupil_percent", "excellent_pupil_percent"].each{|member|
            temp_h = report_h["each_class_pupil_number_chart"][dimesion][member][klass] || {}
            temp_h[lv1_ckp_key] = result_h[member]
            report_h["each_class_pupil_number_chart"][dimesion][member][klass] = temp_h
          }
        end

        grade_report.report_json = report_h.to_json
        grade_report.save
      end

      #classroom
      if item[:_id].keys.include?("classroom") && !item[:_id].keys.include?("lv1_ckp")

        klass_report, report_h = get_class_report_hash item

        klass_value_h ={
          "failed_pupil_percent" => convert_2_hundred(item[:value][:failed_percent]),
          "good_pupil_percent" => convert_2_hundred(item[:value][:good_percent]),
          "excellent_pupil_percent" => convert_2_hundred(item[:value][:excellent_percent])
        }

        if item[:_id].keys.include?('dimesion')
          dimesion = item[:_id][:dimesion]

        #if(item[:_id][:dimesion] == "knowledge")
          report_h["each_level_number"]["class_three_dimesions"]["class_#{dimesion}"] = klass_value_h
          report_h["each_level_number"]["class_grade_#{dimesion}"]["class_#{dimesion}"] = klass_value_h
          report_h["each_level_number"]["class_grade_#{dimesion}"]["grade_#{dimesion}"] = grade_value_h[item[:_id][:grade]][dimesion]
        # elsif(item[:_id][:dimesion] == "skill") 
        #   report_h["each_level_number"]["class_three_dimesions"]["class_skill"] = klass_value_h
        #   report_h["each_level_number"]["class_grade_skill"]["class_skill"] = klass_value_h
        #   report_h["each_level_number"]["class_grade_skill"]["grade_skill"] = grade_value_h[item[:_id][:grade]]["skill"]
        # elsif(item[:_id][:dimesion] == "ability")
        #   report_h["each_level_number"]["class_three_dimesions"]["class_ability"] = klass_value_h
        #   report_h["each_level_number"]["class_grade_ability"]["class_ability"] = klass_value_h
        #   report_h["each_level_number"]["class_grade_ability"]["grade_ability"] = grade_value_h[item[:_id][:grade]]["ability"]
        # end
        else
          report_h["each_level_number"]["total"]["class"] = klass_value_h
          report_h["each_level_number"]["total"]["grade"] = grade_value_h[item[:_id][:grade]]["total"]
        end

        klass_report.report_json = report_h.to_json
        klass_report.save
      end
    }

  end

  def construct_data_table
    logger.info "construct data table"

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => {'$exists' => true },
      '_id.dimesion' => {'$exists' => true }
    }

    data_table, ckp_lv2_to_lv1 = get_ckp_table
    pupil_table = data_table.deep_dup

    Mongodb::ReportTotalAvgResult.where(filter).each{|item|
      #####班级######
      if !item[:_id].keys.include?("pup_uid")

        klass_report, report_h = get_class_report_hash item
        dimesion = item[:_id][:dimesion]
        if(item[:_id].keys.include?("lv1_ckp"))
          lv1_ckp_key = item[:_id][:lv1_ckp]
          next if !ckp_lv2_to_lv1[dimesion].values.include?(lv1_ckp_key)

          data_table[dimesion][lv1_ckp_key]["value"]["cls_average"] = format_float(item[:value][:cls_dim_lv1_avg])
          data_table[dimesion][lv1_ckp_key]["value"]["cls_average_percent"] = convert_2_full_mark(item[:value][:cls_dim_lv1_avg_percent])
          data_table[dimesion][lv1_ckp_key]["value"]["gra_average_percent"] = convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])
          data_table[dimesion][lv1_ckp_key]["value"]["cls_gra_avg_percent_diff"] = convert_2_full_mark(item[:value][:cls_dim_lv1_avg_percent] - item[:value][:gra_dim_lv1_avg_percent])
          data_table[dimesion][lv1_ckp_key]["value"]["full_score"] = format_float(item[:value][:full_mark])

        elsif(item[:_id].keys.include?("lv2_ckp")) 
          lv2_ckp_key = item[:_id][:lv2_ckp]
          lv1_ckp_key = ckp_lv2_to_lv1[dimesion][lv2_ckp_key]
          next if !ckp_lv2_to_lv1[dimesion].keys.include?(lv2_ckp_key)
          data_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["cls_average"] = format_float(item[:value][:cls_dim_lv2_avg])
          data_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["cls_average_percent"] = convert_2_full_mark(item[:value][:cls_dim_lv2_avg_percent])
          data_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["gra_average_percent"] = convert_2_full_mark(item[:value][:gra_dim_lv2_avg_percent])
          data_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["cls_gra_avg_percent_diff"] = convert_2_full_mark(item[:value][:cls_dim_lv2_avg_percent] - item[:value][:gra_dim_lv2_avg_percent])
          data_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["full_score"] = format_float(item[:value][:full_mark])

        end
        report_h["data_table"] = data_table
        klass_report.report_json = report_h.to_json
        klass_report.save
      end

      ######个人#####
      if item[:_id].keys.include?("pup_uid")

        pupil_report, pupil_report_h = get_pupil_report_hash item
        dimesion = item[:_id][:dimesion]
        if(item[:_id].keys.include?("lv1_ckp"))
          lv1_ckp_key = item[:_id][:lv1_ckp]
          next if !ckp_lv2_to_lv1[dimesion].values.include?(lv1_ckp_key)
          pupil_table[dimesion][lv1_ckp_key]["value"]["average"] = convert_2_full_mark(item[:value][:average])
          pupil_table[dimesion][lv1_ckp_key]["value"]["average_percent"] = convert_2_full_mark(item[:value][:average_percent])
          pupil_table[dimesion][lv1_ckp_key]["value"]["gra_average_percent"] = convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])
          pupil_table[dimesion][lv1_ckp_key]["value"]["pup_cls_avg_percent_diff"] = convert_2_full_mark(item[:value][:average_percent] - item[:value][:cls_dim_lv1_avg_percent])
          pupil_table[dimesion][lv1_ckp_key]["value"]["pup_gra_avg_percent_diff"] = convert_2_full_mark(item[:value][:average_percent] - item[:value][:gra_dim_lv1_avg_percent])
          pupil_table[dimesion][lv1_ckp_key]["value"]["full_score"] = format_float(item[:value][:full_mark])
          pupil_table[dimesion][lv1_ckp_key]["value"]["correct_qzp_count"] = format_float(item[:value][:qzp_count])
        elsif(item[:_id].keys.include?("lv2_ckp")) 
          lv2_ckp_key = item[:_id][:lv2_ckp]
          lv1_ckp_key = ckp_lv2_to_lv1[dimesion][lv2_ckp_key]
          next if !ckp_lv2_to_lv1[dimesion].keys.include?(lv2_ckp_key)
          pupil_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["average"] = convert_2_full_mark(item[:value][:average])
          pupil_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["average_percent"] = convert_2_full_mark(item[:value][:average_percent])
          pupil_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["gra_average_percent"] = convert_2_full_mark(item[:value][:gra_dim_lv2_avg_percent])
          pupil_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["pup_cls_avg_percent_diff"] = convert_2_full_mark(item[:value][:average_percent] - item[:value][:cls_dim_lv2_avg_percent])
          pupil_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["pup_gra_avg_percent_diff"] = convert_2_full_mark(item[:value][:average_percent] - item[:value][:gra_dim_lv2_avg_percent])
          pupil_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["full_score"] = format_float(item[:value][:full_mark])
          pupil_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["correct_qzp_count"] = format_float(item[:value][:qzp_count])
        end
        pupil_report_h["data_table"] = pupil_table
        pupil_report.report_json = pupil_report_h.to_json
        pupil_report.save
      end  
    }

    Mongodb::ReportStandDevDiffResult.where(filter).each{|item|
      #### here is the processing ######
      if !item[:_id].keys.include?("pup_uid")

        klass_report, report_h = get_class_report_hash item
        dimesion =item[:_id][:dimesion]
        if(item[:_id].keys.include?("lv1_ckp"))
          lv1_ckp_key = item[:_id][:lv1_ckp]
          next if !ckp_lv2_to_lv1[dimesion].values.include?(lv1_ckp_key)

          data_table[dimesion][lv1_ckp_key]["value"]["class_median_percent"] = convert_2_full_mark(item[:value][:median_percent])
          data_table[dimesion][lv1_ckp_key]["value"]["cls_med_gra_avg_percent_diff"] = convert_2_full_mark(item[:value][:median_percent] - item[:value][:gra_dim_lv1_avg_percent])
          data_table[dimesion][lv1_ckp_key]["value"]["diff_degree"] = convert_2_full_mark(item[:value][:diff_degree])

        elsif(item[:_id].keys.include?("lv2_ckp"))
          lv2_ckp_key = item[:_id][:lv2_ckp]
          lv1_ckp_key = ckp_lv2_to_lv1[dimesion][lv2_ckp_key]
          next if !ckp_lv2_to_lv1[dimesion].keys.include?(lv2_ckp_key)

          data_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["class_median_percent"] = convert_2_full_mark(item[:value][:median_percent])
          data_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["cls_med_gra_avg_percent_diff"] = convert_2_full_mark(item[:value][:median_percent] - item[:value][:gra_dim_lv2_avg_percent])
          data_table[dimesion][lv1_ckp_key]["items"][lv2_ckp_key]["value"]["diff_degree"] = convert_2_full_mark(item[:value][:diff_degree])

        end
        report_h["data_table"] = data_table
        klass_report.report_json = report_h.to_json
        klass_report.save
      end
    }

  end

  def construct_cls_each_qizpoint_average_percent
    logger.info "construct data table"

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.order' => {'$exists' => true }
    }

    Mongodb::ReportTotalAvgResult.where(filter).sort({"_id.order" =>1}).each{|item|
  
      target_report = nil
      report_h = {}

      #班级
      if item[:_id].keys.include?("classroom")
        target_report, report_h = get_class_report_hash item
      #年级
      elsif !item[:_id].keys.include?("classroom")
        target_report, report_h = get_grade_report_hash item
      end

      #统计各题答对率
      if(0 <= item[:value][:average_percent] && 
        item[:value][:average_percent] <Common::Report::ScoreLevel::Level60)
       report_h["average_percent"]["failed"][item[:_id][:order]] =format_float(item[:value][:average_percent])
      elsif(Common::Report::ScoreLevel::Level60 <= item[:value][:average_percent] && 
        item[:value][:average_percent] < Common::Report::ScoreLevel::Level85)
       report_h["average_percent"]["good"][item[:_id][:order]] =format_float(item[:value][:average_percent])
      elsif(Common::Report::ScoreLevel::Level85 <= item[:value][:average_percent] && 
        item[:value][:average_percent] <= 1)
       report_h["average_percent"]["excellent"][item[:_id][:order]] =format_float(item[:value][:average_percent])
      end
      #保存报告
      if target_report
        target_report.report_json = report_h.to_json
        target_report.save
      end

    }
  end

  #　personal reports
  def construct_pupil_charts
    logger.info "construct pupil all charts"

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.pup_uid' => {'$exists' => true },
      '_id.dimesion' => {'$exists' => true }
    }

    Mongodb::ReportTotalAvgResult.where(filter).each{|item|
      #pupils
      pupil_report, report_h = get_pupil_report_hash item
      if item[:id].keys.include?("lv1_ckp")
        lv1_ckp_key = item[:_id][:lv1_ckp]
        report_h["charts"]["#{item[:id][:dimesion]}_radar"]["grade_average"][lv1_ckp_key] = convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])
        report_h["charts"]["#{item[:id][:dimesion]}_radar"]["pupil_average"][lv1_ckp_key] = convert_2_full_mark(item[:value][:average_percent])
      elsif item[:id].keys.include?("lv2_ckp")
        lv2_ckp_key = item[:_id][:lv2_ckp]
        report_h["charts"]["#{item[:id][:dimesion]}_pup_gra_avg_diff_line"][lv2_ckp_key] = convert_2_full_mark(item[:value][:average_percent] - item[:value][:gra_dim_lv2_avg_percent])
      end
      pupil_report.report_json = report_h.to_json
      pupil_report.save
    }
  end

  def construct_pupil_quiz_comments
    logger.info "construct pupil quiz comments"

    filter = {
      :province => @province,
      :city => @city,
      :district => @district, 
      :school => @school,
      :pap_uid => @pap_uid
    }

    Mongodb::PupilReport.where(filter).each{|item|
      report_h = JSON.parse(item.report_json)

      comment_h ={
        :self_best_knowledge =>"",
        :self_best_skill =>"",
        :self_best_ability =>"",
        :inclass_best_knowledge =>"",
        :inclass_best_skill =>"",
        :inclass_best_ability =>"",
        :ingrade_worse_knowledge =>"",
        :ingrade_worse_skill =>"",
        :ingrade_worse_ability =>"",
        :ingrade_worse_cause =>"",
        :ingrade_worse_advice =>""
      }

      lv2_dimesion_key_h ={
        "knowledge" => report_h["data_table"]["knowledge"].values.map{|a| a['items'].keys[0]},
        "skill" => report_h["data_table"]["skill"].values.map{|a| a['items'].keys[0]},
        "ability" => report_h["data_table"]["ability"].values.map{|a| a['items'].keys[0]}
      }
      lv2_dimesion_value_h = {
        "knowledge" => report_h["data_table"]["knowledge"].values.map{|a| a['items'].values[0]["value"]},
        "skill" => report_h["data_table"]["skill"].values.map{|a| a['items'].values[0]["value"]},
        "ability" => report_h["data_table"]["ability"].values.map{|a| a['items'].values[0]["value"]}
      }

      self_best = {
        "knowledge" => lv2_dimesion_value_h["knowledge"].map{|a| a["average_percent"]}.max,
        "skill" => lv2_dimesion_value_h["skill"].map{|a| a["average_percent"]}.max,
        "ability" => lv2_dimesion_value_h["ability"].map{|a| a["average_percent"]}.max
      }

      inclass_best = {
        "knowledge" => lv2_dimesion_value_h["knowledge"].map{|a| a["pup_cls_avg_percent_diff"]}.max,
        "skill" => lv2_dimesion_value_h["skill"].map{|a| a["pup_cls_avg_percent_diff"]}.max,
        "ability" => lv2_dimesion_value_h["ability"].map{|a| a["pup_cls_avg_percent_diff"]}.max
      }

      ingrade_worse = {
        "knowledge" => 0,
        "skill" => 0,
        "ability" => 0
      }

      ["knowledge", "skill", "ability"].each{|dimesion|
        lv2_dimesion_value_h[dimesion].each_with_index{|member, index|
          #个人最佳表现
          cond = (member["average_percent"] == self_best[dimesion])
          if cond
            comment_h[("self_best_"+dimesion).to_sym] += lv2_dimesion_key_h[dimesion][index]
          end
          #与群体比最佳表现
          cond = (member["pup_cls_avg_percent_diff"] == inclass_best[dimesion] && member["pup_cls_avg_percent_diff"] > 0)
          if cond
            comment_h[("inclass_best_"+dimesion).to_sym] += lv2_dimesion_key_h[dimesion][index]
          end
          #低于年纪平均水平较多
          #对象指标：与年级差为年级平均的30%以上
          cond = (member["pup_gra_avg_percent_diff"]/member["gra_average_percent"].to_f).abs > 0.3 && member["pup_gra_avg_percent_diff"] < 0
          if cond
            comment_h[("ingrade_worse_"+dimesion).to_sym] = lv2_dimesion_key_h[dimesion][index]
          end
        }
      }    

      report_h["quiz_comment"] %= comment_h
      item.update(:report_json => report_h.to_json)
    }
  end

  #组装四分位区间表现情况
  def construct_grade_4sections
    logger.info "construct grade 4 sections"

    filter = {
      '_id.pap_uid' => @pap_uid，
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => nil,
      '_id.pup_uid' => nil,
      '_id.dimesion' => {'$exists' => true },
      '_id.lv1_ckp' => {'$exists' => true },
      '_id.lv2_ckp' => nil
    }

    Mongodb::ReportEachLevelPupilNumberResult.where(filter).each{|item|
      #grade
      grade_report, report_h = get_grade_report_hash item
      dimesion = item[:_id][:dimesion]
      lv1_ckp_key = item[:_id][:lv1_ckp]

      report_h["four_sections"]["level0"][dimesion][lv1_ckp_key] =  convert_2_hundred(item[:value][:level0_percent])
      report_h["four_sections"]["level25"][dimesion][lv1_ckp_key] =  convert_2_hundred(item[:value][:level25_percent])
      report_h["four_sections"]["level50"][dimesion][lv1_ckp_key] =  convert_2_hundred(item[:value][:level50_percent])
      report_h["four_sections"]["level75"][dimesion][lv1_ckp_key] =  convert_2_hundred(item[:value][:level75_percent])

      grade_report.report_json = report_h.to_json
      grade_report.save
    }
  end

  #组装各班指标表现水平图
  def construct_each_klass_each_ckp_horizon
    logger.info "construct each class horizon charts"

    filter = {
      '_id.pap_uid' => @pap_uid
    }

    Mongodb::ReportTotalAvgResult.where(filter).each{|item|
      if(item[:_id].keys.include?("grade") && 
        item[:_id].keys.include?("classroom") && 
        !item[:_id].keys.include?("pup_uid") && 
        item[:_id].keys.include?('dimesion') &&
        item[:_id].keys.include?("lv1_ckp") &&
        !item[:_id].keys.include?("lv2_ckp"))

        #grade
        grade_report, report_h = get_grade_report_hash item
        dimesion = item[:_id][:dimesion]
        klass = I18n.t("dict.#{item[:_id][:classroom]}")
        lv1_ckp_key = item[:_id][:lv1_ckp]

        temp_h = report_h["each_checkpoint_horizon"][dimesion]["average_percent"][klass] || {}
        temp_h[lv1_ckp_key] = convert_2_full_mark(item[:value]["average_percent".to_sym])
        report_h["each_checkpoint_horizon"][dimesion]["average_percent"][klass] = temp_h

        grade_report.report_json = report_h.to_json
        grade_report.save
      elsif(item[:_id].keys.include?("grade") && 
        item[:_id].keys.include?("classroom") && 
        !item[:_id].keys.include?("pup_uid") && 
        item[:_id].keys.include?('dimesion') &&
        !item[:_id].keys.include?("lv1_ckp") &&
        !item[:_id].keys.include?("lv2_ckp"))

        #grade
        grade_report, report_h = get_grade_report_hash item
        dimesion = item[:_id][:dimesion]
        klass = I18n.t("dict.#{item[:_id][:classroom]}")

        temp_h = report_h["each_checkpoint_horizon"]["total"]["average_percent"][klass] || {}
        temp_h[dimesion] = convert_2_full_mark(item[:value]["average_percent".to_sym])
        report_h["each_checkpoint_horizon"]["total"]["average_percent"][klass] = temp_h

        grade_report.report_json = report_h.to_json
        grade_report.save

      end
    }

    Mongodb::ReportStandDevDiffResult.where(filter).each{|item|
      if(item[:_id].keys.include?("grade") && 
        item[:_id].keys.include?("classroom") && 
        !item[:_id].keys.include?("pup_uid") && 
        item[:_id].keys.include?('dimesion') &&
        item[:_id].keys.include?("lv1_ckp") &&
        !item[:_id].keys.include?("lv2_ckp"))

        #grade
        grade_report, report_h = get_grade_report_hash item
        dimesion = item[:_id][:dimesion]
        klass = I18n.t("dict.#{item[:_id][:classroom]}")
        lv1_ckp_key = item[:_id][:lv1_ckp]

        ["median_percent", "med_avg_diff", "diff_degree"].each{|member|
          temp_h = report_h["each_checkpoint_horizon"][dimesion][member][klass] || {}
          if member == "med_avg_diff"
            temp_h[lv1_ckp_key] = convert_2_full_mark(item[:value][:median_percent] - item[:value][:average_percent])
          else
            temp_h[lv1_ckp_key] = convert_2_full_mark(item[:value][member.to_sym])
          end
          report_h["each_checkpoint_horizon"][dimesion][member][klass] = temp_h
        }

        grade_report.report_json = report_h.to_json
        grade_report.save
      elsif(item[:_id].keys.include?("grade") && 
        item[:_id].keys.include?("classroom") && 
        !item[:_id].keys.include?("pup_uid") && 
        item[:_id].keys.include?('dimesion') &&
        !item[:_id].keys.include?("lv1_ckp") &&
        !item[:_id].keys.include?("lv2_ckp"))

        #grade
        grade_report, report_h = get_grade_report_hash item
        dimesion = item[:_id][:dimesion]
        klass = I18n.t("dict.#{item[:_id][:classroom]}")

        ["median_percent", "med_avg_diff", "diff_degree"].each{|member|
          temp_h = report_h["each_checkpoint_horizon"]["total"][member][klass] || {}
          if member == "med_avg_diff"
            temp_h[dimesion] = convert_2_full_mark(item[:value][:median_percent] - item[:value][:average_percent])
          else
            temp_h[dimesion] = convert_2_full_mark(item[:value][member.to_sym])
          end
          report_h["each_checkpoint_horizon"]["total"][member][klass] = temp_h
        }

        grade_report.report_json = report_h.to_json
        grade_report.save

      end
    }
  end

  #组装班级诊断
  def construct_class_quiz_comments
    logger.info "construct class quiz comments"

    filter = {
      :province => @province,
      :city => @city,
      :district => @district, 
      :school => @school,
      :pap_uid => @pap_uid,
    }

    Mongodb::ClassReport.where(filter).each{|item|
      report_h = JSON.parse(item.report_json)

      template_h = {
        :head_title => "",
        :pupil_highest_items =>"",
        :pupil_lowest_items =>"",
        :higher_than_grade_items =>"",
        :lower_than_grade_items =>"",
        :klass_average_percent =>"",
        :level =>"",
        :than_grade =>"",
        :excellent_level_percent =>"",
        :excellent_level_percent_than_grade =>"",
        :good_level_percent =>"",
        :good_level_percent_than_grade =>"",
        :failed_level_percent => "",
        :failed_level_percent_than_grade => ""
      }

      comment_h = {
        :knowledge =>template_h.deep_dup,
        :skill =>template_h.deep_dup,
        :ability =>template_h.deep_dup
      }

      total_h={
        :pupil_highest_dimesions =>"",
        :pupil_lowest_dimesions =>"",
        :higher_than_grade_dimesions =>"",
        :lower_than_grade_dimesions =>"",
        :klass_average_percent =>"",
        :level =>"",
        :than_grade =>"",
        :excellent_level_percent =>"",
        :excellent_level_percent_than_grade =>"",
        :good_level_percent =>"",
        :good_level_percent_than_grade =>"",
        :failed_level_percent => "",
        :failed_level_percent_than_grade => "" 
      }
      total_higher_than_grade_dimesion = []
      total_lower_than_grade_dimesion = []

      #使用2级指标做判断
      lv2_dimesion_key_h ={
        "knowledge" => report_h["data_table"]["knowledge"].values.map{|a| a['items'].keys[0]},
        "skill" => report_h["data_table"]["skill"].values.map{|a| a['items'].keys[0]},
        "ability" => report_h["data_table"]["ability"].values.map{|a| a['items'].keys[0]}
      }
      lv2_dimesion_value_h = {
        "knowledge" => report_h["data_table"]["knowledge"].values.map{|a| a['items'].values[0]["value"]},
        "skill" => report_h["data_table"]["skill"].values.map{|a| a['items'].values[0]["value"]},
        "ability" => report_h["data_table"]["ability"].values.map{|a| a['items'].values[0]["value"]}
      }

      klass_best = {
        "knowledge" => lv2_dimesion_value_h["knowledge"].map{|a| a["cls_average_percent"]}.max,
        "skill" => lv2_dimesion_value_h["skill"].map{|a| a["cls_average_percent"]}.max,
        "ability" => lv2_dimesion_value_h["ability"].map{|a| a["cls_average_percent"]}.max
      }

      klass_worst = {
        "knowledge" => lv2_dimesion_value_h["knowledge"].map{|a| a["cls_average_percent"]}.min,
        "skill" => lv2_dimesion_value_h["skill"].map{|a| a["cls_average_percent"]}.min,
        "ability" => lv2_dimesion_value_h["ability"].map{|a| a["cls_average_percent"]}.min
      }

      ["knowledge", "skill", "ability"].each{|dimesion|
        comment_h[dimesion.to_sym][:head_title] = I18n.t("dict.#{dimesion}")
        lv2_dimesion_value_h[dimesion].each_with_index{|member, index|
          ###########学生最佳表现
          cond = (member["cls_average_percent"] == klass_best[dimesion])
          if cond
            comment_h[dimesion.to_sym][:pupil_highest_items] += lv2_dimesion_key_h[dimesion][index] + " "
          end
          ###########学生最差表现
          cond = (member["cls_average_percent"] == klass_worst[dimesion])
          if cond
            comment_h[dimesion.to_sym][:pupil_lowest_items] += lv2_dimesion_key_h[dimesion][index] + " "
          end

          ###########高于年级平均水平
          cond= (member["cls_gra_avg_percent_diff"] > 0)
          if cond
            comment_h[dimesion.to_sym][:higher_than_grade_items] += lv2_dimesion_key_h[dimesion][index] + " "
            total_higher_than_grade_dimesion << dimesion unless total_higher_than_grade_dimesion.include?(dimesion)
          end
          ###########低于年级平均水平
          cond= (member["cls_gra_avg_percent_diff"] < 0)
          if cond
            comment_h[dimesion.to_sym][:lower_than_grade_items] += lv2_dimesion_key_h[dimesion][index] + " "
            total_lower_than_grade_dimesion << dimesion unless total_lower_than_grade_dimesion.include?(dimesion)
          end 
        }
        ###########平均值
        #达到何水平判断
        comment_h[dimesion.to_sym][:klass_average_percent] = convert_2_full_mark(report_h["dimesion_values"][dimesion]["average_percent"])
        comment_h[dimesion.to_sym][:level] = judge_score_level(comment_h[dimesion.to_sym][:klass_average_percent])
        #与年级相比
        cls_gra_diff = report_h["dimesion_values"][dimesion]["average_percent"] - report_h["dimesion_values"][dimesion]["gra_average_percent"]
        comment_h[dimesion.to_sym][:than_grade] = judge_score_level(cls_gra_diff)
        ###########各比例学生百分比
        class_percent = report_h["each_level_number"]["class_grade_#{dimesion}"]["class_#{dimesion}"]
        grade_percent = report_h["each_level_number"]["class_grade_#{dimesion}"]["grade_#{dimesion}"]
        excellent_level_percent_than_grade = get_compare_value_label(class_percent["excellent_pupil_percent"],grade_percent["excellent_pupil_percent"])
        good_level_percent_than_grade = get_compare_value_label(class_percent["good_pupil_percent"],grade_percent["good_pupil_percent"])
        failed_level_percent_than_grade = get_compare_value_label(class_percent["failed_pupil_percent"],grade_percent["failed_pupil_percent"])

        comment_h[dimesion.to_sym][:excellent_level_percent] = class_percent["excellent_pupil_percent"]
        comment_h[dimesion.to_sym][:excellent_level_percent_than_grade] = excellent_level_percent_than_grade
        comment_h[dimesion.to_sym][:good_pupil_percent] = class_percent["good_pupil_percent"]
        comment_h[dimesion.to_sym][:good_level_percent_than_grade] = good_level_percent_than_grade
        comment_h[dimesion.to_sym][:failed_pupil_percent] = class_percent["failed_pupil_percent"]
        comment_h[dimesion.to_sym][:failed_level_percent_than_grade] = failed_level_percent_than_grade        
        report_h["quiz_comment"][dimesion] %= comment_h[dimesion.to_sym]
      }

      #总体情况
      best_dimesion = ""
      best_dimesion_max = klass_best.values.max
      klass_best.each{|k,v|
        best_dimesion = k if(v == best_dimesion_max)
      }
      total_h[:pupil_highest_dimesions] = I18n.t("dict.#{best_dimesion}")

      worst_dimesion = ""
      worst_dimesion_min = klass_worst.values.min
      klass_worst.each{|k,v|
        worst_dimesion = k if(v == worst_dimesion_min)
      }
      total_h[:pupil_lowest_dimesions] = I18n.t("dict.#{worst_dimesion}")

      total_h[:higher_than_grade_dimesions] = total_higher_than_grade_dimesion.join(" ")
      total_h[:lower_than_grade_dimesions] = total_lower_than_grade_dimesion.join(" ")
      total_h[:klass_average_percent] = format_float(comment_h.values.map{|item| item[:klass_average_percent]}.sum/3)
      total_h[:level] = judge_score_level total_h[:klass_average_percent]
      total_grade_average_percent = format_float(report_h["dimesion_values"].values.map{|item| item["gra_average_percent"]}.sum/3)
      total_h[:than_grade] = get_compare_value_label(total_h[:klass_average_percent],total_grade_average_percent)

      total_class_percent = report_h["each_level_number"]["total"]["class"]
      total_grade_percent = report_h["each_level_number"]["total"]["grade"]
      total_excellent_than_grade = get_compare_value_label(total_class_percent["excellent_pupil_percent"],total_grade_percent["excellent_pupil_percent"])
      total_good_than_grade = get_compare_value_label(total_class_percent["good_pupil_percent"],total_grade_percent["good_pupil_percent"])
      total_failed_than_grade = get_compare_value_label(total_class_percent["failed_pupil_percent"],total_grade_percent["failed_pupil_percent"])
      total_h[:excellent_level_percent] = total_class_percent["excellent_pupil_percent"]
      total_h[:excellent_level_percent_than_grade] = total_excellent_than_grade
      total_h[:good_pupil_percent] = total_class_percent["good_pupil_percent"]
      total_h[:good_level_percent_than_grade] = total_good_than_grade
      total_h[:failed_pupil_percent] = total_class_percent["failed_pupil_percent"]
      total_h[:failed_level_percent_than_grade] = total_failed_than_grade
      report_h["quiz_comment"]["total"] %= total_h 
    
      item.update(:report_json => report_h.to_json)
    }
  end

  #
  # 聚合计算: 开始
  #
  # calculate total,average, median, standardation ... of pupil, class and grade
  def cal_total_average_percent_scores
    return false if (@province.blank? || @city.blank? || @district.blank? || @school.blank? || @pap_uid.blank?)
    filter = {
      :province => @province,
      :city => @city,
      :district => @district, 
      :school => @school,
      :pap_uid => @pap_uid
    }

    map = %Q{
      function(){
        var real_total = this.weights * this.real_score;
        var full_total = this.weights * this.full_score;
        var value_obj = {
          pup_uids: this.pup_uid,
          pup_uid: this.pup_uid, 
          real_total: real_total, 
          real_score: this.real_score,
          full_total: full_total,
          full_score: this.full_score,
          full_mark: this.full_score,
          reduced: 0, 
          pupil_number: 1,
          average: this.real_score,
          average_percent: this.real_score/full_total,
          qzp_uids: this.qzp_uid,
          qzp_uid: this.qzp_uid,
          qzp_count: 1
        };
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, order: this.order}, 
           value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, dimesion: this.dimesion}, 
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, dimesion: this.dimesion, lv1_ckp: this.lv1_ckp}, 
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, dimesion: this.dimesion, lv2_ckp: this.lv2_ckp}, 
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, dimesion: this.dimesion}, 
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom},
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, order: this.order},
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, dimesion: this.dimesion, lv1_ckp: this.lv1_ckp},
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, dimesion: this.dimesion, lv2_ckp: this.lv2_ckp},
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, pup_uid: this.pup_uid, dimesion: this.dimesion},
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, pup_uid: this.pup_uid, dimesion: this.dimesion, lv1_ckp: this.lv1_ckp},
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, pup_uid: this.pup_uid, dimesion: this.dimesion, lv2_ckp: this.lv2_ckp},
          value_obj);
      }
    }

    #
    # real_total: 实际总分（所有人）
    # full_total: 原题总分（所有人）
    # number: 学生人数
    # average: 平均分 （个人,单项）
    # full_score: 满分值 （个人,单项）
    # average_percent: 平均得分率 
    #
    reduce = %Q{
      function(key,values){
        var result = {
          pup_uids: "",
          pup_uid: values[0].pup_uid, 
          real_total: 0, 
          real_score: 0,
          full_total: 0,
          full_score: 0,
          full_mark: 0,
          reduced: 1, 
          pupil_number: 0,
          average: 0,
          average_percent: 0,
          qzp_uids: "",
          qzp_uid: "",
          qzp_count: 0
        };

        var pup_arr = [];
        var qzp_arr = [];


        values.forEach(function(value){
          result.real_total += value.real_total;
          result.full_total += value.full_total;
          pup_arr = result.pup_uids.split(",");
          pup_arr.pop();
          if(pup_arr.indexOf(value.pup_uids) == -1 ){
            result.pup_uids += (value.pup_uids + ",");
            result.pupil_number += value.pupil_number;
          }
          qzp_arr = result.qzp_uids.split(",");
          qzp_arr.pop();
          if(value.real_score == value.full_score && qzp_arr.indexOf(value.qzp_uids) == -1){
            result.qzp_uids += (value.qzp_uids + ",");
            result.qzp_count += value.qzp_count;
          }
        });
       
        result.average = result.real_total/result.pupil_number;
        result.full_mark = result.full_total/result.pupil_number;
        result.average_percent = result.real_total/result.full_total;
        
        return result;
      }
    }
=begin
    finalize = %Q{
      function(key,value){
        if(!value.reduced){
          result = value;
          result.average = this.real_score;
          result.average_percent = this.real_score/this.full_score;
          result.qzp_count = 1;
          return result;
        } else {
          return value;
        }
      }
    }
=end

    Mongodb::BankQizpointScore.where(filter).map_reduce(map,reduce).out(:reduce => "mongodb_report_total_avg_results").execute
#    @report_share[:real_total_average_percent_score] = Mongodb::BankQizpointScore.where(filter).map_reduce(map,reduce).finalize(finalize).out(:inline => true).to_a


=begin 
    arr = Mongodb::BankQizpointScore.where(filter).map_reduce(map,reduce).finalize(finalize).out(:inline => true).to_a
    arr.each{|item|
      key = Set.new [item["_id"].values]
      @report_share[:real_total_average_percent_score][key] = item["value"]
    }
=end
  end

  # 
  # 各的分点条目添加如下字段:
  #
  # cls_dim_lv1_avg_percent: 班级1级指标平均得分率
  # cls_dim_lv2_avg_percent: 班级2级指标平均得分率
  # gra_dim_lv1_avg_percent: 年级1级指标平均得分率
  # gra_dim_lv2_avg_percent: 年级2级指标平均得分率
  #
  def add_avg_col
    filter = {
#      :province => @province,
#      :city => @city,
#      :district => @district, 
#      :school => @school,
      '_id.pap_uid' => @pap_uid，
      '_id.grade' => {'$exists' => true },
      '_id.dimesion' => {'$exists' => true },
      '_id.pup_uid' => nil
    }
    arr = Mongodb::ReportTotalAvgResult.where(filter).no_timeout # need add filter here, user_id or somethind

    add_avg_col_core 1, arr
=begin
    total_number = arr.size

    worker_number = 20
    worker_arr = []
    step = total_number/worker_number

    loop_number = (total_number%worker_number == 0)? worker_number : worker_number + 1
    loop_number.times.each{|index|
      worker_arr << Thread.new do
        logger.info(">>>>>>>>>>>>>>>>>>>>>>Thread (No. #{index}): Begin")
        start_pos = step*index
        end_pos = step*(index +1) - 1
        logger.info(">>>>>>>>>>>>>>>>>>>>>>Thread (No. #{index}) range: [#{start_pos}, #{end_pos}]")
        add_avg_col_core index, arr[start_pos..end_pos]
        logger.info(">>>>>>>>>>>>>>>>>>>>>>Thread (No. #{index}): End")
      end 
    }
    ThreadsWait.all_waits(*worker_arr)
=end
  end

  def add_avg_col_core th_index, arr
    total_num =arr.size
    arr.each_with_index{|item,index|
      logger.info(">>>>>>thread #{th_index}, current status (#{index}/#{total_num})<<<<<<") if index%100 == 0
      gra_common_cond = !item[:_id].keys.include?('classroom')
      cls_common_cond = item[:_id].keys.include?('classroom')
      qzp_score_common_cond = {
          '_id.pap_uid' => @pap_uid,
          #:ana_id => "", user id to filter result from mongodb_total_avg_result
          '_id.grade' => item[:_id][:grade],
          '_id.dimesion' => item[:_id][:dimesion]
      }
      qzp_score_upt_h = {}

      if cls_common_cond && item[:_id].keys.include?('lv1_ckp')
        qzp_score_common_cond['_id.classroom']=item[:_id][:classroom]
        qzp_score_common_cond['_id.lv1_ckp']=item[:_id][:lv1_ckp]
        qzp_score_upt_h['value.cls_dim_lv1_avg'] = item[:value][:average]
        qzp_score_upt_h['value.cls_dim_lv1_avg_percent'] = item[:value][:average_percent]
      elsif cls_common_cond && item[:_id].keys.include?('lv2_ckp')
        qzp_score_common_cond['_id.classroom']=item[:_id][:classroom]
        qzp_score_common_cond['_id.lv2_ckp']=item[:_id][:lv2_ckp]
        qzp_score_upt_h['value.cls_dim_lv2_avg'] = item[:value][:average]
        qzp_score_upt_h['value.cls_dim_lv2_avg_percent'] = item[:value][:average_percent]
      elsif cls_common_cond
        qzp_score_common_cond['_id.classroom']=item[:_id][:classroom]
        qzp_score_upt_h['value.cls_dim_avg'] = item[:value][:average]
        qzp_score_upt_h['value.cls_dim_avg_percent'] = item[:value][:average_percent]
      elsif gra_common_cond && item[:_id].keys.include?('lv1_ckp')
        qzp_score_common_cond['_id.lv1_ckp']=item[:_id][:lv1_ckp]
        qzp_score_upt_h['value.gra_dim_lv1_avg'] = item[:value][:average]
        qzp_score_upt_h['value.gra_dim_lv1_avg_percent'] = item[:value][:average_percent]
      elsif gra_common_cond && item[:_id].keys.include?('lv2_ckp')
        qzp_score_common_cond['_id.lv2_ckp']=item[:_id][:lv2_ckp]
        qzp_score_upt_h['value.gra_dim_lv2_avg'] = item[:value][:average]
        qzp_score_upt_h['value.gra_dim_lv2_avg_percent'] = item[:value][:average_percent]
      elsif gra_common_cond 
        #do nothing
        qzp_score_upt_h['value.gra_dim_avg'] = item[:value][:average]
        qzp_score_upt_h['value.gra_dim_avg_percent'] = item[:value][:average_percent]
      end
      unless qzp_score_upt_h.empty?
        results = Mongodb::ReportTotalAvgResult.where(qzp_score_common_cond).no_timeout
        results.each{|result| result.update_attributes(qzp_score_upt_h)}
      end
    }  
  end

  #
  #
  def cal_each_level_pupil_number
    return false if (@province.blank? || @city.blank? || @district.blank? || @school.blank? || @pap_uid.blank?)
    filter = {
#      :province => @province,
#      :city => @city,
#      :district => @district, 
#      :school => @school,
      '_id.pap_uid' => @pap_uid
    }

    map = %Q{
      function(){      

        var value_obj = {
          reduced: 0,
          average_percent: this.value.average_percent,
          total_number: 1,
          failed_pupil_number:  0,
          good_pupil_number: 0,
          excellent_pupil_number: 0,
          failed_percent: 0,
          good_percent: 0,
          excellent_percent: 0,
          level0_number: 0,
          level25_number: 0,
          level50_number: 0,
          level75_number: 0,
          level0_percent: 0,
          level25_percent: 0,
          level50_percent: 0,
          level75_percent: 0
        }

        if( 0.0 <= this.value.average_percent && this.value.average_percent < #{Common::Report::ScoreLevel::Level60} ){
          value_obj.failed_pupil_number = 1;
        } else if (#{Common::Report::ScoreLevel::Level60}<= this.value.average_percent && this.value.average_percent < #{Common::Report::ScoreLevel::Level85}){
          value_obj.good_pupil_number = 1;
        } else if (#{Common::Report::ScoreLevel::Level85} <= this.value.average_percent && this.value.average_percent <= 1.0){
          value_obj.excellent_pupil_number = 1;
        }


        if( 0.0 <= this.value.average_percent && this.value.average_percent <= #{Common::Report::ScoreLevel::Level25} ){
          value_obj.level0_number = 1;
        } else if (#{Common::Report::ScoreLevel::Level25} < this.value.average_percent && this.value.average_percent <= #{Common::Report::ScoreLevel::Level50}){
          value_obj.level25_number = 1;
        } else if (#{Common::Report::ScoreLevel::Level50} < this.value.average_percent && this.value.average_percent <= #{Common::Report::ScoreLevel::Level75}){
          value_obj.level50_number = 1;
        } else if (#{Common::Report::ScoreLevel::Level75} < this.value.average_percent && this.value.average_percent <= 1.0){
          value_obj.level75_number = 1;
        }  

        if(this._id.pup_uid && !this._id.lv1_ckp && !this._id.lv2_ckp){
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade
              }, 
              value_obj 
          );
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade,
                classroom: this._id.classroom,
              }, 
              value_obj 
          );
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade, 
                dimesion: this._id.dimesion
              }, 
              value_obj 
          );
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade, 
                classroom: this._id.classroom,
                dimesion: this._id.dimesion
              }, 
              value_obj
          );
        }
        if(this._id.pup_uid && this._id.lv1_ckp){
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade, 
                dimesion: this._id.dimesion,
                lv1_ckp: this._id.lv1_ckp
              }, 
              value_obj
          );
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade,
                classroom: this._id.classroom,
                dimesion: this._id.dimesion,
                lv1_ckp: this._id.lv1_ckp
              }, 
              value_obj 
          );
        }
        if(this._id.pup_uid && this._id.lv2_ckp){
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade, 
                dimesion: this._id.dimesion,
                lv2_ckp: this._id.lv2_ckp
              }, 
              value_obj
          );
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade,
                classroom: this._id.classroom,
                dimesion: this._id.dimesion,
                lv2_ckp: this._id.lv2_ckp
              }, 
              value_obj 
          );
        }
      }
    }

    reduce = %Q{
      function(key,values){
        var result = {
          reduced: 1,
          average_percent: 0,
          total_number: 0,
          failed_pupil_number:  0,
          good_pupil_number: 0,
          excellent_pupil_number: 0,
          failed_percent: 0,
          good_percent: 0,
          excellent_percent: 0,
          level0_number: 0,
          level25_number: 0,
          level50_number: 0,
          level75_number: 0,
          level0_percent: 0,
          level25_percent: 0,
          level50_percent: 0,
          level75_percent: 0
        }

        values.forEach(function(value){
          result.total_number += value.total_number;
          result.failed_pupil_number += value.failed_pupil_number;
          result.good_pupil_number += value.good_pupil_number;
          result.excellent_pupil_number += value.excellent_pupil_number;
          result.level0_number += value.level0_number;
          result.level25_number += value.level25_number;
          result.level50_number += value.level50_number;
          result.level75_number += value.level75_number;
        });

        result.failed_percent = result.failed_pupil_number/result.total_number;
        result.good_percent = result.good_pupil_number/result.total_number;
        result.excellent_percent = result.excellent_pupil_number/result.total_number;
        result.level0_percent = result.level0_number/result.total_number;
        result.level25_percent = result.level25_number/result.total_number;
        result.level50_percent = result.level50_number/result.total_number;
        result.level75_percent = result.level75_number/result.total_number;
        return result;
      }
    }
=begin
    finalize = %Q{
      function(key,value){
        if(!value.reduced){
          result = value;
          result.reduced = 0;
          result.total_number = 0;
          result.failed_pupil_number = 0;
          result.good_pupil_number = 0;
          result.excellent_pupil_number = 0;
          result.failed_percent = 0;
          result.good_percent = 0;
          result.excellent_percent = 0;
          result.level0_number = 0;
          result.level25_number = 0;
          result.level50_number = 0;
          result.level75_number = 0;
          result.level0_percent = 0;
          result.level25_percent = 0;
          result.level50_percent = 0;
          result.level75_percent = 0;

          return result;
        } else {
          return value;
        }
      }
    }
=end
    Mongodb::ReportTotalAvgResult.where(filter).map_reduce(map,reduce).out(:replace => "mongodb_report_each_level_pupil_number_results").execute
  end

  #
  # 
  def cal_standard_deviation_difference
    return false if (@province.blank? || @city.blank? || @district.blank? || @school.blank? || @pap_uid.blank?)
    filter = {
#      :province => @province,
#      :city => @city,
#      :district => @district, 
#      :school => @school,
      '_id.pap_uid' => @pap_uid
    }

    map = %Q{
      function(){
        if(this._id.pup_uid && !this._id.lv1_ckp && !this._id.lv2_ckp){
          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              classroom: this._id.classroom, 
              dimesion: this._id.dimesion},
            {
              reduced: 0,
              delta: 0,
              diff2_sum: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 1,
              pupil_number: this.value.pupil_number,
              median_percent: this.value.average_percent,
              median_number: 1,
              average: this.value.average,
              average_percent: this.value.average_percent,
              average_stack: this.value.average_percent,
              cls_dim_avg: this.value.cls_dim_avg,
              cls_dim_avg_percent: this.value.cls_dim_avg_percent,
              gra_dim_avg: this.value.gra_dim_avg,
              gra_dim_avg_percent: this.value.gra_dim_avg_percent
            }
          );
        }
        if(this._id.pup_uid && this._id.lv1_ckp){
          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              dimesion: this._id.dimesion, 
              lv1_ckp: this._id.lv1_ckp},
            {
              reduced: 0,
              delta: 0,
              diff2_sum: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 1,
              pupil_number: this.value.pupil_number,
              median_percent: this.value.average_percent,
              median_number: 1,
              average: this.value.average,
              average_percent: this.value.average_percent,
              average_stack: this.value.average_percent,
              gra_dim_lv1_avg: this.value.gra_dim_lv1_avg,
              gra_dim_lv1_avg_percent: this.value.gra_dim_lv1_avg_percent
            }
          );

          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              classroom: this._id.classroom, 
              dimesion: this._id.dimesion, 
              lv1_ckp: this._id.lv1_ckp},
            {
              reduced: 0,
              delta: 0,
              diff2_sum: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 1,
              pupil_number: this.value.pupil_number,
              median_percent: this.value.average_percent,
              median_number: 1,
              average: this.value.average,
              average_percent: this.value.average_percent,
              average_stack: this.value.average_percent,
              cls_dim_lv1_avg: this.value.cls_dim_lv1_avg,
              cls_dim_lv1_avg_percent: this.value.cls_dim_lv1_avg_percent,
              gra_dim_lv1_avg: this.value.gra_dim_lv1_avg,
              gra_dim_lv1_avg_percent: this.value.gra_dim_lv1_avg_percent
            }
          );
        }
        if(this._id.pup_uid && this._id.lv2_ckp){
          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              dimesion: this._id.dimesion, 
              lv2_ckp: this._id.lv2_ckp},
            {
              reduced: 0,
              delta: 0,
              diff2_sum: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 1,
              pupil_number: this.value.pupil_number,
              median_percent: this.value.average_percent,
              median_number: 1,
              average: this.value.average,
              average_percent: this.value.average_percent,
              average_stack: this.value.average_percent,
              gra_dim_lv2_avg: this.value.gra_dim_lv2_avg,
              gra_dim_lv2_avg_percent: this.value.gra_dim_lv2_avg_percent
            }
          );

          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              classroom: this._id.classroom, 
              dimesion: this._id.dimesion, 
              lv2_ckp: this._id.lv2_ckp},
            {
              reduced: 0,
              delta: 0,
              diff2_sum: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 1,
              pupil_number: this.value.pupil_number,
              median_percent: this.value.average_percent,
              median_number: 1,
              average: this.value.average,
              average_percent: this.value.average_percent,
              average_stack: this.value.average_percent,
              cls_dim_lv2_avg: this.value.cls_dim_lv2_avg,
              cls_dim_lv2_avg_percent: this.value.cls_dim_lv2_avg_percent,
              gra_dim_lv2_avg: this.value.gra_dim_lv2_avg,
              gra_dim_lv2_avg_percent: this.value.gra_dim_lv2_avg_percent
            }
          );
        }
      }
    }

    reduce = %Q{
      function(key,values){
        if(!key.hasOwnProperty('lv1_ckp') && !key.hasOwnProperty('lv2_ckp')){
          var result = {
              reduced: 1,
              delta: 0,
              diff2_sum: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 0,
              pupil_number: values[0].pupil_number,
              median_percent: 0,
              median_number: 0,
              average: values[0].average,
              average_percent: values[0].average_percent,
              average_stack: "",
              cls_dim_avg: values[0].cls_dim_avg,
              cls_dim_avg_percent: values[0].cls_dim_avg_percent,
              gra_dim_avg: values[0].gra_dim_avg,
              gra_dim_avg_percent: values[0].gra_dim_avg_percent
          };
        }
        if(key.hasOwnProperty('lv1_ckp')){
          if(key.hasOwnProperty('classroom')){
            var result = {
              reduced: 1,
              delta: 0,
              diff2_sum: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 0,
              pupil_number: values[0].pupil_number,
              median_percent: 0,
              median_number: 0,
              average: values[0].average,
              average_percent: values[0].average_percent,
              average_stack: "",
              cls_dim_lv1_avg: values[0].cls_dim_lv1_avg,
              cls_dim_lv1_avg_percent: values[0].cls_dim_lv1_avg_percent,
              gra_dim_lv1_avg: values[0].gra_dim_lv1_avg,
              gra_dim_lv1_avg_percent: values[0].gra_dim_lv1_avg_percent
            };
          } else {
            var result = {
              reduced: 1,
              delta: 0,
              diff2_sum: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 0,
              pupil_number: values[0].pupil_number,
              median_percent: 0,
              median_number: 0,
              average: values[0].average,
              average_percent: values[0].average_percent,
              average_stack: "",
              gra_dim_lv1_avg: values[0].gra_dim_lv1_avg,
              gra_dim_lv1_avg_percent: values[0].gra_dim_lv1_avg_percent
            };
          }
        }

        if(key.hasOwnProperty('lv2_ckp')){
          if(key.hasOwnProperty('classroom')){
            var result = {
              reduced: 1,
              delta: 0,
              diff2_sum: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 0,
              pupil_number: values[0].pupil_number,
              median_percent: 0,
              median_number: 0,
              average: values[0].average,
              average_percent: values[0].average_percent,
              average_stack: "",
              cls_dim_lv2_avg: values[0].cls_dim_lv2_avg,
              cls_dim_lv2_avg_percent: values[0].cls_dim_lv2_avg_percent,
              gra_dim_lv2_avg: values[0].gra_dim_lv2_avg,
              gra_dim_lv2_avg_percent: values[0].gra_dim_lv2_avg_percent
            };
          } else {
            var result = {
              reduced: 1,
              delta: 0,
              diff2_sum: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 0,
              pupil_number: values[0].pupil_number,
              median_percent: 0,
              median_number: 0,
              average: values[0].average,
              average_percent: values[0].average_percent,
              average_stack: "",
              gra_dim_lv2_avg: values[0].gra_dim_lv2_avg,
              gra_dim_lv2_avg_percent: values[0].gra_dim_lv2_avg_percent
            };
          }
        }

        values.forEach(function(value){
          result.current_pupil_number += value.current_pupil_number;
          if(key.hasOwnProperty('lv1_ckp')){
            if(key.hasOwnProperty('classroom')){
              result.delta += value.average - value.cls_dim_lv1_avg;
            } else {
              result.delta += value.average - value.gra_dim_lv1_avg;
            }
            result.diff2_sum += Math.pow(result.delta, 2);
          }

          if(key.hasOwnProperty('lv2_ckp')){
            if(key.hasOwnProperty('classroom')){
              result.delta += value.average - value.cls_dim_lv2_avg;
            } else {
              result.delta += value.average - value.gra_dim_lv2_avg;
            }
            result.diff2_sum += Math.pow(result.delta, 2);
          }
          
          result.average_stack += (value.average_stack + ",");
        });

        if((result.current_pupil_number&1)==0){
          result.median_number = result.current_pupil_number/2;
        } else {
          result.median_number = parseInt(result.current_pupil_number/2)+1;
        }

        var value_arr = result.average_stack.split(",");
        value_arr.pop();
        var sorted_values = value_arr.sort(function(a, b){ return a > b});
        result.median_percent = parseFloat(sorted_values[result.median_number-1]);

        result.current_pupil_number = (result.current_pupil_number == 0) ? 1:result.current_pupil_number;

        result.stand_dev = Math.sqrt(result.diff2_sum/result.current_pupil_number );

        if(key.hasOwnProperty('lv1_ckp')){ 
          if(key.hasOwnProperty('classroom')){
            result.diff_degree = result.stand_dev/result.cls_dim_lv1_avg;
          } else {
            result.diff_degree = result.stand_dev/result.gra_dim_lv1_avg;
          }         
        }

        if(key.hasOwnProperty('lv2_ckp')){ 
          if(key.hasOwnProperty('classroom')){
            result.diff_degree = result.stand_dev/result.cls_dim_lv2_avg;
          } else {
            result.diff_degree = result.stand_dev/result.gra_dim_lv2_avg;
          }         
        }
        return result;
      }
    }
=begin
    finalize = %Q{
      function(key,value){
        if(!value.reduced){
          result = value;
          result.reduced = 0;
          result.stand_dev = 0; 
          result.diff_degree = 0;
          result.median = 0;
          result.median_percent = 0;

          return result;
        } else {
          return value;
        }
      }
    }
=end
    Mongodb::ReportTotalAvgResult.where(filter).map_reduce(map,reduce).out(:replace => "mongodb_report_stand_dev_diff_results").execute
  end


  #
  # 聚合计算: 结束
  #


  private
  #
  # 
  #
  #年级报告
  def get_grade_report_hash item
    return nil, {} if (@province.blank? || @city.blank? || @district.blank? || @school.blank? || @pap_uid.blank? || item[:_id][:grade].blank?)
    grade_param = {
      :province => @province,
      :city => @city,
      :district => @district,
      :school => @school,
      :grade => item[:_id][:grade]
    }
    klass_count = Location.where(grade_param).size
    grade_param[:pap_uid] = @pap_uid
    grade_report = Mongodb::GradeReport.where(grade_param).first
    unless grade_report
      grade_report = Mongodb::GradeReport.new(grade_param) 
      report_h = Common::Report::Format::Grade.deep_dup
      #basic information
      report_h["basic"]["subject"] = @paper.subject
      report_h["basic"]["area"] = @area
      report_h["basic"]["school"] = @school_label
      report_h["basic"]["grade"] = I18n.t("dict.#{item[:_id][:grade]}")
      report_h["basic"]["klass_count"] = klass_count
      report_h["basic"]["quiz_type"] = @paper.quiz_type
#      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? "" : @paper.quiz_date.strftime("%Y-%m-%d %H:%M")
      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? "" : @paper.quiz_date.strftime("%Y-%m-%d")
      report_h["basic"]["levelword2"] = @paper.levelword2
      grade_report.update(:report_json => report_h.to_json)
    else
      report_h = JSON.parse(grade_report.report_json)
    end
    return grade_report, report_h
  end

  #取得班级报告
  def get_class_report_hash item
    return nil, {} if (@province.blank? || @city.blank? || @district.blank? || @school.blank? || @pap_uid.blank? || item[:_id][:grade].blank? ||item[:_id][:classroom].blank?)
    klass_param = {
      :province => @province,
      :city => @city,
      :district => @district,
      :school => @school,
      :grade => item[:_id][:grade],
      :classroom => item[:_id][:classroom],
      :pap_uid => @pap_uid
    }
    klass_report = Mongodb::ClassReport.where(klass_param).first
    unless klass_report
      klass_report = Mongodb::ClassReport.new(klass_param) 
      report_h = Common::Report::Format::Klass.deep_dup
      #basic information
      report_h["basic"]["subject"] = @paper.subject
      report_h["basic"]["area"] = @area
      report_h["basic"]["school"] = @school_label
      report_h["basic"]["grade"] = I18n.t("dict.#{item[:_id][:grade]}")
      report_h["basic"]["classroom"] = I18n.t("dict.#{item[:_id][:classroom]}")
      report_h["basic"]["quiz_type"] = @paper.quiz_type
#      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? "" : @paper.quiz_date.strftime("%Y-%m-%d %H:%M")
      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? "" : @paper.quiz_date.strftime("%Y-%m-%d")
      report_h["basic"]["levelword2"] = @paper.levelword2

      filter = {
        '_id.pap_uid' => @pap_uid,
        '_id.pup_uid' => nil,
        '_id.lv1_ckp' => nil,
        '_id.lv2_ckp' => nil,
        '_id.order' => nil,
        '_id.dimesion' => {'$exists' => true },
        '_id.classroom' => {'$exists' => true }
      }
      klass_results = Mongodb::ReportTotalAvgResult.where(filter)
      klass_results.each{|item|
        dimesion = item[:_id][:dimesion]
        report_h["dimesion_values"][dimesion]["average"] = item[:value][:cls_dim_avg]
        report_h["dimesion_values"][dimesion]["average_percent"] = item[:value][:cls_dim_avg_percent]
        report_h["dimesion_values"][dimesion]["gra_average"] = item[:value][:gra_dim_avg]
        report_h["dimesion_values"][dimesion]["gra_average_percent"] = item[:value][:gra_dim_avg_percent]
      }
      klass_report.update(:report_json => report_h.to_json)
    else
      report_h = JSON.parse(klass_report.report_json)
    end
    return klass_report, report_h
  end

  #取得学生报告
  def get_pupil_report_hash item
    return nil, {} if (@province.blank? || @city.blank? || @district.blank? || @school.blank? || @pap_uid.blank? || item[:_id][:pup_uid].blank?)
    pupil_param = {
      :province => @province,
      :city => @city,
      :district => @district,
      :school => @school,
      :grade => item[:_id][:grade],
      :classroom => item[:_id][:classroom],
      :pap_uid => @pap_uid,
      :pup_uid => item[:_id][:pup_uid]
    }
    pupil = Pupil.where(uid: item[:_id][:pup_uid]).first
    pupil_report = Mongodb::PupilReport.where(pupil_param).first
    unless pupil_report
      pupil_report = Mongodb::PupilReport.new(pupil_param) 
      report_h = Common::Report::Format::Pupil.deep_dup
      #basic information
      report_h["basic"]["area"] = @area
      report_h["basic"]["school"] = @school_label
      report_h["basic"]["grade"] = I18n.t("dict.#{item[:_id][:grade]}")
      report_h["basic"]["classroom"] = I18n.t("dict.#{item[:_id][:classroom]}")
      report_h["basic"]["subject"] = @paper.subject
      report_h["basic"]["name"] = pupil.nil?? "":pupil.name
      report_h["basic"]["sex"] = pupil.nil?? "":pupil.sex
#      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? "" : @paper.quiz_date.strftime("%Y-%m-%d %H:%M")
      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? "" : @paper.quiz_date.strftime("%Y-%m-%d")
      report_h["basic"]["levelword2"] = @paper.levelword2
      pupil_report.update(:report_json => report_h.to_json)
    else
      report_h = JSON.parse(pupil_report.report_json)
    end
    return pupil_report, report_h
  end

  def get_ckp_table
    result = {
      "knowledge" => {},
      "skill" => {},
      "ability" => {}
    }

    ckp_lv2_to_lv1 ={
      "knowledge" => {},
      "skill" => {},
      "ability" => {}
    }

    qzpoints = @paper.bank_quiz_qizs.map{|item| item.bank_qizpoint_qzps}.flatten
    ckps = qzpoints.map{|item| item.bank_checkpoint_ckps}.flatten.uniq
    ckps.each{|ckp|
      next unless ckp
      # search current level checkpoint
      lv1_ckp = BankCheckpointCkp.where("node_uid = '#{@paper.node_uid}' and rid = '#{ckp.rid.slice(0, 3)}'").first
      lv2_ckp = BankCheckpointCkp.where("node_uid = '#{@paper.node_uid}' and rid = '#{ckp.rid.slice(0, 6)}'").first

      lv1_temph = result[ckp.dimesion][lv1_ckp.checkpoint] || {"value"=> {}, "items"=> {}}
      result[ckp.dimesion][lv1_ckp.checkpoint] = lv1_temph
      result[ckp.dimesion][lv1_ckp.checkpoint]["items"][lv2_ckp.checkpoint] = {"value"=> {}, "items"=> {}}

      ckp_lv2_to_lv1[lv2_ckp.dimesion][lv2_ckp.checkpoint] = lv1_ckp.checkpoint
    }
    return result,ckp_lv2_to_lv1
  end

  def convert_2_hundred value
    format_float(value*100)
  end

  def convert_2_full_mark value
    #format_float(value*@paper.score)
    format_float(value*100)
  end

  def format_float value
    ("%0.02f" % value).to_f
  end

  def judge_score_level value
    #达到何水平判断
    if(value >= 0 &&
       value <= Common::Report::ScoreLevel::Level60)
      return I18n.t("reports.failed_level")
    elsif(value > Common::Report::ScoreLevel::Level60 &&
          value <= Common::Report::ScoreLevel::Level85)
      return I18n.t("reports.good_level")
    else(value > Common::Report::ScoreLevel::Level85 &&
         value <= 1 )
      return I18n.t("reports.excellent_level")
    end
  end

  def get_compare_value_label value1, value2
    if value1 < value2 
      return I18n.t("reports.lower_than")
    elsif value1 == value2
      return I18n.t("reports.equal_to")
    else
      return I18n.t("reports.higher_than")
    end
  end
=begin
  def flatten_hash_array harr
     harr.reduce Hash.new, :merge
  end
=end
end
