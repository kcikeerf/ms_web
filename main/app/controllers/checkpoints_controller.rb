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

  def get_ckp_data
    params.permit!
    ckp_model = BankCheckpointCkp.judge_ckp_source params
    ckp_data = ckp_model.nil?? [] : ckp_model.get_web_ckps(params)
    render json: ckp_data.to_json
  end

  #根据科目读取指标
  def get_tree_data_by_subject
    params.permit!

    ckp_data = BankSubjectCheckpointCkp.get_all_ckps(params[:subject], params[:xue_duan])
    render json: ckp_data.to_json
  end

end
