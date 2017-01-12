class Managers::SubjectCheckpointsController < ApplicationController
	layout false, except: [:index, :list]
  layout 'manager', only: [:index, :list]

  before_action :set_checkpoint, only: [:edit, :update, :destroy, :move_node]
  # skip_before_action :authenticate_person!
  # before_action :authenticate_manager

  def index
    # 学科列表
    @subject_list = Common::Subject::List.map{|k,v| [v,k.to_s]}
    # 学段列表
    @xue_duan_list = Common::Grade::XueDuan::List.map{|k,v| [v,k.to_s]}
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
    # cats = @checkpoint.bank_ckp_cats
    render json: response_json(200)
  end

  def update
    checkpoint =  @checkpoint.update_ckp(checkpoint_params)
    render json: response_json(200, checkpoint)
  end

  def destroy
    params.permit!()
    @checkpoint.destroy if @checkpoint
    render json: response_json(200)
  end

  def destroy_all
    params.permit(:uid, :authenticity_token)

    status = 403
    data = {:status => 403 }

    begin
      target_ckps = BankSubjectCheckpointCkp.where(:uid=> params[:uid])
      target_ckps.destroy_all
      status = 200
      data = {:status => "200"}
    rescue Exception => ex
      status = 500
      data = {:status => 500, :message => ex.message}
    end

    render common_json_response(status, data) 
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

  # 指标文件导入
  def import_ckp_file
    file, @subject, dimesion = params[:file], params[:subject], params[:dimesion]
    file_content = IO.readlines(file.path).join('').gsub(/\n|\s+/, '')
    ckp_hash = JSON.parse(file_content) rescue nil
    @is_ok = ckp_hash && ckp_hash["data"]
    if @is_ok
      BankSubjectCheckpointCkp.generate_ckp(@subject, dimesion, ckp_hash["data"])
    end
    File.delete(file.path)
  end

  # private

  def set_checkpoint
    @checkpoint = BankSubjectCheckpointCkp.find(params[:id])
  end

  def checkpoint_params
    params.permit(
      :id, 
      :subject, 
      :str_pid, 
      :dimesion, 
      :checkpoint,
      :weights,
      :sort, 
      :desc, 
      :advice, 
      :str_uid, 
      :is_entity, 
      :category)
  end

  def select_checked(ckps, uids)
    ckps.each do |ckp|
      ckp.delete(:nocheck)
      ckp[:checked] = true if uids.include?(ckp[:uid])
    end
  end

end
