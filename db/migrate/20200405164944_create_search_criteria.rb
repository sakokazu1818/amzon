class CreateSearchCriteria < ActiveRecord::Migration[5.2]
  def change
    create_table :search_criteria do |t|
      t.string :asin
      t.string :product_url
      t.string :price_conditions
      t.integer :cellar_file_id

      t.timestamps
    end
  end
end
