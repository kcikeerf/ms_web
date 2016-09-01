# -*- coding: UTF-8 -*-

require 'thwait'

class Mongodb::ReportGenerator
  include Mongoid::Document

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

    logger.debug("=====initialization: completed!=====")
  end

  def clear_old_data
    logger.debug("=====clear old data: begin=====")
    filter1 = {
      :pap_uid => @pap_uid
    }
    Mongodb::GradeReport.where(filter1).destroy_all
    Mongodb::ClassReport.where(filter1).destroy_all
    Mongodb::PupilReport.where(filter1).destroy_all

    filter2 = {
      '_id.pap_uid' => @pap_uid
    }
    Mongodb::ReportFourSectionPupilNumberResult.where(filter2).destroy_all
    Mongodb::ReportEachLevelPupilNumberResult.where(filter2).destroy_all
    Mongodb::ReportStandDevDiffResult.where(filter2).destroy_all
    Mongodb::ReportTotalAvgResult.where(filter2).destroy_all
    Mongodb::ReportQuizCommentsResult.where(filter2).destroy_all
    logger.debug("=====clear old data: end=====")
  end

  def when_completed
    logger.debug("=====completed: begin=====")
    @paper.update(paper_status: Common::Paper::Status::ReportCompleted)
    logger.debug(@paper.paper_status)
    logger.debug("=====completed: end=====")
  end

  def construct_gra_cls_charts
    logger.info "construct class all charts"

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.pup_uid' => nil,
      '_id.grade' => {'$exists' => true },
      '_id.dimesion' => {'$exists' => true },
      '_id.lv1_ckp' => {'$exists' => true },
      '_id.lv2_ckp' => nil,
      '_id.order' => nil
    }

    Mongodb::ReportTotalAvgResult.where(filter).each{|item|
      #
      #grade
      #
      if !item[:_id].keys.include?("classroom")

        grade_report, report_h = get_grade_report_hash item
        lv1_ckp_key = item[:_id][:lv1_ckp]
        lv1_ckp_order = item[:_id][:lv1_order]
        dimesion = item[:_id][:dimesion]

        #report_h["charts"]["#{dimesion}_3lines"]["grade_average_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:average_percent])
        temp_arr = report_h["charts"]["#{dimesion}_3lines"]["grade_average_percent"] || []
        target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_full_mark(item[:value][:average_percent])}]
        report_h["charts"]["#{dimesion}_3lines"]["grade_average_percent"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

        grade_report.report_json = report_h.to_json
        grade_report.save
      end

      #
      #classroom
      #
      if item[:_id].keys.include?("classroom")

        klass_report, report_h = get_class_report_hash item
        lv1_ckp_key = item[:_id][:lv1_ckp].to_sym
        lv1_ckp_order = item[:_id][:lv1_order]
        dimesion = item[:_id][:dimesion]

        #report_h["charts"]["#{dimesion}_all_lines"]["grade_average_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])
        temp_arr = report_h["charts"]["#{dimesion}_all_lines"]["grade_average_percent"] || []
        target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])}]
        report_h["charts"]["#{dimesion}_all_lines"]["grade_average_percent"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair


        #report_h["charts"]["#{dimesion}_all_lines"]["class_average_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:average_percent])
        temp_arr = report_h["charts"]["#{dimesion}_all_lines"]["class_average_percent"] || []
        target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_full_mark(item[:value][:average_percent])}]
        report_h["charts"]["#{dimesion}_all_lines"]["class_average_percent"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

#        report_h["charts"]["#{dimesion}_gra_cls_avg_diff_line"][lv1_ckp_key] = convert_diff_2_full_mark(item[:value][:average_percent],item[:value][:gra_dim_lv1_avg_percent])
        temp_arr = report_h["charts"]["#{dimesion}_gra_cls_avg_diff_line"] || []
        target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_diff_2_full_mark(item[:value][:average_percent],item[:value][:gra_dim_lv1_avg_percent])}]
        report_h["charts"]["#{dimesion}_gra_cls_avg_diff_line"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

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
        lv1_ckp_order = item[:_id][:lv1_order]
        dimesion = item[:_id][:dimesion]

        #report_h["charts"]["#{dimesion}_3lines"]["grade_median_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:median_percent])
        temp_arr = report_h["charts"]["#{dimesion}_3lines"]["grade_median_percent"] || []
        target_pair = [lv1_ckp_order ,{lv1_ckp_key => convert_2_full_mark(item[:value][:median_percent])}]
        report_h["charts"]["#{dimesion}_3lines"]["grade_median_percent"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

        #report_h["charts"]["#{dimesion}_3lines"]["grade_diff_degree"][lv1_ckp_key] = convert_2_full_mark(item[:value][:diff_degree])
        temp_arr = report_h["charts"]["#{dimesion}_3lines"]["grade_diff_degree"] || []
        target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_full_mark(item[:value][:diff_degree])}]
        report_h["charts"]["#{dimesion}_3lines"]["grade_diff_degree"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

        #report_h["charts"]["#{dimesion}_med_avg_diff"][lv1_ckp_key] = convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:average_percent])
        temp_arr = report_h["charts"]["#{dimesion}_med_avg_diff"] || []
        target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:average_percent])}]
        report_h["charts"]["#{dimesion}_med_avg_diff"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

        grade_report.report_json = report_h.to_json
        grade_report.save
      end

      #
      #classroom
      #
      if item[:_id].keys.include?("classroom")

        klass_report, report_h = get_class_report_hash item
        lv1_ckp_key = item[:_id][:lv1_ckp]
        lv1_ckp_order = item[:_id][:lv1_order]
        dimesion = item[:_id][:dimesion]

        #report_h["charts"]["#{dimesion}_all_lines"]["class_median_percent"][lv1_ckp_key] = convert_2_full_mark(item[:value][:median_percent])
        temp_arr = report_h["charts"]["#{dimesion}_all_lines"]["class_median_percent"] || []
        target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_full_mark(item[:value][:median_percent])}]
        report_h["charts"]["#{dimesion}_all_lines"]["class_median_percent"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

        #report_h["charts"]["#{dimesion}_all_lines"]["diff_degree"][lv1_ckp_key] = convert_2_full_mark(item[:value][:diff_degree])
        temp_arr = report_h["charts"]["#{dimesion}_all_lines"]["diff_degree"] || []
        target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_full_mark(item[:value][:diff_degree])}]
        report_h["charts"]["#{dimesion}_all_lines"]["diff_degree"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

        #report_h["charts"]["#{dimesion}_cls_mid_gra_avg_diff_line"][lv1_ckp_key] = convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:gra_dim_lv1_avg_percent])
        temp_arr = report_h["charts"]["#{dimesion}_cls_mid_gra_avg_diff_line"] || []
        target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:gra_dim_lv1_avg_percent])}]
        report_h["charts"]["#{dimesion}_cls_mid_gra_avg_diff_line"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

        klass_report.report_json = report_h.to_json
        klass_report.save
      end
    }

    #add dimesioin total
    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.pup_uid' => nil,
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => {'$exists' => true },
      '_id.dimesion' => {'$exists' => true },
      '_id.order' => nil,
      '_id.lv1_ckp' => nil,
      '_id.lv2_ckp' => nil
    }

    Mongodb::ReportTotalAvgResult.where(filter).each{|item|
        klass_report, report_h = get_class_report_hash item
        dimesion = item[:_id][:dimesion]
        report_h["charts"]["#{dimesion}_all_lines"]["grade_average_percent"].push([
            Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:rid], 
            {
              Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:label] => convert_2_full_mark(item[:value][:gra_dim_avg_percent])
            }
        ])
        report_h["charts"]["#{dimesion}_all_lines"]["class_average_percent"].push([
            Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:rid], 
            {
              Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:label] => convert_2_full_mark(item[:value][:average_percent])
            }
        ])
        report_h["charts"]["#{dimesion}_gra_cls_avg_diff_line"].push([
            Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:rid], 
            {
              Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:label] => convert_diff_2_full_mark(item[:value][:average_percent],item[:value][:gra_dim_avg_percent])
            }
        ])
        klass_report.report_json = report_h.to_json
        klass_report.save
    }
    Mongodb::ReportStandDevDiffResult.where(filter).each{|item|
        klass_report, report_h = get_class_report_hash item
        dimesion = item[:_id][:dimesion]
        report_h["charts"]["#{dimesion}_all_lines"]["class_median_percent"].push([
            Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:rid], 
            {
              Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:label] => convert_2_full_mark(item[:value][:median_percent])
            }
        ])
        report_h["charts"]["#{dimesion}_all_lines"]["diff_degree"].push([
            Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:rid], 
            {
              Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:label] => convert_2_full_mark(item[:value][:diff_degree])
            }
        ])
        report_h["charts"]["#{dimesion}_cls_mid_gra_avg_diff_line"].push([
            Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:rid], 
            {
              Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:label] => convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:gra_dim_avg_percent])
            }
        ])
        klass_report.report_json = report_h.to_json
        klass_report.save
    }
  end

  def construct_grade_dimesion_disperse_chart
    logger.info "construct grade dimesion disperse chart"

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => nil,
      '_id.pup_uid' => nil,
      '_id.order' => nil,
      '_id.dimesion' => {'$exists' => true },
      '_id.lv1_ckp' => nil,
      '_id.lv2_ckp' => {'$exists' => true }
    }

    Mongodb::ReportTotalAvgResult.where(filter).each{|item|
      grade_report, report_h = get_grade_report_hash item
      lv_ckp = item[:_id][:lv2_ckp]
      dimesion = item[:_id][:dimesion]

      temph = report_h["charts"]["dimesion_disperse"][dimesion][lv_ckp] || { :average_percent => 0, :diff_degree => 0 }
      temph[:average_percent] = convert_2_full_mark(item[:value][:average_percent])
      report_h["charts"]["dimesion_disperse"][dimesion][lv_ckp] = temph

      grade_report.report_json = report_h.to_json
      grade_report.save
    }

    Mongodb::ReportStandDevDiffResult.where(filter).each{|item|
      grade_report, report_h = get_grade_report_hash item
      lv_ckp = item[:_id][:lv2_ckp]
      dimesion = item[:_id][:dimesion]

      temph = report_h["charts"]["dimesion_disperse"][dimesion][lv_ckp] || { :average_percent => 0, :diff_degree => 0 }
      temph[:diff_degree] = convert_2_full_mark(item[:value][:diff_degree])
      report_h["charts"]["dimesion_disperse"][dimesion][lv_ckp] = temph

      grade_report.report_json = report_h.to_json
      grade_report.save
    }
  end

  def construct_each_level_pupil_number
    logger.info "construct each level number"

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
        lv1_ckp_order = item[:_id][:lv1_order]

        result_h = {
          "failed_pupil_percent" => convert_2_hundred(item[:value][:failed_percent]),
          "good_pupil_percent" => convert_2_hundred(item[:value][:good_percent]),
          "excellent_pupil_percent" => convert_2_hundred(item[:value][:excellent_percent])
        }

        if !item[:_id].keys.include?("classroom")
          #report_h["each_level_number"]["grade_#{dimesion}"][lv1_ckp_key] = result_h
          temp_arr = report_h["each_level_number"]["grade_#{dimesion}"] || []
          target_pair = [lv1_ckp_order, {lv1_ckp_key => result_h }]
          report_h["each_level_number"]["grade_#{dimesion}"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair          
        else
          klass = I18n.t("dict.#{item[:_id][:classroom]}")
          ["failed_pupil_percent", "good_pupil_percent", "excellent_pupil_percent"].each{|member|

            temp_arr = report_h["each_class_pupil_number_chart"][dimesion][member] || []
            target_klass = temp_arr.assoc(klass)
            if klass && target_klass
              pos = temp_arr.index(target_klass) || temp_arr.size
              
              #report_h["each_class_pupil_number_chart"][dimesion][member][pos][1][lv1_ckp_key] = result_h[member]
              temp_arr = report_h["each_class_pupil_number_chart"][dimesion][member][pos][1] || []
              target_pair = [lv1_ckp_order, {lv1_ckp_key => result_h[member]}]
              report_h["each_class_pupil_number_chart"][dimesion][member][pos][1] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

            elsif klass
              target_pair = [klass, [[lv1_ckp_order, {lv1_ckp_key => result_h[member]}]]]
              report_h["each_class_pupil_number_chart"][dimesion][member] = insert_item_to_a_with_order "klass", temp_arr, target_pair
            else 
              next
            end

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

          report_h["each_level_number"]["class_three_dimesions"]["class_#{dimesion}"] = klass_value_h
          report_h["each_level_number"]["class_grade_#{dimesion}"]["class_#{dimesion}"] = klass_value_h
          report_h["each_level_number"]["class_grade_#{dimesion}"]["grade_#{dimesion}"] = grade_value_h[item[:_id][:grade]][dimesion]

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
      '_id.dimesion' => {'$exists' => true },
      '_id.order' => nil
    }

    data_table, ckp_lv2_to_lv1 = get_ckp_table
    Mongodb::ReportTotalAvgResult.where(filter).each{|item|
      #####班级######
      if !item[:_id].keys.include?("pup_uid")

        klass_report, kreport_h = get_class_report_hash item
        dimesion = item[:_id][:dimesion]
        kdata_dim_table = kreport_h["data_table"][dimesion].empty?? data_table[dimesion].deep_dup : kreport_h["data_table"][dimesion]
        if(item[:_id].keys.include?("lv1_ckp"))
          lv1_ckp_key = item[:_id][:lv1_ckp]
          lv1_ckp_order = item[:_id][:lv1_order]
          next unless lv1_ckp_order
          lv1_obj = kdata_dim_table.assoc(lv1_ckp_order)
          pos = kdata_dim_table.index(lv1_obj)
          next unless pos

          kdata_dim_table[pos][1]["label"] = lv1_ckp_key
          kdata_dim_table[pos][1]["value"]["cls_average"] = format_float(item[:value][:cls_dim_lv1_avg])
          kdata_dim_table[pos][1]["value"]["cls_average_percent"] = convert_2_full_mark(item[:value][:cls_dim_lv1_avg_percent])
          kdata_dim_table[pos][1]["value"]["gra_average_percent"] = convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])
          kdata_dim_table[pos][1]["value"]["cls_gra_avg_percent_diff"] = convert_diff_2_full_mark(item[:value][:cls_dim_lv1_avg_percent],item[:value][:gra_dim_lv1_avg_percent])
          kdata_dim_table[pos][1]["value"]["full_score"] = format_float(item[:value][:full_mark])

        elsif(item[:_id].keys.include?("lv2_ckp")) 
          lv2_ckp_key = item[:_id][:lv2_ckp]
          lv2_ckp_order = item[:_id][:lv2_order]
          lv1_ckp_key = ckp_lv2_to_lv1[dimesion][lv2_ckp_order]["lv1_ckp"]
          lv1_ckp_order = ckp_lv2_to_lv1[dimesion][lv2_ckp_order]["lv1_order"]
          next unless lv1_ckp_order
          lv1_obj = kdata_dim_table.assoc(lv1_ckp_order)
          pos_lv1 = kdata_dim_table.index(lv1_obj);
          next unless pos_lv1
          lv2_obj = kdata_dim_table[pos_lv1][1]["items"].assoc(lv2_ckp_order)
          pos_lv2 = kdata_dim_table[pos_lv1][1]["items"].index(lv2_obj)
          next unless pos_lv2

          kdata_dim_table[pos_lv1][1]["items"][pos_lv2][1]["label"] = lv2_ckp_key
          kdata_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["cls_average"] = format_float(item[:value][:cls_dim_lv2_avg])
          kdata_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["cls_average_percent"] = convert_2_full_mark(item[:value][:cls_dim_lv2_avg_percent])
          kdata_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["gra_average_percent"] = convert_2_full_mark(item[:value][:gra_dim_lv2_avg_percent])
          kdata_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["cls_gra_avg_percent_diff"] = convert_diff_2_full_mark(item[:value][:cls_dim_lv2_avg_percent],item[:value][:gra_dim_lv2_avg_percent])
          kdata_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["full_score"] = format_float(item[:value][:full_mark])

        else
          kdata_dim_table.unshift([Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:rid], 
            {
              "label" => Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:label],
              "value" => {
                "cls_average" => format_float(item[:value][:cls_dim_avg]),
                "cls_average_percent" => convert_2_full_mark(item[:value][:cls_dim_avg_percent]),
                "gra_average_percent" => convert_2_full_mark(item[:value][:gra_dim_avg_percent]),
                "cls_gra_avg_percent_diff" => convert_diff_2_full_mark(item[:value][:cls_dim_avg_percent],item[:value][:gra_dim_avg_percent]),
                "full_score" => format_float(item[:value][:full_mark])
              },
              "items" => []
            }
          ])
          kreport_h["basic"]["value_ratio"][dimesion] =  (item[:value][:full_mark] != 0)? @paper.score/item[:value][:full_mark]:0
        end
        kreport_h["data_table"][dimesion] = kdata_dim_table
        klass_report.report_json = kreport_h.to_json
        klass_report.save
      end

      ######个人#####
      if item[:_id].keys.include?("pup_uid")

        pupil_report, pupil_report_h = get_pupil_report_hash item
        dimesion = item[:_id][:dimesion]
        pupil_dim_table = pupil_report_h["data_table"][dimesion].empty?? data_table[dimesion].deep_dup : pupil_report_h["data_table"][dimesion]
        if(item[:_id].keys.include?("lv1_ckp"))
          lv1_ckp_key = item[:_id][:lv1_ckp]
          lv1_ckp_order = item[:_id][:lv1_order]
          next unless lv1_ckp_order
          
          lv1_obj = pupil_dim_table.assoc(lv1_ckp_order)
          pos = pupil_dim_table.index(lv1_obj)
          next unless pos

          pupil_dim_table[pos][1]["label"] = lv1_ckp_key
          pupil_dim_table[pos][1]["value"]["average"] = format_float(item[:value][:average])
          pupil_dim_table[pos][1]["value"]["average_percent"] = convert_2_full_mark(item[:value][:average_percent])
          pupil_dim_table[pos][1]["value"]["gra_average_percent"] = convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])
          pupil_dim_table[pos][1]["value"]["pup_cls_avg_percent_diff"] = convert_diff_2_full_mark(item[:value][:average_percent],item[:value][:cls_dim_lv1_avg_percent])
          pupil_dim_table[pos][1]["value"]["pup_gra_avg_percent_diff"] = convert_diff_2_full_mark(item[:value][:average_percent],item[:value][:gra_dim_lv1_avg_percent])
          pupil_dim_table[pos][1]["value"]["full_score"] = format_float(item[:value][:full_mark])
          pupil_dim_table[pos][1]["value"]["correct_qzp_count"] = format_float(item[:value][:qzp_count])

        elsif(item[:_id].keys.include?("lv2_ckp")) 
          lv2_ckp_key = item[:_id][:lv2_ckp]
          lv2_ckp_order = item[:_id][:lv2_order]
          lv1_ckp_key = ckp_lv2_to_lv1[dimesion][lv2_ckp_order]["lv1_ckp"]
          lv1_ckp_order = ckp_lv2_to_lv1[dimesion][lv2_ckp_order]["lv1_order"]
          next unless lv1_ckp_order
          lv1_obj = pupil_dim_table.assoc(lv1_ckp_order)
          pos_lv1 = pupil_dim_table.index(lv1_obj);
          next unless pos_lv1
          lv2_obj = pupil_dim_table[pos_lv1][1]["items"].assoc(lv2_ckp_order)
          pos_lv2 = pupil_dim_table[pos_lv1][1]["items"].index(lv2_obj)
          next unless pos_lv2

          pupil_dim_table[pos_lv1][1]["items"][pos_lv2][1]["label"] = lv2_ckp_key
          pupil_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["average"] = format_float(item[:value][:average])
          pupil_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["average_percent"] = convert_2_full_mark(item[:value][:average_percent])
          pupil_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["gra_average_percent"] = convert_2_full_mark(item[:value][:gra_dim_lv2_avg_percent])
          pupil_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["pup_cls_avg_percent_diff"] = convert_diff_2_full_mark(item[:value][:average_percent],item[:value][:cls_dim_lv2_avg_percent])
          pupil_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["pup_gra_avg_percent_diff"] = convert_diff_2_full_mark(item[:value][:average_percent],item[:value][:gra_dim_lv2_avg_percent])
          pupil_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["full_score"] = format_float(item[:value][:full_mark])
          pupil_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["correct_qzp_count"] = format_float(item[:value][:qzp_count])
        else
          pupil_dim_table.unshift([Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:rid], 
            {
              "label" => Common::CheckpointCkp::ReservedCkpRid[dimesion.to_sym][:total][:label],
              "value" => {
                "average" => format_float(item[:value][:average]),
                "average_percent" => convert_2_full_mark(item[:value][:average_percent]),
                "gra_average_percent" => convert_2_full_mark(item[:value][:gra_dim_avg_percent]),
                "pup_cls_avg_percent_diff" => convert_diff_2_full_mark(item[:value][:average_percent],item[:value][:cls_dim_avg_percent]),
                "pup_gra_avg_percent_diff" => convert_diff_2_full_mark(item[:value][:average_percent],item[:value][:gra_dim_avg_percent]),
                "full_score" => format_float(item[:value][:full_mark]),
                "correct_qzp_count" => format_float(item[:value][:qzp_count])
              },
              "items" => []
            }
          ])
          if dimesion == Common::CheckpointCkp::Dimesion::Knowledge
            pupil_report_h["basic"]["score"] = format_float(item[:value][:average]) 
          end
          pupil_report_h["basic"]["value_ratio"][dimesion] = (item[:value][:full_mark] != 0)? @paper.score/item[:value][:full_mark]:0
        end
        pupil_report_h["data_table"][dimesion] = pupil_dim_table
        pupil_report.report_json = pupil_report_h.to_json
        pupil_report.save
      end  
    }

    Mongodb::ReportStandDevDiffResult.where(filter).each{|item|
      #### here is the processing ######
      if !item[:_id].keys.include?("pup_uid")

        klass_report, kreport_h = get_class_report_hash item
        dimesion = item[:_id][:dimesion]
        kdata_dim_table = kreport_h["data_table"][dimesion].empty?? data_table[dimesion].deep_dup : kreport_h["data_table"][dimesion]
        if(item[:_id].keys.include?("lv1_ckp"))
          lv1_ckp_key = item[:_id][:lv1_ckp]
          lv1_ckp_order = item[:_id][:lv1_order]
          next unless lv1_ckp_order
          lv1_obj = kdata_dim_table.assoc(lv1_ckp_order)
          pos = kdata_dim_table.index(lv1_obj)
          next unless pos

          kdata_dim_table[pos][1]["label"] = lv1_ckp_key
          kdata_dim_table[pos][1]["value"]["class_median_percent"] = convert_2_full_mark(item[:value][:median_percent])
          kdata_dim_table[pos][1]["value"]["cls_med_gra_avg_percent_diff"] = convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:gra_dim_lv1_avg_percent])
          kdata_dim_table[pos][1]["value"]["diff_degree"] = convert_2_full_mark(item[:value][:diff_degree])

        elsif(item[:_id].keys.include?("lv2_ckp"))
          lv2_ckp_key = item[:_id][:lv2_ckp]
          lv2_ckp_order = item[:_id][:lv2_order]
          lv1_ckp_key = ckp_lv2_to_lv1[dimesion][lv2_ckp_order]["lv1_ckp"]
          lv1_ckp_order = ckp_lv2_to_lv1[dimesion][lv2_ckp_order]["lv1_order"]
          next unless lv1_ckp_order
          lv1_obj = kdata_dim_table.assoc(lv1_ckp_order)
          pos_lv1 = kdata_dim_table.index(lv1_obj);
          next unless pos_lv1
          lv2_obj = kdata_dim_table[pos_lv1][1]["items"].assoc(lv2_ckp_order)
          pos_lv2 = kdata_dim_table[pos_lv1][1]["items"].index(lv2_obj)
          next unless pos_lv2

          kdata_dim_table[pos_lv1][1]["items"][pos_lv2][1]["label"] = lv2_ckp_key
          kdata_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["class_median_percent"] = convert_2_full_mark(item[:value][:median_percent])
          kdata_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["cls_med_gra_avg_percent_diff"] = convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:gra_dim_lv2_avg_percent])
          kdata_dim_table[pos_lv1][1]["items"][pos_lv2][1]["value"]["diff_degree"] = convert_2_full_mark(item[:value][:diff_degree])
        
        else
          kdata_dim_table[0][1]["value"]["class_median_percent"] = convert_2_full_mark(item[:value][:median_percent])
          kdata_dim_table[0][1]["value"]["cls_med_gra_avg_percent_diff"] = convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:gra_dim_avg_percent])
          kdata_dim_table[0][1]["value"]["diff_degree"] = convert_2_full_mark(item[:value][:diff_degree])
        end
        kreport_h["data_table"][dimesion] = kdata_dim_table
        klass_report.report_json = kreport_h.to_json
        klass_report.save
      end
    }

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => nil,
      '_id.pup_uid' => {'$exists' => true },
      '_id.dimesion' => Common::CheckpointCkp::Dimesion::Knowledge,
      '_id.lv1_ckp' => nil,
      '_id.lv2_ckp' => nil
      }

    Mongodb::ReportStandDevDiffResult.where(filter).each{|item|
      pupil_report, pupil_report_h = get_pupil_report_hash item
      dimesion = item[:_id][:dimesion]
      pupil_report_h["basic"]["grade_rank"] = item[:value][:grade_rank]
      pupil_report.report_json = pupil_report_h.to_json
      pupil_report.save
    }

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => nil,
      '_id.dimesion' => {'$exists' => true },
      '_id.pup_uid' => {'$exists' => true },
      '_id.lv1_ckp' => nil,
      '_id.lv2_ckp' => nil,
      '_id.order' => nil
    }
    Mongodb::ReportFourSectionPupilNumberResult.where(filter).each{|item|
      pupil_report, pupil_report_h = get_pupil_report_hash item
      dimesion = item[:_id][:dimesion]
      pupil_report_h["percentile"][dimesion] = format_float(item[:value][:percentile])
      pupil_report.report_json = pupil_report_h.to_json
      pupil_report.save
    }
  end

  def construct_gra_cls_each_qizpoint_average_percent
    logger.info "construct data table"

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.pup_uid' => nil,
      '_id.dimesion' => Common::CheckpointCkp::Dimesion::Knowledge,
      '_id.order' => {'$exists' => true },
      '_id.lv2_ckp' => {'$exists' => true }
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

      next if report_h.blank?
      next unless report_h.keys.include?("average_percent")

      #统计各题答对率
      level_key = "others"
      target_pair = [item[:_id][:order],{:correct_ratio => format_float(item[:value][:average_percent]), :checkpoint => item[:_id][:lv2_ckp]}]
      if(0 <= item[:value][:average_percent] && 
       item[:value][:average_percent] <Common::Report::ScoreLevel::Level60)
       level_key = "failed"
      elsif(Common::Report::ScoreLevel::Level60 <= item[:value][:average_percent] && 
       item[:value][:average_percent] < Common::Report::ScoreLevel::Level85)
       level_key = "good"
      elsif(Common::Report::ScoreLevel::Level85 <= item[:value][:average_percent] && 
       item[:value][:average_percent] <= 1)
       level_key = "excellent"
      end
      report_h["average_percent"][level_key] = insert_item_to_a_with_order "quiz", report_h["average_percent"][level_key],target_pair

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
      '_id.dimesion' => {'$exists' => true },
      '_id.order' => nil
    }

    Mongodb::ReportTotalAvgResult.where(filter).each{|item|
      #pupils
      pupil_report, report_h = get_pupil_report_hash item
      if item[:id].keys.include?("lv1_ckp")
        lv1_ckp_key = item[:_id][:lv1_ckp]
        lv1_ckp_order = item[:_id][:lv1_order]
        # report_h["charts"]["#{item[:id][:dimesion]}_radar"]["grade_average"][lv1_ckp_key] = convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])
        temp_arr = report_h["charts"]["#{item[:id][:dimesion]}_radar"]["grade_average"] || []
        target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_full_mark(item[:value][:gra_dim_lv1_avg_percent])}]
        report_h["charts"]["#{item[:id][:dimesion]}_radar"]["grade_average"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

        #report_h["charts"]["#{item[:id][:dimesion]}_radar"]["pupil_average"][lv1_ckp_key] = convert_2_full_mark(item[:value][:average_percent])
        temp_arr = report_h["charts"]["#{item[:id][:dimesion]}_radar"]["pupil_average"] || []
        target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_full_mark(item[:value][:average_percent])}]
        report_h["charts"]["#{item[:id][:dimesion]}_radar"]["pupil_average"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair
      elsif item[:id].keys.include?("lv2_ckp")
        lv2_ckp_key = item[:_id][:lv2_ckp]
        lv2_ckp_order = item[:_id][:lv2_order]
        #report_h["charts"]["#{item[:id][:dimesion]}_pup_gra_avg_diff_line"][lv2_ckp_key] = convert_diff_2_full_mark(item[:value][:average_percent],item[:value][:gra_dim_lv2_avg_percent])
        temp_arr = report_h["charts"]["#{item[:id][:dimesion]}_pup_gra_avg_diff_line"] || []
        target_pair = [lv2_ckp_order, {lv2_ckp_key => convert_diff_2_full_mark(item[:value][:average_percent],item[:value][:gra_dim_lv2_avg_percent])}]
        report_h["charts"]["#{item[:id][:dimesion]}_pup_gra_avg_diff_line"] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair
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
        "knowledge" => report_h["data_table"]["knowledge"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["label"]}}.flatten,
        "skill" => report_h["data_table"]["skill"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["label"]}}.flatten,
        "ability" => report_h["data_table"]["ability"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["label"]}}.flatten
      }
      lv2_dimesion_value_h = {
        "knowledge" => report_h["data_table"]["knowledge"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["value"]}}.flatten,
        "skill" => report_h["data_table"]["skill"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["value"]}}.flatten,
        "ability" => report_h["data_table"]["ability"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["value"]}}.flatten
      }

      self_best = {
        "knowledge" => lv2_dimesion_value_h["knowledge"].map{|a| a["average_percent"]}.compact.max,
        "skill" => lv2_dimesion_value_h["skill"].map{|a| a["average_percent"]}.compact.max,
        "ability" => lv2_dimesion_value_h["ability"].map{|a| a["average_percent"]}.compact.max
      }

      inclass_best = {
        "knowledge" => lv2_dimesion_value_h["knowledge"].map{|a| a["pup_cls_avg_percent_diff"]}.compact.max,
        "skill" => lv2_dimesion_value_h["skill"].map{|a| a["pup_cls_avg_percent_diff"]}.compact.max,
        "ability" => lv2_dimesion_value_h["ability"].map{|a| a["pup_cls_avg_percent_diff"]}.compact.max
      }

      ingrade_worse = {
        "knowledge" => 0,
        "skill" => 0,
        "ability" => 0
      }

      ["knowledge", "skill", "ability"].each{|dimesion|
        lv2_dimesion_value_h[dimesion].each_with_index{|member, index|
          next if member.blank?
          #个人最佳表现
          cond = (member["average_percent"] == self_best[dimesion])
          if cond
            comment_h[("self_best_"+dimesion).to_sym] += lv2_dimesion_key_h[dimesion][index] + ","
          end
          #与群体比最佳表现
          cond = (member["pup_cls_avg_percent_diff"] == inclass_best[dimesion] && member["pup_cls_avg_percent_diff"] > 0)
          if cond
            comment_h[("inclass_best_"+dimesion).to_sym] += lv2_dimesion_key_h[dimesion][index] + ","
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
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => nil,
      '_id.pup_uid' => nil,
      '_id.dimesion' => {'$exists' => true },
      '_id.lv1_ckp' => {'$exists' => true },
      '_id.lv2_ckp' => nil
    } 

    Mongodb::ReportFourSectionPupilNumberResult.where(filter).each{|item|
      #grade
      grade_report, report_h = get_grade_report_hash item
      dimesion = item[:_id][:dimesion]
      lv1_ckp_key = item[:_id][:lv1_ckp]
      lv1_ckp_order = item[:_id][:lv1_order]

      #report_h["four_sections"]["level0"][dimesion][lv1_ckp_key] =  convert_2_hundred(item[:value][:level0_percent])
      temp_arr = report_h["four_sections"]["level0"][dimesion] || []
      target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_hundred(item[:value][:level0_average_percent])}]
      report_h["four_sections"]["level0"][dimesion] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

      #report_h["four_sections"]["level25"][dimesion][lv1_ckp_key] =  convert_2_hundred(item[:value][:level25_percent])
      temp_arr = report_h["four_sections"]["level25"][dimesion] || []
      target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_hundred(item[:value][:level25_average_percent])}]
      report_h["four_sections"]["level25"][dimesion] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

      #report_h["four_sections"]["level50"][dimesion][lv1_ckp_key] =  convert_2_hundred(item[:value][:level50_percent])
      temp_arr = report_h["four_sections"]["level50"][dimesion] || []
      target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_hundred(item[:value][:level50_average_percent])}]
      report_h["four_sections"]["level50"][dimesion] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

      #report_h["four_sections"]["level75"][dimesion][lv1_ckp_key] =  convert_2_hundred(item[:value][:level75_percent])
      temp_arr = report_h["four_sections"]["level75"][dimesion] || []
      target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_hundred(item[:value][:level75_average_percent])}]
      report_h["four_sections"]["level75"][dimesion] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

      grade_report.report_json = report_h.to_json
      grade_report.save
    }
  end

  #组装各班指标表现水平图
  def construct_each_klass_each_ckp_horizon
    logger.info "construct each class horizon charts"

    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => {'$exists' => true },
      '_id.pup_uid' => nil,
      '_id.dimesion' => {'$exists' => true },
      '_id.lv2_ckp' => nil,
      '_id.order' => nil


    }

    Mongodb::ReportTotalAvgResult.where(filter).each{|item|
      grade_report, report_h = get_grade_report_hash item
      dimesion = item[:_id][:dimesion]
      klass = I18n.t("dict.#{item[:_id][:classroom]}")
      if item[:_id].keys.include?("lv1_ckp")
        lv1_ckp_key = item[:_id][:lv1_ckp]
        lv1_ckp_order = item[:_id][:lv1_order]
        # temp_h = report_h["each_checkpoint_horizon"][dimesion]["average_percent"][klass] || {}
        # temp_h[lv1_ckp_key] = convert_2_full_mark(item[:value]["average_percent".to_sym])
        # report_h["each_checkpoint_horizon"][dimesion]["average_percent"][klass] = temp_h

        temp_arr = report_h["each_checkpoint_horizon"][dimesion]["average_percent"] || []
        target_klass = temp_arr.assoc(klass)
        if klass && target_klass
          pos = temp_arr.index(target_klass) || temp_arr.size
          #report_h["each_checkpoint_horizon"][dimesion]["average_percent"][pos][1][lv1_ckp_key] = convert_2_full_mark(item[:value]["average_percent".to_sym])

          temp_arr = report_h["each_checkpoint_horizon"][dimesion]["average_percent"][pos][1] || []
          target_pair = [lv1_ckp_order, {lv1_ckp_key => convert_2_full_mark(item[:value]["average_percent".to_sym])}]
          report_h["each_checkpoint_horizon"][dimesion]["average_percent"][pos][1] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

        elsif klass
          target_pair = [klass, [[lv1_ckp_order, {lv1_ckp_key => convert_2_full_mark(item[:value]["average_percent".to_sym])}]]]
          report_h["each_checkpoint_horizon"][dimesion]["average_percent"] = insert_item_to_a_with_order "klass", temp_arr, target_pair
        else 
          next
        end
      else
        # temp_h = report_h["each_checkpoint_horizon"]["total"]["average_percent"][klass] || {}
        # temp_h[dimesion] = convert_2_full_mark(item[:value]["average_percent".to_sym])
        # report_h["each_checkpoint_horizon"]["total"]["average_percent"][klass] = temp_h
        dimesion_order = Common::Locale::DimesionOrder[dimesion]
        dimesion_label = I18n.t("dict.#{dimesion}")
        temp_arr = report_h["each_checkpoint_horizon"]["total"]["average_percent"] || []
        target_klass = temp_arr.assoc(klass)
        if klass && target_klass
          pos = temp_arr.index(target_klass) || temp_arr.size
          # report_h["each_checkpoint_horizon"]["total"]["average_percent"][pos][1][dimesion_label] = convert_2_full_mark(item[:value]["average_percent".to_sym])

          temp_arr = report_h["each_checkpoint_horizon"]["total"]["average_percent"][pos][1] || []
          target_pair = [dimesion_order, {dimesion_label => convert_2_full_mark(item[:value]["average_percent".to_sym])}]
          report_h["each_checkpoint_horizon"]["total"]["average_percent"][pos][1] = insert_item_to_a_with_order "dimesion", temp_arr, target_pair
        elsif klass
          target_pair = [klass, [[dimesion_order, {dimesion_label => convert_2_full_mark(item[:value]["average_percent".to_sym])}]]]
          report_h["each_checkpoint_horizon"]["total"]["average_percent"] = insert_item_to_a_with_order "klass", temp_arr, target_pair
        else 
          next
        end
      end
      grade_report.report_json = report_h.to_json
      grade_report.save
    }

    Mongodb::ReportStandDevDiffResult.where(filter).each{|item|
      grade_report, report_h = get_grade_report_hash item
      dimesion = item[:_id][:dimesion]
      klass = I18n.t("dict.#{item[:_id][:classroom]}")
      if item[:_id].keys.include?("lv1_ckp")
        lv1_ckp_key = item[:_id][:lv1_ckp]
        lv1_ckp_order = item[:_id][:lv1_order]
        ["median_percent", "med_avg_diff", "diff_degree"].each{|member|
          # temp_h = report_h["each_checkpoint_horizon"][dimesion][member][klass] || {}
          # if member == "med_avg_diff"
          #   temp_h[lv1_ckp_key] = convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:average_percent])
          # else
          #   temp_h[lv1_ckp_key] = convert_2_full_mark(item[:value][member.to_sym])
          # end
          # report_h["each_checkpoint_horizon"][dimesion][member][klass] = temp_h

          temp_arr = report_h["each_checkpoint_horizon"][dimesion][member] || []
          if member == "med_avg_diff"
            target_value = convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:average_percent])
          else
            target_value = convert_2_full_mark(item[:value][member.to_sym])
          end
          target_klass = temp_arr.assoc(klass)
          if klass && target_klass
            pos = temp_arr.index(target_klass) || temp_arr.size
            #report_h["each_checkpoint_horizon"][dimesion][member][pos][1][lv1_ckp_key] = target_value
          
            temp_arr = report_h["each_checkpoint_horizon"][dimesion][member][pos][1] || []
            target_pair = [lv1_ckp_order, {lv1_ckp_key => target_value}]
            report_h["each_checkpoint_horizon"][dimesion][member][pos][1] = insert_item_to_a_with_order "checkpoint", temp_arr, target_pair

          elsif klass
            target_pair = [klass, [[lv1_ckp_order, {lv1_ckp_key => target_value}]]]
            report_h["each_checkpoint_horizon"][dimesion][member] = insert_item_to_a_with_order "klass", temp_arr, target_pair
          else 
            next
          end
        }
      else
        ["median_percent", "med_avg_diff", "diff_degree"].each{|member|
          # temp_h = report_h["each_checkpoint_horizon"]["total"][member][klass] || {}
          # if member == "med_avg_diff"
          #   temp_h[dimesion] = convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:average_percent])
          # else
          #   temp_h[dimesion] = convert_2_full_mark(item[:value][member.to_sym])
          # end
          # report_h["each_checkpoint_horizon"]["total"][member][klass] = temp_h

          dimesion_order = Common::Locale::DimesionOrder[dimesion]
          dimesion_label = I18n.t("dict.#{dimesion}")

          temp_arr = report_h["each_checkpoint_horizon"]["total"][member] || []
          if member == "med_avg_diff"
            target_value = convert_diff_2_full_mark(item[:value][:median_percent],item[:value][:average_percent])
          else
            target_value = convert_2_full_mark(item[:value][member.to_sym])
          end
          target_klass = temp_arr.assoc(klass)
          if klass && target_klass
            pos = temp_arr.index(target_klass) || temp_arr.size
            #report_h["each_checkpoint_horizon"]["total"][member][pos][1][dimesion] = target_value

            temp_arr = report_h["each_checkpoint_horizon"]["total"][member][pos][1] || []
            target_pair = [dimesion_order, {dimesion_label => target_value}]
            report_h["each_checkpoint_horizon"]["total"][member][pos][1] = insert_item_to_a_with_order "dimesion", temp_arr, target_pair
          elsif klass
            target_pair = [klass, [[dimesion_order, {dimesion_label => target_value}]]]
            report_h["each_checkpoint_horizon"]["total"][member] = insert_item_to_a_with_order "klass", temp_arr, target_pair
          else 
            next
          end
        }
      end
      grade_report.report_json = report_h.to_json
      grade_report.save
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
      next if report_h.blank?
      next unless report_h.keys.include?("data_table")

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
      #1级的时候要考虑,总分项
      lv2_dimesion_key_h ={
        "knowledge" => report_h["data_table"]["knowledge"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["label"]}}.flatten,
        "skill" => report_h["data_table"]["skill"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["label"]}}.flatten,
        "ability" => report_h["data_table"]["ability"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["label"]}}.flatten
      }
      lv2_dimesion_value_h = {
        "knowledge" => report_h["data_table"]["knowledge"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["value"]}}.flatten,
        "skill" => report_h["data_table"]["skill"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["value"]}}.flatten,
        "ability" => report_h["data_table"]["ability"].map{|a| a[1]}.map{|a| a["items"].map{|a| a[1]["value"]}}.flatten
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
            comment_h[dimesion.to_sym][:pupil_highest_items] += lv2_dimesion_key_h[dimesion][index] + ","
          end
          ###########学生最差表现
          cond = (member["cls_average_percent"] == klass_worst[dimesion])
          if cond
            comment_h[dimesion.to_sym][:pupil_lowest_items] += lv2_dimesion_key_h[dimesion][index] + ","
          end

          ###########高于年级平均水平
          cond= (member["cls_gra_avg_percent_diff"] > 0)
          if cond
            comment_h[dimesion.to_sym][:higher_than_grade_items] += lv2_dimesion_key_h[dimesion][index] + ","
            #total_higher_than_grade_dimesion << I18n.t("dict.#{dimesion}") unless total_higher_than_grade_dimesion.include?(dimesion)
          end
          ###########低于年级平均水平
          cond= (member["cls_gra_avg_percent_diff"] < 0)
          if cond
            comment_h[dimesion.to_sym][:lower_than_grade_items] += lv2_dimesion_key_h[dimesion][index] + ","
            #total_lower_than_grade_dimesion << I18n.t("dict.#{dimesion}") unless total_lower_than_grade_dimesion.include?(dimesion)
          end 
        }
        ###########平均值
        #达到何水平判断
        comment_h[dimesion.to_sym][:klass_average_percent] = convert_2_full_mark(report_h["dimesion_values"][dimesion]["average_percent"])
        comment_h[dimesion.to_sym][:level] = judge_score_level(report_h["dimesion_values"][dimesion]["average_percent"])
        #与年级相比
        comment_h[dimesion.to_sym][:than_grade] = get_compare_value_label(report_h["dimesion_values"][dimesion]["average_percent"],report_h["dimesion_values"][dimesion]["gra_average_percent"])
        ###########各比例学生百分比
        class_percent = report_h["each_level_number"]["class_grade_#{dimesion}"]["class_#{dimesion}"]
        grade_percent = report_h["each_level_number"]["class_grade_#{dimesion}"]["grade_#{dimesion}"]
        excellent_level_percent_than_grade = get_compare_value_label(class_percent["excellent_pupil_percent"],grade_percent["excellent_pupil_percent"])
        good_level_percent_than_grade = get_compare_value_label(class_percent["good_pupil_percent"],grade_percent["good_pupil_percent"])
        failed_level_percent_than_grade = get_compare_value_label(class_percent["failed_pupil_percent"],grade_percent["failed_pupil_percent"])

        comment_h[dimesion.to_sym][:excellent_level_percent] = class_percent["excellent_pupil_percent"]
        comment_h[dimesion.to_sym][:excellent_level_percent_than_grade] = excellent_level_percent_than_grade
        comment_h[dimesion.to_sym][:good_level_percent] = class_percent["good_pupil_percent"]
        comment_h[dimesion.to_sym][:good_level_percent_than_grade] = good_level_percent_than_grade
        comment_h[dimesion.to_sym][:failed_level_percent] = class_percent["failed_pupil_percent"]
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

      ["knowledge", "skill", "ability"].each{|dim|
        if report_h["data_table"][dim][0][1]["value"]["cls_gra_avg_percent_diff"] > 0
          total_higher_than_grade_dimesion << I18n.t("dict.#{dim}")
        else
          total_lower_than_grade_dimesion << I18n.t("dict.#{dim}")
        end
      }

      total_h[:higher_than_grade_dimesions] = total_higher_than_grade_dimesion.join(",")
      total_h[:lower_than_grade_dimesions] = total_lower_than_grade_dimesion.join(",")
      klass_avg_percent = comment_h.values.map{|item| item[:klass_average_percent]}.sum/3
      total_h[:klass_average_percent] = format_float(klass_avg_percent)
      total_h[:level] = judge_score_level klass_avg_percent
      total_grade_average_percent = format_float(report_h["dimesion_values"].values.map{|item| item["gra_average_percent"]}.sum/3)
      total_h[:than_grade] = get_compare_value_label(total_h[:klass_average_percent],total_grade_average_percent)

      total_class_percent = report_h["each_level_number"]["total"]["class"]
      total_grade_percent = report_h["each_level_number"]["total"]["grade"]
      total_excellent_than_grade = get_compare_value_label(total_class_percent["excellent_pupil_percent"],total_grade_percent["excellent_pupil_percent"])
      total_good_than_grade = get_compare_value_label(total_class_percent["good_pupil_percent"],total_grade_percent["good_pupil_percent"])
      total_failed_than_grade = get_compare_value_label(total_class_percent["failed_pupil_percent"],total_grade_percent["failed_pupil_percent"])
      total_h[:excellent_level_percent] = total_class_percent["excellent_pupil_percent"]
      total_h[:excellent_level_percent_than_grade] = total_excellent_than_grade
      total_h[:good_level_percent] = total_class_percent["good_pupil_percent"]
      total_h[:good_level_percent_than_grade] = total_good_than_grade
      total_h[:failed_level_percent] = total_class_percent["failed_pupil_percent"]
      total_h[:failed_level_percent_than_grade] = total_failed_than_grade
      report_h["quiz_comment"]["total"] %= total_h 
    
      item.update(:report_json => report_h.to_json)
    }
  end

  #
  # 聚合计算: 开始
  #
  # calculate total,average, median, standardation ... of pupil, class and grade
  def cal_init1
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
        var qzp_count = 0;
        if(real_total == full_total){
          qzp_count = 1;
        }

        var value_obj = {
          pup_uids: [this.pup_uid],
          pup_uid: this.pup_uid, 
          real_total: real_total, 
          real_score: real_total,
          real_scores: [real_total],
          full_total: full_total,
          full_score: full_total,
          full_mark: full_total,
          reduced: 0, 
          pupil_number: 1,
          average: real_total,
          average_percent: real_total/full_total,
          qzp_uids: [this.qzp_uid],
          qzp_uid: this.qzp_uid,
          qzp_count: qzp_count
        };
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, order: this.order}, 
           value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, dimesion: this.dimesion,order: this.order, lv2_ckp: this.lv2_ckp}, 
           value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, dimesion: this.dimesion}, 
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, dimesion: this.dimesion, lv1_ckp: this.lv1_ckp, lv1_order: this.lv1_order}, 
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, dimesion: this.dimesion, lv2_ckp: this.lv2_ckp, lv2_order: this.lv2_order}, 
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
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, dimesion: this.dimesion, order: this.order, lv2_ckp: this.lv2_ckp},
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, dimesion: this.dimesion, lv1_ckp: this.lv1_ckp, lv1_order: this.lv1_order},
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, dimesion: this.dimesion, lv2_ckp: this.lv2_ckp, lv2_order: this.lv2_order},
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, pup_uid: this.pup_uid, dimesion: this.dimesion},
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, pup_uid: this.pup_uid, dimesion: this.dimesion, lv1_ckp: this.lv1_ckp, lv1_order: this.lv1_order},
          value_obj);
        emit(
          {pap_uid: this.pap_uid, grade: this.grade, classroom: this.classroom, pup_uid: this.pup_uid, dimesion: this.dimesion, lv2_ckp: this.lv2_ckp, lv2_order: this.lv2_order},
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
          pup_uids: [],
          pup_uid: values[0].pup_uid, 
          real_total: 0,
          real_scores: [], 
          real_score: 0,
          full_total: 0,
          full_score: 0,
          full_mark: 0,
          reduced: 1, 
          pupil_number: 0,
          average: 0,
          average_percent: 0,
          qzp_uids: [],
          qzp_uid: "",
          qzp_count: 0
        };

        values.forEach(function(value){
          result.real_total += value.real_total;
          result.full_total += value.full_total;

          value.real_scores.forEach(function(score){
              result.real_scores.push(score);
          });

          value.pup_uids.forEach(function(pup_uid){
            if(result.pup_uids.indexOf(pup_uid) == -1 ){
              result.pup_uids.push(pup_uid);
              result.pupil_number += 1;
            }
          });

          value.qzp_uids.forEach(function(qzp_uid){
            if(result.qzp_uids.indexOf(qzp_uid) == -1 && value.real_score == value.full_score){
              result.qzp_uids.push(qzp_uid);
              result.qzp_count += 1;
            }
          });

        });
       
        result.average = result.real_total/result.pupil_number;
        result.full_mark = result.full_total/result.pupil_number;
        result.average_percent = result.real_total/result.full_total;
        
        return result;
      }
    }

    Mongodb::BankQizpointScore.where(filter).map_reduce(map,reduce).out(:reduce => "mongodb_report_total_avg_results").execute
  end

  # 
  # 各的分点条目添加如下字段:
  #
  # cls_dim_lv1_avg_percent: 班级1级指标平均得分率
  # cls_dim_lv2_avg_percent: 班级2级指标平均得分率
  # gra_dim_lv1_avg_percent: 年级1级指标平均得分率
  # gra_dim_lv2_avg_percent: 年级2级指标平均得分率
  #
  def add_materials1
    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.dimesion' => {'$exists' => true },
      '_id.pup_uid' => nil
    }
    arr = Mongodb::ReportTotalAvgResult.where(filter).no_timeout # need add filter here, user_id or somethind

    add_materials1_core 1, arr
  end

  def add_materials1_core th_index, arr
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
      elsif cls_common_cond && item[:_id].keys.include?('order')
        qzp_score_common_cond['_id.classroom']=item[:_id][:classroom]
        qzp_score_common_cond['_id.order']=item[:_id][:order]
        qzp_score_upt_h['value.cls_dim_order_avg'] = item[:value][:average]
        qzp_score_upt_h['value.cls_dim_order_avg_percent'] = item[:value][:average_percent]
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
      elsif gra_common_cond && item[:_id].keys.include?('order')
        qzp_score_common_cond['_id.order']=item[:_id][:lv2_ckp]
        qzp_score_upt_h['value.gra_dim_order_avg'] = item[:value][:average]
        qzp_score_upt_h['value.gra_dim_order_avg_percent'] = item[:value][:average_percent]
      elsif gra_common_cond 
        #do nothing
        qzp_score_upt_h['value.gra_dim_avg'] = item[:value][:average]
        qzp_score_upt_h['value.gra_dim_avg_percent'] = item[:value][:average_percent]
      end
      unless qzp_score_upt_h.empty?
        results = Mongodb::ReportTotalAvgResult.where(qzp_score_common_cond).no_timeout
        results.update_all(qzp_score_upt_h)
      end
    }  
  end

  #
  # 
  def cal_init2
    return false if (@province.blank? || @city.blank? || @district.blank? || @school.blank? || @pap_uid.blank?)
    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.pup_uid' => {'$exists' => true }
    }

    map = %Q{
      function(){
        if(!this._id.lv1_ckp && !this._id.lv2_ckp){
          var value_obj = {
              reduced: 0,
              deltas:[this.value.average - this.value.cls_dim_avg],
              diff2_sum: 0,
              total_avg: this.value.cls_dim_avg,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 1,
              pupil_number: this.value.pupil_number,
              median_percent: this.value.average_percent,
              median_number: 1,
              average: this.value.average,
              average_percent_total: this.value.average_percent,
              average_percent: this.value.average_percent,
              average_stack: [this.value.average_percent],
              cls_dim_avg: this.value.cls_dim_avg,
              cls_dim_avg_percent: this.value.cls_dim_avg_percent,
              gra_dim_avg: this.value.gra_dim_avg,
              gra_dim_avg_percent: this.value.gra_dim_avg_percent
            }
          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              dimesion: this._id.dimesion},
            value_obj
          );
          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              classroom: this._id.classroom, 
              dimesion: this._id.dimesion},
            value_obj
          );
          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              pup_uid: this._id.pup_uid,
              dimesion: this._id.dimesion},
            value_obj
          );
        }
        if(this._id.lv1_ckp){
          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              dimesion: this._id.dimesion, 
              lv1_ckp: this._id.lv1_ckp,
              lv1_order: this._id.lv1_order},
            {
              reduced: 0,
              deltas:[this.value.average - this.value.gra_dim_lv1_avg],
              diff2_sum: 0,
              total_avg: this.value.gra_dim_lv1_avg,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 1,
              pupil_number: this.value.pupil_number,
              median_percent: this.value.average_percent,
              median_number: 1,
              average: this.value.average,
              average_percent_total: this.value.average_percent,
              average_percent: this.value.average_percent,
              average_stack: [this.value.average_percent],
              gra_dim_lv1_avg: this.value.gra_dim_lv1_avg,
              gra_dim_lv1_avg_percent: this.value.gra_dim_lv1_avg_percent
            }
          );

          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade,
              pup_uid: this._id.pup_uid,
              dimesion: this._id.dimesion, 
              lv1_ckp: this._id.lv1_ckp,
              lv1_order: this._id.lv1_order},
            {
              reduced: 0,
              deltas:[this.value.average - this.value.gra_dim_lv1_avg],
              diff2_sum: 0,
              total_avg: this.value.gra_dim_lv1_avg,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 1,
              pupil_number: this.value.pupil_number,
              median_percent: this.value.average_percent,
              median_number: 1,
              average: this.value.average,
              average_percent_total: this.value.average_percent,
              average_percent: this.value.average_percent,
              average_stack: [this.value.average_percent],
              gra_dim_lv1_avg: this.value.gra_dim_lv1_avg,
              gra_dim_lv1_avg_percent: this.value.gra_dim_lv1_avg_percent
            }
          );

          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              classroom: this._id.classroom, 
              dimesion: this._id.dimesion, 
              lv1_ckp: this._id.lv1_ckp,
              lv1_order: this._id.lv1_order},
            {
              reduced: 0,
              deltas:[this.value.average - this.value.cls_dim_lv1_avg],
              diff2_sum: 0,
              stand_dev: 0, 
              total_avg: this.value.cls_dim_lv1_avg,
              diff_degree: 0,
              current_pupil_number: 1,
              pupil_number: this.value.pupil_number,
              median_percent: this.value.average_percent,
              median_number: 1,
              average: this.value.average,
              average_percent_total: this.value.average_percent,
              average_percent: this.value.average_percent,
              average_stack: [this.value.average_percent],
              cls_dim_lv1_avg: this.value.cls_dim_lv1_avg,
              cls_dim_lv1_avg_percent: this.value.cls_dim_lv1_avg_percent,
              gra_dim_lv1_avg: this.value.gra_dim_lv1_avg,
              gra_dim_lv1_avg_percent: this.value.gra_dim_lv1_avg_percent
            }
          );
        }
        if(this._id.lv2_ckp){
          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              dimesion: this._id.dimesion, 
              lv2_ckp: this._id.lv2_ckp,
              lv2_order: this._id.lv2_order},
            {
              reduced: 0,
              deltas:[this.value.average - this.value.gra_dim_lv2_avg],
              diff2_sum: 0,
              stand_dev: 0, 
              total_avg: this.value.gra_dim_lv2_avg,
              diff_degree: 0,
              current_pupil_number: 1,
              pupil_number: this.value.pupil_number,
              median_percent: this.value.average_percent,
              median_number: 1,
              average: this.value.average,
              average_percent_total: this.value.average_percent,
              average_percent: this.value.average_percent,
              average_stack: [this.value.average_percent],
              gra_dim_lv2_avg: this.value.gra_dim_lv2_avg,
              gra_dim_lv2_avg_percent: this.value.gra_dim_lv2_avg_percent
            }
          );

          emit(
            { pap_uid: this._id.pap_uid,
              grade: this._id.grade, 
              classroom: this._id.classroom, 
              dimesion: this._id.dimesion, 
              lv2_ckp: this._id.lv2_ckp,
              lv2_order: this._id.lv2_order},
            {
              reduced: 0,
              deltas:[this.value.average - this.value.cls_dim_lv2_avg],
              diff2_sum: 0,
              stand_dev: 0, 
              total_avg: this.value.cls_dim_lv2_avg,
              diff_degree: 0,
              current_pupil_number: 1,
              pupil_number: this.value.pupil_number,
              median_percent: this.value.average_percent,
              median_number: 1,
              average: this.value.average,
              average_percent_total: this.value.average_percent,
              average_percent: this.value.average_percent,
              average_stack:[this.value.average_percent],
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
              deltas:[],
              diff2_sum: 0,
              total_avg: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 0,
              pupil_number: values[0].pupil_number,
              median_percent: 0,
              median_number: 0,
              average: 0,
              average_percent_total: 0,
              average_percent: 0,
              average_stack: [],
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
              deltas:[],
              diff2_sum: 0,
              total_avg: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 0,
              pupil_number: values[0].pupil_number,
              median_percent: 0,
              median_number: 0,
              average: 0,
              average_percent_total: 0,
              average_percent: 0,
              average_stack: [],
              cls_dim_lv1_avg: values[0].cls_dim_lv1_avg,
              cls_dim_lv1_avg_percent: values[0].cls_dim_lv1_avg_percent,
              gra_dim_lv1_avg: values[0].gra_dim_lv1_avg,
              gra_dim_lv1_avg_percent: values[0].gra_dim_lv1_avg_percent
            };
          } else {
            var result = {
              reduced: 1,
              deltas:[],
              diff2_sum: 0,
              total_avg: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 0,
              pupil_number: values[0].pupil_number,
              median_percent: 0,
              median_number: 0,
              average: 0,
              average_percent_total: 0,
              average_percent: 0,
              average_stack: [],
              gra_dim_lv1_avg: values[0].gra_dim_lv1_avg,
              gra_dim_lv1_avg_percent: values[0].gra_dim_lv1_avg_percent
            };
          }
        }

        if(key.hasOwnProperty('lv2_ckp')){
          if(key.hasOwnProperty('classroom')){
            var result = {
              reduced: 1,
              deltas:[],
              diff2_sum: 0,
              total_avg: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 0,
              pupil_number: values[0].pupil_number,
              median_percent: 0,
              median_number: 0,
              average: 0,
              average_percent_total: 0,
              average_percent: 0,
              average_stack: [],
              cls_dim_lv2_avg: values[0].cls_dim_lv2_avg,
              cls_dim_lv2_avg_percent: values[0].cls_dim_lv2_avg_percent,
              gra_dim_lv2_avg: values[0].gra_dim_lv2_avg,
              gra_dim_lv2_avg_percent: values[0].gra_dim_lv2_avg_percent
            };
          } else {
            var result = {
              reduced: 1,
              deltas:[],
              diff2_sum: 0,
              total_avg: 0,
              stand_dev: 0, 
              diff_degree: 0,
              current_pupil_number: 0,
              pupil_number: values[0].pupil_number,
              median_percent: 0,
              median_number: 0,
              average: 0,
              average_percent_total: 0,
              average_percent: 0,
              average_stack: [],
              gra_dim_lv2_avg: values[0].gra_dim_lv2_avg,
              gra_dim_lv2_avg_percent: values[0].gra_dim_lv2_avg_percent
            };
          }
        }

        values.forEach(function(value){
          result.current_pupil_number += value.current_pupil_number;

          value.deltas.forEach(function(delta){
            result.diff2_sum += Math.pow(delta, 2);
            result.deltas.push(delta);
          });

          value.average_stack.forEach(function(average){
            result.average_stack.push(average);
          });
          
          result.average += value.average;
          result.average_percent_total += value.average_percent_total;

        });

        var sorted_values = result.average_stack.sort(function(a, b){ return a > b});
        if((result.current_pupil_number&1)==0){
          result.median_number = result.current_pupil_number/2;
          result.median_percent = parseFloat((sorted_values[result.median_number - 1] + sorted_values[result.median_number])/2);
        } else {
          result.median_number = parseInt(result.current_pupil_number/2)+1;
          result.median_percent = parseFloat(sorted_values[result.median_number-1]);
        }

        result.current_pupil_number = (result.current_pupil_number == 0) ? 1:result.current_pupil_number;

        result.average = result.average/result.current_pupil_number;
        result.average_percent = result.average_percent_total/result.current_pupil_number;
        result.stand_dev = Math.sqrt(result.diff2_sum/(result.current_pupil_number - 1));
        result.diff_degree = result.stand_dev/values[0].total_avg;
        result.total_avg = values[0].total_avg;
        return result;
      }
    }

    Mongodb::ReportTotalAvgResult.where(filter).map_reduce(map,reduce).out(:replace => "mongodb_report_stand_dev_diff_results").execute
  end

  # 
  #
  #
  def add_materials2
    # 此处为按一级指标以及无指标的排名的filter
    # filter = {
    #   '_id.pap_uid' => @pap_uid,
    #   '_id.grade' => {'$exists' => true },
    #   '_id.classroom' => nil,
    #   '_id.pup_uid' => nil,
    #   '_id.dimesion' => {'$exists' => true },
    #   #'_id.lv1_ckp' => {'$exists' => true },
    #   '_id.lv2_ckp' => nil
    # }

    #排名按维度,不按各指标
    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => nil,
      '_id.pup_uid' => nil,
      '_id.dimesion' => {'$exists' => true },
      '_id.lv1_ckp' => nil,
      '_id.lv2_ckp' => nil
    }
    arr = Mongodb::ReportStandDevDiffResult.where(filter).no_timeout # need add filter here, user_id or somethind

    add_materials2_core 1, arr
