class Managers::MainsController < ApplicationController
  layout false

  def index

  end  

  def navigation
    @navi = Manager.get_all_navi_menus
    render :layout => false
  end
end
