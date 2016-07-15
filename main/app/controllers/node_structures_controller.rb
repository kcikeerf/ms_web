class NodeStructuresController < ApplicationController

  def get_subjects
    subject_nodes = BankNodestructure.subject_gather
    render json: subject_nodes.to_json
  end

	#select grade params: subject
  def get_grades
    grade_nodes = BankNodestructure.grade_gather(params[:subject])
    render json: grade_nodes.to_json
  end

  #select versions, params: subject, grade
  def get_versions
    versions_nodes = BankNodestructure.version_gather(params[:subject], params[:grade])
    render json: versions_nodes.to_json
  end

  def get_units
  	unit_nodes = BankNodestructure.unit_gather(params[:subject], params[:grade], params[:version])
  	render json: unit_nodes.to_json
  end

  def get_catalogs_and_tree_data
    node = BankNodestructure.find(params[:node_uid])
    ckp_data = BankCheckpointCkp.get_all_ckps(node.id)
    ckp_data[:catalogs] = node.bank_node_catalogs
    render json: ckp_data.to_json
  end

  #根据科目读取指标
  def get_tree_data_by_subject
    subject = params[:subject]
    ckp_data = BankSubjectCheckpointCkp.get_all_ckps(subject)
    render json: ckp_data.to_json
  end

  #获取教材或者目录指标(type为catalog时读取单个目录指标)
  def get_ckp_data_by_volume_catalog
    is_catalog = params[:type] == 'catalog'
    model = is_catalog ? BankNodeCatalog : BankNodestructure

    node = model.find_by(uid: params[:node_uid])
    return render json: {knowledge: [], skill: [], ability: []} unless node

    ckps = node.bank_subject_checkpoint_ckps

    ckps_hash = BankSubjectCheckpointCkp.ckps_group(ckps)
    render json: ckps_hash.to_json
  end

  def get_ckp_data
    node = BankNodestructure.find(params[:node_uid])
    ckp_data = BankCheckpointCkp.get_web_ckps(node.id)
    render json: ckp_data.to_json
  end

  # private

  # def add_root_nodes(nodes, dimesion)
  #   root_node = {id: '', rid: '', checkpoint: I18n.t('managers.root_node'), pid: '', name: I18n.t('managers.root_node'), open: true}
  #   nodes.symbolize_keys!
  #   root_node[:dimesion] = dimesion
  #   nodes[:nodes] << root_node
  #   nodes
  # end

end
