class TeachersController < ApplicationController
  layout 'user'

  def my_home
    @current_user = current_user
  end

  def my_pupil

  end

  def test_report

  end

  private

  def teacher_params
  	params.require(:teacher).permit()
  end

end
