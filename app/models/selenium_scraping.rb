class SeleniumScraping
  def initialize(xlsx_io)
    @xlsx_io = xlsx_io
    options = Selenium::WebDriver::Chrome::Options.new

    if Rails.env.production?
      options.add_argument('headless') # ヘッドレスモードをonにするオプション
    end

    options.add_argument('--disable-gpu') # 暫定的に必要なフラグとのこと
    options.add_argument('window-size=1280,800')
    @driver = Selenium::WebDriver.for :chrome, options: options
    if Rails.env.production?
      @wait = Selenium::WebDriver::Wait.new(timeout: 60)
    else
      @wait = Selenium::WebDriver::Wait.new(timeout: 5)
    end
  end

  def run
    # crome80
    @search_criteria = @xlsx_io.search_criteria
    scraping_results = scraping
    binding.pry
  end

  def scroll_for_target
    @driver.execute_script("var element = document.getElementById('sims-consolidated-2_feature_div');
      var rect = element.getBoundingClientRect();
      var elemtop = rect.top + window.pageYOffset;
      document.documentElement.scrollTop = elemtop;")
  end

  def collect_page
    pages = []
    @driver.get(@search_criteria['商品ページURL'])
    scroll_for_target

    target_area_xpath = '/html/body/div[2]/div[2]/div[5]/div[18]/div/div/div/div/div/div[2]'
    @wait.until{ @driver.find_element(:xpath, target_area_xpath).displayed? }
    target_area = @driver.find_element(:xpath, target_area_xpath)

    page_max_xpath = '/html/body/div[2]/div[2]/div[5]/div[18]/div/div/div/div/div/div[1]/div[2]/span/span[1]/span[2]'
    @wait.until{ @driver.find_element(:xpath, page_max_xpath).displayed? }
    page_max = @driver.find_element(:xpath, page_max_xpath).text.to_i

    page_max.times do |page_index|
      ol_xpath = '/html/body/div[2]/div[2]/div[5]/div[18]/div/div/div/div/div/div[2]/div/div[2]/div/ol'
      @wait.until{ @driver.find_element(:xpath, ol_xpath).displayed? }
      li = @driver.find_element(:xpath, ol_xpath).find_elements(css: 'li')

      1.upto li.length do |i|
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

      break if page_index >= page_max - 1

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
    pages.compact
  end

  def scraping_details(pages)
    pages.each do |page|
      next if page.nil?
      @driver.get(page)
      binding.pry
      @driver.quit
    end
  end

  def scraping
    scraping_results = []
    pages = []
    begin
      pages = collect_page
      binding.pry
    rescue => e
      scraping_results << {asin: e}
      binding.pry
    end
 #    pages = ["https://www.amazon.co.jp/Bigtron-%E3%83%99%E3%83%AB%E3%83%88%E7%A9%B4%E3%81%82%E3%81%91%E6%A9%9F-12%E6%9C%AC%E3%82%BB%E3%83%83%E3%83%88-3mm-14mm-%E3%83%8F%E3%83%88%E3%83%A1%E6%8A%9C%E3%81%8D%E4%B8%B8%E3%81%84%E7%A9%B4%E3%81%82%E3%81%91/dp/B075M9F99Q/ref=pd_aw_sbs_60_1/356-4529367-8410118?_encoding=UTF8&pd_rd_i=B075M9F99Q&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/Amzbarley-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%99%E3%83%AB%E3%83%88%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-%E3%83%AC%E3%82%B6%E3%83%BC%E3%83%91%E3%83%B3%E3%83%81/dp/B0827VZ61R/ref=pd_aw_sbs_60_2/356-4529367-8410118?_encoding=UTF8&pd_rd_i=B0827VZ61R&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%83%AC%E3%82%B6%E3%83%BC-%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-%E3%83%8F%E3%83%88%E3%83%A1-%E3%83%9D%E3%83%B3%E3%83%81-A057/dp/B00MN8AWPK/ref=pd_aw_sbs_60_3/356-4529367-8410118?_encoding=UTF8&pd_rd_i=B00MN8AWPK&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/10%E6%9C%AC-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88%E5%B7%A5%E5%85%B7-%E3%83%8F%E3%83%88%E3%83%A1%E6%8A%9C%E3%81%8D-%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%880-5mm%E3%80%811mm%E3%80%811-5mm%E3%80%812mm%E3%80%812-5mm%E3%80%813mm%E3%80%813-5mm%E3%80%814mm%E3%80%814-5mm%E3%80%815mm/dp/B07T96J2JV/ref=pd_aw_sbs_60_4/356-4529367-8410118?_encoding=UTF8&pd_rd_i=B07T96J2JV&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E9%AB%98%E5%84%80-GISUKE-%E5%8F%96%E6%9B%BF%E5%BC%8F%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88-%E3%83%9D%E3%83%B3%E3%83%81%E7%94%A8%E4%B8%8B%E6%95%B7%E3%81%8D%E4%BB%98-No-1/dp/B006JZGV3K/ref=pd_aw_sbs_60_5/356-4529367-8410118?_encoding=UTF8&pd_rd_i=B006JZGV3K&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E9%AB%98%E5%84%80-%E3%82%BF%E3%82%AB%E3%82%AE-%E5%84%80%E5%8A%A9-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-15mm/dp/B00G8PRXNS/ref=pd_aw_sbs_60_6/356-4529367-8410118?_encoding=UTF8&pd_rd_i=B00G8PRXNS&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/Bigtron-%E3%83%99%E3%83%AB%E3%83%88%E7%A9%B4%E3%81%82%E3%81%91%E6%A9%9F-12%E6%9C%AC%E3%82%BB%E3%83%83%E3%83%88-3mm-14mm-%E3%83%8F%E3%83%88%E3%83%A1%E6%8A%9C%E3%81%8D%E4%B8%B8%E3%81%84%E7%A9%B4%E3%81%82%E3%81%91/dp/B075M9F99Q/ref=pd_aw_sbs_60_1/356-4529367-8410118?_encoding=UTF8&pd_rd_i=B075M9F99Q&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/Amzbarley-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%99%E3%83%AB%E3%83%88%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-%E3%83%AC%E3%82%B6%E3%83%BC%E3%83%91%E3%83%B3%E3%83%81/dp/B0827VZ61R/ref=pd_aw_sbs_60_2/356-4529367-8410118?_encoding=UTF8&pd_rd_i=B0827VZ61R&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%83%AC%E3%82%B6%E3%83%BC-%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-%E3%83%8F%E3%83%88%E3%83%A1-%E3%83%9D%E3%83%B3%E3%83%81-A057/dp/B00MN8AWPK/ref=pd_aw_sbs_60_3/356-4529367-8410118?_encoding=UTF8&pd_rd_i=B00MN8AWPK&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%83%9F%E3%83%A9%E3%82%A4%E3%83%A4-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88%E5%B7%A5%E5%85%B7-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-%E9%9D%A9DIY%E3%83%91%E3%83%B3%E3%83%81-0-5mm%E3%80%811mm%E3%80%811-5mm%E3%80%812mm%E3%80%812-5mm%E3%80%813mm%E3%80%813-5mm%E3%80%814mm%E3%80%814-5mm%E3%80%815mm/dp/B07F7BRYGC/ref=pd_aw_sbs_60_10?_encoding=UTF8&pd_rd_i=B07F7BRYGC&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/TRUSCO-%E3%83%88%E3%83%A9%E3%82%B9%E3%82%B3-%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88-8%E6%9C%AC%E7%B5%84-TPO-8S/dp/B002A5VR5K/ref=pd_aw_sbs_60_11?_encoding=UTF8&pd_rd_i=B002A5VR5K&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/15%E3%82%B5%E3%82%A4%E3%82%BA-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-heliltd-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-0-5mm%E3%80%810-8mm%E3%80%811mm%E3%80%811-2mm%E3%80%811-5mm%E3%80%812mm%E3%80%812-5mm%E3%80%813mm%E3%80%813-5mm%E3%80%814mm%E3%80%814-5mm%E3%80%815mm%E3%80%816mm%E3%80%817mm/dp/B07ZHZDX38/ref=pd_aw_sbs_60_12?_encoding=UTF8&pd_rd_i=B07ZHZDX38&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%82%B9%E3%83%88%E3%83%AD%E3%83%B3%E3%82%B0%E3%83%84%E3%83%BC%E3%83%AB-Strong-TooL-%E5%8F%96%E6%9B%BF%E5%BC%8F%E3%83%91%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88-05493/dp/B001S7QBBQ/ref=pd_aw_sbs_60_7?_encoding=UTF8&pd_rd_i=B001S7QBBQ&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E6%96%B0%E6%BD%9F%E7%B2%BE%E6%A9%9F-Niigataseiki-MP-6S-SK-%E4%BA%A4%E6%8F%9B%E5%BC%8F%E3%83%9F%E3%83%8B%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88/dp/B0042W8IP6/ref=pd_aw_sbs_60_8?_encoding=UTF8&pd_rd_i=B0042W8IP6&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/ITOMTE-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88-%E4%B8%B8%E3%81%84%E7%A9%B4%E9%96%8B%E3%81%91-2-5-10mm/dp/B07GCKM7M2/ref=pd_aw_sbs_60_9?_encoding=UTF8&pd_rd_i=B07GCKM7M2&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/Kasamy-%E3%83%AC%E3%82%B6%E3%83%BC-%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-%E3%83%91%E3%83%B3%E3%83%81-%E3%82%BB%E3%83%83%E3%83%88/dp/B01CB9GYRK/ref=pd_aw_sbs_60_16?_encoding=UTF8&pd_rd_i=B01CB9GYRK&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88%E7%94%A8-%E7%A9%B4%E3%81%82%E3%81%91%E5%B7%A5%E5%85%B7-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-2mm10mm-17%E6%9C%AC%E3%82%BB%E3%83%83%E3%83%88/dp/B07PDY3BKN/ref=pd_aw_sbs_60_17?_encoding=UTF8&pd_rd_i=B07PDY3BKN&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/SHiZAK-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%A5%E3%83%BC-6%E3%82%B5%E3%82%A4%E3%82%BA-%E3%83%AC%E3%82%B6%E3%83%BC%E3%83%91%E3%83%B3%E3%83%81/dp/B01N6HGHTQ/ref=pd_aw_sbs_60_18?_encoding=UTF8&pd_rd_i=B01N6HGHTQ&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/14%E3%82%B5%E3%82%A4%E3%82%BA-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-cnomg-%E3%83%8F%E3%83%88%E3%83%A1%E6%8A%9C%E3%81%8D-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88/dp/B07G2PJKDS/ref=pd_aw_sbs_60_13?_encoding=UTF8&pd_rd_i=B07G2PJKDS&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%82%BB%E3%83%B3%E3%82%BF%E3%83%BC%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88-%E3%83%94%E3%83%B3%E3%83%9D%E3%83%B3%E3%83%81-%E7%A9%B4%E3%81%82%E3%81%91%E5%B7%A5%E5%85%B7-%E6%8C%81%E3%81%A1%E9%81%8B%E3%81%B3%E3%81%AB%E4%BE%BF%E5%88%A9/dp/B084TN7H6H/ref=pd_aw_sbs_60_14?_encoding=UTF8&pd_rd_i=B084TN7H6H&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E6%96%B0%E6%BD%9F%E7%B2%BE%E6%A9%9F-Niigataseiki-HP-30-%E7%9A%AE%E6%8A%9C%E3%81%8D%E3%83%9D%E3%83%B3%E3%83%81-30mm/dp/B0042JOD4E/ref=pd_aw_sbs_60_15?_encoding=UTF8&pd_rd_i=B0042JOD4E&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E6%96%B0%E6%BD%9F%E7%B2%BE%E6%A9%9F-Niigataseiki-HMP-20-%E5%85%AD%E8%A7%92%E8%BB%B8%E7%9A%AE%E6%8A%9C%E3%81%8D%E3%83%9D%E3%83%B3%E3%83%81-20mm/dp/B0042WCNFW/ref=pd_aw_sbs_60_22?_encoding=UTF8&pd_rd_i=B0042WCNFW&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%82%BB%E3%83%B3%E3%82%BF%E3%83%BC%E3%83%9D%E3%83%B3%E3%83%81%E3%80%909%E7%A8%AE%E9%A1%9E%E3%82%BB%E3%83%83%E3%83%88%E3%80%91-%E3%83%AD%E3%83%BC%E3%83%AB%E3%83%94%E3%83%B3%E3%83%91%E3%83%B3%E3%83%81-%E3%82%AA%E3%83%BC%E3%83%88%E3%82%BB%E3%83%B3%E3%82%BF%E3%83%BC%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%94%E3%83%B3%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88-%E3%80%90Amatem%E3%80%91/dp/B083TDRSWB/ref=pd_aw_sbs_60_23?_encoding=UTF8&pd_rd_i=B083TDRSWB&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%82%B9%E3%83%88%E3%83%AD%E3%83%B3%E3%82%B0%E3%83%84%E3%83%BC%E3%83%AB-Strong-%E6%89%93%E3%81%A1%E6%8A%9C%E3%81%8D%E3%83%91%E3%83%B3%E3%83%81-69-3-12/dp/B001S7MIEU/ref=pd_aw_sbs_60_24?_encoding=UTF8&pd_rd_i=B001S7MIEU&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E9%AB%98%E5%84%80-%E3%82%BF%E3%82%AB%E3%82%AE-KPS-0317-%E5%84%80%E5%8A%A9-%E7%9A%AE%E3%83%9D%E3%83%B3%E3%83%81%E3%82%B7%E3%83%A3%E3%83%BC%E3%83%97%E3%83%8A%E3%83%BC/dp/B01NBM5ZJM/ref=pd_aw_sbs_60_19?_encoding=UTF8&pd_rd_i=B01NBM5ZJM&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/14%E3%82%B5%E3%82%A4%E3%82%BA-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-cnomg-%E3%83%8F%E3%83%88%E3%83%A1%E6%8A%9C%E3%81%8D-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88/dp/B07WYX19KY/ref=pd_aw_sbs_60_20?_encoding=UTF8&pd_rd_i=B07WYX19KY&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/11pc-%E3%82%AC%E3%82%B9%E3%82%B1%E3%83%83%E3%83%88%E3%80%81%E3%83%93%E3%83%8B%E3%83%BC%E3%83%AB%E3%80%81%E3%83%AC%E3%82%B6%E3%83%BC%E3%81%AA%E3%81%A9%E7%A9%B4%E9%96%8B%E3%81%91%E7%94%A8-%E3%83%91%E3%83%83%E3%82%AD%E3%83%B3-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88-6-25mm/dp/B00BDG5KXW/ref=pd_aw_sbs_60_21?_encoding=UTF8&pd_rd_i=B00BDG5KXW&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%82%B5%E3%83%B3%E3%83%89%E3%83%AA%E3%83%BC-Sundry-%E3%83%91%E3%83%B3%E3%83%81%E3%83%9E%E3%83%83%E3%83%88-80%C3%9780%C3%9710mm-SDR-35/dp/B07S6N68NZ/ref=pd_aw_sbs_60_28?_encoding=UTF8&pd_rd_i=B07S6N68NZ&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%82%B9%E3%83%88%E3%83%AD%E3%83%B3%E3%82%B0%E3%83%84%E3%83%BC%E3%83%AB-Strong-%E3%83%91%E3%83%B3%E3%83%81%E3%83%9E%E3%83%83%E3%83%88-%E6%89%93%E3%81%A1%E6%8A%9C%E3%81%8D%E3%83%91%E3%83%B3%E3%83%81%E7%94%A8-05470/dp/B0043PNI5W/ref=pd_aw_sbs_60_29?_encoding=UTF8&pd_rd_i=B0043PNI5W&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/Cosyland-%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%A5%E3%83%BC%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-6%E6%AE%B5%E9%9A%8E%E5%BC%8F%E3%83%80%E3%82%A4%E3%83%A4%E3%83%AB-%E3%83%99%E3%83%AB%E3%83%88%E3%83%9B%E3%83%BC%E3%83%AB%E3%83%91%E3%83%B3%E3%83%81/dp/B082W518D2/ref=pd_aw_sbs_60_30?_encoding=UTF8&pd_rd_i=B082W518D2&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/uxcell-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88%E4%B8%AD%E7%A9%BA%E3%83%91%E3%83%B3%E3%83%81-%E4%B8%B8%E3%81%84%E7%A9%B4%E3%81%82%E3%81%91-%E3%83%91%E3%83%B3%E3%83%81%E3%83%84%E3%83%BC%E3%83%AB-%E3%83%AC%E3%82%B6%E3%83%BC%E3%83%99%E3%83%AB%E3%83%88%E6%99%82%E8%A8%88%E3%83%90%E3%83%B3%E3%83%89%E3%82%AC%E3%82%B9%E3%82%B1%E3%83%83%E3%83%88%E7%94%A8/dp/B07N3T7Q3F/ref=pd_aw_sbs_60_25?_encoding=UTF8&pd_rd_i=B07N3T7Q3F&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/Aicheson-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%91%E3%83%B3%E3%83%81-%E3%83%AC%E3%82%B6%E3%83%BC%E3%83%91%E3%83%B3%E3%83%81-6%E6%AE%B5%E9%9A%8E%E5%BC%8F%E3%83%80%E3%82%A4%E3%83%A4%E3%83%AB-%E7%A9%B4%E5%BE%843-5mm-7mm/dp/B07RXH6FZL/ref=pd_aw_sbs_60_26?_encoding=UTF8&pd_rd_i=B07RXH6FZL&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88%E7%94%A8-%E7%A9%B4%E3%81%82%E3%81%91%E5%B7%A5%E5%85%B7-%E7%A9%B4%E3%81%82%E3%81%91%E3%83%9D%E3%83%B3%E3%83%81-3mm%E3%81%8B%E3%82%8916%EF%BD%8D%EF%BD%8D-3-16mm12%E6%9C%AC%E3%81%AE%E3%82%BB%E3%83%83%E3%83%88/dp/B07SMPF7RF/ref=pd_aw_sbs_60_27?_encoding=UTF8&pd_rd_i=B07SMPF7RF&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/Qiilu-%E3%80%909%E6%9C%AC%E3%80%91-%E3%82%BB%E3%83%B3%E3%82%BF%E3%83%BC%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88-%E3%83%94%E3%83%B3%E3%83%9D%E3%83%B3%E3%83%81/dp/B07NW6JKJF/ref=pd_aw_sbs_60_34?_encoding=UTF8&pd_rd_i=B07NW6JKJF&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E7%A9%B4%E3%81%82%E3%81%91-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-%E3%82%B9%E3%82%AF%E3%83%AA%E3%83%A5%E3%83%BC%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%AC%E3%82%B6%E3%83%BC%E3%83%91%E3%83%B3%E3%83%81%E4%BA%A4%E6%8F%9B%E5%8F%AF%E8%83%BD-%E5%85%AD%E7%82%B9%E3%82%BB%E3%83%83%E3%83%88/dp/B07MNDXDJK/ref=pd_aw_sbs_60_35?_encoding=UTF8&pd_rd_i=B07MNDXDJK&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%82%B5%E3%83%B3%E3%83%89%E3%83%AA%E3%83%BC-Sundry-RLP-6-SUNDRY-%E3%83%AD%E3%83%BC%E3%82%BF%E3%83%AA%E3%83%BC%E3%83%AC%E3%82%B6%E3%83%BC%E3%83%91%E3%83%B3%E3%83%81/dp/B019X8WGYW/ref=pd_aw_sbs_60_36?_encoding=UTF8&pd_rd_i=B019X8WGYW&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/WAIWAIGOODS-%E7%A9%B4%E3%81%82%E3%81%91-%E3%83%9D%E3%83%B3%E3%83%81-%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-%EF%BC%99%E6%9C%AC%E3%82%BB%E3%83%83%E3%83%88/dp/B00YCEBYM8/ref=pd_aw_sbs_60_31?_encoding=UTF8&pd_rd_i=B00YCEBYM8&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%82%B9%E3%83%88%E3%83%AD%E3%83%B3%E3%82%B0%E3%83%84%E3%83%BC%E3%83%AB-Strong-%E5%B7%AE%E6%9B%BF%E5%BC%8F%E3%83%91%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88-14%E3%83%94%E3%83%BC%E3%82%B91-8mm-65%E2%80%9075/dp/B0043PMUGK/ref=pd_aw_sbs_60_32?_encoding=UTF8&pd_rd_i=B0043PMUGK&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/Sumnacon-%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-%E3%83%9B%E3%83%83%E3%82%AF%E6%89%93%E3%81%A1%E5%85%B7-%E4%B8%87%E8%83%BD%E6%89%93%E3%81%A1%E5%8F%B0-11%E3%82%BB%E3%83%83%E3%83%88/dp/B01IOKEC9C/ref=pd_aw_sbs_60_33?_encoding=UTF8&pd_rd_i=B01IOKEC9C&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E3%83%AC%E3%82%B6%E3%83%BC%E3%82%AF%E3%83%A9%E3%83%95%E3%83%88-12%E6%9C%AC%E3%82%BB%E3%83%83%E3%83%88-%E7%A9%B4%E3%81%82%E3%81%91-%E3%83%9D%E3%83%B3%E3%83%81-%E3%83%8F%E3%83%88%E3%83%A1%E6%8A%9C%E3%81%8D/dp/B00RNQW8YA/ref=pd_aw_sbs_60_40?_encoding=UTF8&pd_rd_i=B00RNQW8YA&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E9%AB%98%E5%84%80-%E3%82%BF%E3%82%AB%E3%82%AE-%E5%84%80%E5%8A%A9-%E7%9A%AE%E3%83%9D%E3%83%B3%E3%83%81%E3%82%BB%E3%83%83%E3%83%88-5%E6%9C%AC%E7%B5%84/dp/B006JZGMQG/ref=pd_aw_sbs_60_41?_encoding=UTF8&pd_rd_i=B006JZGMQG&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R",
 # "https://www.amazon.co.jp/%E6%96%B0%E6%BD%9F%E7%B2%BE%E6%A9%9F-Niigataseiki-MHP-7S-SK-%E7%9A%AE%E6%8A%9C%E3%81%8D%E3%83%9D%E3%83%B3%E3%83%817pcs%E3%82%BB%E3%83%83%E3%83%88/dp/B0042JKKMS/ref=pd_aw_sbs_60_42?_encoding=UTF8&pd_rd_i=B0042JKKMS&pd_rd_r=8619634a-e43e-46d1-bb61-f9dc6e8c0ef7&pd_rd_w=Bd0cn&pd_rd_wg=jJcpS&pf_rd_p=1893a417-ba87-4709-ab4f-0dece788c310&pf_rd_r=PSVTBBJQBSQP2KC7V70R&psc=1&refRID=PSVTBBJQBSQP2KC7V70R"]

    retun scraping_results if pages.blank? || scraping_results.present?

    begin
      scraping_details(pages)
    rescue => e
      scraping_results << {asin: e}
    end

    scraping_results
  end
end