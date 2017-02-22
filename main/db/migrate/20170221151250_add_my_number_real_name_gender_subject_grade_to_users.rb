class AddMyNumberRealNameGenderSubjectGradeToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :my_number, :string
    add_column :users, :real_name, :string
    add_column :users, :gender, :string
    add_column :users, :subject, :string
    add_column :users, :grade, :string  	
  end
end
