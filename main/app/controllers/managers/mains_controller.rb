class Managers::MainsController < ApplicationController
  layout false

  # skip_before_action :authenticate_person!
  # before_action :authenticate_manager

  def index
  	@menus = Manager.left_menus
  end
end
