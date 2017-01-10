class ErrorsController < ApplicationController
  def error_404
    render :status => 404, :formats =>[:html], :layout => "errors"
  end

  def error_500
    render :status => 500, :formats =>[:html], :layout => "errors"
  end
end
