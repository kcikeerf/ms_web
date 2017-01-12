class Managers::RolePermissionsController < ApplicationController

	respond_to :json, :html

	layout 'manager'

	before_action :set_role , only: [:new, :create, :destroy]
    # skip_before_action :authenticate_person!
    # before_action :authenticate_manager
    
	def new
		@permissions = Permission.all.to_a
		role_had_premissions = @role.roles_permissions_links.pluck(:permission_id)
		@permissions.delete_if {|p| role_had_premissions.include?(p.id) }
	end

	def create
		@role.roles_permissions_links.create(permission_params[:permission])
		redirect_to managers_role_path(@role)
	end

	def destroy
		@role_permission = RolesPermissionsLink.find(params[:id])
		@role.roles_permissions_links.destroy(@role_permission)
	end

	private

	def set_role
		@role = Role.find(params[:role_id])
	end

	def permission_params
		params.permit(:role_id, permission: [:permission_id])
	end
end
