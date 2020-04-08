namespace :search_cellar do
  desc "セラー検索"
  task :run => :environment do
    search_cellar = SearchCriterium.new(CellarFile.all.first)
    search_cellar.run
  end

  desc "セレニウムテスト"
  task :test => :environment do
    search_cellar = SearchCriterium.new(CellarFile.all.first)
    search_cellar.run(mode: 'test')
  end
end
