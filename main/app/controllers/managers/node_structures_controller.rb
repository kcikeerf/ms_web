class Managers::NodeStructuresController < ApplicationController
  
  layout 'manager_crud', only: [:index]

  respond_to :json, :html
  
  before_action :set_node_structure, only: [:show, :edit, :update, :add_ckps]
  # skip_before_action :authenticate_person!
  # before_action :authenticate_manager

  def index
    @node_structures = BankNodestructure.page(params[:page]).per(params[:rows])
    respond_with({rows: @node_structures, total: @node_structures.total_count}) 
  end

  def create
    @node_structure = BankNodestructure.new(node_structure_params)
    render json: response_json_by_obj(@node_structure.update_node(node_structure_params), @node_structure)
  end

  def show
    @permissions = @node_structure.node_structures_permissions_links.includes(:permission)
    render layout: 'manager'
  end

  def update    
    render json: response_json_by_obj(@node_structure.update_node(node_structure_params), @node_structure)
  end

  def destroy_all
    BankNodestructure.destroy(params[:id])
    respond_with(@node_structure)
  end

  private

    def set_node_structure
      @node_structure = BankNodestructure.find(params[:id])
    end

    def node_structure_params
      params.permit(:version_cn, :grade, :subject, :term)
    end

end
