class SeleniumScraping
  def initialize(xlsx_io)
    @xlsx_io = xlsx_io
    Capybara.register_driver :selenium do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('headless') # ヘッドレスモードをonにするオプション
      options.add_argument('--disable-gpu') # 暫定的に必要なフラグとのこと
      options.add_argument('window-size=1280,800')
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end

    Capybara.javascript_driver = :selenium
  end

  def run
    # crome80
    @search_criteria = @xlsx_io.search_criteria
    scraping_results = scraping
    binding.pry
  end

  def start_scraping(url, &block)
    Capybara::Session.new(:selenium).tap { |session|
      session.visit url
      session.instance_eval(&block)
    }
  end

  def collect_page
    pages = []
    start_scraping @search_criteria['商品ページURL'] do
      target_area = find_all(:css, '#desktop-dp-sims_session-similarities-sims-feature .a-carousel-controls')
      if target_area.length != 1
        raise
      end

      try = 1
      begin
        execute_script('window.scrollBy(0, 300)')
        page_max = find(:css, '#sims-consolidated-2_feature_div .a-carousel-page-max').text.to_i
      rescue => e
        try += 1
        retry if try < 10

        pages << e
      end

      page_max.times do |page|
        target_area.first.find_all(:css, '.a-carousel-center li').each.with_index(1) do |tl, i|
          try = 1
          href = nil
          loop do
            href = find_all(:xpath, "/html/body/div[2]/div[2]/div[5]/div[18]/div/div/div/div/div/div[2]/div/div[2]/div/ol/li[#{i}]/div/a").try(:first)
            unless href.nil?
              href = href[:href]
              break
            else
              p try
              break if try > 10
              try += 1
            end
          end

          pages << href
        end

        break if page == page_max - 1

        begin
          target_area.first.find(:css, '.a-carousel-goto-nextpage').click
        rescue => e
          try += 1
          retry if try < 10

          pages << e
        end
      end
    end

    pages
  end

  def scraping
    scraping_results = []
    begin
      pages = collect_page
      binding.pry
    rescue => e
      scraping_results << {asin: e}
    end

    scraping_results
  end
end