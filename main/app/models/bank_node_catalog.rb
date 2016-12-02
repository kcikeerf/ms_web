class BankNodeCatalog < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :bank_nodestructure, foreign_key: "node_uid"
  has_many :bank_ckp_cats, foreign_key: "cat_uid"
  has_many :bank_checkpoint_ckps, through: :bank_ckp_cats

  has_many :bank_node_catalog_subject_ckps, foreign_key: 'node_catalog_uid'
  has_many :bank_subject_checkpoint_ckps, through: :bank_node_catalog_subject_ckps

  validates :node, presence: true

  scope :by_node, ->(uid){ where(node_uid: uid) if uid.present? }

  def update_catalog params
    self.update(catalog_params(params))
    self.save!
  end

  def catalog_params params
    catalogs = self.class.by_node(params[:node_structure_id])
    {
      :node_uid => params[:node_structure_id], 
      :node => params[:node],
      :rid => BankRid.get_next_rid(catalogs, params[:former_rid], params[:later_rid])
    }
  end

  def add_ckps(ckps)
    transaction do 
      bank_node_catalog_subject_ckps.destroy_all
      ckp_arr = [].tap do |arr|
        ckps.each {|ckp| arr << {subject_ckp_uid: ckp} }
      end
      bank_node_catalog_subject_ckps.create(ckp_arr)
    end
  end
end
