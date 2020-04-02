class SearchCellar
  def initialize(cellar_file)
    @cellar_file = cellar_file
    @origin_path = ActiveStorage::Blob.service.path_for(@cellar_file.excel.key)
    @new_path = @origin_path + '.xlsx'
    FileUtils.cp(@origin_path, @new_path)
    @xlsx = Roo::Excelx.new(@new_path)
    @xlsx.default_sheet = @xlsx.sheets[0]
  end

  def run
    set_search_criteria
    finalize
  end

  def set_search_criteria
    @search_criteria = {}
    @xlsx.each_row_streaming(offset: 1, max_rows: 1) do |row|
      @search_criteria[row[0].value] = row[1].value
    end
  end

  def finalize
    @cellar_file.excel.purge
    @cellar_file.excel.attach(io: File.open(@new_path), filename: @cellar_file.name)

    new_path_arr = @new_path.split('/')
    new_path_arr.pop(2)
    FileUtils.rm_r(new_path_arr.join('/'))
  end
end