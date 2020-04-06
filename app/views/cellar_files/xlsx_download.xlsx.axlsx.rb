wb = xlsx_package.workbook
wb.styles do |style|
  wb.add_worksheet do |sheet|
    @xlsx_arr.each do |row_value|
      binding.pry
      sheet.add_row row_value, style: [nil, nil]
    end
  end
end