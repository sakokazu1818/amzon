class SeleniumScraping
  def initialize(xlsx)
    @xlsx = xlsx

    # Seleniumの初期化
    # class ref: https://www.rubydoc.info/gems/selenium-webdriver/Selenium/WebDriver/Chrome
    @wait_time = 3
    @timeout = 4
    Selenium::WebDriver.logger.output = File.join("./", "selenium.log")
    Selenium::WebDriver.logger.level = :warn
    @driver = Selenium::WebDriver.for :chrome
    @driver.manage.timeouts.implicit_wait = @timeout
    @wait = Selenium::WebDriver::Wait.new(timeout: @wait_time)
  end

  def run
    set_search_criteria
    begin
      @driver.get('https://www.yahoo.co.jp/')
      binding.pry
      # page = @agent.get(@search_criteria['商品ページURL'])
      # target_area = page.search('#sims-consolidated-2_feature_div')
      # target_list = target_area.search('.a-carousel-center')[0].search('ol')[0].search('li')
      # next_btn = target_area.search('.a-carousel-right')
      # p target_list.length
      driver.quit
    rescue => e
      p e
    end
  end

  def set_search_criteria
    @search_criteria = {}
    @xlsx.each_row_streaming(offset: 1, max_rows: 1) do |row|
      @search_criteria[row[0].value] = row[1].value
    end
  end
end