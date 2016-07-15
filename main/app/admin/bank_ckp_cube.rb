ActiveAdmin.register BankCkpCube do


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

  permit_params :ckp_uid_k, :ckp_uid_s, :ckp_uid_a, :crosstype

  index do
    column :id
    column :ckp_uid_k
    column :ckp_uid_s
    column :ckp_uid_a
    column :crosstype

    actions
  end

  form do |f|
      f.inputs "BankCkpCube Detail" do
      f.input :ckp_uid_k
      f.input :ckp_uid_s
      f.input :ckp_uid_a
      f.input :crosstype
    end
    f.actions
  end

end
