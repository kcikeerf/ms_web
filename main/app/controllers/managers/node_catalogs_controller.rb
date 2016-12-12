class Managers::NodeCatalogsController < ApplicationController
  
  layout 'manager_crud'

  respond_to :json, :html

  before_action :set_node_structure , only: [:index, :new, :create, :destroy_all]
  before_action :set_catalog, only: [:update, :add_ckps]
    # skip_before_action :authenticate_person!
    # before_action :authenticate_manager

  def index
    @catalogs = @node_structure.bank_node_catalogs#.page(params[:page]).per(params[:row])
    @catalogs_options = @node_structure.bank_node_catalogs.map{|item| {"rid" => item.rid}}.sort{|a,b| Common::CheckpointCkp.compare_rid_plus(a["rid"], b["rid"]) }
    # @catalogs.each_with_index{|item, index|
    #   rid = item.rid.nil?? "":item.rid
    #   re =Regexp.new(".{#{Common::SwtkConstants::CkpStep}}")
    #   rid_arr = rid.scan(re)
    #   section_arr = rid_arr#.map{|item| item.gsub!(/(^0*)|(0*$)/,'')}
    #   attr_h = item.attributes
    #   attr_h["section"] = section_arr.join(".")
    #   @catalogs[index] = attr_h#OpenStruct.new(attr_h)
    # }
    total_count = @catalogs.count
    @catalogs = Kaminari.paginate_array(@catalogs.sort{|a,b| Common::CheckpointCkp.compare_rid_plus(a.rid, b.rid) }).page(params[:page]).per(params[:rows])
    respond_with({rows: @catalogs, total: total_count})
  end

  def create
    @catalog = BankNodeCatalog.new
    render json: response_json_by_obj(@catalog.update_catalog(catalog_params), @catalog)
  end

  def update
    render json: response_json_by_obj(@catalog.update_catalog(catalog_params), @catalog)
  end

  def destroy_all
    @catalogs= BankNodeCatalog.find(params[:id])
    @node_structure.bank_node_catalogs.destroy(@catalogs)
    respond_with(@node_structure, @catalog)
  end

  private

    def set_node_structure
      @node_structure = BankNodestructure.find(params[:node_structure_id])
    end

    def set_catalog
      @catalog = BankNodeCatalog.find(params[:id])
    end

    def catalog_params
      params.permit(:node_structure_id, :former_rid, :later_rid, :node, :page, :rows)
    end
end
