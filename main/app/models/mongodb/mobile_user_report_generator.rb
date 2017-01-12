# -*- coding: UTF-8 -*-

class Mongodb::MobileUserReportGenerator
  include Mongoid::Document

  def initialize(args)
    logger.info("=====initialization: begin!=====")
    logger.info("args: #{args}")
    @pap_uid = args[:pap_uid]
#    @pup_uid = args[:pup_uid]
    @wx_openid = args[:wx_openid]
    @paper = Mongodb::BankPaperPap.where(_id: @pap_uid).first
#    if @pup_uid
#      @online_test = Mongodb::OnlineTest.where({:pap_uid=> @pap_uid, :user_id=> args[:user_id]}).first
#    elsif @wx_openid
    if @wx_openid
      @online_test = Mongodb::OnlineTest.where({:pap_uid=> @pap_uid, :wx_openid=> args[:wx_openid]}).first
    else
      @online_test = nil
    end
    logger.info("=====initialization: end!=====")
  end

  #计算排名
  def construct_simple
    logger.info("======组装1:begin===========")
    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.dimesion' => "knowledge",
      '_id.order' => nil,
      '_id.lv1_ckp' => nil,
      '_id.lv2_ckp' => nil,
      '_id.wx_openid' => {'$exists' => true}
    }

    total_tester = Mongodb::MobileReportTotalAvgResult.where(filter).count
    first_record = Mongodb::MobileReportTotalAvgResult.where(filter).sort({'value.average_percent' => -1 }).to_a[0]
    last_score = first_record[:value][:average]
    current_position = 1
    Mongodb::MobileReportTotalAvgResult.where(filter).sort({'value.average_percent' => -1 }).each_with_index{|item,index|
      mobile_report, mobile_report_h = get_mobile_user_report item[:_id][:wx_openid]
      if mobile_report
        mobile_report_h['basic']['score'] = format_float(item[:value][:average])
        if last_score > item[:value][:average]
          last_score = item[:value][:average]
          current_position += 1
        end
        logger.info(">>>>>>#{current_position}, #{last_score}")
        mobile_report_h['rank']['my_position'] = current_position#(index+1)
        mobile_report_h['rank']['total_testers'] = total_tester
        mobile_report.update(:report_json => mobile_report_h.to_json)
      end
    }
    logger.info("======组装1:end===========")
  end

  #构造诊断图
  def construct_ckp_charts
    logger.info("======组装诊断图:begin===========")
    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.dimesion' => {'$exists' => true },
      '_id.order' => nil,
      '_id.lv1_ckp' => nil,
      '_id.lv2_ckp' => {'$exists' => true },
      '_id.wx_openid' => {'$exists' => true }
    }

    Mongodb::MobileReportBasedOnTotalAvgResult.where(filter).each{|item|
#      mobile_report, mobile_report_h = get_mobile_user_report item[:_id][:pup_uid], item[:_id][:wx_openid]
      mobile_report, mobile_report_h = get_mobile_user_report item[:_id][:wx_openid]
      if mobile_report
        dimesion = item[:_id][:dimesion]
        lv_ckp = item[:_id][:lv2_ckp]
        mobile_report_h["charts"][dimesion][lv_ckp] = format_float(item[:value][:user_total_diff])
        mobile_report.update(:report_json => mobile_report_h.to_json)
      end
    }
    logger.info("======组装诊断图:end===========")
  end

  #构造短板提升
  def construct_weak_ckps
    logger.info("======组装短板提升:begin===========")
    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.dimesion' => {'$exists' => true },
      '_id.order' => nil,
      '_id.lv1_ckp' => nil,
      '_id.lv2_ckp' => {'$exists' => true },
      '_id.wx_openid' => {'$exists' => true }
    }

    Mongodb::MobileReportTotalAvgResult.where(filter).sort({'value.correct_qzp_percent' => 1 }).each{|item|
#      mobile_report, mobile_report_h = get_mobile_user_report item[:_id][:pup_uid], item[:_id][:wx_openid]
      mobile_report, mobile_report_h = get_mobile_user_report item[:_id][:wx_openid]
      if mobile_report
        dimesion = item[:_id][:dimesion]
        lv_ckp = item[:_id][:lv2_ckp]

        temph = mobile_report_h["weak_fields"][dimesion][lv_ckp] || {"correct_qzp_count" => 0, "total_qzp_count" => 0}
        temph["correct_qzp_count"] = item[:value][:correct_qzp_count]
        temph["total_qzp_count"] = item[:value][:total_qzp_count]
        mobile_report_h["weak_fields"][dimesion][lv_ckp] = temph
        mobile_report.update(:report_json => mobile_report_h.to_json)
      end
    }
    logger.info("======组装短板提升:end===========")
  end

  #构造错题解析
  def construct_knowledge_weak_ckps
    logger.info("======组装错题分析:begin===========")
    filter = {
      '_id.pap_uid' => @pap_uid,
      '_id.dimesion' => {'$exists' => true },
      '_id.order' => {'$exists' => true },
      '_id.lv1_ckp' => nil,
      '_id.lv2_ckp' => {'$exists' => true },
      '_id.wx_openid' => {'$exists' => true }
    }

    Mongodb::MobileReportTotalAvgResult.where(filter).sort({'value.total_correct_qzp_percent' => -1 }).each{|item|
#      mobile_report, mobile_report_h = get_mobile_user_report item[:_id][:pup_uid], item[:_id][:wx_openid]
      mobile_report, mobile_report_h = get_mobile_user_report item[:_id][:wx_openid]
      if mobile_report
        dimesion = item[:_id][:dimesion]
        order = item[:_id][:order]
        lv_ckp = item[:_id][:lv2_ckp]

        temph = mobile_report_h['wrong_quizs'][dimesion][order] || {"total_correct_qzp_percent" => 0, "checkpoint" => ""}
        temph["total_correct_qzp_percent"] = convert_2_hundred(item[:value][:total_correct_qzp_percent])
        temph["checkpoint"] = lv_ckp
        mobile_report_h['wrong_quizs'][dimesion][order] = temph
        mobile_report.update(:report_json => mobile_report_h.to_json)
      end
    }
    logger.info("======组装错题分析:end===========")
  end

  #计算整体，个人各指标：总分，平均分
  def cal_ckp_total_avg
    logger.info("======计算整体，个人各指标：总分，平均分:begin===========")
    return false if @pap_uid.blank?
    filter = {
#      :wx_openid => @wx_openid,
      :pap_uid => @pap_uid
    }
