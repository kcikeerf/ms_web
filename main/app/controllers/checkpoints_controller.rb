class CheckpointsController < ApplicationController
  def get_nodes
    params.permit!
   
    @tree_data = BankCheckpointCkp.get_ckps   
    return render partial: '/quizs/point_tree'
  end  
end
