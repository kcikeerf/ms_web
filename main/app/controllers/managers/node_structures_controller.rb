class Managers::NodeStructuresController < ApplicationController
  layout 'manager_crud'

  respond_to :json, :html
  
  before_action :set_node_structure, only: [:show, :edit, :update, :add_ckps]
  # skip_before_action :authenticate_person!
  # before_action :authenticate_manager

  def index
    @data = {name: '教材', path: '/managers/node_structures'}
    @node_structures = BankNodestructure.page(params[:page]).per(params[:rows])
    respond_with({rows: @node_structures, total: @node_structures.total_count}) 
  end

  def create
    @node_structure = BankNodestructure.new(node_structure_params)
    render json: response_json_by_obj(@node_structure.save, @node_structure)
  end

  def show
    @permissions = @node_structure.node_structures_permissions_links.includes(:permission)
    render layout: 'manager'
  end

  def update    
    render json: response_json_by_obj(@node_structure.update(node_structure_params), @node_structure)
  end

  def destroy_all
    BankNodestructure.destroy(params[:id])
    respond_with(@node_structure)
  end

  def add_ckps
    ckps = @node_structure.add_ckps(params[:subject_checkpoint_ckp_uids])
    render json: response_json_by_obj(@node_structure.errors.empty?, @node_structure)
  end

  private

  def set_node_structure
    @node_structure = BankNodestructure.find(params[:id])
  end

  def node_structure_params
    params.permit(:grade, :subject, :version, :volume)
  end


end
