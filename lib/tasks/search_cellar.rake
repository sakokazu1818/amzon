namespace :search_cellar do
  desc "実行処理の説明"
  task :run => :environment do
    scraping = Scraping.new(CellarFile.all.first)
    scraping.run
  end
end
