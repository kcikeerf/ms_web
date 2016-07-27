ActiveAdmin.register BankDicItem do


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

  permit_params :sid, :caption, :desc,:bank_dic, :bank_dic_ids => []

  index do
    column :sid
    column :caption
    column :desc
    column :bank_dic
    column :dt_add
    column :dt_update

    actions
  end

=begin
  show do
    attributes_table do
    row :sid
    row :caption
    row :desc
    row :dt_add
    row :dt_update
#    default_main_content
    table_for bank_dic_item.bank_dic do
      column "Parent #{I18n.t 'activerecord.models.bank_dic'}" do |item|
        link_to item, [:admin, item]
      end
    end
    end
  end
=end
  form do |f|
    f.inputs "BankDicItem Detail" do
      f.input :sid
      f.input :caption
      f.input :desc
      f.input :bank_dic, as: :select, collection: BankDic.all.map{|bd| bd.caption}
    end
    f.actions
  end

end
