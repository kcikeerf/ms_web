# -*- coding: UTF-8 -*-

class Managers::CheckpointsController < ApplicationController
  layout false
  layout 'manager', only: [:index, :tree]
  
  def index
  end

  def tree
  	params.permit!
    @target_catalog = BankNodeCatalog.where(:uid => params[:node_catalog_id]).first
    @target_node = BankNodestructure.where(:uid => params[:node_structure_id]).first
  	@tree_nodes = BankCheckpointCkp.node_catalog_checkpoints params
  end

  def list
    params.permit!
    result = BankCheckpointCkp.catalogs_checkpoints params
    render :json => result.to_json
  end

  def combine_node_catalogs_subject_checkpoints
    params.permit!#(:node_uid, :catalogs, :checkpoints)

    BankCheckpointCkp.combine_node_catalogs_subject_checkpoints params
    target_node = BankNodestructure.where(:uid => params[:node_uid]).first
    render :json => target_node.bank_nodestructure_subject_ckps.to_json
  end
end
