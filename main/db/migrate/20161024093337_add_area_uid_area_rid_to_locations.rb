class AddAreaUidAreaRidToLocations < ActiveRecord::Migration
  def up
    change_table :locations do |t|
      t.column :area_uid, :string
      t.column :area_rid, :string
    end

    Location.all.each{|loc|
      next unless loc
      target_area = Area.get_area_by_name({:province => loc.province, :city => loc.city, :district => loc.district})
      unless loc.update_attributes({:area_uid => target_area.uid,:area_rid => target_area.rid})
        exit -1
      end
    }
  end

  def down
    change_table :locations do |t|
      t.remove :area_uid
      t.remove :area_rid
    end
  end
end
