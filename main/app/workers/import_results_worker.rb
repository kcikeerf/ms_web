# -*- coding: UTF-8 -*-

class ImportResultsWorker
  include Sidekiq::Worker

  def perform(*args)
    logger = Sidekiq::Logging.logger
    Common::process_sync_template(__method__.to_s()) {|pids|
      pids << fork do # fork new process, begin
        begin
          logger.info ">>>>>>>Import Results Worker: Begin<<<<<<<"
          logger.info "#{args}"
          params = {}
          args[0].each{|k,v|
          	params[k.to_sym] = v
          }
          logger.info "#{params}"

          @cols = {
            :grade => 0,
            :classroom => 1,
            :head_teacher_name => 2,
            :head_teacher_number => 3,
            :subject_teacher_name => 4,
            :subject_teacher_number => 5,
            :pupil_name => 6,
            :pupil_number => 7,
            :pupil_gender => 8,
            :pupil_full_score => 9,
            :data_start => 10,
          }

          @rows = {
            :loc_row => 1,
            :hidden_row => 2,
            :order_row => 3,
            :title_row => 4,
            :data_start => 5
          }

          # 获取试卷信息
          @target_paper = Mongodb::BankPaperPap.where(id: params[:pap_uid]).first 
          raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "paper id: #{params[:pap_uid]}")) unless @target_paper
          @target_paper_id =  @target_paper._id.to_s
          @target_test = @target_paper.bank_tests[0]
          raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "test object")) unless @target_test
          raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "test no tenant associated")) if @target_test.bank_test_tenant_links.blank?

          unless @target_test.tenants.map(&:uid).include?(params[:tenant_uid])
            raise SwtkErrors::TestTenantNotAssociatedError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => ""))
          end

          @target_tenant = Tenant.where(uid: params[:tenant_uid]).first
          raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "tenant object")) unless @target_tenant
          @target_tenant_uid = @target_tenant.uid

          score_file = ScoreUpload.where(id: params[:score_file_id]).first
          raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "score file id: #{params[:score_file_id]}")) unless score_file

          filled_file = Roo::Excelx.new(score_file.filled_file.current_path)
          raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "score file path: #{score_file.filled_file.current_path}")) unless filled_file

          @result_sheet = filled_file.sheet(Common::Locale::i18n('scores.excel.score_title'))
          raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "result sheet")) unless @result_sheet

          paper_qzps = @target_paper.bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps}.flatten.compact

          # 获取Task信息，创建JOB
          target_task = @target_test.tasks.by_task_type(Common::Task::Type::ImportResult).first
          raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "task uid: #{target_task.uid}")) unless target_task
          @job_tracker = JobList.where(uid: params[:job_uid]).first
          raise SwtkErrors::NotFoundError.new(Common::Locale::i18n("swtk_errors.object_not_found", :message => "job uid: #{params[:job_uid]}")) unless @job_tracker

          # 检查指标mapping，若未生成则生成
          paper_qzps.each{|qzp|
            next if Common::valid_json?(qzp.ckps_json)
            qzp.format_ckps_json 
          }

          # 检查大纲，若未生成则生成
          paper_qzps.each{|qzp|
            next if Common::valid_json?(qzp.paper_outline_json)
            qzp.format_paper_outline_json
          }

          # 指标mapping
          @qzps_ckps_mapping_h = {}
          paper_qzps.each{|qzp|
          	@qzps_ckps_mapping_h[qzp.id.to_s] = JSON.parse(qzp.ckps_json)
          }

          # 大纲mapping
          @qzps_outlines_mapping_h = {}
          paper_qzps.each{|qzp|
            next if qzp.paper_outline_json.blank?
            @qzps_outlines_mapping_h[qzp.id.to_s] = JSON.parse(qzp.paper_outline_json)
          }

          logger.info(">>>初始化<<<")
          logger.info "paper id: #{params[:pap_uid]}"
          logger.info "test id: #{@target_test.id.to_s}"
          logger.info "tenant id: #{params[:tenant_uid]}"
          logger.info "score file id: #{params[:score_file_id]}"

          # 更新Task, Job的信息
          target_task.touch(:dt_update)
          # JOB的分处理的数量
          @phase_total = 15
          @job_tracker.update({
            :status => Common::Job::Status::InQueue,
            :process => 1/@phase_total.to_f
          })

          #为了记录处理的进度
          @redis_key = Common::SwtkRedis::Prefix::ImportResult + @job_tracker.uid
          @redis_ns = Common::SwtkRedis::Ns::Sidekiq
          Common::SwtkRedis::set_key(@redis_ns,@redis_key, 0)

          # temp = target_paper.bank_tests[0].bank_test_tenant_links.where(:tenant_uid => params[:tenant_uid]).first
          # temp.update({
          #   :tenant_status => Common::Test::Status::ScoreImporting,
          #   :job_uid => @job_tracker.uid
          # })

          #delete old scores
          old_scores = Mongodb::BankTestScore.delete_all({
            :pap_uid => params[:pap_uid], 
            :test_id => @target_test.id.to_s,
            :tenant_uid => params[:tenant_uid]})
          # old_scores.destroy_all unless old_scores.blank?
          #target_paper.update(:paper_status =>  Common::Paper::Status::ScoreImporting)

          ###
          logger.info ">>> 读取excel title <<<"
          @job_tracker.update(status: Common::Job::Status::Processing)
          @job_tracker.update(process: 2/@phase_total.to_f)

          # read title
          # loc_row = @result_sheet.row(1)
          @hidden_row = @result_sheet.row(@rows[:hidden_row])
          @order_row = @result_sheet.row(@rows[:order_row])
          @title_row = @result_sheet.row(@rows[:title_row])
          # target_area = Area.get_area_by_name({
          #   :province => Common::Locale.hanzi2pinyin(loc_row[1]),
          #   :city => Common::Locale.hanzi2pinyin(loc_row[3]),
          #   :district => Common::Locale.hanzi2pinyin(loc_row[5])
          # })
          @loc_h = { :tenant_uid => @target_tenant_uid }
          target_area = @target_tenant.area
          @loc_h.merge!({
            :area_uid => target_area.uid,
            :area_rid => target_area.rid
          }) if target_area
            
          ###
          logger.info ">>> 确定读取范围 <<<"
          @job_tracker.update(process: 3/@phase_total.to_f)

          @total_row = @result_sheet.count
          @total_cols = @hidden_row.size

          ###
          logger.info ">>> 老师及学生sheet初始化 <<<"
          @job_tracker.update(process: 4/@phase_total.to_f)

          out_excel = Axlsx::Package.new
          wb = out_excel.workbook
          
          @head_teacher_sheet = wb.add_worksheet(:name => Common::Locale::i18n('scores.excel.head_teacher_password_title'))
          @teacher_sheet = wb.add_worksheet(:name => Common::Locale::i18n('scores.excel.teacher_password_title'))
          @pupil_sheet = wb.add_worksheet(:name => Common::Locale::i18n('scores.excel.pupil_password_title'))

          @head_teacher_sheet.sheet_protection.password = Common::SwtkConstants::DefaultSheetPassword
          @teacher_sheet.sheet_protection.password = Common::SwtkConstants::DefaultSheetPassword
          @pupil_sheet.sheet_protection.password = Common::SwtkConstants::DefaultSheetPassword

          @head_teacher_sheet.add_row [
              Common::Locale::i18n('activerecord.attributes.user.name'),
              Common::Locale::i18n('activerecord.attributes.user.password'),
              Common::Locale::i18n('dict.classroom'),
              Common::Locale::i18n('dict.name'),
              Common::Locale::i18n('reports.generic_url'),
              Common::Locale::i18n('reports.op_guide')
          ]

          @teacher_sheet.add_row [
              Common::Locale::i18n('activerecord.attributes.user.name'),
              Common::Locale::i18n('activerecord.attributes.user.password'),
              Common::Locale::i18n('dict.classroom'),
              Common::Locale::i18n('dict.subject'),
              Common::Locale::i18n('dict.name'),
              Common::Locale::i18n('reports.generic_url'),
              Common::Locale::i18n('reports.op_guide')
          ]

          @pupil_sheet.add_row [
              Common::Locale::i18n('activerecord.attributes.user.name'),
              Common::Locale::i18n('activerecord.attributes.user.password'),
              Common::Locale::i18n('dict.classroom'),
              Common::Locale::i18n('dict.name'),
              Common::Locale::i18n('dict.pupil_number'),
              Common::Locale::i18n('reports.generic_url'),
              Common::Locale::i18n('reports.op_guide')
          ]

          ###
          logger.info ">>> 读取表格数据 <<<"
          @job_tracker.update(process: 5/@phase_total.to_f)

          #上传成绩多线程处理
          logger.info ">>>多线程读取<<<"
          
          th_number = Common::Score::Thread::ThNum
          num_per_th = @total_row/Common::Score::Thread::ThNum
          mod_num = @total_row%num_per_th
          logger.info "线程数量: #{th_number}, 行数: #{@total_row}"

          th_arr = []
          th_number.times.each{|th|
            start_num = th*num_per_th
            end_num = (th+1)*num_per_th + (((th + 1) == th_number)? mod_num : 0) #为保证读取到最后一行，最后一组不减一
            end_num -=1 if (th+1) != th_number
            #th_arr << Thread.new do
              import_score_core({
                :th_index => th,
                :start_num => start_num,
                :end_num => end_num,
              })
            #end
          }
          #ThreadsWait.all_waits(*th_arr)

          # create user password file
          file_path = Rails.root.to_s + "/tmp/#{@target_paper_id}_#{params[:score_file_id]}_password.xlsx"
          out_excel.serialize(file_path)
          file_h = {:score_file_id => params[:score_file_id], :file_path => file_path}
          score_file = Common::Score.create_usr_pwd file_h

          @job_tracker.update(process: 1.0)
          @target_test.update_test_tenants_status([params[:tenant_uid]], Common::Test::Status::ScoreImported, {:job_uid => params[:job_uid]})
          # temp.update({ :tenant_status => Common::Test::Status::ScoreImported })
          File.delete(file_path)
          #多JOB并存的时候试卷状态判断，在取试卷的时候
          #target_paper.update(:paper_status =>  Common::Paper::Status::ScoreImported)
        rescue Exception => ex
          logger.info ">>>Excepion<<<"
          logger.info "[message]"
          logger.info ex.message
          logger.info "[backtrace]"
          logger.info ex.backtrace
        ensure
          logger.info("redis 计数值: #{Common::SwtkRedis::get_value(@redis_ns,@redis_key)}")
          Common::SwtkRedis::del_keys(@redis_ns, @redis_key)
          #compare = nil
          #GC.start
          logger.info ">>>>>>>Import Result Job: End<<<<<<<"
        end
      end # fork new process, end
    }
  end

  def import_score_core args={}
      logger.info ">>>thread index #{args[:th_index]}: [from, to]=>[#{args[:start_num]},#{args[:end_num]}] <<<"
      #p "线程（#{args[:target_tenant]}）：>>>thread index #{args[:th_index]}: [from, to]=>[#{args[:start_num]},#{args[:end_num]}] <<<"
      begin
        #主线程读取用户信息
        teacher_username_in_sheet = []
        pupil_username_in_sheet = []
        # qzps_h = []
        # @hidden_row[@cols[:data_start]..(@total_cols-1)].each{|item|
        #   qzps_h << Mongodb::BankQizpointQzp.where(_id: item).first
        # }

        #######start to analyze#######
        location_list = {}   
        (args[:start_num]..args[:end_num]).each{|index|
          next if index < @rows[:data_start]
          row_qzps_arr = []
          row = @result_sheet.row(index)
          grade_pinyin = Common::Locale.hanzi2pinyin(row[@cols[:grade]].to_s.strip)
          klass_pinyin = Common::Locale.hanzi2pinyin(row[@cols[:classroom]].to_s.strip)
          klass_value = Common::Klass::List.keys.include?(klass_pinyin.to_sym) ? klass_pinyin : row[@cols[:classroom]].to_s.strip
          
          cells = {
            :grade => grade_pinyin,
            :xue_duan => Common::Grade.judge_xue_duan(grade_pinyin),
            :classroom => klass_value,
            :head_teacher => row[@cols[:head_teacher_name]].to_s.strip,
            :head_teacher_number => row[@cols[:head_teacher_number]].to_s.strip,
            :teacher => row[@cols[:subject_teacher_name]].to_s.strip,
            :teacher_number => row[@cols[:subject_teacher_number]].to_s.strip,
            :pupil_name => row[@cols[:pupil_name]].to_s.strip,
            :stu_number => row[@cols[:pupil_number]].to_s.strip,
            :sex => row[@cols[:pupil_gender]].to_s.strip
          }

          #
          # get location
          #
          @loc_h[:grade] = cells[:grade]
          @loc_h[:classroom] = cells[:classroom]
          loc_key = @target_tenant_uid + cells[:grade] + cells[:classroom]
          if location_list.keys.include?(loc_key)
            loc = location_list[loc_key]
          else
            loc = Location.new(@loc_h)
            loc.save!
            location_list[loc_key] = loc
          end
          raise SwtkErrors::NotFoundError.new(I18.t("swtk_errors.object_not_found", :message => "location, loc_h:#{@loc_h}")) unless loc
          user_row_arr = []
          # 
          # create teacher user 
          #
          head_tea_h = {
            :loc_uid => loc.uid,
            :tenant_uid => @target_tenant.uid,
            :name => cells[:head_teacher],
            :classroom => cells[:classroom],
            # :subject => @target_paper.subject,
            :head_teacher => true,
            :user_name =>format_user_name([
              @target_tenant.number,
              #Common::Subject::Abbrev[@target_paper.subject.to_sym],
              cells[:head_teacher_number],
              Common::Locale.hanzi2abbrev(cells[:head_teacher])
            ])
          }
          user_row_arr = format_user_password_row(Common::Role::Teacher, head_tea_h)
          unless teacher_username_in_sheet.include?(user_row_arr[0])
            @head_teacher_sheet.add_row user_row_arr
            teacher_username_in_sheet << user_row_arr[0]
          end
          
          tea_h = {
            :loc_uid => loc.uid,
            :tenant_uid => @target_tenant.uid,
            :name => cells[:teacher],
            :classroom => cells[:classroom],
            :subject => @target_paper.subject,
            :head_teacher => false,
            :user_name => format_user_name([
              @target_tenant.number,
              #Common::Subject::Abbrev[@target_paper.subject.to_sym],
              cells[:teacher_number],
              Common::Locale.hanzi2abbrev(cells[:teacher])
            ])
          }
          user_row_arr = format_user_password_row(Common::Role::Teacher, tea_h)
          unless teacher_username_in_sheet.include?(user_row_arr[0])
            @teacher_sheet.add_row user_row_arr
            teacher_username_in_sheet << user_row_arr[0]
          end

          #
          # create pupil user
          #
          pup_h = {
            :loc_uid => loc.uid,
            :tenant_uid => @target_tenant_uid,
            :name => cells[:pupil_name],
            :stu_number => cells[:stu_number],
            :grade => cells[:grade],
            :classroom => cells[:classroom],
            :subject => @target_paper.subject,
            :sex => Common::Locale.hanzi2pinyin(cells[:sex]),
            :user_name => format_user_name([
              @target_tenant.number,
              cells[:stu_number],
              Common::Locale.hanzi2abbrev(cells[:pupil_name])
            ])
          }
          user_row_arr = format_user_password_row(Common::Role::Pupil, pup_h)
          unless pupil_username_in_sheet.include?(user_row_arr[0])
            @pupil_sheet.add_row user_row_arr
            pupil_username_in_sheet << user_row_arr[0]
          end

          current_user = User.where(name: pup_h[:user_name]).first
          current_pupil = current_user.nil?? nil : current_user.pupil

          #logger.info ">>>thread index #{args[:th_index]} cols range: #{@cols[:data_start]},#{@total_cols} <<<"
          # p "线程（#{args[:target_tenant]}）：>>>thread index #{args[:th_index]}: row:#{index},  cols range: #{@cols[:data_start]},#{@total_cols} <<<"

          col_params = {
            :area_uid => @loc_h[:area_uid],
            :area_rid => @loc_h[:area_rid],
            :tenant_uid => @loc_h[:tenant_uid],
            :loc_uid => loc.uid,
            :test_id => @target_test.id.to_s,
            :pup_uid => current_pupil.nil?? "":current_pupil.uid,
            :pap_uid => @target_paper_id
          }

          (@cols[:data_start]..(@total_cols-1)).each{|qzp_index|
            next if ( !row[qzp_index].is_a?(Numeric) || row[qzp_index] < 0 )

            col_params.merge!({
              :qzp_uid => @hidden_row[qzp_index],
              :order => @order_row[qzp_index],
              :real_score => row[qzp_index],
              :full_score => @title_row[qzp_index]
            })

            #qizpoint = qzps_h[qzp_index - @cols[:data_start]]
            qzp_outline_h = @qzps_outlines_mapping_h[@hidden_row[qzp_index]]
            qzp_ckp_h = @qzps_ckps_mapping_h[@hidden_row[qzp_index]]
            qzp_ckp_h.each{|dimesion, ckps|
              col_params[:dimesion] = dimesion
              ckps.each{|ckp|
                col_params[:ckp_uids] = ckp.keys[0]
                col_params[:ckp_order] = ckp.values[0]["rid"]
                col_params[:ckp_weights] = ckp.values[0]["weights"]
                col_params[:outline_ids] = qzp_outline_h.blank?? "" : qzp_outline_h["ids"]
                col_params[:outline_order] = qzp_outline_h.blank?? "" : qzp_outline_h["rids"]
                row_qzps_arr << col_params.clone
              }
            }

          }

          #Mongodb::BankTestScore.create!(row_qzps_arr)
          Mongodb::BankTestScore.collection.insert_many(row_qzps_arr)

          Common::SwtkRedis::incr_key(@redis_ns, @redis_key)
          # p "线程（#{args[:target_tenant]}）：>>>thread index #{args[:th_index]}: redis count=>#{Common::SwtkRedis::get_value(@redis_key)}"
          redis_count = Common::SwtkRedis::get_value(@redis_ns, @redis_key).to_f
          process_value = 5 + 9*redis_count/(@total_row-@rows[:data_start]).to_f
          #p "线程（#{args[:target_tenant]}）：>>>thread index #{args[:th_index]}: process_value => #{process_value}"
          @job_tracker.update(process: process_value/@phase_total.to_f)
        }
      rescue Exception => ex
        logger.info ">>>thread index #{args[:th_index]}: Exception Message (#{ex.message})<<<"
        logger.info ">>>thread index #{args[:th_index]}: Exception Message (#{ex.backtrace})<<<"
      ensure
        logger.info ">>>thread index #{args[:th_index]}: end<<<"
      end
  end
  #end

  #######私有方法#######
  private
    # 组装用户名
    def format_user_name args=[]
      'u' + args.join(Common::Uzer::UserNameSperator)
    end

    # 组装用户名密码行数据
    def format_user_password_row role, item
      row_data = {
        Common::Role::Teacher.to_sym => {
          :username => item[:user_name],
          :password => "",
          :classroom => Common::Klass::List[item[:classroom].to_sym],
          # :subject => Common::Subject::List[item[:subject].to_sym],
          :name => item[:name],
          :report_url => "",
          :op_guide => Common::Locale::i18n('reports.op_guide_details'),
          :tenant_uid => item[:tenant_uid]
        },
        Common::Role::Pupil.to_sym => {
          :username => item[:user_name],
          :password => "",
          :classroom => Common::Klass::List[item[:classroom].to_sym],
          :name => item[:name],
          :stu_number => item[:stu_number],
          :report_url => "",#Common::SwtkConstants::MyDomain + "/reports/new_square?username=",
          :op_guide => Common::Locale::i18n('reports.op_guide_details'),
          :tenant_uid => item[:tenant_uid]
        }
      }
      row_data[Common::Role::Teacher.to_sym][:subject] = Common::Subject::List[item[:subject].to_sym] if item[:subject]

      ret, flag = User.add_user item[:user_name],role, item

      target_username = ""
      if (ret.is_a? Array) && ret.empty?
        row_data[role.to_sym][:password] = Common::Locale::i18n("scores.messages.info.old_user")
        row_data[role.to_sym][:report_url] = generate_url
        target_username = ret[0]
      elsif (ret.is_a? Array) && !ret.empty?
        row_data[role.to_sym][:password] = ret[1]
        row_data[role.to_sym][:report_url] = generate_url
        target_username = ret[0]
      else
        row_data[role.to_sym][:password] = Common::Locale::i18n("scores.messages.error.add_user_failed")
      end
      
      associate_user_and_pap role, target_username if (ret.is_a? Array)
      return row_data[role.to_sym].values
    end

    # 生成URL
    def generate_url
      return Common::SwtkConstants::MyDomain 
    end

    # 关联用户与试卷
    def associate_user_and_pap role, username
      target_user = User.where(name: username).first
      return false unless target_user
      case role
      when "pupil"
        target_pupil = target_user.pupil
        return false unless target_pupil
        pup_uid = target_pupil.uid
        bpp = Mongodb::BankPupPap.new
        bpp.save_pup_pap pup_uid, @target_paper_id
      when "teacher"
        target_teacher = target_user.teacher
        return false unless target_teacher
        tea_uid = target_teacher.uid
        btp = Mongodb::BankTeaPap.new
        btp.save_tea_pap tea_uid, @target_paper_id
      end
      return true
    end
end
