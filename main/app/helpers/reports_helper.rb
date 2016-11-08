module ReportsHelper
  def report_menus_field menus
    return "" if menus.blank?
    data_type = (menus[0][:data_type] == "project")? "grade":menus[0][:data_type]
    str = %Q{
      <ul class="zy-#{data_type}-menu">
    }
    menus.each{|menu|
      menu_str = %Q{
        <li>
          <a href="#" report_url="#{menu[:report_url]}" data_type="#{menu[:data_type]}">
            <span>#{menu[:label]}</span>
            <span class="glyphicon glyphicon-chevron-right" aria-hidden="true"></span>
          </a>
          %{items}
        </li>
      }
      menu_str %= {:items => report_menus_field(menu[:items])}
      str += menu_str
    }
    str += %Q{
      </ul>
    }
    return str
  end
end



      # <ul class="zy-grade-menu">
      #   <li>
      #     <a
      #     href="#"
      #     report_url="<%= @scope_menus[:report_url] %>"
      #     data_type="<%= @scope_menus[:data_type] %>"
      #     >
      #       <span><%= @scope_menus[:label]%></span>
      #       <span class="glyphicon glyphicon-chevron-right" aria-hidden="true"></span>
      #     </a>
      #     <ul class="zy-class-menu">
      #       <% @scope_menus[:items].each do |klass| %>
      #           <li>
      #             <a
      #             report_id="<%= klass[:report_id] %>"
      #             report_name="<%= klass[:report_name] %>"
      #             data_type="<%= klass[:data_type] %>"
      #             grade_report_id="<%= @scope_menus[:report_id] %>"
      #             >
      #               <span><%= klass[:label] %></span>
      #               <span class="glyphicon glyphicon-chevron-right" aria-hidden="true"></span>
      #             </a>
      #             <ul class="zy-student-menu">
      #               <div class="title"><%= LABEL("dict.ge_ren_bao_gao") %></div>
      #               <% klass[:items].each do |pupil| %>
      #                   <li>
      #                     <a
      #                     report_id="<%= pupil[:report_id] %>"
      #                     report_name="<%= pupil[:report_name] %>"
      #                     data_type="<%= pupil[:data_type] %>"
      #                     class_report_id="<%= klass[:report_id] %>"
      #                     grade_report_id="<%= @scope_menus[:report_id] %>"
      #                     >
      #                       <%= pupil[:label] %>
      #                     </a>
      #                   </li>
      #               <% end %>
      #             </ul>
      #       <% end if false %>
      #       </li>
      #     </ul>
      #   </li>
      # </ul>
