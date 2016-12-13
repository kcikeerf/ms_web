# -*- coding: UTF-8 -*-

require 'ox'
require 'roo'
require 'axlsx'

namespace :swtk do

  #添加所有controller和action到permission表
  require 'find'
  desc 'add all controllers、acton to table permissons'
  task add_acton_to_permisson: :environment do
    dir = Rails.root.join('app', 'controllers')
    Find.find(dir) do |controller_name|
      if controller_name =~ /_controller/ && controller_name !~ /application/
        controller = controller_name.gsub("#{dir.to_s}", '').gsub('.rb', '').camelcase.constantize
        controller.instance_methods(false).each do |action|
          p controller.to_s
          p action.to_s
          save_permission(controller.to_s, action.to_s)
        end
      end
    end
  end


  desc "load permissions definition"
  task load_permissions: :environment do
#    xml_str = ""
#    xml_file = File.open("lib/tasks/permissions.xml", "r")
#    xml_file.each do |line|
#      xml_str += line.chomp!
#    end
#    xml = Ox.parse(xml_str)

    xml = get_xml_obj("lib/tasks/permissions.xml") 
    if xml
      # clear all permission tables
      ActiveRecord::Base.transaction do
        Permission.destroy_all
      end

      xml.nodes.each{|ctl|
        ctl.nodes.each{|act|
          p = Permission.new({
            :name => ctl.attributes[:name] + '#' +act.attributes[:name],
            :subject_class => ctl.attributes[:name],
            :action => act.attributes[:name],
            :description => ctl.attributes[:name] + '#' +act.attributes[:name] 
          })
          p.save  
        }
      }
    end

  end

  desc "create super administrator"
  task create_super_admin: :environment do
    Role.new({:name => "super_administrator", 
              :desc => "this role is for who has all permissions", 
              :permissions => Permission.all}).save
    User.new({:email=>"admin@swtk.com", 
              :password=>"welcome1", 
              :role => Role.where(:name => "super_administrator")[0]}).save
  end

  desc "create manager console administrator"
  task :create_manager, [:name,:password,:email] => :environment do |t, args|
    if args[:name].nil? ||  args[:password].nil?
      puts "Command format not correct, Usage: #rake swtk:create_manager[:name,:password,:email]"
      exit 
    end
    begin
      m= Manager.new({
        :name => args[:name],
        :password => args[:password],
        :email => args[:email]})
      m.save!
    rescue Exception => ex
      p m.errors.message
      p "---"
      p ex.message
    end
  end

  desc "reload dictionary data"
  task reload_dictionary: :environment do
