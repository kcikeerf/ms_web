# -*- coding: UTF-8 -*-

class Managers::CheckpointsController < ApplicationController
  layout false
  layout 'manager', only: [:index]

  # before_action :set_node_structure , only: [:new, :create, :destroy_all]
  # before_action :set_checkpoint, only: [:edit, :update, :destroy, :move_node]
  # skip_before_action :authenticate_person!
  # before_action :authenticate_manager
  
  def index
  end

  def tree
    render :text => "123"
  end

  # def create
  #   checkpoint =  BankCheckpointCkp.save_ckp(checkpoint_params)
    
  #   render json: response_json(200, checkpoint)
  # end

  # def edit    
  #   cats = @checkpoint.bank_ckp_cats
  #   render json: response_json(200, cats)
  # end

  # def update
  #   checkpoint =  @checkpoint.update_ckp(checkpoint_params)
  #   render json: response_json(200, checkpoint)
  # end

  # def destroy
  #   @checkpoint.destroy if @checkpoint
  #   render json: response_json(200)
  # end

  # def move_node
  #   checkpoint = @checkpoint.move_node(params[:str_pid])
  #   status, message = checkpoint ? 200 : 500, checkpoint ? '' : {message: '不能把本节点拖拽到此节点'}
  #   render json: response_json(checkpoint ? 200 : 500, message)
  # end

  # # 指标文件导入
  # def import_ckp_file
  #   file, node_uid, dimesion = params[:file], params[:node_uid], params[:dimesion]
  #   file_content = IO.readlines(file.path).join('').gsub(/\n|\s+/, '')
  #   ckp_hash = JSON.parse(file_content) rescue nil
  #   @is_ok = ckp_hash && ckp_hash["data"]
  #   if @is_ok
  #     BankCheckpointCkp.generate_ckp(node_uid, dimesion, ckp_hash["data"])
  #   end
  #   File.delete(file.path)
  # end



  private
    # def set_node_structure
    #   @node_structure = BankNodestructure.where(uid: params[:node_structure_id]).first
    # end

    # def set_checkpoint
    #   @checkpoint = BankCheckpointCkp.where(uid: params[:uid]).first
    # end

    # def checkpoint_params
    #   params.permit(:uid, :node_uid, :str_pid, :dimesion, :checkpoint, :sort, :desc, :advice, :str_uid, :is_entity, cats: [:cat_uid])
    # end
end
