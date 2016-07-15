class ClassReportsController < ApplicationController
  layout false
  def index
    params.permit!

    render :file => "public/class_reports/index"
  end
end
