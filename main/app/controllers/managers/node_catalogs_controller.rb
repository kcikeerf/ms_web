class Managers::NodeCatalogsController < ApplicationController
  layout 'manager_crud'

  respond_to :json, :html

  before_action :set_node_structure , only: [:index, :new, :create, :destroy_all]
  before_action :set_catalog, only: [:update, :add_ckps]
    # skip_before_action :authenticate_person!
    # before_action :authenticate_manager

  def index
    arr = [
      @node_structure.version_cn,
      @node_structure.subject_cn,
      @node_structure.grade_cn,
      @node_structure.term_cn,
    ]
    @data = {name: "#{arr.join("_")}的目录", path: "/managers/node_structures/#{@node_structure.id}/node_catalogs"}
    @catalogs = @node_structure.bank_node_catalogs.page(params[:page]).per(params[:row])
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
    total_count = @catalogs.total_count
    @catalogs = @catalogs.sort{|a,b| Common::CheckpointCkp.compare_rid_plus(a["rid"], b["rid"]) }
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
    params.permit(:node_structure_id, :former_rid, :later_rid, :node)
  end
end
