ActiveAdmin.register BankPapertagPtg do


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

  permit_params :sid

  form do |f|
      f.inputs "BankQuiztagQtg Detail" do
      f.input :sid
    end
    f.actions
  end

end