=begin
    map = %Q{
      function(){
        var real_total = this.weights * this.real_score;
        var full_total = this.weights * this.full_score;

        var value_obj = {
          reduced: 0,
          wx_openids: this.wx_openid,
          wx_openid: this.wx_openid,
          total_tester: 1,
          real_score: this.real_score,
          full_score: this.full_score,
          average: this.real_score,
          average_percent: this.real_score/this.full_score,
          real_total: real_total,
          full_total: full_total,
          full_mark: this.full_score,
          qzp_uids: this.qzp_uid,
          qzp_uid: this.qzp_uid,
          total_qzp_count: 1,
          correct_qzp_count: 1,
          correct_qzp_percent: 1
        };
        emit({pap_uid: this.pap_uid}, value_obj);
        emit({pap_uid: this.pap_uid, dimesion: this.dimesion}, value_obj);
        emit({pap_uid: this.pap_uid, dimesion: this.dimesion, lv1_ckp: this.lv1_ckp}, value_obj);
        emit({pap_uid: this.pap_uid, dimesion: this.dimesion, lv2_ckp: this.lv2_ckp}, value_obj);
        emit({pap_uid: this.pap_uid, pup_uid:this.pup_uid, wx_openid: this.wx_openid}, value_obj);
        emit({pap_uid: this.pap_uid, pup_uid:this.pup_uid, wx_openid: this.wx_openid, dimesion: this.dimesion}, value_obj);
        emit({pap_uid: this.pap_uid, pup_uid:this.pup_uid, wx_openid: this.wx_openid, dimesion: this.dimesion, lv1_ckp: this.lv1_ckp}, value_obj);
        emit({pap_uid: this.pap_uid, pup_uid:this.pup_uid, wx_openid: this.wx_openid, dimesion: this.dimesion, lv2_ckp: this.lv2_ckp}, value_obj);
        emit({pap_uid: this.pap_uid, pup_uid:this.pup_uid, wx_openid: this.wx_openid, dimesion: this.dimesion, order: this.order, lv1_ckp: this.lv1_ckp}, value_obj);
        emit({pap_uid: this.pap_uid, pup_uid:this.pup_uid, wx_openid: this.wx_openid, dimesion: this.dimesion, order: this.order, lv2_ckp: this.lv2_ckp}, value_obj);
      }
    }
