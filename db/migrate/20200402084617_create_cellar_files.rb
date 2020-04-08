class CreateCellarFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :cellar_files do |t|
      t.boolean :run, null: false, default: false

      t.timestamps
    end
  end
end
