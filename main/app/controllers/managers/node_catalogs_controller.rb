class Managers::NodeCatalogsController < ApplicationController
	layout 'manager_crud'

	respond_to :json, :html

	before_action :set_node_structure , only: [:index, :new, :create, :destroy_all]
	before_action :set_catalog, only: [:update, :add_ckps]
    skip_before_action :authenticate_person!
    before_action :authenticate_manager

	def index
		@data = {name: '目录', path: "/managers/node_structures/#{@node_structure.id}/node_catalogs"}
		@catalogs = @node_structure.bank_node_catalogs.page(params[:page]).per(params[:row])
		respond_with({rows: @catalogs, total: @catalogs.total_count})
	end

	def create
		@node_structure.bank_node_catalogs.build(catalog_params[:node_structrue])
		render json: response_json_by_obj(@node_structure.save, @node_structure)
	end

	def update
    render json: response_json_by_obj(@catalog.update(node: params[:node]), @catalog)
	end

	def destroy_all
		@catalogs= BankNodeCatalog.find(params[:id])
		@node_structure.bank_node_catalogs.destroy(@catalogs)
		respond_with(@node_structure, @catalog)
	end

	def add_ckps
    ckps = @catalog.add_ckps(params[:subject_checkpoint_ckp_uids])
    render json: response_json_by_obj(@catalog.errors.empty?, @catalog)
  end

	private

	def set_node_structure
		@node_structure = BankNodestructure.find(params[:node_structure_id])
	end

	def set_catalog
		@catalog = BankNodeCatalog.find(params[:id])
	end

	def catalog_params
		params.permit(:node_structure_id, node_structrue: [:node])
	end
end