=begin
    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => nil,
      '_id.pup_uid' => nil,
      '_id.dimesion' => {'$exists' => true },
      '_id.lv1_ckp' => nil,
      '_id.lv2_ckp' => nil
    }
    arr = Mongodb::ReportStandDevDiffResult.where(filter).no_timeout # need add filter here, user_id or somethind

    add_materials2_core 1, arr, "dimesion"
=end
  end

  def add_materials2_core th_index, arr
    total_num =arr.size
    arr.each_with_index{|item,index|
      logger.info(">>>>>>thread #{th_index}, current status (#{index}/#{total_num})<<<<<<") if index%100 == 0
      # pupil_filter = {
      # '_id.pap_uid' => @pap_uid,
      # '_id.grade' => {'$exists' => true },
      # #'_id.classroom' => nil,
      # '_id.pup_uid' => {'$exists' => true },
      # '_id.dimesion' => item[:_id][:dimesion],
      # '_id.lv1_ckp' => item[:_id].keys.include?("lv1_ckp")? item[:_id][:lv1_ckp] : nil,
      # '_id.lv2_ckp' => nil
      # }

      pupil_filter = {
        '_id.pap_uid' => @pap_uid,
        '_id.grade' => item[:_id][:grade],
        '_id.classroom' => nil,
        '_id.pup_uid' => {'$exists' => true },
        '_id.dimesion' => item[:_id][:dimesion],
        '_id.lv1_ckp' => nil,
        '_id.lv2_ckp' => nil
      }

      average_arr = item[:value][:average_stack].blank?? [] : item[:value][:average_stack].sort.reverse
      values_h = {
        'value.grade_rank' => 0,
        'value.grade_pupil_number' => item[:value][:current_pupil_number]
      }

      pupils = Mongodb::ReportStandDevDiffResult.where(pupil_filter).no_timeout
      pupils.each{|pupil|
        values_h['value.grade_rank'] = (average_arr.index(pupil[:value][:average_percent]) +1 )|| 0
        filter = {
          '_id.pap_uid' => @pap_uid,
          '_id.grade' => pupil[:_id][:grade],
          '_id.pup_uid' => pupil[:_id][:pup_uid],
          '_id.dimesion' => pupil[:_id][:dimesion]
        }
        target_pupils = Mongodb::ReportStandDevDiffResult.where(filter).no_timeout
        target_pupils.update_all(values_h)
      }
    }  
  end

  #
  #
  def cal_init3
    return false if (@province.blank? || @city.blank? || @district.blank? || @school.blank? || @pap_uid.blank?)
    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.pup_uid' => {'$exists' => true }
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
          excellent_percent: 0
        }

        if( 0.0 <= this.value.average_percent && this.value.average_percent < #{Common::Report::ScoreLevel::Level60} ){
          value_obj.failed_pupil_number = 1;
        } else if (#{Common::Report::ScoreLevel::Level60}<= this.value.average_percent && this.value.average_percent < #{Common::Report::ScoreLevel::Level85}){
          value_obj.good_pupil_number = 1;
        } else if (#{Common::Report::ScoreLevel::Level85} <= this.value.average_percent && this.value.average_percent <= 1.0){
          value_obj.excellent_pupil_number = 1;
        } 

        if(!this._id.lv1_ckp && !this._id.lv2_ckp){
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
        if(this._id.lv1_ckp){
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade, 
                dimesion: this._id.dimesion,
                lv1_ckp: this._id.lv1_ckp,
                lv1_order: this._id.lv1_order
              }, 
              value_obj
          );
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade,
                classroom: this._id.classroom,
                dimesion: this._id.dimesion,
                lv1_ckp: this._id.lv1_ckp,
                lv1_order: this._id.lv1_order
              }, 
              value_obj 
          );
        }
        if(this._id.lv2_ckp){
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade, 
                dimesion: this._id.dimesion,
                lv2_ckp: this._id.lv2_ckp,
                lv2_order: this._id.lv2_order
              }, 
              value_obj
          );
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade,
                classroom: this._id.classroom,
                dimesion: this._id.dimesion,
                lv2_ckp: this._id.lv2_ckp,
                lv2_order: this._id.lv2_order
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
          excellent_percent: 0
        }

        values.forEach(function(value){
          result.total_number += value.total_number;
          result.failed_pupil_number += value.failed_pupil_number;
          result.good_pupil_number += value.good_pupil_number;
          result.excellent_pupil_number += value.excellent_pupil_number;
        });

        result.failed_percent = result.failed_pupil_number/result.total_number;
        result.good_percent = result.good_pupil_number/result.total_number;
        result.excellent_percent = result.excellent_pupil_number/result.total_number;
        return result;
      }
    }

    Mongodb::ReportTotalAvgResult.where(filter).map_reduce(map,reduce).out(:replace => "mongodb_report_each_level_pupil_number_results").execute
  end

  #
  #
  def cal_init4
    return false if (@province.blank? || @city.blank? || @district.blank? || @school.blank? || @pap_uid.blank?)
    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.grade' => {'$exists' => true },
      '_id.classroom' => nil,
      '_id.pup_uid' => {'$exists' => true },
      '_id.dimesion' => {'$exists' => true },
      '_id.order' => nil,
