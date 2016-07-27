ActiveAdmin.register BankCheckpointCkp do


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

  permit_params :dimesion, :rid, :checkpoint, :is_entity, :desc, :bank_nodestructures, :bank_nodestructure_ids=>[]

  show do
    attributes_table do
    row :uid
    row :dimesion
    row :rid
    row :checkpoint
    row :is_entity
    row :desc
    row :dt_add
    row :dt_update
    table_for bank_checkpoint_ckp.bank_nodestructures.order('dt_add ASC') do
      column 'Related BankNodestructures' do |item|
        link_to "#{item.subject} > #{item.version} > #{item.grade} > #{item.rid}  > #{item.node}" , [:admin, item]
      end
    end
    end
  end

  form do |f|
      f.inputs "BankCheckpointCkp Detail" do
      f.input :dimesion
      f.input :rid
      f.input :checkpoint
      f.input :is_entity
      f.input :desc
      f.input :bank_nodestructures, as: :check_boxes, colletion: BankNodestructure.all.map{|bn| bn.uid + '>' + bn.node}
    end
    f.actions
  end

end
