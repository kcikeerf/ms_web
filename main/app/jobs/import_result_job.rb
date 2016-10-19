# -*- coding: UTF-8 -*-

require 'thwait'

class ImportResultJob < ActiveJob::Base
  queue_as :result

  def self.perform_later(*args)
    begin
      logger.info "============>>Import Result Job: Begin<<=============="
      params = args[0]

      # 获取试卷信息
      target_paper = Mongodb::BankPaperPap.where(id: params[:pap_uid]).first 
      raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "paper id: #{params[:pap_uid]}")) unless target_paper
      raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "test object")) unless target_paper.bank_tests[0]

      target_tenant = Tenant.where(uid: params[:tenant_uid]).first
      raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "tenant object")) unless target_tenant
      
      score_file = ScoreUpload.where(id: params[:score_file_id]).first
      raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "score file id: #{params[:score_file_id]}")) unless score_file

      filled_file = Roo::Excelx.new(score_file.filled_file.current_path)
      raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "score file path: #{score_file.filled_file.current_path}")) unless filled_file

      result_sheet = filled_file.sheet(Common::Locale::i18n('scores.excel.score_title'))
      raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "result sheet")) unless result_sheet

      logger.info(">>>初始化<<<")
      logger.info "paper id: #{params[:pap_uid]}"
      logger.info "test id: #{target_paper.bank_tests[0].id.to_s}"
      logger.info "tenant id: #{params[:tenant_uid]}"
      logger.info "score file id: #{params[:score_file_id]}"

      # 获取Task信息，创建JOB
      target_task = target_paper.bank_tests[0].tasks.by_task_type(Common::Task::Type::ImportResult).first
      target_task.touch(:dt_update)
      logger.info "task uid: #{target_task.uid}"
      
      # JOB的分处理的数量
      phase_total = 15
      job_tracker = JobList.new({
        :name => "ImportResultJob",
        :task_uid => target_task.uid,
        :status => Common::Job::Status::InQueue,
        :process => 1/phase_total.to_f
      })
      job_tracker.save!
      logger.info "job uid: #{job_tracker.uid}"
      target_paper.update(:paper_status =>  Common::Paper::Status::ScoreImporting)

      ###
      logger.info ">>> 读取excel title <<<"
      job_tracker.update(status: Common::Job::Status::Processing)
      job_tracker.update(process: 2/phase_total.to_f)

      # read title
      loc_row = result_sheet.row(1)
      hidden_row = result_sheet.row(2)
      order_row = result_sheet.row(3)
      title_row = result_sheet.row(4)
      loc_h = {
        :province => Common::Locale.hanzi2pinyin(loc_row[1]),
        :city => Common::Locale.hanzi2pinyin(loc_row[3]),
        :district => Common::Locale.hanzi2pinyin(loc_row[5]),
        :school => Common::Locale.hanzi2pinyin(loc_row[7]),
        :tenant_uid => target_tenant.uid
      }

      ###
      logger.info ">>> 确定读取范围 <<<"
      job_tracker.update(process: 3/phase_total.to_f)

      data_start_row = 5
      data_start_col = 8
      total_row = result_sheet.count
      total_cols = hidden_row.size

      ###
      logger.info ">>> 老师及学生sheet初始化 <<<"
      job_tracker.update(process: 4/phase_total.to_f)

      out_excel = Axlsx::Package.new
      wb = out_excel.workbook
      teacher_sheet = wb.add_worksheet(:name => Common::Locale::i18n('scores.excel.teacher_password_title'))
      pupil_sheet = wb.add_worksheet(:name => Common::Locale::i18n('scores.excel.pupil_password_title'))
      teacher_sheet.sheet_protection.password = Common::SwtkConstants::DefaultSheetPassword
      pupil_sheet.sheet_protection.password = Common::SwtkConstants::DefaultSheetPassword

      teacher_title_row = [
          Common::Locale::i18n('activerecord.attributes.user.name'),
          Common::Locale::i18n('activerecord.attributes.user.password'),
          Common::Locale::i18n('dict.name'),
          Common::Locale::i18n('reports.generic_url'),
          Common::Locale::i18n('reports.op_guide')
      ]
      teacher_sheet.add_row teacher_title_row

      pupil_title_row = [
          Common::Locale::i18n('activerecord.attributes.user.name'),
          Common::Locale::i18n('activerecord.attributes.user.password'),
          Common::Locale::i18n('dict.name'),
          Common::Locale::i18n('dict.pupil_number'),
          Common::Locale::i18n('reports.generic_url'),
          Common::Locale::i18n('reports.op_guide')
      ]
      pupil_sheet.add_row pupil_title_row

      ###
      logger.info ">>> 读取表格数据 <<<"
      job_tracker.update(process: 5/phase_total.to_f)

      #上传成绩多线程处理
      logger.info ">>>多线程读取<<<"
      num_per_th = Common::Score::Thread::NumPerTh
      th_number = total_row/num_per_th + 1
      mod_num = total_row%num_per_th
      logger.info "线程数量: #{th_number}, 行数: #{total_row}"

      th_arr = []
      th_number.times.each{|th|
        start_num = th*num_per_th
        end_num = (th+1)*num_per_th - 1 + (((th + 1) == th_number)? mod_num : 0)
        th_arr << Thread.new {
          import_score_core({
            :th_index => th,
            :result_sheet => result_sheet.clone,
            :hidden_row => hidden_row,
            :order_row => order_row,
            :title_row => title_row,
            :start_num => start_num,
            :end_num => end_num,
            :data_start_row => data_start_row,
            :data_start_col => data_start_col,
            :total_cols => total_cols,
            :loc_h => loc_h,
            :target_paper => target_paper,
            :target_tenant => target_tenant,
            :teacher_sheet => teacher_sheet.clone,
            :pupil_sheet => pupil_sheet.clone

          })
        }
      }
      ThreadsWait.all_waits(*th_arr)

      # create user password file
      file_path = Rails.root.to_s + "/tmp/#{target_paper._id.to_s}_password.xlsx"
      out_excel.serialize(file_path)
      file_h = {:score_file_id => target_paper.score_file_id, :file_path => file_path}
      score_file = Common::Score.create_usr_pwd file_h

      #job_tracker.update(process: 1.0)
      #target_paper.update(:paper_status =>  Common::Paper::Status::ScoreImported)
    rescue Exception => ex
      logger.info "===Excepion==="
      logger.info "[message]"
      logger.warn ex.message
      logger.info "[backtrace]"
      logger.warn ex.backtrace
    ensure 
      logger.info "============>>Import Result Job: End<<=============="
    end
  end

  def self.import_score_core args={}
      logger.info ">>>thread index #{args[:th_index]}: [from, to]=>[#{args[:start_num]},#{args[:end_num]}] <<<"
      begin
        #主线程读取用户信息
        teacher_username_in_sheet = []
        pupil_username_in_sheet = []
        #######start to analyze#######      
        (args[:start_num]..args[:end_num]).each{|index|
          next if index < args[:data_start_row]
          row = args[:result_sheet].row(index)
          grade_pinyin = Common::Locale.hanzi2pinyin(row[0])
          klass_pinyin = Common::Locale.hanzi2pinyin(row[1])
          klass_value = Common::Klass::List.keys.include?(klass_pinyin.to_sym) ? klass_pinyin : row[1]
          cells = {
            :grade => grade_pinyin,
            :xue_duan => BankNodestructure.get_subject_category(grade_pinyin),
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
          args[:loc_h][:grade] = cells[:grade]
          args[:loc_h][:classroom] = cells[:classroom]
          loc = Location.where(args[:loc_h]).first
          if loc.nil?
            loc = Location.new(args[:loc_h])
            loc.save!
          end
          raise SwtkErrors::NotFoundError.new(I18.t("swtk_errors.object_not_found", :message => "location, loc_h:#{args[:loc_h]}")) unless loc
           
          user_row_arr = []
          # 
          # create teacher user 
          #
          head_tea_h = {
            :loc_uid => loc.uid,
            :name => cells[:head_teacher],
            :subject => args[:target_paper].subject,
            :head_teacher => true,
            :user_name => args[:target_paper].format_user_name([
              args[:target_tenant].number,
              Common::Subject::Abbrev[args[:target_paper].subject.to_sym],
              Common::Locale.hanzi2abbrev(cells[:head_teacher])
            ])
          }
          user_row_arr =args[:target_paper].format_user_password_row(Common::Role::Teacher, head_tea_h)
          unless teacher_username_in_sheet.include?(user_row_arr[0])
            args[:teacher_sheet].add_row user_row_arr
            teacher_username_in_sheet << user_row_arr[0]
          end
          
          tea_h = {
            :loc_uid => loc.uid,
            :name => cells[:teacher],
            :subject => args[:target_paper].subject,
            :head_teacher => false,
            :user_name => args[:target_paper].format_user_name([
              args[:target_tenant].number,
              Common::Subject::Abbrev[args[:target_paper].subject.to_sym],
              Common::Locale.hanzi2abbrev(cells[:teacher])
            ])
          }
          user_row_arr = args[:target_paper].format_user_password_row(Common::Role::Teacher, tea_h)
          unless teacher_username_in_sheet.include?(user_row_arr[0])
            args[:teacher_sheet].add_row user_row_arr
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
            :subject => args[:target_paper].subject,
            :sex => Common::Locale.hanzi2pinyin(cells[:sex]),
            :user_name => args[:target_paper].format_user_name([
              args[:target_tenant].number,
              cells[:stu_number],
              Common::Locale.hanzi2abbrev(cells[:pupil_name])
            ])
          }
          user_row_arr = args[:target_paper].format_user_password_row(Common::Role::Pupil, pup_h)
          unless pupil_username_in_sheet.include?(user_row_arr[0])
            args[:pupil_sheet].add_row user_row_arr
            pupil_username_in_sheet << user_row_arr[0]
          end

          current_user = User.where(name: pup_h[:user_name]).first
          current_pupil = current_user.nil?? nil : current_user.pupil

          logger.info ">>>thread index #{args[:th_index]} cols range: #{args[:data_start_col]},#{args[:total_cols]} <<<"
          (args[:data_start_col]..(args[:total_cols]-1)).each{|qzp_index|
            param_h = {
              :province => args[:loc_h][:province],
              :city => args[:loc_h][:city],
              :district => args[:loc_h][:district],
              :school => args[:loc_h][:school],
              :grade => cells[:grade],
              :classroom => cells[:classroom],         
              :pup_uid => current_pupil.nil?? "":current_pupil.uid,
              :pap_uid => args[:target_paper]._id.to_s,
              :qzp_uid => args[:hidden_row][qzp_index],
              :tenant_uid => args[:target_tenant].uid,
              :order => args[:order_row][qzp_index],
              :real_score => row[qzp_index],
              :full_score => args[:title_row][qzp_index]
            }

            qizpoint = Mongodb::BankQizpointQzp.where(_id: args[:hidden_row][qzp_index]).first
            qizpoint_qiz = qizpoint.nil?? nil : qizpoint.bank_quiz_qiz 
            #next unless qizpoint
            ckps = qizpoint.bank_checkpoint_ckps
            ckps.each{|ckp|
              next unless ckp
              if ckp.is_a? BankCheckpointCkp
                lv1_ckp = BankCheckpointCkp.where("node_uid = '#{args[:target_paper].node_uid}' and rid = '#{ckp.rid.slice(0,3)}'").first
                lv2_ckp = BankCheckpointCkp.where("node_uid = '#{args[:target_paper].node_uid}' and rid = '#{ckp.rid.slice(0,6)}'").first
              elsif ckp.is_a? BankSubjectCheckpointCkp
                lv1_ckp = BankSubjectCheckpointCkp.where("subject = '#{args[:target_paper].subject}' and category = '#{cells[:xue_duan]}' and rid = '#{ckp.rid.slice(0,3)}'").first
                lv2_ckp = BankSubjectCheckpointCkp.where("subject = '#{args[:target_paper].subject}' and category = '#{cells[:xue_duan]}' and rid = '#{ckp.rid.slice(0,6)}'").first
              end
              next unless lv1_ckp || lv2_ckp

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
                :subject => args[:target_paper].subject,
                :dimesion=> param_h[:dimesion], 
                :weights => ckp.weights, 
                :difficulty=> qizpoint_qiz.levelword2})
              qizpoint_score = Mongodb::BankQizpointScore.new(param_h)
              qizpoint_score.save!
            }
          }

          # process_value = 5 + 9*(index+1)/(total_row-data_start_row)
          # job_tracker.update(process: process_value/phase_total.to_f)
        }
      rescue Exception => ex
        logger.info ">>>thread index #{args[:th_index]}: Excepion Message (#{ex.message})<<<"
        logger.warn ">>>thread index #{args[:th_index]}: Excepion Message (#{ex.backtrace})<<<"
      ensure
        logger.info ">>>thread index #{args[:th_index]}: end<<<"
      end
  end
end
