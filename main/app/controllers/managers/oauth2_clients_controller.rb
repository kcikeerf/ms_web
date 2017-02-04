class Managers::Oauth2ClientsController < ApplicationController
  layout 'manager_crud'

  respond_to :json, :html

  before_action :set_oauth2_client , except: [:index]

  def index
    oauth2_clients = Oauth2::Client.order(updated_at: :desc).page(params[:page]).per(params[:rows])
    @oauth2_clients = Kaminari.paginate_array(oauth2_clients.map{|item| itemh = item.attributes; itemh["id"] = item.id.to_s; itemh}).page(params[:page]).per(params[:rows])
    respond_with({rows: @oauth2_clients, total: @oauth2_clients.total_count})
  end

  def create
    @oauth2_client = Oauth2::Client.new(oauth2_client_params)
    render json: response_json_by_obj(@oauth2_client.save, @oauth2_client)
  end

  def update
    render json: response_json_by_obj(@oauth2_client.update(oauth2_client_params), @oauth2_client)
  end

  def destroy_all
    ids = params.permit(:id => [])["id"]
    Oauth2::Client.destroy_all(_id: {"$in" => ids})
    render json: params.permit(:id => []).to_json
  end

  private

    def set_oauth2_client
      @oauth2_client = Oauth2::Client.where(_id: params[:id]).first
    end

    def oauth2_client_params
      paramsh = params.permit(:name, :secret_code, :machine_code, :scope)
      paramsh[:scope] = paramsh[:scope].split(",")
      paramsh
    end

end
