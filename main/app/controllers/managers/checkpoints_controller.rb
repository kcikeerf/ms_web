# -*- coding: UTF-8 -*-

class Managers::CheckpointsController < ApplicationController
  layout false
  layout 'manager', only: [:index]
  
  def index

  end

  def combine_node_catalogs_subject_checkpoints
    params.permit(:node_uid, :catalogs =>[], :subject_checkpoints => [])
    
  end
end
