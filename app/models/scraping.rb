class Scraping
  agent = Mechanize.new
  page = agent.get("http://hoge.com")
end