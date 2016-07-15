class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
    	t.string :mobile, limit: 11, null: false
    	t.string :content, null: false
    	t.string :channel, limit: 20
    	t.boolean :status, default: false
      t.boolean :is_valid, default: true
    	t.string :kinds, limit: 30
      t.string :auth_number, limit: 20
      t.datetime :valid_time

      t.timestamps
    end

    add_index :messages, [:mobile, :is_valid, :kinds], name: 'mobile_kinds'
    add_index :messages, [:channel, :status], name: "channel"
  end


end
