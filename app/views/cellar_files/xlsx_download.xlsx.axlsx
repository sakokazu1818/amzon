wb = xlsx_package.workbook
wb.styles do |style|
  highlight_cell = style.add_style(bg_color: "EFC376")

  wb.add_worksheet do |sheet|
    @xlsx_arr.each do |row_value|
      sheet.add_row row_value, style: [nil, nil]
    end
  end
end