#    def get_xml_obj(file_path)
#      xml_str = ""
#      xml_file = File.open(file_path, "r")
#      xml_file.each do |line|
#        xml_str += line.chomp!
#      end
#      xml = Ox.parse(xml_str)
#    end

    #load generic dictionary
    xml_g = get_xml_obj("lib/tasks/dictionary_generic.xml")

    if xml_g
      # clear all generic dictionary tables
      ActiveRecord::Base.transaction do
        BankDic.destroy_all
        BankDicItem.destroy_all
      end
      
      # reload generic dictionary data with pre-defined xml
      xml_g.nodes.each{|dic|
        new_dic = BankDic.new({
            :sid => dic.attributes[:sid],
            :caption => dic.attributes[:caption],
            :desc => dic.attributes[:desc]
        })
        new_dic.save
        dic.nodes.each{|dicitem|
          new_dic_item = BankDicItem.new({
            :sid => dicitem.attributes[:sid],
            :caption => dicitem.attributes[:caption],
            :desc => dicitem.attributes[:desc]
          })
          new_dic_item.save
          new_dic.bank_dic_items << new_dic_item
        }
      }
    end

    #load subject dictionary
    xml_s = get_xml_obj("lib/tasks/dictionary_subject.xml")
    if xml_s
      # clear all subject dictionary tables
      ActiveRecord::Base.transaction do
        BankDicQuizSubject.destroy_all
        BankDicQuiztype.destroy_all
        BankSubjectQiztypeLink.destroy_all
      end

      # reload subject dictionary data with pre-defined xml
      xml_s.nodes.each{|subj|
        new_subj = BankDicQuizSubject.new({
          :subject => subj.attributes[:subject],
          :caption => subj.attributes[:caption],
          :desc => subj.attributes[:desc]
        })
        new_subj.save
        subj.nodes.each{|qtype|
          new_qtype =  BankDicQuiztype.where(:sid=> qtype[:sid])
          if new_qtype.blank?
            new_qtype = BankDicQuiztype.new({
              :sid => qtype[:sid],
              :caption => qtype[:caption],
              :desc => qtype[:desc]
            })
            new_qtype.save
          end
          new_subj.bank_dic_quiztypes << new_qtype
        }
      }
    end 

  end

  #针对默认类型指标
  desc "import node checkpoints, temporary use"
  task :read_node_checkpoint,[:file_path,:node_uid,:dimesion]=> :environment do |t, args|
    if args[:file_path].nil? ||  args[:node_uid].nil? || args[:dimesion].nil?
      puts "Command format not correct."
      exit 
    end

    ckp_file = File.open(args[:file_path], "r")
    ckp_file.each do |line|
      str = line.chomp!
      if str
        arr =str.split(",")
        arr_len = arr.size
        if arr_len < 3
          puts "line not a correct format!" 
          exit -1
        end
        next if arr[0].blank?

        rid = arr[0]
        ckp_desc = arr[1..-2].join(",")
        weights = arr[-1]

        ckp_desc_arr = ckp_desc.split("__:__")
        checkpoint = ckp_desc_arr[0]
        desc = ckp_desc_arr[1]

        ckp = BankCheckpointCkp.new({:node_uid => args[:node_uid].strip,
          :dimesion => args[:dimesion].strip,
          :rid=>rid,
          :checkpoint => checkpoint,
          :desc => desc,
          :advice => "建议",
          :weights => weights,
          :sort => rid,
          :is_entity => false
        })
        ckp.save
      end
    end

    ckps = BankCheckpointCkp.where(node_uid: args[:node_uid])
    ckps.each_with_index{|ckp,index|
        next unless ckp
#      result = BankRid.get_all_higher_nodes ckps,ckp
#      if result.empty?
        ckp.update(:is_entity => true) if ckp.children.blank?
     # else
 #       ckp.update(:is_entity => true)
      #end
    }

  end

  #针对默认类型指标
  desc "import subject checkpoints, temporary use"
  task :read_subject_checkpoint,[:file_path,:subject,:xue_duan,:dimesion]=> :environment do |t, args|
    if args[:file_path].nil? ||  args[:subject].nil? || args[:xue_duan].nil? || args[:dimesion].nil?
      puts "Command format not correct."
      exit 
    end

    if BankSubjectCheckpointCkp.where(subject: args[:subject], dimesion:args[:dimesion], category: args[:xue_duan]).count > 0
      puts "#{args[:subject]}, #{args[:xue_duan]} not empty"
      exit
    end

    ckp_file = File.open(args[:file_path], "r")
    ckp_file.each do |line|
      str = line.chomp!
      if str
        arr =str.split(",")
        arr_len = arr.size
        if arr_len < 3
          puts "line not a correct format!" 
          exit -1
        end
        next if arr[0].blank?

        rid = arr[0].strip
        ckp_desc = arr[1..-2].join(",")
        weights = arr[-1].strip

        ckp_desc_arr = ckp_desc.split("__:__")
        checkpoint = ckp_desc_arr[0].nil?? "":ckp_desc_arr[0].strip
        desc = ckp_desc_arr[1].nil?? "":ckp_desc_arr[1].strip

        ckp = BankSubjectCheckpointCkp.new({
          :dimesion => args[:dimesion].strip,
          :category => args[:xue_duan],
          :subject => args[:subject],
          :rid=>rid || "",
          :checkpoint => checkpoint || "",
          :desc =>desc || "",
          :advice => "建议",
          :weights => weights,
          :sort => rid,
          :is_entity => false
        })

        ckp.save
      end
    end

    ckps = BankSubjectCheckpointCkp.where(subject: args[:subject], category: args[:xue_duan], dimesion: args[:dimesion])
    ckps.each_with_index{|ckp,index|
        next unless ckp
        p index
        ckp.update(:is_entity => true) if ckp.children.blank?
    }

  end

  desc "deconstruct paper to a status: editting, editted, analyzing"
  task :deconstruct_paper,[:pap_uid, :back_to]=> :environment do |t, args|
    if args[:pap_uid].nil? ||  args[:back_to].nil?
      puts "Command format not correct."
      exit
    end
    args[:pap_uid].strip!
    args[:back_to].strip!

    target_pap = Mongodb::BankPaperPap.where(_id: args[:pap_uid]).first
    if target_pap
      #get quizs, qizpoint 
      quizs = target_pap.bank_quiz_qizs
      qzps = target_pap.bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps}.flatten

      paramh = {}
      case args[:back_to]
      when "editting"
        #clear relations between quiz points and checkpoints
        qzps.map{|qzp|
          Mongodb::BankCkpQzp.where(:qzp_uid => qzp._id.to_s).destroy_all
        }
        #clear all qizpoints
        qzps.map{|qzp|
          qzp.destroy
        }
        #clear all quizs
        quizs.map{|quiz|
          quiz.destroy
        }
        j = JSON.parse(target_pap.paper_json)
        j["bank_quiz_qizs"].each{|qiz| qiz["bank_qizpoint_qzps"].each{|qzp| qzp["bank_checkpoints_ckps"] = "" }}
        paramsh = {:paper_status => "editting" ,:paper_json=> j.to_json}
      when "editted"
        #clear relations between quiz points and checkpoints
        qzps.map{|qzp|
          Mongodb::BankCkpQzp.where(:qzp_uid => qzp._id.to_s).destroy_all
        }
        j = JSON.parse(target_pap.paper_json)
        j["bank_quiz_qizs"].each{|qiz| qiz["bank_qizpoint_qzps"].each{|qzp| qzp["bank_checkpoints_ckps"] = "" }}
        paramsh = {:paper_status => "editted" ,:paper_json=> j.to_json}
      when "analyzing"
        #clear relations between quiz points and checkpoints
        qzps.map{|qzp|
          Mongodb::BankCkpQzp.where(:qzp_uid => qzp._id.to_s).destroy_all
        }
        paramsh = {:paper_status => "analyzing"}
      when "analyzed"
        Mongodb::BankQizpointScore.where({:pap_uid => args[:pap_uid]}).destroy_all
        paramsh = {:paper_status => "analyzed"}
      end
      if ["editting", "editted", "analyzing", "analyzed"].include?(args[:back_to])
        target_pap.update(paramsh)
      end
      puts "done"
    else
      puts "Paper not found"
    end
  end

  desc "export paper structure"
  task :export_paper_structure,[:pap_uid,:out]=> :environment do |t, args|

    if args[:pap_uid].nil? || args[:out].nil?
      puts "Command format not correct."
      exit
    end
    args[:pap_uid].strip!

    target_pap = Mongodb::BankPaperPap.where(_id: args[:pap_uid]).first

    ckp_model = BankCheckpointCkp.judge_ckp_source({:pap_uid => args[:pap_uid]})
    target_subject = target_pap.subject
    target_category =  Common::Grade.judge_xue_duan(target_pap.grade)

    ckp_objs = ckp_model.where(subject: target_subject, category: target_category)
    if target_pap
      if ["analyzed", "score_importing", "score_imported", "report_generating", "report_completed"].include?(target_pap.paper_status)
        #get quizs, qizpoint 
        quizs = target_pap.bank_quiz_qizs
        qzps = target_pap.bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps}.flatten

        begin
          out_excel = Axlsx::Package.new
          wb = out_excel.workbook

          wb.add_worksheet name: "Paper Structure" do |sheet|
            sheet.add_row(["PaperID", target_pap._id.to_s, "Paper Name", target_pap.heading])
            sheet.add_row(["Quit Point", "Score", "Dimesion", "Checkpoint Path"])
            qzps.each{|qzp|
              ckps = qzp.bank_checkpoint_ckps
              ckps.each{|ckp|
                next unless ckp
                ckp_ancestors = BankRid.get_all_higher_nodes ckp_objs, ckp
                ckp_path = ckp_ancestors.map{|a| a.checkpoint }.join(" >> ") + ">> #{ckp.checkpoint}"
                #p qzp.order + "::" +ckp.dimesion + "::" + ckp_path
                sheet.add_row([qzp.order, qzp.score, I18n.t("dict.#{ckp.dimesion}"), ckp_path])
              }
            }
          end
          out_path = args[:out]
          out_excel.serialize(out_path)
        rescue Exception => ex
          puts ex.message
          puts ex.backtrace
          puts "failed"
        end
        puts "done"
      end
    else
      puts "Paper not found"
    end
  end

  desc "export pupil report data"
  task :export_pupil_report_data,[:pap_uid,:out]=> :environment do |t, args|
    if args[:pap_uid].nil?# || args[:out].nil?
      puts "Command format not correct."
      exit
    end
    args[:pap_uid].strip!

    target_pap = Mongodb::BankPaperPap.where(_id: args[:pap_uid]).first
    if target_pap
      if ["report_completed"].include?(target_pap.paper_status)
        loc_h = {
          :province => Common::Locale.hanzi2pinyin(target_pap.province),
          :city => Common::Locale.hanzi2pinyin(target_pap.city),
          :district => Common::Locale.hanzi2pinyin(target_pap.district),
          :school => Common::Locale.hanzi2pinyin(target_pap.school),
          :grade => target_pap.grade
        }
        menus = Location.get_report_menus Common::Role::Analyzer, target_pap._id.to_s, loc_h
        
        #写入excel
        out_excel = Axlsx::Package.new
        wb = out_excel.workbook

        wb.add_worksheet name: "Data" do |sheet|

          cell_style = {
            :knowledge => wb.styles.add_style(:bg_color => "FF00F7", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
            :skill => wb.styles.add_style(:bg_color => "FFCB1C", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
            :ability => wb.styles.add_style(:bg_color => "00BCFF", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
            :total => wb.styles.add_style(:bg_color => "5DC402", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
            :label => wb.styles.add_style(:bg_color => "CBCBCB", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 14, :alignment => { :horizontal=> :center }),
            :percentile => wb.styles.add_style(:bg_color => "E6FF00", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center })
          }

          #省市区行
          sheet.add_row([
            I18n.t("dict.province"), 
            target_pap.province, 
            I18n.t("dict.city"),
            target_pap.city,
            I18n.t("dict.district"),
            target_pap.district,
            "Tenant",
            target_pap.tenant.name_cn
          ], :style =>[
            cell_style[:label],
            nil,
            cell_style[:label],
            nil,
            cell_style[:label],
            nil, 
            cell_style[:label],
            nil                       
          ])

          #标题行
          title_row1_info = 8.times.map{|t| ""}
          style_row1_info = 8.times.map{|t| cell_style[:label] }

          #标题行
          title_row2_info = [
            I18n.t("dict.grade"),
            I18n.t("dict.classroom"),
            I18n.t("dict.head_teacher"), 
            I18n.t("dict.subject_teacher"), 
            I18n.t("activerecord.attributes.user.name"),
            I18n.t("dict.pupil_number"), 
            I18n.t("dict.sex"),
            I18n.t("scores.grade_rank")
          ]

          title_filled = false
          menus[:items].each{|klass|
            grade_label = I18n.t("dict.#{menus[:key]}")
            klass_label = I18n.t("dict.#{klass[:key]}")
            klass_report = Mongodb::ClassReport.find(klass[:report_id])
            klass[:items].each{|pupil|
              loc = Location.where({
                :province => klass_report.province,
                :city => klass_report.city,
                :district => klass_report.district,
                :school => klass_report.school,
                :grade => klass_report.grade,
                :classroom => klass_report.classroom
                }).first
              pupil_report = Mongodb::PupilReport.find(pupil[:report_id])
              reporth = JSON.parse(pupil_report.report_json)
              target_pupil = Pupil.find(pupil_report.pup_uid)

              data_row = []
              data_row_info = [
                grade_label,
                klass_label,
                loc.head_teacher.nil?? "-" : loc.head_teacher.name,
                loc.subject_teacher(target_pap.subject).nil?? "-" : loc.subject_teacher(target_pap.subject).name,
                target_pupil.name,
                target_pupil.stu_number,
                I18n.t("dict.#{target_pupil.sex}"),
                reporth["basic"]["grade_rank"]
              ]
              #数据行
              data_row_lv1 = []
              data_row_total = []
              data_row_percentile = []
              data_row_lv2 = []

              # style_row_lv1 = []
              # style_row_total = []
              # style_row_percentile = []
              # style_row_lv2 = []
              
              #标题1行
              title_row1_lv1 = []
              title_row1_total = []
              title_row1_percentile = []
              title_row1_lv2 = []
              
              style_row1_lv1 = []
              style_row1_total = []
              style_row1_percentile = []
              style_row1_lv2 = []
              
              #标题2行
              title_row2_lv1 = []
              title_row2_total = []
              title_row2_percentile = []
              title_row2_lv2 = []
              
              style_row2_lv1 = []
              style_row2_total = []
              style_row2_percentile = []
              style_row2_lv2 = []

              reporth["percentile"].each{|dimesion, item|
                title_row1_percentile = ["百分位等级","",""] if title_row1_percentile.blank?
                title_row2_percentile << I18n.t("dict.#{dimesion}")
                data_row_percentile  << item
                style_row1_percentile << cell_style[:percentile]
                style_row2_percentile << cell_style[:percentile]

              }
              
              reporth["data_table"].each{|dimesion, items|
                dim_lv1_count = 0
                dim_lv2_count = 0

                total_item = items.shift
                title_row1_total = ["总得分率","",""] if title_row1_total.blank?
                title_row2_total << I18n.t("dict.#{dimesion}")
                data_row_total << total_item[1]["value"]["average_percent"]
                style_row1_total << cell_style[:total]
                style_row2_total << cell_style[:total]

                items.each{|order, lv1_item|
                  unless title_filled
                    if dim_lv1_count == 0 
                      title_row1_lv1.push(I18n.t("dict.#{dimesion}") + "一级得分率")
                      dim_lv1_count = 1
                    else
                      title_row1_lv1.push("") 
                    end
                    title_row2_lv1.push(lv1_item["label"])
                    style_row1_lv1 << cell_style[dimesion.to_sym]
                    style_row2_lv1 << cell_style[dimesion.to_sym]
                  end
                  data_row_lv1.push(lv1_item["value"]["average_percent"])
                  lv1_item["items"].each{|order, lv2_item|
                    unless title_filled
                      if dim_lv2_count == 0
                        title_row1_lv2.push(I18n.t("dict.#{dimesion}") + "二级得分率")
                        dim_lv2_count = 1
                      else
                        title_row1_lv2.push("")
                      end
                      title_row2_lv2.push(lv2_item["label"])
                      style_row1_lv2 << cell_style[dimesion.to_sym]
                      style_row2_lv2 << cell_style[dimesion.to_sym]
                    end
                    data_row_lv2.push(lv2_item["value"]["average_percent"])
                  }
                }               
              }
              unless title_filled
                sheet.add_row(title_row1_info + title_row1_lv1 + title_row1_total + title_row1_percentile + title_row1_lv2,
                    :style => style_row1_info + style_row1_lv1 + style_row1_total + style_row1_percentile + style_row1_lv2 
                  )
                sheet.add_row(title_row2_info + title_row2_lv1 + title_row2_total + title_row2_percentile + title_row2_lv2,
                    :style => style_row1_info + style_row2_lv1 + style_row2_total + style_row2_percentile + style_row2_lv2 
                  )
                title_filled = true
              end
              data_row = data_row_info + data_row_lv1 + data_row_total + data_row_percentile + data_row_lv2
              sheet.add_row data_row    
            }
          }

        end
        out_path = args[:out]
        out_excel.serialize(out_path)
      end
    else
      puts "Paper not found"
    end
  end

  desc "export original paper score"
  task :export_original_paper_score,[:pap_uid,:out]=> :environment do |t, args|

    if args[:pap_uid].nil? || args[:out].nil?
      puts "Command format not correct."
      exit
    end
    args[:pap_uid].strip!

    target_pap = Mongodb::BankPaperPap.where(_id: args[:pap_uid]).first
    target_scores = Mongodb::BankQizpointScore.where(pap_uid: args[:pap_uid])
    begin
      out_excel = Axlsx::Package.new
      wb = out_excel.workbook

      wb.add_worksheet name: "Scores" do |sheet|
        sheet.add_row(["PaperID", target_pap._id.to_s, "Paper Name", target_pap.heading])
        sheet.add_row(["ClassRoom","PupilName","Quit Point", "Full Score", "Real Score", "Dimesion", "Level1 Ckp", "Level2 Ckp", "End Level Ckp", "Weights"])
        target_scores.each{|score|
          target_pupil=Pupil.where(uid: score.pup_uid).first
          sheet.add_row([I18n.t("dict.#{score.classroom}"), target_pupil.name, score.order, score.full_score,score.real_score, I18n.t("dict.#{score.dimesion}"), score.lv1_ckp, score.lv2_ckp, score.lv_end_ckp,score.weights])
        }
      end
      out_path = args[:out]
      out_excel.serialize(out_path)
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace
      puts "failed"
    end
    puts "done"
  end

  desc "export test results"
  task :export_test_results,[:pap_uid,:tenant_uid,:out]=> :environment do |t, args|

    if args[:pap_uid].nil? || args[:out].nil?
      puts "Command format not correct."
      exit
    end
    args[:pap_uid].strip!

    target_pap = Mongodb::BankPaperPap.where(_id: args[:pap_uid]).first
    target_scores = Mongodb::BankQizpointScore.where(pap_uid: args[:pap_uid])
    target_scores = Mongodb::BankTestScore.where(:test_id => target_pap.bank_tests[0].id.to_s, :tenant_uid => args[:tenant_uid]) if target_scores.blank?

    ckp_model = target_pap.bank_quiz_qizs[0].bank_qizpoint_qzps[0].bank_checkpoint_ckps[0].class 

    begin
      out_excel = Axlsx::Package.new
      wb = out_excel.workbook

      wb.add_worksheet name: "Scores" do |sheet|
        sheet.add_row(["PaperID", target_pap._id.to_s, "Paper Name", target_pap.heading])
        sheet.add_row(["ClassRoom","PupilName","Quit Point", "Full Score", "Real Score", "Dimesion", "Level1 Ckp", "Level2 Ckp", "End Level Ckp", "Weights"])
        target_scores.each{|score|
          target_pupil=Pupil.where(uid: score.pup_uid).first
          location = target_pupil.location
          ckp_uids_arr = score.ckp_uids.split("/")
          ckp_weights_arr = score.ckp_weights.split("/")
          ckp_arr = ckp_uids_arr.map{|uid| ckp_model.where(uid: uid).first }
          ckp = ckp_model
          sheet.add_row([Common::Locale::i18n("dict.#{location.nil?? "" : location.classroom}"), target_pupil.name, score.order, score.full_score,score.real_score, I18n.t("dict.#{score.dimesion}"), ckp_arr[1].checkpoint, ckp_arr[2].checkpoint, ckp_arr[-1].checkpoint, ckp_weights_arr[-1]])
        }
      end
      out_path = args[:out]
      out_excel.serialize(out_path)
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace
      puts "failed"
    end
    puts "done"
  end

  desc "generate random paper analysis"
  task :generate_paper_analysis,[:pap_uid]=> :environment do |t, args|
    if args[:pap_uid].nil?
      puts "Command format not correct."
      exit
    end
    args[:pap_uid].strip!

    target_pap = Mongodb::BankPaperPap.where(_id: args[:pap_uid]).first
    begin
      j = JSON.parse(target_pap.paper_json)
      j["bank_quiz_qizs"].each_with_index{|qiz,qiz_index|
        j["bank_quiz_qizs"][qiz_index]["bank_qizpoint_qzps"].each_with_index{|qzp,qzp_index|
          qzp_ckp = []
          ["knowledge", "skill", "ability"].each{|dimesion|
            ckp = BankSubjectCheckpointCkp.where({
               :dimesion => dimesion,
               :subject => target_pap.subject,
               :category => Common::Grade.judge_xue_duan(target_pap.grade),
               :is_entity => true}).sample
            ckp_qzp = Mongodb::BankCkpQzp.new
            ckp_qzp.save_ckp_qzp  qzp["id"], ckp.uid.to_s, "BankSubjectCheckpointCkp"
            qzp_ckp << {"dimesion" => dimesion, "checkpoint"=>ckp.checkpoint, "uid" => ckp.uid, "ckp_source" => "BankSubjectCheckpointCkp"}
          }
          j["bank_quiz_qizs"][qiz_index]["bank_qizpoint_qzps"][qzp_index]["bank_checkpoints_ckps"] = qzp_ckp
        }
      }
      target_pap.update(:paper_json => j.to_json, :paper_status=> "analyzed")
=begin
      qzps = target_pap.bank_quiz_qizs.map{|a| a.bank_qizpoint_qzps}.flatten
      qzps.each{|qzp|
        ["knowledge", "skill", "ability"].each{|dimesion|
          ckp = BankCheckpointCkp.where({
            :node_uid => "728539189095694336", 
            :dimesion => dimesion, 
            :is_entity => true}).sample
          Mongodb::BankCkpQzp.new({:qzp_uid=> qzp._id.to_s, :ckp_uid=> ckp.uid.to_s}).save!
        }
      }
=end
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace
      puts "failed"
    end
    puts "done"
  end

  desc "import replace china area data"
  task :import_area,[:file_path]=> :environment do |t, args|
    if args[:file_path].nil?
      puts "Command format not correct."
      exit
    end
    args[:file_path].strip!

    begin
      xls = Roo::Excelx.new(args[:file_path])
      sheet = xls.sheet("area") if xls
      sheet.count.times.each{|count|
        p "row number: #{count}"
        row = sheet.row(count)
        next if row.compact.blank?
        arr = row[0].to_s.split("_")
        row.each_with_index{|col, index|
          next if index == 0
          next if col.blank?
          paramsh = {}
          rid = Common::Area::CountryRids["zhong_guo"] #China first :)
          if arr.length == 1
            rid += (index-1).to_s.rjust(3, '0')
            type = "province"
          elsif arr.length == 2
            rid += arr[1].to_s.rjust(3, '0') + (index-1).to_s.rjust(3, '0')
            type = "city"
          elsif arr.length == 3
            rid += arr[1].to_s.rjust(3, '0') + arr[2].to_s.rjust(3, '0') + (index-1).to_s.rjust(3, '0')
            type = "district"
          else
            next
          end

          paramsh = {
            :rid => rid,
            :area_type => type,
            :name => Common::Locale.hanzi2pinyin(col.strip),
            :name_cn => col.strip,
            :comment => ""
          } if rid and type
          unless paramsh.empty?
            a = Area.new(paramsh)
            a.save!
          end
        }
      }
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace
      puts "failed"
    end
    puts "done"
  end

  desc "merge node ckp to subject ckp"
  task :merge_ckp_node_to_subject, [:node_uid,:category] => :environment do |t, args|
    if args[:node_uid].nil? || args[:category].nil?
      puts "Command format not correct."
      exit 
    end
    begin
      node = BankNodestructure.find(args[:node_uid])
      node_ckps = BankCheckpointCkp.where(:node_uid => args[:node_uid])
      node_ckps.each{|n_ckp|
        s_ckp = BankSubjectCheckpointCkp.new({
          :dimesion => n_ckp.dimesion,
          :rid => n_ckp.rid,
          :checkpoint => n_ckp.checkpoint,
          :subject => node.subject,
          :is_entity => n_ckp.is_entity,
          :category => args[:category],
          :advice => n_ckp.advice,
          :desc => n_ckp.desc,
          :weights => n_ckp.weights,
          :sort => n_ckp.sort
        })
        s_ckp.save!
      }
    rescue Exception => ex
      p m.errors.message
      p "---"
      p ex.message
    end
  end

  def save_permission(controller, action)
    name = "#{controller}##{action}"

    permisson = Permission.find_or_initialize_by(subject_class: controller, action: action)
    permisson.name = name if permisson.name.blank?
    permisson.description = name if permisson.description.blank?
    permisson.save
  end

  # get xml string
  def get_xml_obj(file_path)
    xml_str = ""
    xml_file = File.open(file_path, "r")
    xml_file.each do |line|
      xml_str += line.chomp!
    end
    xml = Ox.parse(xml_str)
  end

  desc "create mongo indexes"
  task create_mongo_indexes: :environment do
    #version1.0
    klass_version_1_0_arr = [
      "ReportEachLevelPupilNumberResult",
      "ReportFourSectionPupilNumberResult",
      "ReportStandDevDiffResult",
      "ReportTotalAvgResult",
      "ReportQuizCommentsResult",
      "MobileReportTotalAvgResult",
      "MobileReportBasedOnTotalAvgResult",
    ]
    
    #version1.1
    group_types = Common::Report::Group::ListArr
    base_result_klass_arr = []
    base_result_klass_arr += group_types.map{|t|
      collect_type = t.capitalize 
      [
        "Report#{collect_type}BaseResult",
        "Report#{collect_type}Lv1CkpResult",
        "Report#{collect_type}Lv2CkpResult",
        "Report#{collect_type}LvEndCkpResult",
        "Report#{collect_type}OrderResult",
        "Report#{collect_type}OrderLv1CkpResult",
        "Report#{collect_type}OrderLv2CkpResult",
        "Report#{collect_type}OrderLvEndCkpResult"
      ]
    }

    pupil_stat_klass_arr = []
    pupil_stat_klass_arr += group_types[1..-1].map{|t|
      collect_type = t.capitalize 
      [
        "Report#{collect_type}BeforeBasePupilStatResult",
        "Report#{collect_type}BeforeLv1CkpPupilStatResult",
        "Report#{collect_type}BeforeLv2CkpPupilStatResult",
        "Report#{collect_type}BeforeLvEndCkpPupilStatResult",
        "Report#{collect_type}BasePupilStatResult",
        "Report#{collect_type}Lv1CkpPupilStatResult",
        "Report#{collect_type}Lv2CkpPupilStatResult",
        "Report#{collect_type}LvEndCkpPupilStatResult"
      ]
    }

    #
    klass_arr = klass_version_1_0_arr + base_result_klass_arr.flatten + pupil_stat_klass_arr.flatten
    klass_arr.each{|klass|
      # self.const_set(klass, Class.new)
      "Mongodb::#{klass}".constantize.create_indexes
    }
  end

  # 教材指标
  desc "export subject checkpoint template"
  task :export_subejct_checkpoint_for_node, [:node_uid,:out] => :environment do |t, args|
    if args[:node_uid].nil? || args[:out].nil?
      puts "Command format not correct."
      exit 
    end

    # 获取教材
    node = BankNodestructure.where(uid: args[:node_uid]).first
    if node
      node_catalogs = node.bank_node_catalogs.sort{|a,b| Common::CheckpointCkp.compare_rid_plus(a.rid, b.rid) }

      catalog_arr = []
      hidden_arr = []

      #输出内容
      begin
        out_excel = Axlsx::Package.new
        wb = out_excel.workbook

        wb.add_worksheet name: "章节表" do |sheet|
          sheet.add_row(["Catalog ID", "Catalog Name"])
          sheet.add_row(["id, don't change", "tree"])
          node_catalogs.each{|node|
            ancestors = BankRid.get_all_higher_nodes BankNodeCatalog.where(node_uid: args[:node_uid]),node
            path_arr = ancestors.map(&:node)
            path_arr.reverse!
            path_arr.push(node.node)
            catalog_arr.push(node.node)
            hidden_arr.push(node.uid)
            sheet.add_row([node.uid, path_arr.join(" > ")])
          }
        end

        empty_cols = node_catalogs.map{|item| "" }

        wb.add_worksheet name: "知识点章节对应表" do |sheet|
          sheet.add_row(["Knowledge ID","级知识点"].concat(catalog_arr))
          sheet.add_row(["id", "级知识点"].concat(hidden_arr))
          
          ckps = BankSubjectCheckpointCkp.where(subject: node.subject, category: node.xue_duan, dimesion: "knowledge")

          ckps.each_with_index{|ckp, index|
            next unless ckp
            ckp_ancestors = BankRid.get_all_higher_nodes ckps, ckp
            ckp_path_arr = ckp_ancestors.map{|a| a.checkpoint }
            ckp_path_arr.push(ckp.checkpoint)
            ckp_path = ckp_path_arr.join(" >> ")
            row_arr = [ckp.uid, ckp_path].concat(empty_cols)
            sheet.add_row(row_arr)
            cells= sheet.rows.last.cells[2..row_arr.count].map{|cell| {:key=> cell.r }}
            cells.each{|cell|
              sheet.add_data_validation(cell[:key],{
                :type => :list,
                :formula1 => "y",
                :showDropDown => false,
                :showInputMessage => true,
                :promptTitle => "章节表",
                :prompt => ""
              })
            }

          }
        end
        out_path = args[:out]
        out_excel.serialize(out_path)
      rescue Exception => ex
        puts ex.message
        puts ex.backtrace
        puts "failed"
      end
      puts "done"
    else
      puts "教材不存在！"
    end
  end

end
