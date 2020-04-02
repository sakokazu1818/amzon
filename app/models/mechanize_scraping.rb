class MechanizeScraping
  def initialize(xlsx)
    @xlsx = xlsx
    @agent = Mechanize.new
  end

  def run
    set_search_criteria
    begin
      page = @agent.get(@search_criteria['商品ページURL'])
      target_area = page.search('#sims-consolidated-2_feature_div')
      target_list = target_area.search('.a-carousel-center')[0].search('ol')[0].search('li')
      next_btn = target_area.search('.a-carousel-right')
      p target_list.length
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