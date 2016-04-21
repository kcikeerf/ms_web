ActiveAdmin.register BankDic do


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

  permit_params :sid, :caption, :desc, :bank_dic_items, :bank_dic_item_ids => []

  index do
    column :sid
    column :caption
    column :desc
#    column :bank_dic_items
    column :dt_add
    column :dt_update

    actions
  end

  show do
    attributes_table do
    row :sid
    row :caption
    row :desc
    table_for bank_dic.bank_dic_items.order('caption ASC') do
      column 'Related BankDicItems' do |item|
        link_to item.sid, [:admin, item]
      end
    end
    end
  end

  form do |f|
      f.inputs "BankDic Detail" do
      f.input :sid
      f.input :caption
      f.input :desc
      #f.input :bank_dic_items, as: :check_boxes, collection: BankDicItem.all.map{|bdi| bdi.sid}
      f.input :bank_dic_items, as: :check_boxes, collection: BankDicItem.all.map{|bdi| bdi.sid }
    end
    f.actions
  end

end
