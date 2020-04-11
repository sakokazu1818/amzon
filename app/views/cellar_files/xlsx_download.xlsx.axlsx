wb = xlsx_package.workbook

wb.styles do |style|
  wb.add_worksheet do |sheet|
    sheet.add_row ['チェックする商品']
    sheet.add_row ['ASIN', @xlsx_arr[0]['ASIN']]
    sheet.add_row ['商品ページURL', @xlsx_arr[0]['商品ページURL']]
    sheet.add_row ['', '', '', '', '', '', '', '価格条件', @xlsx_arr[0]['価格条件']]
    sheet.add_row ['この商品をチェックした人はこんな商品もチェックしています']
    sheet.merge_cells("B6:C6")
    sheet.merge_cells("D6:K6")
    sheet.add_row ['', '商品情報', '', 'ストアフロント情報']
    sheet.add_row ['No', 'ASIN', '商品名', 'ストア名', 'セラーID', 'ストアフロントURL', '商品数', '価格条件', '価格条件割合', 'プライム数', 'プライム数割合']

    next if @xlsx_arr[1].nil?
    @xlsx_arr[1].each.with_index(1) do |cellar_arr, cellar_index|
      next unless cellar_arr.has_key?('shop_name')
      over_price_ritu = cellar_arr['products']['over_price'].to_i.zero? ? 0 : cellar_arr['products']['over_price'].to_i / cellar_arr['products']['totla'].to_f
      prime_ritu = cellar_arr['products']['prime'].to_i.zero? ? 0 : cellar_arr['products']['prime'].to_i / cellar_arr['products']['totla'].to_f
      row = [cellar_index, cellar_arr['asin'], cellar_arr['product_name'], cellar_arr['shop_name'], cellar_arr['cellar_id'],
        cellar_arr['store_front_url'], cellar_arr['products']['totla'],
        cellar_arr['products']['over_price'],
        (over_price_ritu.round(2) * 100).to_i,
        cellar_arr['products']['prime'], (prime_ritu.round(2) * 100).to_i]
      sheet.add_row row
    end
  end
end