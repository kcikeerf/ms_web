# -*- coding: UTF-8 -*-

require 'ox'
require 'roo'
require 'axlsx'
require 'find'

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
    #
    klass_arr = Mongoid.models
    klass_arr.each{|klass|
      klass.create_indexes()
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

  namespace :v1_1 do
    desc "export original paper score"
    task :export_original_paper_score,[:test_id,:out]=> :environment do |t, args|

      if args[:test_id].nil? || args[:out].nil?
        puts "Command format not correct."
        exit
      end

      target_test = Mongodb::BankTest.where(id: args[:test_id]).first
      target_pap = target_test.bank_paper_pap
      target_scores = Mongodb::BankTestScore.where(test_id: args[:test_id])
      begin
        out_excel = Axlsx::Package.new
        wb = out_excel.workbook

        wb.add_worksheet name: "Scores" do |sheet|
          sheet.add_row(["PaperID", target_pap._id.to_s, "Paper Name", target_pap.heading])
          sheet.add_row(["Tenant","ClassRoom","PupilName","Quiz Point", "Full Score", "Real Score", "Dimesion", "Level1 Ckp", "Level2 Ckp", "End Level Ckp", "Weights"])
          target_scores.each{|item|
            tenant = Tenant.where(uid: item.tenant_uid).first
            location = Location.where(uid: item.loc_uid).first
            pupil = Pupil.where(uid: item.pup_uid).first
            ckp_uids = item.ckp_uids.split("/")
            ckp_weights = item.ckp_weights.split("/")
            lv1_ckp = BankSubjectCheckpointCkp.where(uid: ckp_uids[1]).first
            lv2_ckp = BankSubjectCheckpointCkp.where(uid: ckp_uids[2]).first
            lv_end_ckp = BankSubjectCheckpointCkp.where(uid: ckp_uids[-1]).first

            sheet.add_row([
              tenant.name_cn,
              I18n.t("dict.#{location.classroom}"), 
              pupil.name, 
              item.order, 
              item.full_score,
              item.real_score, 
              I18n.t("dict.#{item.dimesion}"), 
              lv1_ckp.checkpoint, 
              lv2_ckp.checkpoint, 
              lv_end_ckp.checkpoint,
              ckp_weights[-1]
              ])
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

    desc 'Print compiled grape routes'
    task :api_routes => :environment do
      api_arr =[
        PaperOnlineTest::API,
        Reports::API,
        ReportsWarehouse::API
      ]
      api_arr.each do |api|
        api.routes.each do |route|
          puts route.path
        end
      end
    end

    desc "export v1.1 pupil report data"
    task :export_pupil_report_data,[:base_path,:pap_id,:top_group,:out]=> :environment do |t, args|
      # target_test = Mongodb::BankTest.where(_id: args[:test_id]).first
      # target_pap = target_test ? target_test.bank_paper_pap : nil
      base_path = args[:base_path].blank?? "" : args[:base_path]
      target_pap = Mongodb::BankPaperPap.where(_id: args[:pap_id]).first
      if target_pap
        target_test = target_pap.bank_tests[0]
        test_id = target_test.id.to_s
        if ["report_completed"].include?(target_pap.paper_status)

          ReportWarehousePath = base_path + "/reports_warehouse/tests/#{test_id}"

          #写入excel
          out_excel = Axlsx::Package.new
          wb = out_excel.workbook

          wb.add_worksheet name: "Data" do |sheet|

            ####### 标题行，指标列, begin #######
            cell_style = {
              :knowledge => wb.styles.add_style(:bg_color => "FF00F7", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
              :skill => wb.styles.add_style(:bg_color => "FFCB1C", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
              :ability => wb.styles.add_style(:bg_color => "00BCFF", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
              :total => wb.styles.add_style(:bg_color => "5DC402", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center }),
              :label => wb.styles.add_style(:bg_color => "CBCBCB", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 14, :alignment => { :horizontal=> :center }),
              :percentile => wb.styles.add_style(:bg_color => "E6FF00", :border => { :style => :thin, :color => "00" },:fg_color => "000000", :sz => 12, :alignment => { :horizontal=> :center })
            }

            #标题行
            title_row2_info = [
              I18n.t("dict.province"),
              I18n.t("dict.city"),
              I18n.t("dict.district"),
              "Tenant",
              I18n.t("dict.grade"),
              I18n.t("dict.classroom"),
              I18n.t("dict.head_teacher"), 
              I18n.t("dict.subject_teacher"), 
              I18n.t("activerecord.attributes.user.name"),
              I18n.t("dict.pupil_number"), 
              I18n.t("dict.sex")#,
              # I18n.t("scores.grade_rank")
            ]

            #标题行
            title_row1_info = [target_pap.heading]
            title_row1_info += (title_row2_info.size-1).times.map{|t| ""}
            style_row1_info = title_row2_info.size.times.map{|t| cell_style[:label] }

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

            fdata = File.open(ReportWarehousePath + "/ckps_qzps_mapping.json", 'rb').read
            ckps_json =JSON.parse(fdata)

            ckps_data = ckps_json.values[0]
            title_row1_total = ["总得分率","",""]
            # title_row1_percentile = ["整体百分位等级","",""]
            ckps_data.each{|k0,v0| #三维
              dim_label = I18n.t("dict.#{k0}")
              dim_lv1_data = v0["lv_n"].map{|lv1| lv1.values[0]}.flatten
              title_row1_lv1.push(dim_label + "一级得分率")
              dim_lv1_data.each_with_index{|item, index| #一级指标
                title_row1_lv1.push("") if index > 0
                title_row2_lv1.push(item["checkpoint"])
                style_row1_lv1 << cell_style[k0.to_sym]
                style_row2_lv1 << cell_style[k0.to_sym]
              }

              dim_lv2_data = dim_lv1_data.map{|lv1| lv1["items"].map{|lv2| lv2.values[0]} }.flatten
              title_row1_lv2.push(dim_label + "二级得分率")
              dim_lv2_data.each_with_index{|item, index| #二级指标
                title_row1_lv2.push("") if index > 0
                title_row2_lv2.push(item["checkpoint"])
                style_row1_lv2 << cell_style[k0.to_sym]
                style_row2_lv2 << cell_style[k0.to_sym]
              }

              
              title_row2_total << dim_label
              style_row1_total << cell_style[:total]
              style_row2_total << cell_style[:total]

              # title_row2_percentile << dim_label
              # style_row1_percentile << cell_style[:percentile]
              # style_row2_percentile << cell_style[:percentile]

            }

            group_index = Common::Report::Group::ListArr.find_index(args[:top_group])
            Common::Report::Group::ListArr[1..group_index].each{|group|
              case group
              when "klass"
                title_row1_percentile += ["班级百分位等级","",""]
              when "grade"
                title_row1_percentile += ["年级百分位等级","",""]
              when "project"
                title_row1_percentile += ["联考百分位等级","",""]
              end
              Common::CheckpointCkp::TYPE.each{|dim|
                dim_label = I18n.t("dict.#{dim}")
                title_row2_percentile << dim_label
                style_row1_percentile << cell_style[:percentile]
                style_row2_percentile << cell_style[:percentile]
              }
            }

            sheet.add_row(
                title_row1_info + title_row1_lv1  + title_row1_total + title_row1_percentile  + title_row1_lv2,
                :style => style_row1_info + style_row1_lv1 + style_row1_total + style_row1_percentile  + style_row1_lv2 
            )

            sheet.add_row(
                title_row2_info + title_row2_lv1 + title_row2_total + title_row2_percentile   + title_row2_lv2,
                :style => style_row1_info + style_row2_lv1 + style_row2_total + style_row2_percentile + style_row2_lv2
            )
            ####### 标题行，指标列, begin #######

            ####### 学生数据行, begin #######
            #数据行


            urls = find_all_pupil_report_urls base_path,ReportWarehousePath,[]
            urls.each{|item|
              rpt_path = base_path + item
              fdata = File.open(rpt_path, 'rb').read
              rpt_json =JSON.parse(fdata)
              rpt_data = rpt_json["data"]

              path_arr = item.split(".json")[0].split("/")
              target_pupil = nil
              target_location = nil
              target_tenant = nil
              Common::Report::Group::ListArr[0..group_index].each{|group|
                group_pos = path_arr.find_index(group)
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
                target_location.head_teacher.blank?? "-" : target_location.head_teacher.name,
                target_location.subject_teacher(target_pap.subject).nil?? "-" : target_location.subject_teacher(target_pap.subject).name,
                target_pupil.name,
                target_pupil.stu_number,
                 Common::Locale::i18n("dict.#{target_pupil.sex}")
              ].flatten

              data_row_lv1 = []
              data_row_total = []
              data_row_percentile = []
              data_row_lv2 = []

              rpt_data.each{|k0,v0| #三维
                rpt_lv1_data = v0["lv_n"].map{|lv1| lv1.values[0]}.flatten
                rpt_lv1_data.each_with_index{|item, index| #一级指标
                  data_row_lv1.push(item["weights_score_average_percent"])
                }

                rpt_lv2_data = rpt_lv1_data.map{|lv1| lv1["items"].map{|lv2| lv2.values[0]} }.flatten
                rpt_lv2_data.each_with_index{|item, index| #二级指标
                  data_row_lv2.push(item["weights_score_average_percent"])
                }

                data_row_total.push(v0["base"]["weights_score_average_percent"])
                percentile_keys = v0["base"].keys.find_all{|a| a.include?("percentile")}
                percentile_keys.size.times{|i| data_row_percentile.push([])} if data_row_percentile.blank?
                percentile_keys.each_with_index{|k, index|
                  data_row_percentile[index].push(v0["base"][k])
                }
              }

              sheet.add_row data_row_info + data_row_lv1 + data_row_total + data_row_percentile.flatten + data_row_lv2   
            }

            ####### 学生数据行, begin #######
          end
          out_path = args[:out]
          out_excel.serialize(out_path)
        end
      else
        puts "Paper not found"
      end
    end

    desc "temporary use: import zhiduoxing json"
    task :import_zhiduoxing_json,[:base_path,:test_name,:test_type,:test_date,:target_path] => :environment do |t, args|
      begin
        if args[:test_name].blank? || args[:test_type].blank? || args[:target_path].blank?
          raise "Command format not correct."
        end

        base_path = args[:base_path].blank?? "" : args[:base_path]

        target_pap = Mongodb::PaperQuestion.new({
          :name => args[:test_name],
          :heading => args[:test_name],
          :quiz_type => args[:test_type],
          :quiz_date => args[:test_date]
        })
        unless target_pap.save
          raise "Mongodb::PaperQuestion save failed"
        end

        target_test = Mongodb::BankTest.new({
          :name => args[:test_name],
          :quiz_type => args[:test_type],
          :quiz_date => args[:test_date],
          :paper_question_id => target_pap._id.to_s
        })
        unless target_test.save
          raise "Mongodb::BankTest save failed"
        end

        # test nav
        url_arr = [
          "#{base_path}",
          "reports_warehouse",
          "tests",
          target_test.id.to_s,
          "project",
          target_test.id.to_s
        ]
        nav_item = [target_test.id.to_s, { :label => target_test.name, :report_url =>  url_arr.join("/") + ".json" }]
        nav_arr = [
          "#{base_path}",
          "reports_warehouse",
          "tests",
          target_test.id.to_s
        ]
        update_nav_json nav_arr.join("/"), "tests", "project", nav_item

        Dir.glob(args[:target_path] + "/*.json").each{|f|
          puts f
          fdata = File.binread(f)
          str = fdata.force_encoding(Encoding::UTF_8)
          jdata = JSON.parse(str)
          json_path = "#{base_path}/reports_warehouse/tests/#{target_test.id.to_s}/project/#{target_test.id.to_s}"
          if jdata["basic"]["tenant"].blank? || jdata["basic"]["grade"].blank? || jdata["basic"]["classroom"].blank? || jdata["basic"]["stu_number"].blank? || jdata["basic"]["name"].blank?
            puts "#{f}, invalid data"
            puts jdata["basic"]
            next
          end

          # tenant
          target_tenant = Tenant.where(name:  Common::Locale::hanzi2pinyin(jdata["basic"]["tenant"].strip) ).first
          unless target_tenant
            puts "#{f}, invalid tenant"
            next
          end
          json_path += "/grade/#{target_tenant.uid}"

          link_params = {
            :bank_test_id => target_test.id.to_s,
            :tenant_uid => target_tenant.uid
          }
          target_link = Mongodb::BankTestTenantLink.where(link_params) 
          if target_link.blank?
            target_link = Mongodb::BankTestTenantLink.new(link_params)
            target_link.save!
          end

          link_params = {
            :bank_test_id => target_test.id.to_s,
            :area_uid => target_tenant.area.uid
          }
          target_link = Mongodb::BankTestAreaLink.where(link_params) 
          if target_link.blank?
            target_link = Mongodb::BankTestAreaLink.new(link_params)
            target_link.save!
          end

          # project nav
          url_arr = [
            "#{base_path}",
            "reports_warehouse",
            "tests",
            target_test.id.to_s,
            "project",
            target_test.id.to_s,
            "grade",
            target_tenant.uid
          ]
          nav_item = [target_tenant.name, { :label => target_tenant.name_cn, :report_url =>  url_arr.join("/") + ".json" }]
          nav_arr = [
            "#{base_path}",
            "reports_warehouse",
            "tests",
            target_test.id.to_s,
            "project",
            target_test.id.to_s
          ]
          update_nav_json nav_arr.join("/"), "project", "grade", nav_item

          # location
          grade = Common::Locale::hanzi2pinyin jdata["basic"]["grade"].strip
          klass = Common::Locale::hanzi2pinyin jdata["basic"]["classroom"].strip
          target_location = target_tenant.locations.where(grade: grade, classroom: klass).order(dt_update: :desc).first
          unless target_location
            puts "#{f}, invalid location"
            next
          end
          json_path += "/klass/#{target_location.uid}"

          link_params = {
            :bank_test_id => target_test.id.to_s,
            :loc_uid => target_location.uid
          }
          target_link = Mongodb::BankTestLocationLink.where(link_params) 
          if target_link.blank?
            target_link = Mongodb::BankTestLocationLink.new(link_params)
            target_link.save!
          end

          # grade nav
          url_arr = [
            "#{base_path}",
            "reports_warehouse",
            "tests",
            target_test.id.to_s,
            "project",
            target_test.id.to_s,
            "grade",
            target_tenant.uid,
            "klass",
            target_location.uid
          ]
          nav_item = [target_location.classroom, { :label => Common::Locale::i18n("dict.#{target_location.classroom}"), :report_url =>  url_arr.join("/") + ".json" }]
          nav_arr = [
            "#{base_path}",
            "reports_warehouse",
            "tests",
            target_test.id.to_s,
            "project",
            target_test.id.to_s,
            "grade",
            target_tenant.uid
          ]
          update_nav_json nav_arr.join("/"), "grade", "klass", nav_item

          # pupil
          user_name = target_tenant.number + jdata["basic"]["stu_number"].strip + Common::Locale.hanzi2abbrev(jdata["basic"]["name"].strip)
          target_user= User.where(name: user_name).first
          unless target_user
            puts "#{f}, invalid pupil: #{user_name}"
            next
          end

          link_params = {
            :bank_test_id => target_test.id.to_s,
            :user_id => target_user.id
          }
          target_link = Mongodb::BankTestUserLink.where(link_params)
          if target_link.blank?
            target_link = Mongodb::BankTestUserLink.new(link_params)
            target_link.save!
          end

          # location nav
          url_arr = [
            "#{base_path}",
            "reports_warehouse",
            "tests",
            target_test.id.to_s,
            "project",
            target_test.id.to_s,
            "grade",
            target_tenant.uid,
            "klass",
            target_location.uid,
            "pupil",
            target_user.role_obj.uid
          ]
          nav_item = [target_user.role_obj.stu_number, { :label => target_user.role_obj.name+"(#{target_user.role_obj.stu_number})", :report_url =>  url_arr.join("/") + ".json" }]
          nav_arr = [
            "#{base_path}",
            "reports_warehouse",
            "tests",
            target_test.id.to_s,
            "project",
            target_test.id.to_s,
            "grade",
            target_tenant.uid,
            "klass",
            target_location.uid
          ]
          update_nav_json nav_arr.join("/"), "klass", "pupil", nav_item

          json_path += "/pupil"
          FileUtils.mkdir_p json_path
          json_path += "/#{target_user.pupil.uid}.json"
          FileUtils.cp f,json_path
        }
      rescue Exception => ex
        target_pap.destroy
        target_test.destroy
        Mongodb::BankTestAreaLink.delete_all(:bank_test_id => target_test.id.to_s)
        Mongodb::BankTestTenantLink.delete_all(:bank_test_id => target_test.id.to_s)
        Mongodb::BankTestLocationLink.delete_all(:bank_test_id => target_test.id.to_s)
        Mongodb::BankTestUserLink.delete_all(:bank_test_id => target_test.id.to_s)
        puts "exception: #{ex.message}"
        puts ex.backtrace
        exit -1
      end

    end


    desc "temporary use: import hyt quiz picture url"
    task :import_hyt_quiz_url,[:report_path,:hyt_file_path] => :environment do |t, args|

      hyt_pupil_items = {}
      hyt_file = Roo::Excelx.new(args[:hyt_file_path])
      hyt_sheet = hyt_file.sheet(hyt_file.sheets[0])
      hyt_row_count = hyt_sheet.count
      hyt_title_row = hyt_sheet.row(1)
      [*2..hyt_row_count].each{|index|
        row_data = hyt_sheet.row(index)        
        temp_arr = []
        row_data[2..-1].each_with_index{|item,i|
          temp_arr << {
            :qzp_order => hyt_title_row[2+i].to_s,
            :image_url => item
          }
        }
        hyt_pupil_items[row_data[0].to_s] = temp_arr
      }

      Find.find(args[:report_path]){|f|
        re = Regexp.new ".*pupil/(.*).json"
        r = re.match(f)
        unless r.blank?
          pup_uid = r[1].to_s
          target_pupil = Pupil.where(uid: pup_uid).first
          target_stu_number = target_pupil.stu_number if target_pupil
          next if hyt_pupil_items[target_stu_number.to_s].blank?
          target_pupil_optional_filename = f.split(".json")[0] + "_hyt_snapshot_data.json"
          File.write(target_pupil_optional_filename, hyt_pupil_items[target_stu_number.to_s].to_json)
        end
      }
    end

    desc "temporary use: import hyt quiz answers"
    task :import_hyt_quiz_answer,[:report_path,:hyt_file_path] => :environment do |t, args|

      hyt_pupil_items = {}
      hyt_file = Roo::Excelx.new(args[:hyt_file_path])
      hyt_sheet = hyt_file.sheet(hyt_file.sheets[0])
      hyt_row_count = hyt_sheet.count
      [*2..hyt_row_count].each{|index|
        row_data = hyt_sheet.row(index)        
        temp_arr = []
        answer_str = row_data[8]
        answer_arr = answer_str.split(",")
        answer_arr.each_with_index{|item,i|
          temp_arr << {
            :qzp_order => (i + 1).to_s,
            :answer => item
          }
        }
        hyt_pupil_items[row_data[0].to_s] = temp_arr
      }

      Find.find(args[:report_path]){|f|
        re = Regexp.new ".*pupil/(.*).json"
        r = re.match(f)
        unless r.blank?
          pup_uid = r[1].to_s
          target_pupil = Pupil.where(uid: pup_uid).first
          target_stu_number = target_pupil.stu_number if target_pupil
          next if hyt_pupil_items[target_stu_number.to_s].blank?
          target_pupil_optional_filename = f.split(".json")[0] + "_hyt_quiz_data.json"
          File.write(target_pupil_optional_filename, hyt_pupil_items[target_stu_number.to_s].to_json)
        end
      }
    end

    def find_all_pupil_report_urls base_path, search_path, urls=[]
      fdata = File.open(search_path + "/nav.json", 'rb').read
      jdata = JSON.parse(fdata)
      jdata.values[0].each{|item|
        current_report_url = item[1]["report_url"]
        next_search_path = base_path + current_report_url.split(".json")[0]
        unless jdata.keys[0].include?("klass")
          urls = find_all_pupil_report_urls base_path, next_search_path, urls
        else
          urls.push(current_report_url)
        end
      }
      return urls
    end

    def update_nav_json nav_path, parent_group, group_type, nav_item
      begin
        FileUtils.mkdir_p(nav_path) unless File.directory?(nav_path)
        nav_json_path = nav_path + "/nav.json"
        if File.exist?(nav_json_path)
          fdata = File.binread(nav_json_path)
          str = fdata.force_encoding(Encoding::UTF_8)
          jdata = JSON.parse(str)

          nav_items_arr = jdata[parent_group]
          unless nav_items_arr.assoc(nav_item[0]).blank?
            return true
          else
            jdata[parent_group] = Common::insert_item_to_arr_with_order(group_type, nav_items_arr, nav_item)
          end        
        else
          jdata = { parent_group => [nav_item]}
        end
        File.write(nav_json_path, jdata.to_json)
      rescue Exception => ex
        puts ex.message
        puts ex.backtrace
        return false
      end
    end

  end
end
