class Manager < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def self.get_all_navi_menus
    result = {"nodes" =>[]}
    
    # Level1: Node Structure 
    result["nodes"] << { 
      "id" => "000",
      "rid" => "000",
      "pid" => "",
      "name" => I18n.t("managers.node_structure"),
      "file" => ""
    }

    # Level1: Checkpoint
    result["nodes"] << { 
      "id" => "001",
      "rid" => "001",
      "pid" => "",
      "name" => I18n.t("managers.checkpoint"),
      "file" => "/managers/checkpoints/"
    }
    return result
  end
end