=end

    map = %Q{
      function(){
        var real_total = this.weights * this.real_score;
        var full_total = this.weights * this.full_score;

        var value_obj = {
          reduced: 0,
          wx_openids: this.wx_openid,
          wx_openid: this.wx_openid,
          total_tester: 1,
          real_score: this.real_score,
          full_score: this.full_score,
          average: this.real_score,
          average_percent: this.real_score/this.full_score,
          real_total: real_total,
          full_total: full_total,
          full_mark: this.full_score,
          qzp_uids: this.qzp_uid,
          qzp_uid: this.qzp_uid,
          total_qzp_count: 1,
          correct_qzp_count: 1,
          correct_qzp_percent: 1
        };
        emit({pap_uid: this.pap_uid}, value_obj);
        emit({pap_uid: this.pap_uid, dimesion: this.dimesion}, value_obj);
        emit({pap_uid: this.pap_uid, dimesion: this.dimesion, lv1_ckp: this.lv1_ckp}, value_obj);
        emit({pap_uid: this.pap_uid, dimesion: this.dimesion, lv2_ckp: this.lv2_ckp}, value_obj);
        emit({pap_uid: this.pap_uid, wx_openid: this.wx_openid}, value_obj);
        emit({pap_uid: this.pap_uid, wx_openid: this.wx_openid, dimesion: this.dimesion}, value_obj);
        emit({pap_uid: this.pap_uid, wx_openid: this.wx_openid, dimesion: this.dimesion, lv1_ckp: this.lv1_ckp}, value_obj);
        emit({pap_uid: this.pap_uid, wx_openid: this.wx_openid, dimesion: this.dimesion, lv2_ckp: this.lv2_ckp}, value_obj);
        emit({pap_uid: this.pap_uid, wx_openid: this.wx_openid, dimesion: this.dimesion, order: this.order, lv1_ckp: this.lv1_ckp}, value_obj);
        emit({pap_uid: this.pap_uid, wx_openid: this.wx_openid, dimesion: this.dimesion, order: this.order, lv2_ckp: this.lv2_ckp}, value_obj);
      }
    }

    reduce= %Q{
      function(key,values){
        var result = {
          reduced: 1,
          wx_openids:"",
          wx_openid: values[0].wx_openid,
          total_tester: 0,
          real_score: 0,
          full_score: 0,
          average: 0,
          average_percent: 0,
          real_total: 0,
          full_total: 0,
          full_mark: 0,
          qzp_uids: "",
          qzp_uid: values[0].qzp_uid,
          total_qzp_count: 0,
          correct_qzp_count: 0,
          correct_qzp_percent: 0 
        };

        var user_arr = [];
        var qzp_arr = [];


        values.forEach(function(value){
          result.real_total += value.real_total;
          result.full_total += value.full_total;
          user_arr = result.wx_openids.split(",");
          user_arr.pop();
          if(user_arr.indexOf(value.wx_openids) == -1 ){
            result.wx_openids += (value.wx_openids + ",");
            result.total_tester += value.total_tester;
          }
          qzp_arr = result.qzp_uids.split(",");
          qzp_arr.pop();
          if( qzp_arr.indexOf(value.qzp_uids) == -1 ){
            result.total_qzp_count += value.total_qzp_count;
            if( value.real_score == value.full_score ){
              result.qzp_uids += (value.qzp_uids + ",");
              result.correct_qzp_count += value.correct_qzp_count;
            }
          }

        });

        result.average = result.real_total/result.total_tester;
        result.full_mark = result.full_total/result.total_tester;
        result.average_percent = result.real_total/result.full_total;
        result.correct_qzp_percent = result.correct_qzp_count/result.total_qzp_count;

        return result;
      }
    }
    finalize = %Q{
      function(key,value){
        if(!value.reduced){
          result = value;
          if(value.real_score != value.full_score){
            result.correct_qzp_count = 0;
            result.correct_qzp_percent = 0;
          }
          return result;
        } else {
          return value;
        }
      }
    }

    Mongodb::MobileUserQizpointScore.where(filter).map_reduce(map,reduce).finalize(finalize).out(:reduce => "mongodb_mobile_report_total_avg_results").execute
    logger.info("======计算整体，个人各指标：总分，平均分:end===========")
  end

  def add_avg_col
    logger.info("======信息加工:begin===========")
    filter = {
      '_id.pap_uid' => @pap_uid
    }
    arr = Mongodb::MobileReportTotalAvgResult.where(filter).no_timeout # need add filter here, user_id or somethind

    add_avg_col_core 1, arr
    logger.info("======信息加工:end===========")
  end

  def add_avg_col_core th_index, arr
    total_num =arr.size
    arr.each_with_index{|item,index|
      logger.info(">>>>>>thread #{th_index}, current status (#{index}/#{total_num})<<<<<<") if index%100 == 0
      total_common_cond = ( !item[:_id].keys.include?('wx_openid') )
      qzp_score_common_cond = {'_id.pap_uid' => @pap_uid }
      qzp_score_upt_h = {}

      if(total_common_cond && 
        item[:_id].keys.include?('dimesion') && 
        item[:_id].keys.include?('lv1_ckp'))
        qzp_score_common_cond['_id.dimesion']=item[:_id][:dimesion]
        qzp_score_common_cond['_id.lv1_ckp']=item[:_id][:lv1_ckp]
        qzp_score_upt_h['value.total_dim_lv1_avg'] = item[:value][:average]
        qzp_score_upt_h['value.total_dim_lv1_avg_percent'] = item[:value][:average_percent]
        qzp_score_upt_h['value.total_correct_qzp_percent'] = item[:value][:correct_qzp_percent]
      elsif(total_common_cond &&
            item[:_id].keys.include?('dimesion') && 
            item[:_id].keys.include?('lv2_ckp'))
        qzp_score_common_cond['_id.dimesion']=item[:_id][:dimesion]
        qzp_score_common_cond['_id.lv2_ckp']=item[:_id][:lv2_ckp]
        qzp_score_upt_h['value.total_dim_lv2_avg'] = item[:value][:average]
        qzp_score_upt_h['value.total_dim_lv2_avg_percent'] = item[:value][:average_percent]
        qzp_score_upt_h['value.total_correct_qzp_percent'] = item[:value][:correct_qzp_percent]
      elsif(total_common_cond &&
            item[:_id].keys.include?('dimesion') &&
            !item[:_id].keys.include?('order'))
        qzp_score_common_cond['_id.dimesion']=item[:_id][:dimesion]
        qzp_score_upt_h['value.total_dim_avg'] = item[:value][:average]
        qzp_score_upt_h['value.total_dim_avg_percent'] = item[:value][:average_percent]
        qzp_score_upt_h['value.total_correct_qzp_percent'] = item[:value][:correct_qzp_percent]
      elsif(total_common_cond &&
            !item[:_id].keys.include?('dimesion') &&
            item[:_id].keys.include?('order'))
        qzp_score_common_cond['_id.order']=item[:_id][:order]
        qzp_score_upt_h['value.total_dim_avg'] = item[:value][:average]
        qzp_score_upt_h['value.total_dim_avg_percent'] = item[:value][:average_percent]
        qzp_score_upt_h['value.total_correct_qzp_percent'] = item[:value][:correct_qzp_percent]
      elsif total_common_cond
        qzp_score_upt_h['value.total_avg'] = item[:value][:average]
        qzp_score_upt_h['value.total_avg_percent'] = item[:value][:average_percent]
        qzp_score_upt_h['value.total_correct_qzp_percent'] = item[:value][:correct_qzp_percent]
      end
      unless qzp_score_upt_h.empty?
        results = Mongodb::MobileReportTotalAvgResult.where(qzp_score_common_cond).no_timeout
        results.each{|result| result.update_attributes(qzp_score_upt_h)}
      end
    }  
  end

  def cal_based_on_total_avg
    logger.info("======信息加工2:begin===========")
    return false if @pap_uid.blank?
    filter = {
      '_id.pap_uid' => @pap_uid
    }

