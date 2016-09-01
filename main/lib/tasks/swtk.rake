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
  desc "import checkpoints, temporary use"
  task :read_checkpoint,[:file_path,:node_uid,:dimesion]=> :environment do |t, args|
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
        next if arr[0].blank?
        ckp = BankCheckpointCkp.new({:node_uid => args[:node_uid].strip,
          :dimesion => args[:dimesion].strip,
          :rid=>arr[0],
          :checkpoint => arr[1..arr_len-2].join(","),
          :advice => "建议",
          :weights => arr[-1].nil?? 1:arr[-1],
          :sort => arr[0],
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
        Mongodb::BankQizpointScore.where({:pap_uid => args[:pap_uid]})
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

    ckp_objs = BankCheckpointCkp.where(node_uid: target_pap.node_uid)
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

  desc "export paper score"
  task :export_paper_score,[:pap_uid,:out]=> :environment do |t, args|

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
end
