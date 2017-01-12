# -*- coding: UTF-8 -*-

class ImportScoreJob < ActiveJob::Base
  queue_as :score

  def self.perform_later(*args)
    begin
      params = args[0]
      logger.info "============>>Import Score Job: Begin<<=============="

      job_tracker = JobList.new(name: "ImportScoreJob",
                                task_uid: params[:task_uid],
                                status: Common::Job::Status::InQueue)
      job_tracker.save
      phase_total = 15

      logger.info "============>>>Import Score Job: 初始化<<<============"
      job_tracker.update(status: Common::Job::Status::Processing)
      job_tracker.update(process: 1/phase_total.to_f)

      target_paper = Mongodb::BankPaperPap.find(params[:pap_uid])
      target_paper.update(:paper_status =>  Common::Paper::Status::ScoreImporting)

      paper_h = JSON.parse(target_paper.paper_json)
      paper_h["task_uid"] = params[:task_uid]
      target_paper.update(paper_json: paper_h.to_json)

      score_file = ScoreUpload.where(id: target_paper.score_file_id).first
      target_tenant = target_paper.tenant
      raise I18n.t "scores.messages.error.no_tenant" unless target_tenant
      subject = target_paper.subject

      filled_file = Roo::Excelx.new(score_file.filled_file.current_path)
      sheet = filled_file.sheet(I18n.t('scores.excel.score_title')) if filled_file

      logger.info ">>> 读取excel title <<<"
      job_tracker.update(process: 2/phase_total.to_f)

      # read title
      loc_row = sheet.row(1)
      hidden_row = sheet.row(2)
      order_row = sheet.row(3)
      title_row = sheet.row(4)
      loc_h = {
        :province => Common::Locale.hanzi2pinyin(loc_row[1]),
        :city => Common::Locale.hanzi2pinyin(loc_row[3]),
        :district => Common::Locale.hanzi2pinyin(loc_row[5]),
        :school => Common::Locale.hanzi2pinyin(loc_row[7]),
        :tenant_uid => target_tenant.uid
      }

      logger.info ">>> 确定读取范围 <<<"
      job_tracker.update(process: 3/phase_total.to_f)

      # initial data
      data_start_row = 5
      data_start_col = 8
      total_row = sheet.count
      total_cols = hidden_row.size

      logger.info ">>> 老师及学生sheet初始化 <<<"
      job_tracker.update(process: 4/phase_total.to_f)

      out_excel = Axlsx::Package.new
      wb = out_excel.workbook
      teacher_sheet = wb.add_worksheet(:name => I18n.t('scores.excel.teacher_password_title'))
      pupil_sheet = wb.add_worksheet(:name => I18n.t('scores.excel.pupil_password_title'))

      teacher_sheet.sheet_protection.password = Common::SwtkConstants::DefaultSheetPassword
      pupil_sheet.sheet_protection.password = Common::SwtkConstants::DefaultSheetPassword

      teacher_title_row = [
          I18n.t('activerecord.attributes.user.name'),
          I18n.t('activerecord.attributes.user.password'),
          I18n.t('dict.name'),
          I18n.t('reports.generic_url'),
          I18n.t('reports.op_guide')
      ]
      teacher_sheet.add_row teacher_title_row

      pupil_title_row = [
          I18n.t('activerecord.attributes.user.name'),
          I18n.t('activerecord.attributes.user.password'),
          I18n.t('dict.name'),
          I18n.t('dict.pupil_number'),
          I18n.t('reports.generic_url'),
          I18n.t('reports.op_guide')
      ]
      pupil_sheet.add_row pupil_title_row

      logger.info "============>>>Import Score Job: 读取表格数据<<<============"
      job_tracker.update(process: 5/phase_total.to_f)

      teacher_username_in_sheet = []
      pupil_username_in_sheet = []
      #######start to analyze#######      
      (data_start_row..total_row).each{|index|
        row = sheet.row(index)
        grade_pinyin = Common::Locale.hanzi2pinyin(row[0])
        klass_pinyin = Common::Locale.hanzi2pinyin(row[1])
        klass_value = Common::Klass::List.keys.include?(klass_pinyin.to_sym) ? klass_pinyin : row[1]
        cells = {
          :grade => grade_pinyin,
          :xue_duan => Common::Grade.judge_xue_duan(grade_pinyin),
          :classroom => klass_value,
          :head_teacher => row[2],
          :teacher => row[3],
          :pupil_name => row[4],
          :stu_number => row[5],
          :sex => row[6]
        }

        #
        # get location
        #
        loc_h[:grade] = cells[:grade]
        loc_h[:classroom] = cells[:classroom]
        loc = Location.where(loc_h).first
        if loc.nil?
          loc = Location.new(loc_h)
          loc.save!
        end
        raise I18n.t "locations.messages.error.invalid_location" unless loc
         
        user_row_arr = []
        # 
        # create teacher user 
        #
        head_tea_h = {
          :loc_uid => loc.uid,
          :name => cells[:head_teacher],
          :subject => target_paper.subject,
          :head_teacher => true,
          :user_name => target_paper.format_user_name([
            target_tenant.number,
            Common::Subject::Abbrev[target_paper.subject.to_sym],
            Common::Locale.hanzi2abbrev(cells[:head_teacher])
          ])
        }
        user_row_arr =target_paper.format_user_password_row(Common::Role::Teacher, head_tea_h)
        unless teacher_username_in_sheet.include?(user_row_arr[0])
          teacher_sheet.add_row user_row_arr
          teacher_username_in_sheet << user_row_arr[0]
        end
        
        tea_h = {
          :loc_uid => loc.uid,
          :name => cells[:teacher],
          :subject => target_paper.subject,
          :head_teacher => false,
          :user_name => target_paper.format_user_name([
            target_tenant.number,
            Common::Subject::Abbrev[target_paper.subject.to_sym],
            Common::Locale.hanzi2abbrev(cells[:teacher])
          ])
        }
        user_row_arr = target_paper.format_user_password_row(Common::Role::Teacher, tea_h)
        unless teacher_username_in_sheet.include?(user_row_arr[0])
          teacher_sheet.add_row user_row_arr
          teacher_username_in_sheet << user_row_arr[0]
        end

        #
        # create pupil user
        #
        pup_h = {
          :loc_uid => loc.uid,
          :name => cells[:pupil_name],
          :stu_number => cells[:stu_number],
          :grade => cells[:grade],
          :classroom => cells[:classroom],
          :subject => target_paper.subject,
          :sex => Common::Locale.hanzi2pinyin(cells[:sex]),
          :user_name => target_paper.format_user_name([
            target_tenant.number,
            cells[:stu_number],
            Common::Locale.hanzi2abbrev(cells[:pupil_name])
          ])
        }
        user_row_arr = target_paper.format_user_password_row(Common::Role::Pupil, pup_h)
        unless pupil_username_in_sheet.include?(user_row_arr[0])
          pupil_sheet.add_row user_row_arr
          pupil_username_in_sheet << user_row_arr[0]
        end

        current_user = User.where(name: pup_h[:user_name]).first
        current_pupil = current_user.nil?? nil : current_user.pupil

        (data_start_col..(total_cols-1)).each{|qzp_index|
          param_h = {
            :province => loc_h[:province],
            :city => loc_h[:city],
            :district => loc_h[:district],
            :school => loc_h[:school],
            :grade => cells[:grade],
            :classroom => cells[:classroom],         
            :pup_uid => current_pupil.nil?? "":current_pupil.uid,
            :pap_uid => target_paper._id.to_s,
            :qzp_uid => hidden_row[qzp_index],
            :tenant_uid => target_tenant.uid,
            :order => order_row[qzp_index],
            :real_score => row[qzp_index],
            :full_score => title_row[qzp_index]
          }

          qizpoint = Mongodb::BankQizpointQzp.where(_id: hidden_row[qzp_index]).first
          qizpoint_qiz = qizpoint.nil?? nil : qizpoint.bank_quiz_qiz 
          #next unless qizpoint
          ckps = qizpoint.bank_checkpoint_ckps
          ckps.each{|ckp|
            next unless ckp
            if ckp.is_a? BankCheckpointCkp
              lv1_ckp = BankCheckpointCkp.where("node_uid = '#{target_paper.node_uid}' and rid = '#{ckp.rid.slice(0,3)}'").first
              lv2_ckp = BankCheckpointCkp.where("node_uid = '#{target_paper.node_uid}' and rid = '#{ckp.rid.slice(0,6)}'").first
            elsif ckp.is_a? BankSubjectCheckpointCkp
              lv1_ckp = BankSubjectCheckpointCkp.where("subject = '#{target_paper.subject}' and category = '#{cells[:xue_duan]}' and rid = '#{ckp.rid.slice(0,3)}'").first
              lv2_ckp = BankSubjectCheckpointCkp.where("subject = '#{target_paper.subject}' and category = '#{cells[:xue_duan]}' and rid = '#{ckp.rid.slice(0,6)}'").first
            end
            param_h[:dimesion] = ckp.dimesion
            param_h[:lv1_uid] = lv1_ckp.uid
            param_h[:lv1_ckp] = lv1_ckp.checkpoint
            param_h[:lv1_advice] = lv1_ckp.advice
            param_h[:lv1_order] = lv1_ckp.sort
            param_h[:lv2_uid] = lv2_ckp.uid
            param_h[:lv2_ckp] = lv2_ckp.checkpoint
            param_h[:lv2_advice] = lv2_ckp.advice
            param_h[:lv2_order] = lv2_ckp.sort
            param_h[:lv3_uid] = ckp.uid
            param_h[:lv3_ckp] = ckp.checkpoint
            param_h[:lv3_advice] = ckp.advice
            param_h[:lv3_order] = ckp.sort
            param_h[:lv_end_uid] = ckp.uid
            param_h[:lv_end_ckp] = ckp.checkpoint
            param_h[:lv_end_advice] = ckp.advice
            param_h[:lv_end_order] = ckp.sort

            #调整权重系数
            # 1.单题难度关联
            #
            param_h[:weights] = Mongodb::BankPaperPap.ckp_weights_modification({
              :subject => target_paper.subject,
              :dimesion=> param_h[:dimesion], 
              :weights => ckp.weights, 
              :difficulty=> qizpoint_qiz.levelword2})
            qizpoint_score = Mongodb::BankQizpointScore.new(param_h)
            qizpoint_score.save!
          }
        }

        process_value = 5 + 9*(index+1)/(total_row-data_start_row)
        job_tracker.update(process: process_value/phase_total.to_f)
      }

      # create user password file
      file_path = Rails.root.to_s + "/tmp/#{target_paper._id.to_s}_password.xlsx"
      out_excel.serialize(file_path)
      file_h = {:score_file_id => target_paper.score_file_id, :file_path => file_path}
      score_file = Common::Score.create_usr_pwd file_h

      job_tracker.update(process: 1.0)
      target_paper.update(:paper_status =>  Common::Paper::Status::ScoreImported)
    rescue Exception => ex
      logger.info "===!Excepion!==="
      logger.info "[message]"
      logger.warn ex.message
      logger.info "[backtrace]"
      logger.warn ex.backtrace
    ensure 
      logger.info "============>>Import Score Job: End<<=============="
    end
  end
end
