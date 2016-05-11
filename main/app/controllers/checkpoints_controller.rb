class CheckpointsController < ApplicationController
  def get_nodes
    params.permit!
   
    nodes = BankCheckpointCkp.get_ckps   
    render :json => nodes.to_json
  end  
end
