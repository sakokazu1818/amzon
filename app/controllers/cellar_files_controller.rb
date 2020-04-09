class CellarFilesController < ApplicationController
  before_action :set_cellar_file, only: [:show, :edit, :update, :destroy, :search]

  # GET /cellar_files
  # GET /cellar_files.json
  def index
    @cellar_files = CellarFile.all
  end

  # GET /cellar_files/new
  def new
    @cellar_file = CellarFile.new
    @cellar_file.name = Time.current.strftime('%Y-%m-%d-%H-%M-%S.xlsx')

    if CellarFile.all.length > 4
      d_c_f = CellarFile.all.last
      d_c_f.excel.purge if @cellar_file.excel.attached?
      d_c_f.destroy
    end
  end

  # POST /cellar_files
  # POST /cellar_files.json
  def create
    @cellar_file = CellarFile.new(cellar_file_params)

    respond_to do |format|
      if @cellar_file.save
        format.html { redirect_to action: 'index', notice: 'Cellar file was successfully created.' }
        format.json { render :show, status: :created, location: @cellar_file }
      else
        format.html { render :new }
        format.json { render json: @cellar_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cellar_files/1
  # DELETE /cellar_files/1.json
  def destroy
    @cellar_file.excel.purge if @cellar_file.excel.attached?
    @cellar_file.destroy
    respond_to do |format|
      format.html { redirect_to cellar_files_url, notice: 'Cellar file was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def search
    cellar_file = CellarFile.find(params[:id])
    cellar_file.run = true
    cellar_file.save!

    search_cellar = SearchCriterium.new(cellar_file)
    search_cellar.run
    render :json => {run: true}
  end

  def xlsx_download
    cellar_file = CellarFile.find(params[:id])

    respond_to do |format|
      # @xlsx_arr = [
      #   {
      #     :shop_name=>"Big Tron",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A3PJWOLFXYB2GU&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A3PJWOLFXYB2GU",
      #     :products=>{:totla=>115, :over_price=>69, :prime=>18}
      #   },
      #   {
      #     :shop_name=>"AmzBarley JP",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=APRUZYPLN6UVZ&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"APRUZYPLN6UVZ",
      #     :products=>{:totla=>97, :over_price=>24, :prime=>80}
      #   },
      #   {
      #     :shop_name=>"Gnognauq JP",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=AHHW2SC5W15BL&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"AHHW2SC5W15BL",
      #     :products=>{:totla=>117, :over_price=>9, :prime=>117}
      #   },
      #   {:shop_name=>"鮮やかな日々",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A3SKI7T1LLXX1J&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A3SKI7T1LLXX1J",
      #     :products=>{:totla=>661, :over_price=>73, :prime=>22}
      #   },
      #   {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"iTomte",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A2DI96CE3775TC&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A2DI96CE3775TC",
      #     :products=>{:totla=>54, :over_price=>12, :prime=>31}},
      #    {:shop_name=>"ヤクニタツ",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A21RXK6ZU361RS&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A21RXK6ZU361RS",
      #     :products=>{:totla=>164, :over_price=>6, :prime=>145}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"ミライユメ",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A201W5VVII7BW0&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A201W5VVII7BW0",
      #     :products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"Enjoy at home 5%ｷｬｯｼｭﾚｽ還元対象",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A3RLKVE4TTAW1G&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A3RLKVE4TTAW1G",
      #     :products=>{:totla=>110, :over_price=>94, :prime=>45}},
      #    {:shop_name=>"cnomgjp",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A7QY6LSTIG99O&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A7QY6LSTIG99O",
      #     :products=>{:totla=>38, :over_price=>7, :prime=>35}},
      #    {:shop_name=>"heliltdjp",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A1LBPBVEHJX6Z5&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A1LBPBVEHJX6Z5",
      #     :products=>{:totla=>26, :over_price=>2, :prime=>17}},
      #    {:shop_name=>"Banvee",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=AEC5COQ635LO7&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"AEC5COQ635LO7",
      #     :products=>{:totla=>20, :over_price=>16, :prime=>16}},
      #    {:shop_name=>"Kerally（商願2017-045937登録完了）",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A2RXEKH2UGJFE9&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A2RXEKH2UGJFE9",
      #     :products=>{:totla=>238, :over_price=>206, :prime=>50}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"Ａｕｔｏ Ｇａｒａｇｅ．ｃｏｍ",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=AVANPIWRFZVB3&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"AVANPIWRFZVB3",
      #     :products=>{:totla=>52, :over_price=>25, :prime=>46}},
      #    {:shop_name=>"LIFE STORE 商標登録第5439807号【国内発送 返金保証 誠実にお届けします】",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A1TXK6HBQX5WU8&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A1TXK6HBQX5WU8",
      #     :products=>{:totla=>80, :over_price=>34, :prime=>78}},
      #    {:shop_name=>"cnomgjp",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A7QY6LSTIG99O&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A7QY6LSTIG99O",
      #     :products=>{:totla=>38, :over_price=>7, :prime=>35}},
      #    {:shop_name=>"SHiZAK JP",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A12J3KZHYZ57FP&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A12J3KZHYZ57FP",
      #     :products=>{:totla=>17, :over_price=>3, :prime=>16}},
      #    {:shop_name=>"Kerally（商願2017-045937登録完了）",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A2RXEKH2UGJFE9&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A2RXEKH2UGJFE9",
      #     :products=>{:totla=>238, :over_price=>206, :prime=>50}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"uxcell Japan (日本ウェアハウスからの出荷商品以外、お届けまで１０ー１５日かかります)",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=AANM8PRMV1MBN&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"AANM8PRMV1MBN",
      #     :products=>{:totla=>200, :over_price=>13, :prime=>145}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"わいわいぐっずSHOP",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A3ABMA66GTQ22F&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A3ABMA66GTQ22F",
      #     :products=>{:totla=>57, :over_price=>40, :prime=>26}},
      #    {:shop_name=>"Vencci",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A31KD1496YS1AK&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A31KD1496YS1AK",
      #     :products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"WHATNOT",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A1EYW7Y3M1M6GF&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A1EYW7Y3M1M6GF",
      #     :products=>{:totla=>20, :over_price=>6, :prime=>15}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"MetroVision JP",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=AB9JW9YCZSWTE&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"AB9JW9YCZSWTE",
      #     :products=>{:totla=>26, :over_price=>17, :prime=>24}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"Z-Liant JP",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A14TYTN4I7MEZW&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A14TYTN4I7MEZW",
      #     :products=>{:totla=>54, :over_price=>2, :prime=>54}},
      #    {:shop_name=>"Growfast-JP",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A261KDRGVY1I86&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A261KDRGVY1I86",
      #     :products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"ヤクニタツ",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A21RXK6ZU361RS&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A21RXK6ZU361RS",
      #     :products=>{:totla=>163, :over_price=>6, :prime=>144}},
      #    {:products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"HIlLO　shop",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A282Y4LX9VCUIJ&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A282Y4LX9VCUIJ",
      #     :products=>{:totla=>0, :over_price=>0, :prime=>0}},
      #    {:shop_name=>"AMONIDA JJ",
      #     :store_front_url=>"https://www.amazon.co.jp/s?me=A3B57B7R0MTOXJ&marketplaceID=A1VC38T7YXB528",
      #     :cellar_id=>"A3B57B7R0MTOXJ",
      #     :products=>{:totla=>4, :over_price=>3, :prime=>4}}
      #   ]
      @xlsx_arr = JSON.parse(cellar_file.scraping_result.result)

      format.xlsx {
        response.headers['Content-Disposition'] = "attachment; filename=#{Time.current}.xlsx"
      }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cellar_file
      @cellar_file = CellarFile.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def cellar_file_params
      params.fetch(:cellar_file, {}).permit(:excel, :name)
    end
end