=begin
    map = %Q{
      function(){
        if(this._id.wx_openid){
          if(this._id.lv1_ckp){
            emit(
              {pap_uid: this._id.pap_uid, pup_uid:this._id.pup_uid, wx_openid: this._id.wx_openid, dimesion: this._id.dimesion, lv1_ckp: this._id.lv1_ckp},
              {
                reduced: 0,
                average: this.value.average,
                average_percent: this.value.average_percent,
                total_average: this.value.total_dim_lv1_avg,
                total_average_percent: this.value.total_dim_lv1_avg_percent,
                user_total_diff: (this.value.average_percent - this.value.total_dim_lv1_avg_percent)
              }
            );
          } else if(this._id.lv2_ckp){
            emit(
              {pap_uid: this._id.pap_uid, pup_uid:this._id.pup_uid, wx_openid: this._id.wx_openid, dimesion: this._id.dimesion, lv2_ckp: this._id.lv2_ckp},
              {
                reduced: 0,
                average: this.value.average,
                average_percent: this.value.average_percent,
                total_average: this.value.total_dim_lv2_avg,
                total_average_percent: this.value.total_dim_lv2_avg_percent,
                user_total_diff: (this.value.average_percent - this.value.total_dim_lv2_avg_percent)
              }
            );
          } else if(this._id.dimesion){
            emit(
              {pap_uid: this._id.pap_uid, pup_uid:this._id.pup_uid, wx_openid: this._id.wx_openid, dimesion: this._id.dimesion},
              {
                reduced: 0,
                average: this.value.average,
                average_percent: this.value.average_percent,
                total_average: this.value.total_dim_avg,
                total_average_percent: this.value.total_dim_avg_percent,
                user_total_diff: (this.value.average_percent - this.value.total_dim_avg_percent)
              }
            );
          } else if(this._id.order){
            emit(
              {pap_uid: this._id.pap_uid, pup_uid:this._id.pup_uid, wx_openid: this._id.wx_openid, order: this._id.order},
              {
                reduced: 0,
                average: this.value.average,
                average_percent: this.value.average_percent,
                total_average: this.value.total_avg,
                total_average_percent: this.value.total_avg_percent,
                user_total_diff: (this.value.average_percent - this.value.total_avg_percent)
              }
            );
          } else {
            emit(
              {pap_uid: this._id.pap_uid, pup_uid:this._id.pup_uid, wx_openid: this._id.wx_openid },
              {
                reduced: 0,
                average: this.value.average,
                average_percent: this.value.average_percent,
                total_average: this.value.total_avg,
                total_average_percent: this.value.total_avg_percent,
                user_total_diff: (this.value.average_percent - this.value.total_avg_percent)
              }
            );
          }
        }
      }
    }
