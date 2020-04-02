class AddNameToCellarFile < ActiveRecord::Migration[5.2]
  def change
    add_column :cellar_files, :name, :string
  end
end
