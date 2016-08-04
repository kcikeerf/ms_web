class PupilsController < ApplicationController
  layout 'user'

  def my_home
    @current_user = current_user
  end

  def my_report
    @papers = current_user.pupil.papers.page(params[:page]).per(Common::Page::PerPage)
  end
end
