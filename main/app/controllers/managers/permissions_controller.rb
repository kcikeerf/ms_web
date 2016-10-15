class Managers::PermissionsController < ApplicationController

	respond_to :json, :html

	layout 'manager_crud'

	before_action :set_permission, only: [:edit, :update]
    # skip_before_action :authenticate_person!
    # before_action :authenticate_manager

	def index
		#@data = {name: '权限', path: '/managers/permissions'}
		@permissions = Permission.page(params[:page]).per(params[:rows])
		respond_with({rows: @permissions, total: @permissions.total_count}) 
	end

	def create
		@permission = Permission.new(permission_params)
		render json: response_json_by_obj(@permission.save, @permission)
	end

	def update
		@permission.update(permission_params)
		render json: response_json_by_obj(@permission.update(permission_params), @permission)
	end

	def destroy_all
		Permission.destroy(params[:id])
		respond_with(@permission)
	end

	private

	def set_permission
		@permission = Permission.find(params[:id])
	end

	def permission_params
		params.permit(:name, :subject_class, :action, :description)
	end
end
