# -*- coding: UTF-8 -*-

require 'ox'
require 'roo'
require 'axlsx'
require 'find'

namespace :swtk_patch do
  namespace :v1_2 do

    desc "get wechat openid excel"
    task get_wechat_openid_excel: :environment do      
      Axlsx::Package.new do |p|
        p.workbook.add_worksheet(:name => "获取微信信息") do |sheet|
          sheet.add_row(["openid"])
          WxUser.pluck(:wx_openid).each {|wx_openid|            
            sheet.add_row([wx_openid])
          }
        end
        p.serialize("./wx_openid_list.xlsx")
      end    
    end

    desc "update unionid with openid"
    task :update_unionid_with_openid, [:file_path] => :environment do
      if args[:file_path].nil?
        puts "Command format not correct, Usage: #rake swtk_patch:v1_2:update_unionid_with_openid[file_path]"
        exit 
      end
      wx_xlsx = Roo::Excelx.new(args[:file_path])
      wx_unionid_arr = []
      wx_xlsx.sheet(0).each_with_index do |row, index|
        if index < 1
        else
          wx = WxUser.where(wx_openid: row[0]).first
          if wx && wx_unionid_arr.include?(row[1])
            master_wx = WxUser.where(wx_unionid: row[1]).first
            master_wx.migrate_other_wx_user_binded_user(wx)
            wx.destroy if wx
          else
            wx.update(wx_openid: row[0], wx_unionid: row[1])
            wx_unionid_arr << row[1]
          end 
        end
      end
    end

    desc "update wx_user is_master merge users"
    task update_wx_user_is_master: :environment do
      puts "开始迁移身份用户"
      WxUser.all.each do |wx|
        master_user = nil
        master_user = wx.users.by_master(true).first if wx.users
        unless master_user
          wx.default_user!
          master_user = wx.users.by_master(true).first if wx.users
        end
        slave_user = wx.users.by_master(false)
        slave_user.each do |slave|
          unless master_user.children.include?(slave)
            master_user.children.push(slave)
          end
          wx.users.delete(slave)
        end
        puts "#{wx.wx_openid}已迁移"
      end
      puts "迁移完成"
    end

    desc "update all project optional optional-abstract"
    task :update_all_tests_project_optional, [] => :environment do |t, args|
      puts "开始刷新"
      BasePath = ""
      ReportWarehousePath = BasePath + "/reports_warehouse/tests/"
      # redis_key_prefix = "/" + Time.now.to_i.to_s
      _nav_re = /.*project\/(.*)\/nav.json$/
      _test_ids = args.extras
      _test_ids = Mongodb::BankTest.all.only(:id).map{|item| item.id.to_s} if _test_ids.blank?
      _test_ids.each{|_id|
        # target_test =Mongodb::BankTest.where(id: _id).first
        nav_arr = Dir[ReportWarehousePath + _id + "/project/*/nav.json"]
        puts "#{_id}, nav_url: #{nav_arr}"
        next if nav_arr.blank?
        nav_file = nav_arr.first
        _project_id = _nav_re.match(nav_file)[1]
        next unless _project_id
        file_data = File.open(nav_file, 'rb').read
        next if file_data.blank?
        nav_h = JSON.parse(file_data)
        next if nav_h.values.blank?
        optional_h = nav_h.deep_dup
        optional_abstract_h = nav_h.deep_dup
        nav_h.values[0].each_with_index{|_item, _index|
          _target_report_url = _item[1]["report_url"].split("?")[0]
          next unless File.exists?(BasePath + _target_report_url)
          _report_data = File.open(BasePath + _target_report_url, 'rb').read
          next if _report_data.blank?
          _report_h = JSON.parse(_report_data)
          next if _report_h.blank?
          optional_h.values[0][_index][1]["report_data"] = _report_h
          optional_abstract_h.values[0][_index][1]["report_data"] = {"basic" => _report_h["basic"], "data" => _report_h["data"]["knowledge"]["base"]}
        }
        File.write( ReportWarehousePath + _id + "/project/" + _project_id + "_optional.json", optional_h.to_json)
        File.write( ReportWarehousePath + _id + "/project/" + _project_id + "_optional_abstract.json", optional_abstract_h.to_json)
        puts nav_file + ", done"
        # nav_arr.each{|nav_path|
        #   target_nav_h = get_report_hash(nav_path)
        #   target_nav_count = target_nav_h.values[0].size
        #   target_path = nav_path.split("/nav.json")[0]
        #   target_path_arr = target_path.split("/")
        #   current_group = (Common::Report::Group::ListArr&target_path_arr)[-1]
        #   sub_group = (Common::Report::Group::ListArr - target_path_arr)[-1]
        #   next unless sub_group
        #   while target_path_arr.include?(target_test.report_top_group)
        #     target_key = redis_key_prefix + "/" + target_path_arr.join("/")
        #     reset_redis_value(target_key, sub_group, target_nav_count)
        #     target_path_arr.pop(2)
        #   end
        # }
      }
      # rpt_stat_redis_keys = Common::SwtkRedis::find_keys($cache_redis, redis_key_prefix + "/*")
      # rpt_stat_redis_keys.each{|key|
      #   target_path = key + "/report_stat.json"
      #   p target_path
      #   File.write(target_path.split(redis_key_prefix)[1], $cache_redis.get(key))
      #   $cache_redis.del(key)
      # }   
      puts "刷新完成"
    end 

    desc "Use Openid or Unionid rollback"
    task :rollback_wx_with_args, [:wx_openid, :wx_unionid] => :environment do
      wx_users = WxUser.where("wx_unionid = ? or wx_openid = ?", args[:wx_unionid], args[:wx_openid])
      wx_users.each do |wx|
        if wx.master
          wx.master.delete
        end
      end
    end

    desc "rollback wx user with time"
    task :rollback_wx_with_time, [:rollback_time] => :environment do
      if args[:rollback_time].nil?
        puts "Need rollback_time, Usage: #rake swtk_patch:v1_2:rollback_wx_with_time[rollback_time]"
        exit 
      end      
      roll_time = Time.parse(args[:rollback_time])
      wx_users = WxUser.where("dt_update > ?", roll_time )
      wx_users.each do |wx|
        if wx.master
          wx.master.delete
        end
      end
    end

    desc "migrate paper pupil teacher to bank_test"
    task migrate_paper_pupil_teacher_to_bank_test: :environment do
      Mongodb::BankPupPap.all.each do |pup_pap|
        paper = pup_pap.bank_paper_pap
        bank_test = paper.bank_tests[0] if paper
        user = pup_pap.pupil.user if pup_pap.pupil
        if bank_test.present? && user.present?
          test_name = paper.heading.to_s + "_测试"
          bank_test.update(test_status: "report_completed",name: test_name)
          bank_test_user = Mongodb::BankTestUserLink.where(bank_test_id: bank_test._id.to_s, user_id: user.id).first
          unless bank_test_user.present?            
            bank_test_user = Mongodb::BankTestUserLink.new(bank_test_id: bank_test._id.to_s, user_id: user.id)
          end
          bank_test_user.save!
        end
      end
      Mongodb::BankTeaPap.all.each do |tea_pap|
        paper = pup_pap.bank_paper_pap
        bank_test = paper.bank_tests[0] if paper
        user = tea_pap.teacher.user if tea_pap.teacher
        if bank_test.present? && user.present?
          test_name = paper.heading.to_s + "_测试"
          bank_test.update(test_status: "report_completed",name: test_name)
          bank_test_user = Mongodb::BankTestUserLink.where(bank_test_id: bank_test._id.to_s, user_id: user.id).first
          unless bank_test_user.present?            
            bank_test_user = Mongodb::BankTestUserLink.new(bank_test_id: bank_test._id.to_s, user_id: user.id)
          end
          bank_test_user.save!
        end
      end
    end

    desc "晋安数学临时命令"
    task add_jinan201711_to_jinan: :environment do
      paper_uids = ["5a0d2379fa3318763fe45678","5a0d51dbfa3318763ce4591b", "5a0d68a6fa33183f5be4549d", "5a0d5c0ffa3318734de45474"]
      tag = Mongodb::BankTag.where(content: "jinan2017").first
      unless tag.present?
        tag = Mongodb::BankTag.new(content: "jinan2017").save
      end
      tag_uid = tag._id.to_s
      paper_uids.each do |puid|
        paper = Mongodb::BankPaperPap.where(_id: puid).first
        p paper
        if paper.present?
          bank_quiz_qizs = paper.bank_quiz_qizs
          if bank_quiz_qizs.present?
            bank_quiz_qizs.each {|quiz|
              quiz.bank_quiz_tag_links.new(tag_uid: tag_uid).save 
            }
          end
        end
      end
    end
  end

  namespace :v1_2_1 do
    desc "match grade and subject to bank_quiz_qiz"
    task :match_grade_subject => :environment do
      Mongodb::BankQuizQiz.each_with_index do |quiz,index|
        p index
        paper = quiz.bank_paper_paps[0]
        if paper.present?
          if paper.grade.present?
            quiz.grade = paper.grade
            quiz.subject = paper.subject
          end
        elsif quiz.node_uid.present?
          node = BankNodestructure.where(uid: quiz.node_uid).first
          if node
            quiz.grade = node.grade
            quiz.subject = node.subject
          end
        else 
          quiz.grade = nil
          quiz.subject = nil
        end
        quiz.save!
      end
    end

    desc "import permission definition into mysql"
    task :inport_permission_diffnition, [:file_path] => :environment do |t,args|

      xlsx = Roo::Excelx.new(args[:file_path])
      # permissions = Permission.all.delete_all
      # (3..xlsx.sheet("permissions").last_row).each do |i|     
      #   row = xlsx.sheet("permissions").row(i)
      #   Permission.new(name: row[1], subject_class: row[2],operation: row[3], description: row[4]).save!
      # end
      api_permissions = ApiPermission.all.delete_all
      (2..xlsx.sheet("api_permissions").last_row).each do |j|
        row = xlsx.sheet("api_permissions").row(j)
        ApiPermission.new(name: row[0], method: row[1], path: row[2], description: row[3]).save!
      end
    end

    desc "set tag to all quiz with test paper"
    task :set_tag_to_all_quiz_with_test_paper, [:test_uid] => :environment do |t,args|
      p args
      if args[:test_uid].nil?
        puts "Need set_tag_to_all_quiz_with_test_paper, Usage: #rake swtk_patch:v1_2_1:set_tag_to_all_quiz_with_test_paper[test_uid]"
        exit
      end
      bank_test = Mongodb::BankTest.where(_id: args[:test_uid]).first
      paper = bank_test.bank_paper_pap
      bank_quiz_qizs = paper.bank_quiz_qizs
      tag_uids = []
      ["111","222","333"].each do |str|
        tag = Mongodb::BankTag.new(content: str)
        tag.save
        tag_uids << tag._id.to_s
      end
      bank_quiz_qizs.each {|quiz|
        tag_uids.each { |t|
          quiz.bank_quiz_tag_links.new(tag_uid: t).save 
        }
      }
    end


  end
end