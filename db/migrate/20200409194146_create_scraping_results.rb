class CreateScrapingResults < ActiveRecord::Migration[5.2]
  def change
    create_table :scraping_results do |t|
      t.text :result
      t.integer :cellar_file_id

      t.timestamps
    end
  end
end
