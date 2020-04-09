class SeleniumScraping
  if Rails.env.production?
    WAIT_TIME = 20
    SLEEP_TIME = 3
  else
    WAIT_TIME = 10
    SLEEP_TIME = 2
  end

  def set_driver
    options = Selenium::WebDriver::Chrome::Options.new

    options.add_argument('headless') # ヘッドレスモードをonにするオプション
    # if Rails.env.production? || @headless_mode
    #   options.add_argument('headless') # ヘッドレスモードをonにするオプション
    # end

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
    @search_criteria = @xlsx_io.search_criteria
    scraping_results = scraping
    return scraping_results if scraping_results.nil?

    return [@search_criteria, scraping_results]
  end

  def test_run
    @driver.get('https://www.google.co.jp/')
    p @driver.page_source
  end

  def scroll_for_target
    SLEEP_TIME
    @driver.execute_script("var element = document.querySelector('#desktop-dp-sims_session-similarities-sims-feature');
      var rect = element.getBoundingClientRect();
      var elemtop = rect.top + window.pageYOffset;
      document.documentElement.scrollTop = elemtop;")
  end

  def collect_page
    pages = []
    pages_info = []
    @driver.get(@search_criteria['商品ページURL'])
    scroll_for_target

    page_max_xpath = '/html/body/div[2]/div[2]/div[5]/div[15]/div/div/div/div/div[1]/div[2]/span/span[1]/span[2]'
    @wait.until{ @driver.find_element(:xpath, page_max_xpath).displayed? }
    page_max = @driver.find_element(:xpath, page_max_xpath).text.to_i

    1.upto page_max do |page_index|
      ol_xpath = '/html/body/div[2]/div[2]/div[5]/div[15]/div/div/div/div/div[2]/div/div[2]/div/ol'
      @wait.until{ @driver.find_element(:xpath, ol_xpath).displayed? }
      li = @driver.find_element(:xpath, ol_xpath).find_elements(css: 'li')

      li_index = []
      1.upto li.length do |i|
        li_index << "#{i}"
        sleep SLEEP_TIME
        begin
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
        p e
      end
    end

    @driver.quit
    @driver = nil

    return pages if pages.nil?
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
        sleep SLEEP_TIME

        uri = URI::parse(@driver.current_url)
        q_array = URI::decode_www_form(uri.query)
        q_hash = Hash[q_array]
        @page_info[pages_index][:asin] = q_hash['pd_rd_i']

        product_name_xpath = '/html/body/div[2]/div[2]/div[5]/div[5]/div[4]/div[1]/div/h1/span'
        @wait.until{ @driver.find_element(:xpath, product_name_xpath).displayed? }
        @page_info[pages_index][:product_name] = @driver.find_element(:xpath, product_name_xpath).text

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
            p e
            break
          end
          products[:totla] = products[:totla] += 1

          prime_xpath = "/html/body/div[1]/div[2]/div[1]/div[2]/div/span[4]/div[1]/div[#{product_index}]/div/span/div/div/div[2]/div[2]/div/div[2]/div[1]/div/div[2]"
          if @driver.find_element(:xpath, prime_xpath).text.include?('までに')
            products[:prime] = products[:prime] += 1
          end
          product_index += 1

          if i % 16 == 0
            @driver.execute_script("var element = document.getElementsByClassName('a-pagination')[0];
              var rect = element.getBoundingClientRect();
              var elemtop = rect.top + window.pageYOffset;
              document.documentElement.scrollTop = elemtop;")

            @driver.execute_script('var element = document.querySelector("#search > div.s-desktop-width-max.s-desktop-content.sg-row > div.sg-col-20-of-24.sg-col-28-of-32.sg-col-16-of-20.sg-col.sg-col-32-of-36.sg-col-8-of-12.sg-col-12-of-16.sg-col-24-of-28 > div > span:nth-child(10) > div > div > span > div > div > ul > li.a-last > a");
              element.click();')

            sleep SLEEP_TIME
            product_index = 1
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
    end
    p @page_info

    return nil if @page_info.empty?
  end

  def scraping
    begin
      pages = collect_page
      return pages if pages.nil?

      scraping_details(['', ['https://www.amazon.co.jp/Bigtron-%E3%83%99%E3%83%AB%E3%83%88%E7%A9%B4%E3%81%82%E3%81%91%E6%A9%9F-12%E6%9C%AC%E3%82%BB%E3%83%83%E3%83%88-3mm-14mm-%E3%83%8F%E3%83%88%E3%83%A1%E6%8A%9C%E3%81%8D%E4%B8%B8%E3%81%84%E7%A9%B4%E3%81%82%E3%81%91/dp/B075M9F99Q/ref=pd_aw_sbs_60_1/355-1275993-5102726?_encoding=UTF8&pd_rd_i=B075M9F99Q&pd_rd_r=08c6bc7d-9777-4f0e-ba37-d6a453ebc7d8&pd_rd_w=CIriZ&pd_rd_wg=FFY1r&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=Y6VJJRJM1E5E7P58W6DX&psc=1&refRID=Y6VJJRJM1E5E7P58W6DX']])
      scraping_details(pages)

      # [{:asin=>"B075M9F99Q", :product_name=>"Bigtron 革穴パンチ ベルト穴あけ機 中空 12本セット 3mm-14mm ハトメ抜き丸い穴あけ レザーツール", :shop_name=>"Big Tron", :store_front_url=>"https://www.amazon.co.jp/s?marketplaceID=A1VC38T7YXB528&me=A3PJWOLFXYB2GU&merchant=A3PJWOLFXYB2GU", :cellar_id=>"A3PJWOLFXYB2GU", :products=>{:totla=>121, :over_price=>72, :prime=>20}}]
    rescue => e
      binding.pry
      return nil
    end
  end
end