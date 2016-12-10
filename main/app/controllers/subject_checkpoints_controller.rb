class SubjectCheckpointsController < ApplicationController
  layout false

  #根据科目读取指标
  def ztree_data_list
    params.permit(:subject, :xue_duan, :diemsion)

    ckp_data = BankSubjectCheckpointCkp.get_all_ckps_by_dimesion(
    	params[:subject], 
    	params[:xue_duan], 
    	params[:dimesion], 
    	nil, 
    	{
    		:disable_no_check => false
    	})
    render json: ckp_data.to_json
  end
end