=end

    map = %Q{
      function(){
        if(this._id.wx_openid){
          if(this._id.lv1_ckp){
            emit(
              {pap_uid: this._id.pap_uid, wx_openid: this._id.wx_openid, dimesion: this._id.dimesion, lv1_ckp: this._id.lv1_ckp},
              {
                reduced: 0,
                average: this.value.average,
                average_percent: this.value.average_percent,
                total_average: this.value.total_dim_lv1_avg,
                total_average_percent: this.value.total_dim_lv1_avg_percent,
                user_total_diff: (this.value.average_percent - this.value.total_dim_lv1_avg_percent)
              }
            );
          } else if(this._id.lv2_ckp){
            emit(
              {pap_uid: this._id.pap_uid, wx_openid: this._id.wx_openid, dimesion: this._id.dimesion, lv2_ckp: this._id.lv2_ckp},
              {
                reduced: 0,
                average: this.value.average,
                average_percent: this.value.average_percent,
                total_average: this.value.total_dim_lv2_avg,
                total_average_percent: this.value.total_dim_lv2_avg_percent,
                user_total_diff: (this.value.average_percent - this.value.total_dim_lv2_avg_percent)
              }
            );
          } else if(this._id.dimesion){
            emit(
              {pap_uid: this._id.pap_uid, wx_openid: this._id.wx_openid, dimesion: this._id.dimesion},
              {
                reduced: 0,
                average: this.value.average,
                average_percent: this.value.average_percent,
                total_average: this.value.total_dim_avg,
                total_average_percent: this.value.total_dim_avg_percent,
                user_total_diff: (this.value.average_percent - this.value.total_dim_avg_percent)
              }
            );
          } else if(this._id.order){
            emit(
              {pap_uid: this._id.pap_uid, wx_openid: this._id.wx_openid, order: this._id.order},
              {
                reduced: 0,
                average: this.value.average,
                average_percent: this.value.average_percent,
                total_average: this.value.total_avg,
                total_average_percent: this.value.total_avg_percent,
                user_total_diff: (this.value.average_percent - this.value.total_avg_percent)
              }
            );
          } else {
            emit(
              {pap_uid: this._id.pap_uid, wx_openid: this._id.wx_openid },
              {
                reduced: 0,
                average: this.value.average,
                average_percent: this.value.average_percent,
                total_average: this.value.total_avg,
                total_average_percent: this.value.total_avg_percent,
                user_total_diff: (this.value.average_percent - this.value.total_avg_percent)
              }
            );
          }
        }
      }
    }

    # 目前无reduce运算
    reduce = %Q{
      function(key,values){
        var result = values[0];
        return result;
      }
    }

    Mongodb::MobileReportTotalAvgResult.where(filter).map_reduce(map,reduce).out(:reduce => "mongodb_mobile_report_based_on_total_avg_results").execute
    logger.info("======信息加工2:end===========")
  end

