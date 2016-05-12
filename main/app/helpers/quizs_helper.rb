module QuizsHelper

	def organization_tree(data, is_children=false)
		return '' unless data
		html = ''
		if is_children
			html << '
				<li>
					<span><label class="checkbox-inline"><input type="checkbox" id="inlineCheckbox2" uid="' + data['uid'] +' " value="' + data['rid'] + '"> ' + data['checkpoint'] + '</label></span>
				</li>
			' 
		else
			data.keys.each do |first_key|
				need_data = data[first_key]
				is_entity = need_data['is_entity']

				html << '
					<li class="parent_li">
						<span title="Expand this branch"><i class="icon-plus-sign"></i> ' + need_data['checkpoint'] +'</span>
					<ul>
				' unless is_entity
				html << organization_tree(is_entity ? need_data : need_data['children'], is_entity) 
							
				html << '</ul></li>' unless is_entity
				
			end			
		end
		html
	end

end