#      '_id.lv1_ckp' => {'$exists' => true },
      '_id.lv2_ckp' => nil
    }

    map = %Q{
      function(){      

        var value_obj = {
          reduced: 0,
          percentile: 0,
          total_number: 1,
          level0_number: 0,
          level25_number: 0,
          level50_number: 0,
          level75_number: 0,
          level0_average_percent: 0,
          level25_average_percent: 0,
          level50_average_percent: 0,
          level75_average_percent: 0,
          level0_average_percent_total: 0,
          level25_average_percent_total: 0,
          level50_average_percent_total: 0,
          level75_average_percent_total: 0
        };

        if(this.value.grade_rank && this.value.grade_pupil_number && this.value.grade_rank != 0 && this.value.grade_pupil_number!=0){
          percentile = 100 - (100*this.value.grade_rank - 50)/this.value.grade_pupil_number;
        } else {
          percentile = 0;
        }

        value_obj.percentile = percentile;

        if( 0.0 <= percentile && percentile <= #{Common::Report::FourSection::Level25} ){
          value_obj.level0_number = 1;
          value_obj.level0_average_percent_total = this.value.average_percent;
        } else if (#{Common::Report::FourSection::Level25} < percentile && percentile <= #{Common::Report::FourSection::Level50}){
          value_obj.level25_number = 1;
          value_obj.level25_average_percent_total = this.value.average_percent;
        } else if (#{Common::Report::FourSection::Level50} < percentile && percentile <= #{Common::Report::FourSection::Level75}){
          value_obj.level50_number = 1;
          value_obj.level50_average_percent_total = this.value.average_percent;
        } else if (#{Common::Report::FourSection::Level75} < percentile && percentile <= 100){
          value_obj.level75_number = 1;
          value_obj.level75_average_percent_total = this.value.average_percent;
        }

        if(this._id.lv1_ckp){
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade, 
                dimesion: this._id.dimesion,
                lv1_ckp: this._id.lv1_ckp,
                lv1_order: this._id.lv1_order
              }, 
              value_obj
          );
        } else {
          emit(
              { pap_uid: this._id.pap_uid,
                grade: this._id.grade,
                dimesion: this._id.dimesion,
                pup_uid: this._id.pup_uid
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
          percentile: values[0].percentile,
          total_number: 0,
          level0_number: 0,
          level25_number: 0,
          level50_number: 0,
          level75_number: 0,
          level0_average_percent: 0,
          level25_average_percent: 0,
          level50_average_percent: 0,
          level75_average_percent: 0,
          level0_average_percent_total: 0,
          level25_average_percent_total: 0,
          level50_average_percent_total: 0,
          level75_average_percent_total: 0
        }

        values.forEach(function(value){
          result.total_number += value.total_number;
          result.level0_number += value.level0_number;
          result.level25_number += value.level25_number;
          result.level50_number += value.level50_number;
          result.level75_number += value.level75_number;
          result.level0_average_percent_total += value.level0_average_percent_total;
          result.level25_average_percent_total += value.level25_average_percent_total;
          result.level50_average_percent_total += value.level50_average_percent_total;
          result.level75_average_percent_total += value.level75_average_percent_total;
        });

        result.level0_average_percent = result.level0_average_percent_total/result.level0_number;
        result.level25_average_percent = result.level25_average_percent_total/result.level25_number;
        result.level50_average_percent = result.level50_average_percent_total/result.level50_number;
        result.level75_average_percent = result.level75_average_percent_total/result.level75_number;
        return result;
      }
    }

    Mongodb::ReportStandDevDiffResult.where(filter).map_reduce(map,reduce).out(:replace => "mongodb_report_four_section_pupil_number_results").execute
  end


  #private
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

    grade_param[:pap_uid] = @pap_uid
    grade_report = Mongodb::GradeReport.where(grade_param).first
    unless grade_report
      grade_report = Mongodb::GradeReport.new(grade_param) 
      report_h = Common::Report::Format::Grade.deep_dup

      # grade_param.extract!(:pap_uid)
      # klass_count = Location.where(grade_param).size
      grade_filter = {
        '_id.pap_uid' => @pap_uid,
        '_id.pup_uid' => nil,
        '_id.grade' => item[:_id][:grade],
        '_id.classroom' => nil,
        '_id.dimesion' => "knowledge",
        '_id.lv1_ckp' => nil,
        '_id.lv2_ckp' => nil,
        '_id.order' => nil
      }
      target_grade = Mongodb::ReportTotalAvgResult.where(grade_filter).first

      #basic information
      report_h["basic"]["subject"] = @paper.subject
      report_h["basic"]["area"] = @area
      report_h["basic"]["school"] = @school_label
      report_h["basic"]["grade"] = I18n.t("dict.#{item[:_id][:grade]}")
      report_h["basic"]["term"] = @paper.term.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{@paper.term}")
      report_h["basic"]["klass_count"] = 0
      report_h["basic"]["pupil_number"]= target_grade.nil?? I18n.t("dict.unknown") : target_grade[:value][:pupil_number].to_i
      report_h["basic"]["quiz_type"] = @paper.quiz_type.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{@paper.quiz_type}")