#  def get_mobile_user_report pup_uid, wx_openid
   def get_mobile_user_report wx_openid
  	#未来因为绑定与未绑定区别时，可作处理
  	# 无pup_id：未绑定用户
  	# 无wx_openid：非微信用户
  	# 无pup_id，有wx_openid: 微信未绑定用户
  	# 
=begin
  	if !pup_uid.blank?
      mobile_report = Mongodb::PupilMobileReport.where(:pup_uid=> pup_uid, :pap_uid => @pap_uid ).first
      pupil = Pupil.where(uid: pup_uid).first
      username = pupil.name
      sex = pupil.sex
    elsif !wx_openid.blank?
      mobile_report = Mongodb::PupilMobileReport.where(:wx_openid=> wx_openid, :pap_uid => @pap_uid ).first
      username = wx_openid 
      sex = Common::Locale::i18n("dict.unknown")
    else
      mobile_report = nil
    end
=end

    if !wx_openid.blank?
      mobile_report = Mongodb::PupilMobileReport.where(:wx_openid=> wx_openid, :pap_uid => @pap_uid ).first
      username = wx_openid 
      sex = Common::Locale::i18n("dict.unknown")
    else
      mobile_report = nil
    end

  	unless mobile_report
#  	  if !pup_uid.blank? || !wx_openid.blank?
      if !wx_openid.blank?
  	  	params_h= {
          :pap_uid => @pap_uid,
#          :pup_uid => pup_uid,
          :wx_openid => wx_openid
        }
        mobile_report = Mongodb::PupilMobileReport.new(params_h)
        mobile_report_h = Common::Report::Format::PupilMobile.deep_dup

        mobile_report_h["basic"]["name"] = username
        mobile_report_h["basic"]["subject"] = Common::Locale::i18n("dict.#{@paper.subject}")
        mobile_report_h["basic"]["sex"] = sex
        mobile_report_h["basic"]["levelword2"] = @paper.levelword2
        mobile_report_h["basic"]["quiz_date"] = @online_test.nil?? "" : @online_test.dt_add.strftime("%Y-%m-%d %H:%M")
#        j = JSON.parse(@online_test.result_json) if @online_test
#        mobile_report_h["basic"]["score"] = @online_test.nil?? 0 : j["bank_quiz_qizs"].values.map{|qiz| qiz["bank_qizpoint_qzps"].values }.flatten.map{|a| a["real_score"].to_i}.sum
        mobile_report_h["basic"]["full_score"] = @paper.score
        mobile_report.update(:report_json => mobile_report_h.to_json)
      end
    else
      mobile_report_h = JSON.parse(mobile_report.report_json)
    end
    return mobile_report, mobile_report_h
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

end
