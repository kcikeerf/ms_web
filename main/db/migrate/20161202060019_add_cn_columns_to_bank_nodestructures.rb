class AddCnColumnsToBankNodestructures < ActiveRecord::Migration
  def change
    add_column :bank_nodestructures, :grade_cn, :string, limit: 255
    add_column :bank_nodestructures, :subject_cn, :string, limit: 255
    add_column :bank_nodestructures, :term, :string, limit: 255
    add_column :bank_nodestructures, :term_cn, :string, limit: 255
    add_column :bank_nodestructures, :version_cn, :string, limit: 255
    add_column :bank_nodestructures, :xue_duan, :string, limit: 255
    add_column :bank_nodestructures, :xue_duan_cn, :string, limit: 255

    remove_column :bank_nodestructures, :volume
  end
end