#      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? "" : @paper.quiz_date.strftime("%Y-%m-%d %H:%M")
      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? I18n.t("dict.unknown") : @paper.quiz_date.strftime("%Y-%m-%d")
      report_h["basic"]["levelword2"] = @paper.levelword2.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{@paper.levelword2}")
      grade_report.update(:report_json => report_h.to_json)
    else
      report_h = JSON.parse(grade_report.report_json)
    end
    return grade_report, report_h
  end

  def get_class_report_hash item
    return nil, {} if (@province.blank? || @city.blank? || @district.blank? || @school.blank? || @pap_uid.blank? || item[:_id][:grade].blank? ||item[:_id][:classroom].blank?)

    grade_param = {
      :province => @province,
      :city => @city,
      :district => @district,
      :school => @school,
      :grade => item[:_id][:grade],
      :pap_uid => @pap_uid
    }
    grade_report = Mongodb::GradeReport.where(grade_param).first
    grade_report_h = JSON.parse(grade_report.report_json)

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

      klass_filter = {
        '_id.pap_uid' => @pap_uid,
        '_id.pup_uid' => nil,
        '_id.grade' => item[:_id][:grade],
        '_id.classroom' => item[:_id][:classroom],
        '_id.dimesion' => "knowledge",
        '_id.lv1_ckp' => nil,
        '_id.lv2_ckp' => nil,
        '_id.order' => nil
      }
      target_klass = Mongodb::ReportTotalAvgResult.where(klass_filter).first

      loc_h = {
        :province => @province,
        :city => @city,
        :district => @district,
        :school => @school,
        :grade => item[:_id][:grade],
        :classroom => item[:_id][:classroom]
      }
      target_loc = Location.where(loc_h).first

      #basic information
      report_h["basic"]["subject"] = @paper.subject
      report_h["basic"]["area"] = @area
      report_h["basic"]["school"] = @school_label
      report_h["basic"]["grade"] = I18n.t("dict.#{item[:_id][:grade]}")
      klass_label = Common::Klass::List.keys.include?(item[:_id][:classroom].to_sym) ? I18n.t("dict.#{klass.classroom}") : klass.classroom
      report_h["basic"]["classroom"] = klass_label
      report_h["basic"]["term"] = @paper.term.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{@paper.term}")
      report_h["basic"]["pupil_number"] = target_klass.nil?? I18n.t("dict.unknown") : target_klass[:value][:pupil_number].to_i
      report_h["basic"]["quiz_type"] = @paper.quiz_type.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{@paper.quiz_type}")
