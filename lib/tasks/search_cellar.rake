namespace :search_cellar do
  desc "実行処理の説明"
  task :run => :environment do
    search_cellar = SearchCellar.new(CellarFile.all.first)
    search_cellar.run
  end
end
