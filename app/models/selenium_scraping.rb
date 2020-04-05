class SeleniumScraping
  if Rails.env.production?
    WAIT_TIME = 60
    SLEEP_TIME = 3
  else
    WAIT_TIME = 60
    SLEEP_TIME = 1
  end

  def set_driver
    options = Selenium::WebDriver::Chrome::Options.new

    if Rails.env.production? || @headless_mode
      options.add_argument('headless') # ヘッドレスモードをonにするオプション
    end

    options.add_argument('--disable-gpu') # 暫定的に必要なフラグとのこと
    options.add_argument('window-size=1280,800')
    @driver = Selenium::WebDriver.for :chrome, options: options
    @driver.manage.timeouts.implicit_wait = WAIT_TIME
    @wait = Selenium::WebDriver::Wait.new(timeout: WAIT_TIME)
  end

  def initialize(xlsx_io, headless_mode: false)
    @xlsx_io = xlsx_io
    @headless_mode = headless_mode
    set_driver
  end

  def run
    # crome80
    @search_criteria = @xlsx_io.search_criteria
    scraping_results = scraping
    binding.pry
  end

  def test_run
    @driver.get('https://www.google.co.jp/')
    p @driver.page_source
  end

  def scroll_for_target
    @driver.execute_script("var element = document.getElementById('sims-consolidated-2_feature_div');
      var rect = element.getBoundingClientRect();
      var elemtop = rect.top + window.pageYOffset;
      document.documentElement.scrollTop = elemtop;")
  end

  def collect_page
    pages = []
    pages_info = []
    @driver.get(@search_criteria['商品ページURL'])
    scroll_for_target

    target_area_xpath = '/html/body/div[2]/div[2]/div[5]/div[18]/div/div/div/div/div/div[2]'
    @wait.until{ @driver.find_element(:xpath, target_area_xpath).displayed? }
    target_area = @driver.find_element(:xpath, target_area_xpath)

    page_max_xpath = '/html/body/div[2]/div[2]/div[5]/div[18]/div/div/div/div/div/div[1]/div[2]/span/span[1]/span[2]'
    @wait.until{ @driver.find_element(:xpath, page_max_xpath).displayed? }
    page_max = @driver.find_element(:xpath, page_max_xpath).text.to_i

    1.upto page_max do |page_index|
      ol_xpath = '/html/body/div[2]/div[2]/div[5]/div[18]/div/div/div/div/div/div[2]/div/div[2]/div/ol'
      @wait.until{ @driver.find_element(:xpath, ol_xpath).displayed? }
      li = @driver.find_element(:xpath, ol_xpath).find_elements(css: 'li')

      li_index = []
      1.upto li.length do |i|
        li_index << "#{i}"
        sleep SLEEP_TIME
        begin
          li_xpath = "/html/body/div[2]/div[2]/div[5]/div[18]/div/div/div/div/div/div[2]/div/div[2]/div/ol/li[#{i}]"
          @wait.until{ @driver.find_element(:xpath, li_xpath).displayed? }

          href_xpath = "/html/body/div[2]/div[2]/div[5]/div[18]/div/div/div/div/div/div[2]/div/div[2]/div/ol/li[#{i}]/div/a"
          @wait.until{ @driver.find_element(:xpath, href_xpath).displayed? }
          pages << @driver.find_element(:xpath, href_xpath)[:href]
        rescue => e
          pages << nil
        end
      end
      pages_info << {page_index: page_index, li_index: li_index}

      break if page_index > page_max - 1

      begin
        next_btn_xpath = '/html/body/div[2]/div[2]/div[5]/div[18]/div/div/div/div/div/div[2]/div/div[3]/a'
        @wait.until{ @driver.find_element(:xpath, next_btn_xpath).displayed? }
        next_btn = @driver.find_element(:xpath, next_btn_xpath).click
      rescue => e
        try += 1
        scroll_for_target
        retry if try < 10

        pages << e
      end
    end

    @driver.quit
    [pages_info, pages.compact]
  end

  def scraping_details(pages)
    page_info = []
    pages.each_with_index do |page, pages_index|
      next if page.nil?
      set_driver if @driver.nil?
      @driver.get(page)

      page_info[pages_index] = {}
      shop_name_xpath = '//*[@id="sellerProfileTriggerId"]'
      @wait.until{ @driver.find_element(:xpath, shop_name_xpath).displayed? }
      shop_name = @driver.find_element(:xpath, shop_name_xpath)
      page_info[pages_index][:shop_name] = shop_name[:text]
      shop_name.click

      sleep SLEEP_TIME
      store_front_xpath = '/html/body/div[1]/div[2]/div[2]/div[1]/div[1]/div/div/div[2]/a'
      @wait.until{ @driver.find_element(:xpath, store_front_xpath).displayed? }
      @driver.find_element(:xpath, store_front_xpath).click

      store_front_url = @driver.current_url
      page_info[pages_index][:store_front_url] = store_front_url

      uri = URI::parse(store_front_url)
      q_array = URI::decode_www_form(uri.query)
      q_hash = Hash[q_array]
      page_info[pages_index][:cellar_id] = q_hash['me']

      product_count_xpath = '/html/body/div[1]/div[2]/span/div/span/h1/div/div[1]/div/div/span[1]'
      @wait.until{ @driver.find_element(:xpath, product_count_xpath).displayed? }
      product_count = @driver.find_element(:xpath, product_count_xpath).text.split(' ')[1].to_i

      products = {totla: product_count, over_price: 0, prime: 0}
      product_index = 1
      1.upto product_count do |i|
        sleep SLEEP_TIME
        begin
          price_xpath = "/html/body/div[1]/div[2]/div[1]/div[2]/div/span[4]/div[1]/div[#{product_index}]/div/span/div/div/div[2]/div[2]/div/div[2]/div[1]/div/div[1]"
          @wait.until{ @driver.find_element(:xpath, price_xpath).displayed? }
          if @driver.find_element(:xpath, price_xpath).text.split("\n").first.delete('￥').delete(',').to_i > @search_criteria['価格条件']
            products[:over_price] = products[:over_price] += 1
          end

          prime_xpath = "/html/body/div[1]/div[2]/div[1]/div[2]/div/span[4]/div[1]/div[#{product_index}]/div/span/div/div/div[2]/div[2]/div/div[2]/div[1]/div/div[2]"
          if @driver.find_element(:xpath, prime_xpath).text.include?('までに')
            products[:prime] = products[:prime] += 1
          end

          p products
          product_index += 1

          if i % 16 == 0
            @driver.execute_script("var element = document.getElementsByClassName('a-pagination')[0];
              var rect = element.getBoundingClientRect();
              var elemtop = rect.top + window.pageYOffset;
              document.documentElement.scrollTop = elemtop;")

            sleep SLEEP_TIME
            next_btn_xpath = '/html/body/div[1]/div[2]/div[1]/div[2]/div/span[8]/div/div/span/div/div/ul/li[7]'
            @wait.until{ @driver.find_element(:xpath, next_btn_xpath).displayed? }
            @driver.find_element(:xpath, next_btn_xpath).click
            product_index = 1
          end
        rescue => e
          p e
        end
      end

      page_info[pages_index][:products] = products
      binding.pry
      @driver.quit
      @driver = nil
      sleep SLEEP_TIME
    end
  end

  def scraping
    scraping_results = []
    pages = []
    # begin
    #   pages = collect_page
    # rescue => e
    #   scraping_results << {asin: e}
    # end
    #
    # retun scraping_results if pages.blank? || scraping_results.present?

    begin
      pages = ["https://www.amazon.co.jp/Bigtron-%E3%83%99%E3%83%AB%E3%83%88%E7%A9%B4%E3%81%82%E3%81%91%E6%A9%9F-12%E6%9C%AC%E3%82%BB%E3%83%83%E3%83%88-3mm-14mm-%E3%83%8F%E3%83%88%E3%83%A1%E6%8A%9C%E3%81%8D%E4%B8%B8%E3%81%84%E7%A9%B4%E3%81%82%E3%81%91/dp/B075M9F99Q/ref=pd_aw_sbs_60_1/355-1178888-9759135?_encoding=UTF8&pd_rd_i=B075M9F99Q&pd_rd_r=c24eef9e-f177-458d-9cdf-a8436d2d67cb&pd_rd_w=3RKAG&pd_rd_wg=3wZ12&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=CASAHT7X6QPDP0E07180&psc=1&refRID=CASAHT7X6QPDP0E07180",
 "https://www.amazon.co.jp/Amzbarley-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%99%E3%83%AB%E3%83%88%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-%E3%83%AC%E3%82%B6%E3%83%BC%E3%83%91%E3%83%B3%E3%83%81/dp/B0827VZ61R/ref=pd_aw_sbs_60_2/355-1178888-9759135?_encoding=UTF8&pd_rd_i=B0827VZ61R&pd_rd_r=c24eef9e-f177-458d-9cdf-a8436d2d67cb&pd_rd_w=3RKAG&pd_rd_wg=3wZ12&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=CASAHT7X6QPDP0E07180&psc=1&refRID=CASAHT7X6QPDP0E07180",
 "https://www.amazon.co.jp/10%E6%9C%AC-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88%E5%B7%A5%E5%85%B7-%E3%83%8F%E3%83%88%E3%83%A1%E6%8A%9C%E3%81%8D-%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%880-5mm%E3%80%811mm%E3%80%811-5mm%E3%80%812mm%E3%80%812-5mm%E3%80%813mm%E3%80%813-5mm%E3%80%814mm%E3%80%814-5mm%E3%80%815mm/dp/B07T96J2JV/ref=pd_aw_sbs_60_3/355-1178888-9759135?_encoding=UTF8&pd_rd_i=B07T96J2JV&pd_rd_r=c24eef9e-f177-458d-9cdf-a8436d2d67cb&pd_rd_w=3RKAG&pd_rd_wg=3wZ12&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=CASAHT7X6QPDP0E07180&psc=1&refRID=CASAHT7X6QPDP0E07180",
 "https://www.amazon.co.jp/%E3%82%B9%E3%83%88%E3%83%83%E3%82%AB%E3%83%BC-%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%88-2%E5%80%8B%E3%82%BB%E3%83%83%E3%83%88-%E3%82%A4%E3%83%B3%E3%83%86%E3%83%AA%E3%82%A2-%E3%82%AC%E3%83%BC%E3%83%87%E3%83%8B%E3%83%B3%E3%82%B0/dp/B00LD25RCU/ref=pd_aw_sbs_60_4/355-1178888-9759135?_encoding=UTF8&pd_rd_i=B086JMMFCP&pd_rd_r=c24eef9e-f177-458d-9cdf-a8436d2d67cb&pd_rd_w=3RKAG&pd_rd_wg=3wZ12&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=CASAHT7X6QPDP0E07180&psc=1&refRID=CASAHT7X6QPDP0E07180",
 "https://www.amazon.co.jp/%E9%AB%98%E5%84%80-GISUKE-%E5%8F%96%E6%9B%BF%E5%BC%8F%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88-%E3%83%9D%E3%83%B3%E3%83%81%E7%94%A8%E4%B8%8B%E6%95%B7%E3%81%8D%E4%BB%98-No-1/dp/B006JZGV3K/ref=pd_aw_sbs_60_5/355-1178888-9759135?_encoding=UTF8&pd_rd_i=B006JZGV3K&pd_rd_r=c24eef9e-f177-458d-9cdf-a8436d2d67cb&pd_rd_w=3RKAG&pd_rd_wg=3wZ12&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=CASAHT7X6QPDP0E07180&psc=1&refRID=CASAHT7X6QPDP0E07180"]
      scraping_details(pages)
    rescue => e
      scraping_results << {asin: e}
    end

    scraping_results
  end
end