#      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? "" : @paper.quiz_date.strftime("%Y-%m-%d %H:%M")
      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? I18n.t("dict.unknown") : @paper.quiz_date.strftime("%Y-%m-%d")
      report_h["basic"]["levelword2"] = @paper.levelword2.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{@paper.levelword2}")
      report_h["basic"]["head_teacher"] = (target_loc.nil? || target_loc.head_teacher.nil?)? I18n.t("dict.unknown") : target_loc.head_teacher.name
      report_h["basic"]["subject_teacher"] = (target_loc.nil? || target_loc.subject_teacher(@paper.subject).nil?)? I18n.t("dict.unknown") : target_loc.subject_teacher(@paper.subject).name

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
      grade_report_h["basic"]["klass_count"] += 1
      grade_report.update(:report_json => grade_report_h.to_json)
    else
      report_h = JSON.parse(klass_report.report_json)
    end
    return klass_report, report_h
  end

  def get_pupil_report_hash item
    return nil, {} if (@province.blank? || @city.blank? || @district.blank? || @school.blank? || @pap_uid.blank? || item[:_id][:pup_uid].blank?)
    pupil_param = {
      :province => @province,
      :city => @city,
      :district => @district,
      :school => @school,
      :grade => item[:_id][:grade],
      #:classroom => item[:_id][:classroom],
      :pap_uid => @pap_uid,
      :pup_uid => item[:_id][:pup_uid]
    }
    pupil_report = Mongodb::PupilReport.where(pupil_param).first
    unless pupil_report
      pupil_report = Mongodb::PupilReport.new(pupil_param) 
      report_h = Common::Report::Format::Pupil.deep_dup

      pupil = Pupil.where(uid: item[:_id][:pup_uid]).first

      #basic information
      report_h["basic"]["area"] = @area
      report_h["basic"]["school"] = @school_label
      report_h["basic"]["grade"] = I18n.t("dict.#{item[:_id][:grade]}")
      klass_label = Common::Klass::List.keys.include?(item[:_id][:classroom].to_sym) ? I18n.t("dict.#{klass.classroom}") : klass.classroom
      report_h["basic"]["classroom"] = klass_label
      report_h["basic"]["subject"] = I18n.t("dict.#{@paper.subject}")
      report_h["basic"]["name"] = pupil.nil?? I18n.t("dict.unknown") : pupil.name
      report_h["basic"]["sex"] = pupil.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{pupil.sex}")
