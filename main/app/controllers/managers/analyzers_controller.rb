class Managers::AnalyzersController < ApplicationController

  layout 'manager_crud'

  respond_to :json, :html

  before_action :get_user, only: [:edit, :update]

  def index
    @data = {name: 'user(学校)', path: '/managers/users'}
    @users = User.page(params[:page]).per(params[:rows])
    respond_with({rows: @users, total: @users.total_count}) 
  end

  def create
  	render json: response_json_by_obj(User.save_user(user_params), @user)
  end

  def update
  	@user.update(user_params)
  	render json: response_json_by_obj(@user.update(user_params), @user)
  end

  def destroy_all
  	User.destroy(params[:id])
  	respond_with(@user)
  end

  private
  def get_user
    @user = user.where("uid = ? ", params[:id]).first
  end

  def user_params
    params.permit(:name, :school_type, :moto, :address, :build_at,:phone, :email, :web, :comment)
  end

end
