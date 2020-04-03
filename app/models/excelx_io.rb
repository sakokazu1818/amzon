class ExcelxIo
  def initialize(file_path, sheet_index)
    @roo_xlsx = Roo::Excelx.new(file_path)
    @roo_xlsx.default_sheet = @roo_xlsx.sheets[sheet_index]
  end

  def search_criteria
    @search_criteria = {}
    @roo_xlsx.each_row_streaming(offset: 1, max_rows: 1) do |row|
      @search_criteria[row[0].value] = row[1].value
    end

    @search_criteria
  end
end