class SeleniumScraping
  def initialize(xlsx)
    @xlsx = xlsx
    Capybara.register_driver :selenium do |app|
      # headless
      Capybara::Selenium::Driver.new(app,
        browser: :chrome,
        desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(
          chrome_options: {
            args: %w(disable-gpu window-size=1280,800),
          },
        )
      )
    end

    Capybara.javascript_driver = :selenium
  end

  def run
    # crome80
    set_search_criteria
    scraping_results = scraping
  end

  def set_search_criteria
    @search_criteria = {}
    @xlsx.each_row_streaming(offset: 1, max_rows: 1) do |row|
      @search_criteria[row[0].value] = row[1].value
    end
  end

  def start_scraping(url, &block)
    Capybara::Session.new(:selenium).tap { |session|
      session.visit url
      session.instance_eval(&block)
    }
  end

  def scraping
    scraping_results = []
    begin
      start_scraping @search_criteria['商品ページURL'] do
        target_area = find_all(:css, '#desktop-dp-sims_session-similarities-sims-feature .a-carousel-controls')
        if target_area.length != 1
          raise
        end

        scroll_end = false
        loop do
          target_list = target_area.first.find_all(:css, '.a-carousel-center li')
          if target_list.last.text == ''
            break
          end

          target_list.each do |tl|
            scraping_results << {asin: e}
          end

          try = 1
          begin
            execute_script('window.scrollBy(0, 300)') unless scroll_end
            target_area.first.find(:css, '.a-carousel-goto-nextpage').click
          rescue => e
            p try
            try += 1
            retry if try > 10

            scraping_results << {asin: e}
            raise
          end
          scroll_end = true
          sleep 2
        end
      end
    rescue => e
      scraping_results << {asin: e}
    end
  end
end