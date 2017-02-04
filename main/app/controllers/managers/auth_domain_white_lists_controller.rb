class Managers::AuthDomainWhiteListsController < ApplicationController

  layout 'manager_crud'

  respond_to :json, :html

  before_action :set_white_domain , except: [:index]

  def index
    white_domain = AuthWl::DomainWhiteList.only(:domain).order(domain: :asc).page(params[:page]).per(params[:rows])
    @white_domain = Kaminari.paginate_array(white_domain.map{|item| itemh = item.attributes; itemh["id"] = item.id.to_s; itemh}).page(params[:page]).per(params[:rows])
    respond_with({rows: @white_domain, total: @white_domain.total_count})
  end

  def create
    @white_domain = AuthWl::DomainWhiteList.new(white_domain_params)
    render json: response_json_by_obj(@white_domain.save, @white_domain)
  end

  def update
    render json: response_json_by_obj(@white_domain.update(white_domain_params), @white_domain)
  end

  def destroy_all
    ids = params.permit(:id => [])["id"]
    AuthWl::DomainWhiteList.destroy_all(_id: {"$in" => ids})
    render json: params.permit(:id => []).to_json
  end

  private

    def set_white_domain
      @white_domain = AuthWl::DomainWhiteList.where(_id: params[:id]).first
    end

    def white_domain_params
      params.permit(:domain, :description)
    end

end
