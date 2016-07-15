class PupilsController < ApplicationController
  layout 'user'

  def my_home
    @current_user = current_user
  end

  def my_report

  end
end