#      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? "" : @paper.quiz_date.strftime("%Y-%m-%d %H:%M")
      report_h["basic"]["term"] = @paper.term.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{@paper.term}")
      report_h["basic"]["quiz_type"] = @paper.quiz_type.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{@paper.quiz_type}")
      report_h["basic"]["quiz_date"] = @paper.quiz_date.nil?? I18n.t("dict.unknown") : @paper.quiz_date.strftime("%Y-%m-%d")
      report_h["basic"]["levelword2"] =  @paper.levelword2.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{@paper.levelword2}")

      pupil_report.update(:report_json => report_h.to_json)
    else
      report_h = JSON.parse(pupil_report.report_json)
    end
    return pupil_report, report_h
  end

  def get_ckp_table
    result = {
      "knowledge" => [],
      "skill" => [],
      "ability" => []
    }

    ckp_lv2_to_lv1 ={
      "knowledge" => {},
      "skill" => {},
      "ability" => {}
    }

    qzpoints = @paper.bank_quiz_qizs.map{|item| item.bank_qizpoint_qzps}.flatten
    ckps = qzpoints.map{|item| item.bank_checkpoint_ckps}.flatten.uniq
    ckps.each{|ckp|
      next unless 
      # search current level checkpoint
      if ckp.is_a? BankCheckpointCkp
        lv1_ckp = BankCheckpointCkp.where("node_uid = '#{@paper.node_uid}' and rid = '#{ckp.rid.slice(0, 3)}'").first
        lv2_ckp = BankCheckpointCkp.where("node_uid = '#{@paper.node_uid}' and rid = '#{ckp.rid.slice(0, 6)}'").first
      elsif ckp.is_a? BankSubjectCheckpointCkp
        xue_duan = BankNodestructure.get_subject_category(@paper.grade)
        lv1_ckp = BankSubjectCheckpointCkp.where("category = '#{xue_duan}' and rid = '#{ckp.rid.slice(0, 3)}'").first
        lv2_ckp = BankSubjectCheckpointCkp.where("category = '#{xue_duan}' and rid = '#{ckp.rid.slice(0, 6)}'").first
      end
      dimesion = ckp.dimesion
      # lv1_ckp = ckp.class.where("node_uid = '#{@paper.node_uid}' and rid = '#{ckp.rid.slice(0, 3)}'").first
      lv1_ckp_label = lv1_ckp.checkpoint
      lv1_ckp_order = lv1_ckp.nil?? "":lv1_ckp.sort
      # lv2_ckp = ckp.class.where("node_uid = '#{@paper.node_uid}' and rid = '#{ckp.rid.slice(0, 6)}'").first
      lv2_ckp_label = lv2_ckp.checkpoint
      lv2_ckp_order = lv2_ckp.nil?? "":lv2_ckp.sort

      target_lv1_ckp = result[dimesion].assoc(lv1_ckp_order)
      unless target_lv1_ckp
        target_pair = [lv1_ckp_order, {"label" => lv1_ckp_label, "value" => {}, "items" => []}]
        result[dimesion] = insert_item_to_a_with_order "checkpoint", result[dimesion], target_pair
      end

      target_lv1_ckp = result[dimesion].assoc(lv1_ckp_order)
      pos = result[dimesion].index(target_lv1_ckp)
      lv2_temp_arr = result[dimesion][pos][1]["items"]
      target_lv2_ckp = lv2_temp_arr.assoc(lv2_ckp_order)
      unless target_lv2_ckp
        target_pair = [lv2_ckp_order, {"label" => lv2_ckp_label, "value" => {}, "items" => []}]
        lv2_temp_arr = insert_item_to_a_with_order "checkpoint", lv2_temp_arr, target_pair
        result[dimesion][pos][1]["items"] = lv2_temp_arr
      end
      ckp_lv2_to_lv1[dimesion][lv2_ckp_order] = {"lv1_ckp" => lv1_ckp_label, "lv1_order" => lv1_ckp_order}
    }
    # add total row
    ["knowledge", "skill", "ability"].each{|dimesion|
      
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

  def convert_diff_2_full_mark value1,value2
    format_float((format_float_4(value1) - format_float_4(value2))*100)
  end

  def format_float_4 value
    ("%0.04f" % value).to_f
  end

  def judge_score_level value
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

  # hash array
  def insert_item_to_a_with_order type, target_arr, arr
    keys = target_arr.map{|a| a[0]}
    last_key = ""
    keys.each{|key|
      case type
      when "quiz"
        if Common::Paper::quiz_order(arr[0], key) < 0
          last_key = key
          break
        end
      when "klass"
        a = Common::Locale.hanzi2pinyin(arr[0])
        b = Common::Locale.hanzi2pinyin(key)
        if Common::Locale.mysort(Common::Klass::Order[a],Common::Klass::Order[b]) < 0
          last_key = key
          break
        end
      when "checkpoint"
        if Common::CheckpointCkp::compare_rid(arr[0], key) < 0
          last_key = key
          break
        end
      when "dimesion"
        if Common::Locale.mysort(arr[0],key) < 0
          last_key = key
          break
        end
      end
    }
    target_arr.insert_before(last_key, arr)
    return target_arr
  end

  def find_insert_position_for_ckp targetH,targetRid
    keys = targetH.keys
    keys.each{|key|
      return key if Common::CheckpointCkp::compare_rid(targetRid, key) < 0 
    }
    return ""
  end

  def insert_item_to_h_with_order targeth, arr, order="checkpoint"
    if !arr[0].blank? && !arr[1].blank?
      case order
      when "checkpoint"
        target_key = find_insert_position_for_ckp(targeth, arr[0])
      end      
      targeth.insert_before(target_key, arr)
    end
    return targeth
  end
end
