# -*- coding: UTF-8 -*-

require 'ox'
require 'roo'
require 'axlsx'
require 'bigdecimal'
require 'bigdecimal/util'
require 'fileutils'


namespace :swtk do
  namespace :report do
  	#namespace :v1_2 do
      desc "统计系统报告数量"
      task update_all_report_state: :environment do
        target_test = Mongodb::BankTest.all
        target_test.each do |test|
          p test._id
          test.get_report_state
        end
        report = Mongodb::Dashbord.where(total_tp: "report").first
        report = Mongodb::Dashbord.initialize_report if report.blank?
        report.update_report_overall_stat
      end

      desc "输出区域报告用数据表"
      task :export_test_overall_report_data_table,[] => :environment do |t, args|
        ReportWarehousePath = "/reports_warehouse/tests/"
        _test_ids = args.extras
        _test_count = _test_ids.size
        _test_arr = _test_ids.map{|test_id|
          target_test = Mongodb::BankTest.find(test_id)
          target_paper = target_test.bank_paper_pap
          tenant_nav_file = Dir[ReportWarehousePath + test_id + '/**/project/' + test_id + "/nav.json"].first.to_s
          fdata = File.open(tenant_nav_file, 'rb').read
          nav_h =JSON.parse(fdata)
          fdata = File.open(ReportWarehousePath + test_id + "/ckps_qzps_mapping.json", 'rb').read
          ckps_json =JSON.parse(fdata)
          ckps_data = ckps_json.values[0]
          {
            :id => test_id,
            :pap_heading => target_paper.heading,
            :subject => Common::Subject::List[target_paper.subject.to_sym],
            :ckps => ckps_data,
            :tenants => nav_h.values[0]
          }
        }
        _data_types = [
          {
            :label => "平均得分率",
            :key => "weights_score_average_percent"
          },
          {
            :label => "中位数得分率",
            :key => "_median_percent"
          },
          {
            :label => "分化度",
            :key => "diff_degree"
          }
        ]

        #写入excel
        out_excel = Axlsx::Package.new
        wb = out_excel.workbook
        
        ####### 标题行，指标列, begin #######
        cell_style = {
          :knowledge => wb.styles.add_style(:bg_color => "FF00F7", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
          :skill => wb.styles.add_style(:bg_color => "FFCB1C", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
          :ability => wb.styles.add_style(:bg_color => "00BCFF", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
          :total => wb.styles.add_style(:bg_color => "5DC402", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
          :label => wb.styles.add_style(:bg_color => "CBCBCB", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 14, :alignment => { :horizontal=> :center }),
          :percentile => wb.styles.add_style(:bg_color => "E6FF00", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center })
        }

        _test_arr.each{|target_test|
          _data_types.each{|data_type|
            sheet_name = target_test[:id] + "_" + target_test[:subject] + "_" + data_type[:label]
            sheet_name = sheet_name[(sheet_name.size - 30)..(sheet_name.size - 1)]
            wb.add_worksheet name: sheet_name do |sheet|
              ####### 制表头, begin #######
              #标题行
              title_row2_info = [
                "类别",
                "名称",
                "班级数",
                "学生数"
              ]
              style_row2_info = title_row2_info.size.times.map{|t| cell_style[:label] }

              #标题行
              title_row2_info_length = title_row2_info.size - 1
              title_row1_info = [target_test[:pap_heading]] + title_row2_info_length.times.map{|t| ""}
              style_row1_info = title_row2_info.size.times.map{|t| cell_style[:label] }

              #标题1行
              title_row1_lv1 = []
              title_row1_total = ["总得分率","",""]           
              style_row1_lv1 = []
              style_row1_total = []
              
              #标题2行
              title_row2_lv1 = []
              title_row2_total = []
              style_row2_lv1 = []
              style_row2_total = []

              target_test[:ckps].each{|k0,v0| #三维
                dim_label = I18n.t("dict.#{k0}")
                dim_lv1_data = v0["lv_n"].map{|lv1| lv1.values[0]}.flatten
                title_row1_lv1.push(dim_label + "一级得分率")
                dim_lv1_data.each_with_index{|item, index| #一级指标
                  title_row1_lv1.push("") if index > 0
                  title_row2_lv1.push(item["checkpoint"])
                  style_row1_lv1 << cell_style[k0.to_sym]
                  style_row2_lv1 << cell_style[k0.to_sym]
                }

               
                title_row2_total << dim_label
                style_row1_total << cell_style[:total]
                style_row2_total << cell_style[:total]
              }
              # 表头第1行
              sheet.add_row(
                  title_row1_info + title_row1_lv1  + title_row1_total,
                  :style => style_row1_info + style_row1_lv1 + style_row1_total 
              )
              # 表头第2行
              sheet.add_row(
                  title_row2_info + title_row2_lv1 + title_row2_total,
                  :style => style_row2_info + style_row2_lv1 + style_row2_total
              )
              ####### 制表头, end #######

              ####### 输出数据, begin #######

              # 测试整体数据
              target_test_report_file = Dir[ReportWarehousePath + target_test[:id] + "/project/" + target_test[:id] + ".json"].first.to_s
              rpt_h = get_report_hash(target_test_report_file)

              data_row_info = [
                "区域整体",
                target_test[:pap_heading],
                "-",
                rpt_h["data"]["knowledge"]["base"]["pupil_number"]
              ]

              target_value_key = data_type[:key].include?("_median_percent") ? "project_median_percent" : data_type[:key]
              overall_data_row = get_report_data_row(rpt_h["data"], target_value_key)
              sheet.add_row data_row_info + overall_data_row

              # 各学校数据
              target_test[:tenants].each{|tnt|
                target_test_report_file = Dir[ReportWarehousePath + target_test[:id] + '/**/grade/' + tnt[1]["uid"] + ".json"].first.to_s
                rpt_h = get_report_hash(target_test_report_file)
                tenant_nav_file = Dir[ReportWarehousePath + target_test[:id] + '/**/grade/' + tnt[1]["uid"] + "/nav.json"].first.to_s
                nav_h = get_report_hash(tenant_nav_file)

                data_row_info = [
                  "学校",
                  tnt[1]["label"],
                  nav_h.values[0].size,
                  rpt_h["data"]["knowledge"]["base"]["pupil_number"]
                ]

                target_value_key = data_type[:key].include?("_median_percent") ? "grade_median_percent" : data_type[:key]
                overall_data_row = get_report_data_row(rpt_h["data"], target_value_key)
                sheet.add_row data_row_info + overall_data_row
              }
              ####### 输出数据， end ########
            end #测试总览
          }
        }

        file_path = Rails.root.to_s + "/tmp/" + Time.now.to_i.to_s + ".xlsx"
        out_excel.serialize(file_path)        
        puts "Output: " + file_path 
      end # export_test_area_report_tenants_basic, end

      desc "输出测试大榜信息"
      task :export_test_pupil_data_table,[] => :environment do |t, args|
        ReportBasePath = "" #Rails.root.to_s
        ReportWarehousePath = "/reports_warehouse/tests/"
        _test_ids = args.extras
        _test_count = _test_ids.size
        _test_arr = _test_ids.map{|test_id|
          target_test = Mongodb::BankTest.find(test_id)
          target_paper = target_test.bank_paper_pap
          target_pupil_urls = find_all_pupil_report_urls(ReportBasePath, ReportWarehousePath + test_id, [])
          re = Regexp.new ".*pupil/(.*).json"
          target_pupil_uids = target_pupil_urls.map{|url| 
            r = re.match(url) 
            r.blank? ? nil : r[1].to_s
          }.compact

          {
            :id => test_id,
            :pap_heading => target_paper.heading,
            :subject => Common::Subject::List[target_paper.subject.to_sym],
            :pupil_report_urls => target_pupil_urls,
            :pupil_uids => target_pupil_uids
          }
        }
        _all_pupil_urls = eval(_test_arr.map{|item| "#{item[:pupil_report_urls]}" }.join("|"))
        _all_pupil_uids = eval(_test_arr.map{|item| "#{item[:pupil_uids]}" }.join("|"))


        #写入excel
        out_excel = Axlsx::Package.new
        wb = out_excel.workbook
        
        ####### 标题行，指标列, begin #######
        cell_style = {
          :knowledge => wb.styles.add_style(:bg_color => "FF00F7", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
          :skill => wb.styles.add_style(:bg_color => "FFCB1C", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
          :ability => wb.styles.add_style(:bg_color => "00BCFF", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
          :total => wb.styles.add_style(:bg_color => "5DC402", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
          :label => wb.styles.add_style(:bg_color => "CBCBCB", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 14, :alignment => { :horizontal=> :center }),
          :percentile => wb.styles.add_style(:bg_color => "E6FF00", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center })
        }

        wb.add_worksheet name: "大榜" do |sheet|

          ####### 标题行，指标列, begin #######
          #标题行
          title_row2_info = [
            I18n.t("dict.province"),
            I18n.t("dict.city"),
            I18n.t("dict.district"),
            "Tenant",
            I18n.t("dict.grade"),
            I18n.t("dict.classroom"),
            I18n.t("activerecord.attributes.user.name"),
            I18n.t("dict.pupil_number"), 
            I18n.t("dict.sex")
          ]

          #标题行
          title_row1_info = ["大榜"]
          title_row1_info += (title_row2_info.size-1).times.map{|t| ""}
          style_row1_info = []

          #标题1行
          title_row1_total = []
          style_row1_total = []
          
          #标题2行
          title_row2_total = []
          style_row2_total = []

          title_row1_total = _test_arr.map{|item|
            [item[:pap_heading] + "总得分率", "", ""]
          }.flatten

          title_row2_total = _test_arr.size.times.map{|item|
            ["知识", "技能", "能力"]
          }.flatten
          style_row1_info = style_row1_total = style_row2_total = title_row2_info.size.times.map{|t| cell_style[:label] }

          sheet.add_row(
              title_row1_info  + title_row1_total,
              :style => style_row1_info + style_row1_total
          )

          sheet.add_row(
              title_row2_info  + title_row2_total,
              :style => style_row1_info + style_row2_total
          )
          ####### 标题行，指标列, begin #######

          ####### 学生数据行, begin #######
          #数据行
          _all_pupil_uids.each{|pup_uid|
            a_report_url = _all_pupil_urls.find{|item| item.include?(pup_uid)}
            path_arr = a_report_url.split(".json")[0].split("/")
            target_pupil = nil
            target_location = nil
            target_tenant = nil
            Common::Report::Group::ListArr.each{|group|
              group_pos = path_arr.find_index(group)
              next unless group_pos
              group_uid = path_arr[group_pos + 1]
              case group
              when "pupil"
                target_pupil = Pupil.where(uid: group_uid).first
              when "klass"
                target_location = Location.where(uid: group_uid).first
              when "grade"
                target_tenant = Tenant.where(uid: group_uid).first
              else
                # do nothing
              end
            }

            if target_tenant.blank? ||  target_location.blank? ||  target_pupil.blank?
              puts "invalid path data"
              puts "path: #{item}"
              puts "tenant: #{target_tenant}"
              puts "location: #{target_location}"
              puts "pupil: #{target_pupil}"
              next
            end
            target_area = target_tenant.area
            
            data_row_info = [
              target_area.blank?? ["","",""] : target_area.pcd_h.values.map{|item| item[:name_cn]},
              target_tenant.name_cn,
              Common::Grade::List[target_location.grade.to_sym],
              Common::Klass::List[target_location.classroom.to_sym],
              target_pupil.name,
              target_pupil.stu_number,
              Common::Locale::i18n("dict.#{target_pupil.sex}")
            ].flatten

            data_row_total = []

            _test_arr.each{|item|
              target_report_url = item[:pupil_report_urls].find{|url| url.include?(pup_uid)}
              target_report_h = target_report_url.blank? ? {} : get_report_hash(ReportBasePath + target_report_url.to_s)
              target_arr = target_report_h.blank? ? ["-","-","-"] : [
                target_report_h["data"]["knowledge"]["base"]["weights_score_average_percent"],
                target_report_h["data"]["skill"]["base"]["weights_score_average_percent"],
                target_report_h["data"]["ability"]["base"]["weights_score_average_percent"]
                ]
              data_row_total.push(target_arr)
            }
            data_row_total.flatten!

            sheet.add_row data_row_info + data_row_total
          }

          ####### 学生数据行, begin #######
        end

        file_path = Rails.root.to_s + "/tmp/" + Time.now.to_i.to_s + ".xlsx"
        out_excel.serialize(file_path)        
        puts "Output: " + file_path 
      end # export_test_area_report_tenants_basic, end

      desc "输出测试用户绑定信息"
      task :export_test_user_binded_stat,[] => :environment do |t, args|
        ReportBasePath = ""#Rails.root.to_s
        ReportWarehousePath = "/reports_warehouse/tests/"
        _test_ids = args.extras
        _test_count = _test_ids.size
        _test_arr = _test_ids.map{|test_id|
          target_test = Mongodb::BankTest.find(test_id)
          target_paper = target_test.bank_paper_pap
          target_pupil_urls = find_all_pupil_report_urls(ReportBasePath, ReportWarehousePath + test_id, [])
          re = Regexp.new ".*pupil/(.*).json"
          target_pupil_uids = target_pupil_urls.map{|url| 
            r = re.match(url) 
            r.blank? ? nil : r[1].to_s
          }.compact

          {
            :id => test_id,
            :pap_heading => target_paper.heading,
            :subject => Common::Subject::List[target_paper.subject.to_sym],
            :pupil_report_urls => target_pupil_urls,
            :pupil_uids => target_pupil_uids
          }
        }
        _all_pupil_urls = eval(_test_arr.map{|item| "#{item[:pupil_report_urls]}" }.join("|"))
        _all_pupil_uids = eval(_test_arr.map{|item| "#{item[:pupil_uids]}" }.join("|"))

        target_loc_uids = []
        binded_pupil_number = _all_pupil_uids.map{|pup_uid| 
          target_pupil = Pupil.where(uid: pup_uid).first
          target_location = target_pupil.location
          target_loc_uids.push(target_location.uid) if target_location
          target_pupil.user.wx_users.blank? ? 0 : 1
        }.sum

        puts "total pupils: #{_all_pupil_uids.size}, binded pupils: #{binded_pupil_number}"

        target_loc_uids = target_loc_uids.uniq.compact
        target_locations = target_loc_uids.map{|uid| 
          target_loc = Location.where(uid: uid).first
        }
        target_locations = target_locations.uniq.compact
        target_tenants = target_locations.map{|loc| loc.tenant }
        target_teachers = target_locations.map{|loc| loc.teachers.map{|item| item[:teacher]} }.flatten
        target_teachers = target_teachers.uniq.compact
        binded_teacher_number = target_teachers.map{|tea| tea.user.wx_users.blank? ? 0 : 1 }.sum

        puts "total teachers: #{target_teachers.size}, binded teachers: #{binded_teacher_number}"

        target_tenant_administrators = target_tenants.map{|tnt| tnt.tenant_administrators }.flatten.uniq.compact
        binded_tenant_administrators_number = target_tenant_administrators.map{|tnt_admin| tnt_admin.user.wx_users.blank? ? 0 : 1 }.sum

        puts "total tenant administrators: #{target_tenant_administrators.size}, binded tenant administrators: #{binded_tenant_administrators_number}"

        puts ">>>not binded tenant administrators<<<"
        target_tenant_administrators.each{|tnt_admin|
          if tnt_admin.user.wx_users.blank? 
            target_tenant = tnt_admin.tenant
            puts "#{target_tenant.name_cn}: #{tnt_admin.name}"
          end
        }
       
      end # export_test_area_report_tenants_basic, end

      desc "输出报告的整体的各题得分率"
      task :export_test_overall_quiz_table,[] => :environment do |t, args|
        ReportWarehousePath = "/reports_warehouse/tests/"
        _test_ids = args.extras

        out_excel = Axlsx::Package.new
        wb = out_excel.workbook

        _test_ids.each{|_id|
          target_test =Mongodb::BankTest.where(id: _id).first
          target_paper =  target_test.bank_paper_pap
          ordered_qzps = target_paper.ordered_qzps
          wb.add_worksheet name: target_paper.id.to_s do |sheet|
            title_row = [
              "No",
              "Order",
              "Average Percent(Difficulty)"
            ]
            sheet.add_row title_row
            if target_test.report_top_group == "project"
              fdata = File.open(ReportWarehousePath + _id + "/project/" + _id + ".json", 'rb').read
            else
              target_tenant = target_test.tenants.first
              fdata = File.open(ReportWarehousePath + _id + "/grade/" + target_tenant.uid + ".json", 'rb').read
            end
            target_report_data =JSON.parse(fdata)

            qzps_data = target_report_data["paper_qzps"]
            ordered_qzps.each_with_index{|qzp, index|
              data_row = [
	             index,
                qzp.order,
                qzps_data[index]["value"]["weights_score_average_percent"]
              ]
              sheet.add_row(data_row)  
            }
          end
        }      
        file_path = Rails.root.to_s + "/tmp/" + Time.now.to_i.to_s + ".xlsx"
        out_excel.serialize(file_path)        
        puts "Output: " + file_path         
      end

      desc "组装报告数量json"
      task :construct_all_reports_stat_json,[] => :environment do |t, args|
        ReportWarehousePath = "/reports_warehouse/tests/"
        redis_key_prefix = "/" + Time.now.to_i.to_s
        _test_ids = args.extras
        _test_ids = Mongodb::BankTest.all.only(:id).map{|item| item.id.to_s} if _test_ids.blank?
        _test_ids.each{|_id|
          target_test =Mongodb::BankTest.where(id: _id).first
          nav_arr = Dir[ReportWarehousePath + _id + "/**/**/nav.json"]
          next if nav_arr.blank?
          nav_arr.each{|nav_path|
            target_nav_h = get_report_hash(nav_path)
            target_nav_count = target_nav_h.values[0].size
            target_path = nav_path.split("/nav.json")[0]
            target_path_arr = target_path.split("/")
            current_group = (Common::Report::Group::ListArr&target_path_arr)[-1]
            sub_group = (Common::Report::Group::ListArr - target_path_arr)[-1]
            next unless sub_group
            while target_path_arr.include?(target_test.report_top_group)
              target_key = redis_key_prefix + "/" + target_path_arr.join("/")
              reset_redis_value(target_key, sub_group, target_nav_count)
              target_path_arr.pop(2)
            end
          }
        }
        rpt_stat_redis_keys = Common::SwtkRedis::find_keys($cache_redis, redis_key_prefix + "/*")
        rpt_stat_redis_keys.each{|key|
          target_path = key + "/report_stat.json"
          p target_path
          File.write(target_path.split(redis_key_prefix)[1], $cache_redis.get(key))
          $cache_redis.del(key)
        }             
      end

      desc "检查报告的内容"
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
          FileUtils.mkdir_p("./tmp/#{args[:test_uid]}") unless File.exists?("./tmp/#{args[:test_uid]}")  
          tenant_uid_arr = bank_test.score_uploads.to_a
          # 线程数量
          th_number = 3
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


      def reset_redis_value redis_key, sub_group, target_nav_count
        target_value = $cache_redis.get(redis_key)
        if target_value.blank?
          result = {}
          result[sub_group] = target_nav_count
        else
          result = JSON.parse(target_value)
          result[sub_group] = 0 unless result[sub_group]
          result[sub_group] += target_nav_count
        end
        $cache_redis.set(redis_key, result.to_json)
      end      

      # 获取报告数据HASH
      def get_report_hash file_path
        return {} if file_path.blank?
        target_file_path = file_path.split("?")[0]
        fdata = File.open(target_file_path, 'rb').read
        JSON.parse(fdata)
      end

      # 获取报告数据行
      def get_report_data_row rpt_data, which_data
        data_row_lv1 = []
        data_row_total = []

        rpt_data.each{|k0,v0| #三维
          rpt_lv1_data = v0["lv_n"].map{|lv1| lv1.values[0]}.flatten
          rpt_lv1_data.each_with_index{|item, index| #一级指标
            data_row_lv1.push(item[which_data])
          }
          data_row_total.push(v0["base"][which_data])
        }
        return data_row_lv1 + data_row_total
      end

      # 查找所有学生
      def find_all_pupil_report_urls base_path, search_path, urls=[]
        fdata = File.open(base_path + search_path + "/nav.json", 'rb').read
        jdata = JSON.parse(fdata)
        jdata.values[0].each{|item|
          current_report_url = item[1]["report_url"]
          next_search_path = current_report_url.split(".json")[0]
          unless jdata.keys[0].include?("klass")
            urls = find_all_pupil_report_urls base_path, next_search_path, urls
          else
            urls.push(current_report_url)
          end
        }
        return urls
      end


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
          # base_path = ""
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
                target_tenant.number.strip,
                row[stu_num_index].strip,
                Common::Locale.hanzi2abbrev(row[stu_name_index]).strip
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
          out_excel.serialize("./tmp/" + bank_test._id.to_s + "/" + out_file_name + '_error.xlsx')
        end
      end

    #end
  end
end
