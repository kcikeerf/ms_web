module ApplicationHelper


	def success_notice(message)
		unless message.blank?
			"<div class='alert alert-success' role='alert'>#{flash[:notice]}</div>"
		end
	end

	def error_message(resource, column)
		raw "<small class='help-block'>#{resource.errors[column.to_sym].first}</small>" unless resource.errors[column.to_sym].blank?
	end

  #local i18n abbrev
  def LABEL str
    Common::Locale::i18n(str)
  end

end
