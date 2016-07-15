ActiveAdmin.register BankCkpComment do


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
  
  permit_params :uid, :target, :template, :bank_checkpoint_ckp

  index do
    column :uid
    column :target
    column :template
    column :bank_checkpoint_ckp
    column :dt_add
    column :dt_update

    actions
  end
 
  form do |f|
      f.inputs "BankCkpComment Detail" do
      f.input :uid
      f.input :target
      f.input :template
      f.input :bank_checkpoint_ckp, as: :select, collection: BankCheckpointCkp.all.map{|bcc| bcc.checkpoint}
    end
    f.actions
  end  

end
