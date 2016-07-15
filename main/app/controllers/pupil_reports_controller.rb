class PupilReportsController < ApplicationController
  layout false
  def index
    params.permit!

    render :file => "public/pupil_reports/index"
  end
end
