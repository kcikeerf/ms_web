class ProjectAdministratorsController < ApplicationController
  layout 'new_user'

  before_action :authenticate_user!
 
  def my_home

  end
end
