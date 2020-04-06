class SeleniumScraping
  if Rails.env.production?
    WAIT_TIME = 20
    SLEEP_TIME = 3
  else
    WAIT_TIME = 10
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
    [@search_criteria, scraping_results]
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
    @driver = nil
    [pages_info, pages.compact]
  end

  def scraping_details(pages)
    @page_info = []
    pages[1].each_with_index do |page, pages_index|
      next if page.nil?
      next if page.include?('help/customer')

      @page_info[pages_index] = {}
      products = {totla: 0, over_price: 0, prime: 0}
      begin
        set_driver if @driver.nil?
        @driver.get(page)

        shop_name_xpath = '//*[@id="sellerProfileTriggerId"]'
        @wait.until{ @driver.find_element(:xpath, shop_name_xpath).displayed? }
        shop_name = @driver.find_element(:xpath, shop_name_xpath)
        @page_info[pages_index][:shop_name] = shop_name[:text]
        shop_name.click

        sleep SLEEP_TIME
        store_front_xpath = '/html/body/div[1]/div[2]/div[2]/div[1]/div[1]/div/div/div[2]/a'
        @wait.until{ @driver.find_element(:xpath, store_front_xpath).displayed? }
        @driver.find_element(:xpath, store_front_xpath).click

        store_front_url = @driver.current_url
        @page_info[pages_index][:store_front_url] = store_front_url

        uri = URI::parse(store_front_url)
        q_array = URI::decode_www_form(uri.query)
        q_hash = Hash[q_array]
        @page_info[pages_index][:cellar_id] = q_hash['me']

        product_count_xpath = '/html/body/div[1]/div[2]/span/div/span/h1/div/div[1]/div/div/span[1]'
        @wait.until{ @driver.find_element(:xpath, product_count_xpath).displayed? }
        product_count = @driver.find_element(:xpath, product_count_xpath).text.split(' ')[1].to_i

        products[:totla] = product_count
        product_index = 1
        @next_page_href = nil
        @next_page_index = 1
        1.upto product_count do |i|
          p i
          sleep SLEEP_TIME
          price_xpath = "/html/body/div[1]/div[2]/div[1]/div[2]/div/span[4]/div[1]/div[#{product_index}]/div/span/div/div/div[2]/div[2]/div/div[2]/div[1]/div/div[1]"
          begin
            @wait.until{ @driver.find_element(:xpath, price_xpath).displayed? }
            if @driver.find_element(:xpath, price_xpath).text.split("\n").first.delete('￥').delete(',').to_i > @search_criteria['価格条件']
              products[:over_price] = products[:over_price] += 1
            end
          rescue => e
            # TODO やっぱりNEXTにしたい
            p e
            break
          end

          prime_xpath = "/html/body/div[1]/div[2]/div[1]/div[2]/div/span[4]/div[1]/div[#{product_index}]/div/span/div/div/div[2]/div[2]/div/div[2]/div[1]/div/div[2]"
          if @driver.find_element(:xpath, prime_xpath).text.include?('までに')
            products[:prime] = products[:prime] += 1
          end
          product_index += 1

          if i % 16 == 0
            if @next_page_href.nil?
              # TODO JS でクリックすればうまくいく？
              @driver.execute_script("var element = document.getElementsByClassName('a-pagination')[0];
                var rect = element.getBoundingClientRect();
                var elemtop = rect.top + window.pageYOffset;
                document.documentElement.scrollTop = elemtop;")

              sleep SLEEP_TIME
              next_btn_xpath = '/html/body/div[1]/div[2]/div[1]/div[2]/div/span[8]/div/div/span/div/div/ul/li[7]'
              @wait.until{ @driver.find_element(:xpath, next_btn_xpath).displayed? }
              @driver.find_element(:xpath, next_btn_xpath).click

              @next_page_href = @driver.current_url
              @next_page_index += 1
              product_index = 1
            else
              @next_page_index += 1
              uri = URI::parse(@next_page_href)
              q_array = URI::decode_www_form(uri.query)
              q_hash = Hash[q_array]
              q_hash['page'] = @next_page_index

              @next_page_href = 'https://' + uri.host + '/s?'
              q_hash.each do |k,v|
                @next_page_href = @next_page_href + k.to_s + '=' + v.to_s + '&'
              end
              @next_page_href = @next_page_href.chop

              @driver.quit
              @driver = nil
              set_driver
              @driver.get(@next_page_href)
              sleep SLEEP_TIME
              product_index = 1
            end
          end
        end
        @page_info[pages_index][:products] = products
        @driver.quit
        @driver = nil
        sleep SLEEP_TIME
      rescue => e
        p e
        @page_info[pages_index][:products] = products
        @driver.quit
        @driver = nil
        sleep SLEEP_TIME
        next
      end

      p @page_info
      # p pages_index
    end
    p @page_info

    @page_info
  end

  def scraping
    scraping_results = []
    pages = []
    begin
      pages = collect_page
    rescue => e
      scraping_results << {asin: e}
    end

    return scraping_results unless scraping_results.empty?

    begin
      # pages = [nil,[
      #   "https://www.amazon.co.jp/Bigtron-%E3%83%99%E3%83%AB%E3%83%88%E7%A9%B4%E3%81%82%E3%81%91%E6%A9%9F-12%E6%9C%AC%E3%82%BB%E3%83%83%E3%83%88-3mm-14mm-%E3%83%8F%E3%83%88%E3%83%A1%E6%8A%9C%E3%81%8D%E4%B8%B8%E3%81%84%E7%A9%B4%E3%81%82%E3%81%91/dp/B075M9F99Q/ref=pd_aw_sbs_60_1/355-1178888-9759135?_encoding=UTF8&pd_rd_i=B075M9F99Q&pd_rd_r=c24eef9e-f177-458d-9cdf-a8436d2d67cb&pd_rd_w=3RKAG&pd_rd_wg=3wZ12&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=CASAHT7X6QPDP0E07180&psc=1&refRID=CASAHT7X6QPDP0E07180",
      #   "https://www.amazon.co.jp/Amzbarley-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%99%E3%83%AB%E3%83%88%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-%E3%83%AC%E3%82%B6%E3%83%BC%E3%83%91%E3%83%B3%E3%83%81/dp/B0827VZ61R/ref=pd_aw_sbs_60_2/355-1178888-9759135?_encoding=UTF8&pd_rd_i=B0827VZ61R&pd_rd_r=c24eef9e-f177-458d-9cdf-a8436d2d67cb&pd_rd_w=3RKAG&pd_rd_wg=3wZ12&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=CASAHT7X6QPDP0E07180&psc=1&refRID=CASAHT7X6QPDP0E07180"]]
      scraping_results = scraping_details(pages)
    rescue => e
      p e
    end

    scraping_results
  end
end