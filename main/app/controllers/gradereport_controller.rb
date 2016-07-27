class GradereportController < ApplicationController
  def index
    params.permit!

    render :layout =>false, :file => "public/gradereport/index"
  end

  def demo
  end
end
