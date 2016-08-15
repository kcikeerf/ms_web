class CreateAreas < ActiveRecord::Migration
  def change
    create_table :areas,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :rid
      t.string :area_type
      t.string :name
      t.string :name_cn
      t.string :comment

      t.datetime :dt_add
      t.datetime :dt_update
    end

    Common::Area::CountryRids.each{|k,v|
      a = Area.new({
        :rid => v, 
        :area_type => "country",
        :name => k,
        :name_cn => I18n.t("area.#{k}"),
        :comment => I18n.t("area.#{k}")
      })
      a.save!
    }
  end
end
