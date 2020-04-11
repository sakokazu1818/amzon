class SearchCriterium < ApplicationRecord
  belongs_to :cellar_file

  def initialize(cellar_file)
    @cellar_file = cellar_file
    @origin_path = ActiveStorage::Blob.service.path_for(@cellar_file.excel.key)
    @working_files_path = @origin_path + '.xlsx'
    FileUtils.cp(@origin_path, @working_files_path)
    @xlsx_io = ExcelxIo.new(@working_files_path, 0)
  end

  def run(mode: 'prod')
    begin
      if mode == 'test'
        scraping = SeleniumScraping.new(@xlsx_io, headless_mode: true)
        scraping.test_run
      else
        p 'start SeleniumScraping'
        scraping = SeleniumScraping.new(@xlsx_io, headless_mode: false)
        scraping_results = scraping.run
      end

      if scraping_results.nil?
        @cellar_file.scraping_result = ScrapingResult.new(result: @xlsx_io.search_criteria.to_json)
      else
        unless @cellar_file.scraping_result.nil?
          @cellar_file.scraping_result.delete
        end
        @cellar_file.scraping_result = ScrapingResult.new(result: scraping_results.to_json)
      end

      @cellar_file.run = false
      @cellar_file.save!
      @cellar_file.scraping_result.save!
    rescue => e
      @cellar_file.run = false
      p e
    end
  end
end
