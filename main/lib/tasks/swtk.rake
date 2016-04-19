require 'ox'

namespace :swtk do
  desc "load permissions definition"
  task load_permissions: :environment do
    xml_str = ""
    xml_file = File.open("lib/tasks/permissions.xml", "r")
    xml_file.each do |line|
      xml_str += line.chomp!
    end
    p xml_str
    xml = Ox.parse(xml_str)

    if xml
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

    p Permission.all

  end

end
