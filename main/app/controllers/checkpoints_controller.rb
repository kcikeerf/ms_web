class CheckpointsController < ApplicationController
  # def get_nodes
  #   params.permit!
   
  #   @tree_data = BankCheckpointCkp.get_ckps params 
  #   return render partial: '/quizs/point_tree'
  # end

  # 
  # get all nodes count of pid node
  # 
  # def get_node_count
  #   params.permit!

  #   result ={:count => 0}
  #   result[:count] = BankCheckpointCkp.get_ckp_count params
  #   render :json => result.to_json
  # end
  
  #
  # get child nodes of pid node
  #
  # def get_child_nodes
  #   params.permit!

  #   nodes = BankCheckpointCkp.get_child_ckps params
  #   render :json => nodes.to_json
  # end

  #
  # get all child nodes of pid node
  #
  # def get_all_nodes 
  #   params.permit!
    
  #   nodes=BankCheckpointCkp.get_all_ckps params
  #   render :json => nodes.to_json
  # end

  #
  # save current node
  #
  # def save_node
  #   params.permit!

  #   BankCheckpointCkp.save_ckp
    
  # end

  #
  # update current node
  #
  # def update_node
  #   params.permit!

  #   BankCheckpointCkp.update_ckp
  # end

  #
  # delete current node
  # 
  # def delete_node
  #   params.permit!
  
  #   BankCheckpointCkp.delete_ckp
  # end

  def dimesion_tree
    params.permit!
    render :layout => "ztree"
  end

  def get_ckp_type_system
    params.permit!
    ckp_systems = CheckpointSystem.get_system_with_type(params)
    render json: ckp_systems.to_json
  end


  def get_ckp_data
    params.permit!
    ckp_model = BankCheckpointCkp.judge_ckp_source params
    ckp_data = ckp_model.nil?? [] : ckp_model.get_web_ckps(params)
    render json: ckp_data.to_json
  end


  # def get_ckp_data_plus
  #   params.permit!
  #   ckp_model = BankCheckpointCkp.judge_ckp_source params
  #   ckp_data = ckp_model.nil?? [] : ckp_model.get_web_ckps(params)
  #   render json: ckp_data.to_json 
  # end

  #根据科目读取指标
  def get_tree_data_by_subject
    params.permit!

    ckp_data = BankSubjectCheckpointCkp.get_all_ckps(params[:subject], params[:xue_duan])
    render json: ckp_data.to_json
  end

  def get_tree_date_include_checkpoint_system
    params.permit!
    ckp_system = CheckpointSystem.where(rid: params[:ckp_system_rid]).first
    ckp_system_rid = ckp_system.blank? ? "000" : ckp_system.rid
    ckp_data = BankSubjectCheckpointCkp.get_all_ckps_plus(params[:subject], params[:xue_duan], ckp_system_rid)
    render json: ckp_data.to_json      
  end   


end
