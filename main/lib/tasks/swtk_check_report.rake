# -*- coding: UTF-8 -*-

require 'ox'
require 'roo'
require 'axlsx'
require 'find'
require 'bigdecimal'
require 'bigdecimal/util'
namespace :check_report do
  namespace :v1_2 do


    def check_report_method bank_test, su_arr, *args
      su_arr.each do |su|
        stu_name_index = args[0].to_i
        stu_num_index = args[1].to_i
        begin_data_index = args[2].to_i      
        bank_qizpoint_qzps = []
        # p su.tenant_uid
        # p su.filled_file.current_path

        target_tenant = Tenant.where(uid: su.tenant_uid).first
        base_path = Rails.root.to_s + '/public'
        file_path = base_path + su.filled_file.current_path
        user_info_xlsx = Roo::Excelx.new(file_path)
        out_excel = Axlsx::Package.new
        base_file_sheet = out_excel.workbook.add_worksheet(:name => "出错人员")

        user_info_xlsx.sheet(5).each_with_index do |row, index|
          if index < 1 || (index > 1 && index < 4)
            next
          elsif index == 1
            bank_qizpoint_qzps = row[begin_data_index..-1]
          else
            user_name = [
              target_tenant.number,
              #Common::Subject::Abbrev[@target_paper.subject.to_sym],
              row[stu_num_index],
              Common::Locale.hanzi2abbrev(row[stu_name_index])
            ].join("")
            user = User.where("name LIKE :u_name", {u_name: "%#{user_name}%"}).first
            if user.present?
              _rpt_type, _rpt_id = Common::Uzer::get_user_report_type_and_id_by_role(user)
              rpt_type = _rpt_type || Common::Report::Group::Project
              rpt_id = (_rpt_type == Common::Report::Group::Project)? bank_test._id.to_s : _rpt_id
              report_url = Common::Report::get_test_report_url(bank_test._id.to_s, rpt_type, rpt_id)
              # p report_url
              # p bank_qizpoint_qzps
              base_path = "/Users/shuai/workspace/tk_main/main"
              # base_path = ""                 
              report_path = base_path + report_url
              target_report_f = Dir[report_path].first
              if target_report_f.present?
                target_report_data = File.open(target_report_f, 'rb').read
                if target_report_data.present?
                  report_data = JSON.parse(target_report_data)
                  pap_qzp_data = report_data["paper_qzps"]

                  if pap_qzp_data.present?
                    pap_qzp_data.each { |qzp_obj|
                      qzp_id = qzp_obj["qzp_id"]
                      stu_score = row[begin_data_index..-1]
                      qzp_index = bank_qizpoint_qzps.index(qzp_id)
                      if qzp_obj["value"].present? && qzp_obj["value"]["total_real_score"].present?
                        if qzp_obj["value"]["total_real_score"].to_d != stu_score[qzp_index].to_d
                          base_file_sheet.add_row(row + ["学生成绩有误: 得分点uid#{qzp_id},报告分数: #{qzp_obj["total_real_score"]},成绩表分数:#{stu_score[qzp_index].to_d}"])
                          break
                        else
                          next
                        end
                      else
                        base_file_sheet.add_row(row + ["报告内容缺失: 得分点uid#{qzp_id},得分点顺序#{qzp_obj["qzp_order"]}"])
                        break
                      end
                    }
                  else
                    base_file_sheet.add_row(row + ["报告内容不存在"])
                  end
                else
                  base_file_sheet.add_row(row + ["未找到报告"])
                end
              else
                base_file_sheet.add_row(row + ["未找到报告"])
              end
            else
              base_file_sheet.add_row(row + ["用户不存在"])
            end
          end
        end
        out_file_name = target_tenant.name_cn
        out_excel.serialize('./tmp/' + out_file_name + '_error.xlsx')
      end
    end

    desc "check report data"
    task :check_report_data, [:test_uid,:stu_name_index,:stu_num_index,:begin_data_index] => :environment do |t,args|
      t1 = Time.new
      if args[:test_uid].nil? || args[:stu_name_index].nil? || args[:stu_num_index].nil? || args[:begin_data_index].nil? 
        puts "Need test_uid,stu_name_index,stu_num_index,begin_data_index Usage: #rake swtk_patch:v1_2:check_report_data[test_uid,stu_name_index,stu_num_index,begin_data_index]"
        exit 
      end      
      bank_test = Mongodb::BankTest.where(_id: args[:test_uid]).first
      exit unless bank_test.present?
      stu_name_index = args[:stu_name_index].to_i
      stu_num_index = args[:stu_num_index].to_i
      begin_data_index = args[:begin_data_index].to_i

      tenant_uid_arr = bank_test.score_uploads.to_a

      th_number = 2
      num_per_th = tenant_uid_arr.size/th_number

      p "线程数量: #{th_number}, 每个最大数量: #{num_per_th+1}"
      threads = []
      th_number.times do |th|
        start_num = th*(num_per_th + 1)
        end_num = (th+1)*(num_per_th + 1) - 1
        end_num =  -1 if((th + 1) == th_number)#为保证读取到最后一行，最后一组不减一
        new_su = tenant_uid_arr[start_num..end_num]
        p new_su
        threads << Thread.new do
          check_report_method(bank_test, new_su, stu_name_index, stu_num_index, begin_data_index)
        end
      end
      threads.each {|thr| thr.join}
      t2 = Time.new
      p t2 - t1
      # bank_test.score_uploads.each do |su|
      #   check_report_method bank_test, su, stu_name_index, stu_num_index, begin_data_index
      # end
    end
  end
end