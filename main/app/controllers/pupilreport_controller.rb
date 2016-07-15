class PupilreportController < ApplicationController
  def index
    params.permit!

    render :layout => false, :file => "public/pupilreport/index"
  end

  def demo
  end
end
