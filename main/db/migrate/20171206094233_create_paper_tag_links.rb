class CreatePaperTagLinks < ActiveRecord::Migration
  def change
    create_table :paper_tag_links do |t|
    	t.string :paper_id
    	t.string :tag_id
      t.timestamps null: false
    end
  end
end
