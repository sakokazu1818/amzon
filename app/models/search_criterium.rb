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
        scraping = SeleniumScraping.new(@xlsx_io, headless_mode: false)
        scraping_results = scraping.run
      end

      if scraping_results.nil?
        @cellar_file.scraping_result = ScrapingResult.new(result: @xlsx_io.search_criteria.to_json)
      else
        @cellar_file.scraping_result = ScrapingResult.new(result: scraping_results.to_json)
      end

      @cellar_file.run = false
      @cellar_file.save!

      finalize
    rescue
      delete_working_files
    end
  end

  def finalize
    @cellar_file.excel.purge
    @cellar_file.excel.attach(io: File.open(@working_files_path), filename: @cellar_file.name)

    delete_working_files
    working_files_path_arr = @working_files_path.split('/')
    working_files_path_arr.pop(2)
    FileUtils.rm_r(working_files_path_arr.join('/'))
  end

  def delete_working_files
    FileUtils.rm(@working_files_path)
  end
end
