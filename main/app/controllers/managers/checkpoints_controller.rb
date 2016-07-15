class Managers::CheckpointsController < ApplicationController
  layout false, except: [:index]
  layout 'manager', only: [:index]

  before_action :set_checkpoint, only: [:edit, :update, :destroy, :move_node]

  def index
    @subjects = deal_label('dict.', BankNodestructure.pluck(:subject).uniq)
  end

  def create
    checkpoint =  BankCheckpointCkp.save_ckp(checkpoint_params)
    
    render json: response_json(200, checkpoint)
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

  private

  def set_checkpoint
    @checkpoint = BankCheckpointCkp.find(params[:id])
  end

  def checkpoint_params
    params.permit(:id, :node_uid, :str_pid, :dimesion, :checkpoint, :desc, :advice, :str_uid, :is_entity, cats: [:cat_uid])
  end
end
