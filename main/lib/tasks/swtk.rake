require 'ox'
require 'roo'

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
        ckp = BankCheckpointCkp.new({:node_uid => args[:node_uid].strip,
          :dimesion => args[:dimesion].strip,
          :rid=>arr[0],
          :checkpoint => arr[1],
          :advice => "建议",
          #:weights =>
          :is_entity => true})
        ckp.save
      end
    end

    ckps = BankCheckpointCkp.where(node_uid: args[:node_uid])
    ckps.each_with_index{|ckp,index|
#      result = BankRid.get_all_higher_nodes ckps,ckp
#      if result.empty?
        p index
        BankRid.update_ancestors(ckps,ckp,{:is_entity => false})
     # else
 #       ckp.update(:is_entity => true)
      #end
    }

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
