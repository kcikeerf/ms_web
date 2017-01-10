class WelcomesController < ApplicationController
	def index; end

	def about_us; end

	def contact_us; end

	def error_404
		render 'errors/error_404', status: 404,  layout: 'error'
	end
	
end
