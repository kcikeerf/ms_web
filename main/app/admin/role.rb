ActiveAdmin.register Role do


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

  permit_params :name, :desc, :permissions,:permission_ids => []
  form do |f|
     f.inputs "Role Details" do
       f.input :name
       f.input :desc
       f.input :permissions, as: :check_boxes, collection: Permission.all
     end
     f.actions
  end
end
