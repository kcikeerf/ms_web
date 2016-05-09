require 'ox'
require 'roo'

namespace :swtk do
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

  desc "read checkpoint data from excel file, rake swtk:reload_checkpoint[<file_path>, {knowledge|skill|ability}]"
  task :read_checkpoint,[:file_path, :sheet_name]=> :environment do |t, args|
    if args[:file_path].nil? || args[:sheet_name].nil?
      puts "Usage: rake swtk:reload_checkpoint[<file_path>, {knowledge|skill|ability}]"
      exit 
    end
    xlsx = Roo::Excelx.new(args[:file_path])
    ckp = args[:sheet_name]
    ckp_sheet = xlsx.sheet(ckp)
    start_line = 5
    total_line = ckp_sheet.count

    subject = ckp_sheet.row(1)[0]
    text_book = ckp_sheet.row(2)[0]
    grade = ckp_sheet.row(3)[0]
    volume = ckp_sheet.row(4)[0]
    level1_max_rid = BankCheckpointCkp.where("rid >= 000 and rid <=999 and length(rid) < 4").select("rid").map{|t| t.rid}.max
    level2_max_rid = 0#BankCheckpointCkp.where("substring(rid,3,5)>= 000 and substring(rid,3,5) <=999 and length(rid) >3 and length(rid) < 7").select("rid").map{|t| t.rid.slice(3,5)}.max
    level3_max_rid = 0#BankCheckpointCkp.where("substring(rid,6,8) >= 000 and substring(rid,6,8) <=999 and length(rid) > 6 and length(rid) < 10").select("rid").map{|t| t.rid.slice(6,8)}.max
    level1_start = level1_max_rid.nil?? 1:level1_max_rid.to_i + 1
    level2_start = 0#level2_max_rid.nil?? 0:level2_max_rid.to_i
    level3_start = 0#level3_max_rid.nil?? 0:level3_max_rid.to_i
    p level1_start,level2_start,level3_start
    h = {}
    (start_line..total_line).each{|x| 
      r = ckp_sheet.row(x)
      h[r[0]]= {} if h[r[0]].nil?
      h[r[0]][r[1]] ={} if h[r[0]][r[1]].nil?
      if h[r[0]][r[1]][r[2]].nil?
        h[r[0]][r[1]][r[2]] = {:desc =>r[3], :unit => r[4]}
      end
    }
    h.keys.each_with_index{|key1, index1|
      level1_rid = (level1_start + index1).to_s.rjust(3,"0")
      ckp_level1= BankCheckpointCkp.new({
         :dimesion => ckp,
         :rid => level1_rid,
         :checkpoint => key1,
         :desc => nil
      })
      ckp_level1.save
      h[key1].keys.each_with_index{|key2, index2|
        level2_rid = level1_rid + (level2_start + index2).to_s.rjust(3, "0")
        ckp_level2 = BankCheckpointCkp.new({
          :dimesion => ckp,
          :rid => level2_rid,
          :checkpoint => key2,
          :desc => nil
        })
        ckp_level2.save
        h[key1][key2].keys.each_with_index{|key3, index3|
          level3_rid = level2_rid + (level3_start + index3).to_s.rjust(3, "0")
          ckp_level3 = BankCheckpointCkp.new({
            :dimesion => ckp,
            :rid => level3_rid,
            :checkpoint => key3,
            :desc => h[key1][key2][key3][:desc]
          })
          ckp_level3.save
          unless h[key1][key2][key3][:unit].nil?
            arr = h[key1][key2][key3][:unit].split("#unit#")
            arr.each{|unit|
              bn = BankNodestructure.where(:subject=> subject, :version=> text_book, :grade=> grade, :volume => volume, :node => unit)
              bn[0].bank_checkpoint_ckps << ckp_level3 unless bn.blank?
            }
          end
        }
      }
    }
    
  end

  desc "import text_book catalog data from excel file, rake swtk:import_catalog[<file_path>, {catalog}]"
  task :import_catalog,[:file_path, :sheet_name]=> :environment do |t, args|
    if args[:file_path].nil? || args[:sheet_name].nil?
      puts "Usage: rake swtk:import_catalog[<file_path>, sheet_name]"
      exit
    end
    xlsx = Roo::Excelx.new(args[:file_path])
    catalog = args[:sheet_name]
    sheet = xlsx.sheet(catalog)
    start_line = 5 # catalog start line
    total_line = sheet.count
    subject = sheet.row(1)[0]
    text_book = sheet.row(2)[0]
    grade = sheet.row(3)[0]
    volume = sheet.row(4)[0]
    (start_line..total_line).each{|i|
      bn = BankNodestructure.new({
        :subject => subject,
        :version => text_book,
        :grade => grade,
        :volume => volume,
        :node => sheet.row(i)[0]
      })
      bn.save
    }
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
