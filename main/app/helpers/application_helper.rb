module ApplicationHelper


	def success_notice(message)
		unless message.blank?
			"<div class='alert alert-success' role='alert'>#{flash[:notice]}</div>"
		end
	end
end
