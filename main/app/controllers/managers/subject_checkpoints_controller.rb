class Managers::SubjectCheckpointsController < ApplicationController
	layout false, except: [:index, :list]
  layout 'manager', only: [:index, :list]

  before_action :set_checkpoint, only: [:edit, :update, :destroy, :move_node]

  def index
    @subjects = BankDicQuizSubject.pluck(:desc, :subject)
  end

  def create
    checkpoint =  BankSubjectCheckpointCkp.save_ckp(checkpoint_params)
    
    render json: response_json(200, checkpoint)
  end

  def list
    @subject = params[:subject]
    @node_structure_uid = params[:node_structure_uid]
    @node_catalog_uid = params[:node_catalog_uid]
  end

  def edit    
    cats = @checkpoint.bank_ckp_cats
    render json: response_json(200, cats)
  end

  def update
    checkpoint =  @checkpoint.update_ckp(checkpoint_params)
    render json: response_json(200, checkpoint)
  end

  def destroy
    @checkpoint.destroy if @checkpoint
    render json: response_json(200)
  end

  def move_node
    checkpoint = @checkpoint.move_node(params[:str_pid])
    status, message = checkpoint ? 200 : 500, checkpoint ? '' : {message: '不能把本节点拖拽到此节点'}
    render json: response_json(checkpoint ? 200 : 500, message)
  end

  #获取科目指标和教材指标
  def get_subject_volume_ckps
    subject, node_structure_uid = params[:subject], params[:node_structure_uid]

    ckp_data = BankSubjectCheckpointCkp.get_all_ckps(subject)

    node_structure = BankNodestructure.find(node_structure_uid)
    had_subject_uids = node_structure.bank_nodestructure_subject_ckps.pluck(:subject_ckp_uid)
    
    render json: {knowledge: select_checked(ckp_data[:knowledge][:nodes], had_subject_uids), skill: select_checked(ckp_data[:skill][:nodes], had_subject_uids), ability: select_checked(ckp_data[:ability][:nodes], had_subject_uids)}.to_json
  end

  #获取教材指标和目录指标
  def get_volume_catalog_ckps
    node_structure_uid, node_catalog_uid =  params[:node_structure_uid], params[:node_catalog_uid]

    node_structure = BankNodestructure.find(node_structure_uid)
    ckps = node_structure.bank_subject_checkpoint_ckps

    node_catalog = BankNodeCatalog.find(node_catalog_uid)
    had_subject_uids = node_catalog.bank_node_catalog_subject_ckps.pluck(:subject_ckp_uid)
    
    ckps_hash = BankSubjectCheckpointCkp.ckps_group(ckps, had_subject_uids)

    render json: ckps_hash.to_json
  end

  # private

  def set_checkpoint
    @checkpoint = BankSubjectCheckpointCkp.find(params[:id])
  end

  def checkpoint_params
    params.permit(:id, :subject, :str_pid, :dimesion, :checkpoint, :desc, :advice, :str_uid, :is_entity)
  end

  def select_checked(ckps, uids)
    ckps.each {|c| c[:checked] = true if uids.include?(c[:uid]) }
  end

end