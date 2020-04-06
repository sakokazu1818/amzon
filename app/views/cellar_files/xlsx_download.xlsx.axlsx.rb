wb = xlsx_package.workbook
wb.styles do |style|
  wb.add_worksheet do |sheet|
    sheet.add_row ['No', 'ASIN', '商品名', 'ストア名', 'セラーID', 'ストアフロントURL', '商品数', '価格条件', '価格条件割合', 'プライム数', 'プライム数割合']
    @xlsx_arr.each.with_index(1) do |cellar_arr, cellar_index|
      next unless cellar_arr.has_key?(:shop_name)
      row = [cellar_index, '', '', cellar_arr[:shop_name], cellar_arr[:cellar_id],
        cellar_arr[:store_front_url], cellar_arr[:products][:totla],
        cellar_arr[:products][:over_price],
        (cellar_arr[:products][:over_price].to_i / cellar_arr[:products][:totla].to_i),
        cellar_arr[:products][:prime], '']
      sheet.add_row row
    end
  end
end