class GradeReportsController < ApplicationController
  layout false
  def index
    params.permit!

    render :file => "public/grade_reports/index"
  end
end
