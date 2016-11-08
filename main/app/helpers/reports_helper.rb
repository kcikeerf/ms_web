module ReportsHelper
  def report_menus_field menus
    return "" if menus.blank?
    menu_panel_title = ""
    case menus[0][:data_type]
    when "project"
      data_type = "project"
      menu_panel_title = %Q{
        <div class="title">#{LABEL("dict.xiang_mu_bao_gao")}</div>        
      }
    when "grade"
      data_type = "grade"
      menu_panel_title = %Q{
        <div class="title">#{LABEL("dict.nian_ji_bao_gao")}</div>        
      } 
    when "klass"
      data_type = "class"
      menu_panel_title = %Q{
        <div class="title">#{LABEL("dict.ban_ji_bao_gao")}</div>        
      } 
    when "pupil"
      data_type = "student"
      menu_panel_title = %Q{
        <div class="title">#{LABEL("dict.ge_ren_bao_gao")}</div>        
      } 
    else
      data_type= menus[0][:data_type]
    end
    # str = %Q{
    #   <ul class="zy-#{data_type}-menu">
    #   #{menu_panel_title}
    # }
    str = %Q{
      <ul class="zy-report-menu">
      #{menu_panel_title}
    }
    menus.each{|menu|
      inner_a = %Q{
        <span title="#{menu[:label]}">#{abbrev_menu_label menu[:label]}</span>
        <span class="glyphicon glyphicon-chevron-right" aria-hidden="true"></span>          
      }
      if menu[:data_type] == "pupil"
        inner_a = %Q{
          #{abbrev_menu_label menu[:label]}
        }
      end

      menu_str = %Q{
        <li>
          <a href="#" report_url="#{menu[:report_url]}" data_type="#{menu[:data_type]}">
          %{inner_a}
          </a>
          %{items}
        </li>
      }
      menu_str %= {
        :inner_a => inner_a,
        :items => report_menus_field(menu[:items])
      }
      str += menu_str
    }
    str += %Q{
      </ul>
    }
    return str
  end

  def abbrev_menu_label str
    ( str.size >7 )? str[0..7] + "..." : str
  end
end