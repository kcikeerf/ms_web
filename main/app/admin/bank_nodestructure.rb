ActiveAdmin.register BankNodestructure do


  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # permit_params :list, :of, :attributes, :on, :model
  #
  # or
  #
  # permit_params do
  #   permitted = [:permitted, :attributes]
  #   permitted << :other if resource.something?
  #   permitted
  # end
  permit_params :subject, :version, :grade, :rid, :node, :bank_checkpoint_ckps, :bank_checkpoint_ckp_ids=>[]

  show do
    attributes_table do
    row :uid
    row :subject
    row :version
    row :grade
    row :rid
    row :node
    row :dt_add
    row :dt_update
    table_for bank_nodestructure.bank_checkpoint_ckps.order('dt_add ASC') do
      column 'Related BankCheckpointCkps' do |item|
        link_to "#{item.dimesion} > #{item.rid} > #{item.checkpoint} > #{item.is_entity}" , [:admin, item]
      end
    end
    end
  end

  form do |f|
      f.inputs "BankNodestructure Detail" do
      f.input :subject
      f.input :version
      f.input :grade
      f.input :rid
      f.input :node
      f.input :bank_checkpoint_ckps, as: :check_boxes, colletion: BankCheckpointCkp.all.map{|bcc| bcc.uid.to_s + '>' + bcc.checkpoint.to_s}
    end
    f.actions
  end

end
