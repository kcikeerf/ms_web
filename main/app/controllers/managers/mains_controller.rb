class Managers::MainsController < ApplicationController
  layout false

  def index
  	@menus = Manager.left_menus
  end  

end
