class ClassreportController < ApplicationController
  def index
    params.permit!

    render :layout=> false, :file => "public/classreport/index"
  end

  def demo
  end
end
