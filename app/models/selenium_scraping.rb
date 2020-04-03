class SeleniumScraping
  def initialize(xlsx_io)
    @xlsx_io = xlsx_io
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

  def scraping
    scraping_results = []
    begin
      start_scraping @search_criteria['商品ページURL'] do
        target_area = find_all(:css, '#desktop-dp-sims_session-similarities-sims-feature .a-carousel-controls')
        if target_area.length != 1
          raise
        end

        try = 1
        begin
          execute_script('window.scrollBy(0, 300)')
          page_max = find(:css, '#sims-consolidated-2_feature_div .a-carousel-page-max').text.to_i - 1
        rescue => e
          try += 1
          retry if try < 10

          scraping_results << {asin: e}
          raise
        end

        page_max.times do |page|
          target_area.first.find_all(:css, '.a-carousel-center li').each do |tl|
            scraping_results << {asin: tl.text}
          end

          begin
            target_area.first.find(:css, '.a-carousel-goto-nextpage').click
          rescue => e
            try += 1
            binding.pry
            retry if try < 10

            scraping_results << {asin: e}
          end

          sleep 1
        end
      end
    rescue => e
      scraping_results << {asin: e}
    end

    scraping_results
  end
end