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
    scraping = Scraping.new(@cellar_file)
    FileUtils.touch(Rails.root + 'tmp/hogemge')

    begin
      scraping.run
    rescue
    end
  end

  def xlsx_download
    respond_to do |format|
      @xlsx_arr = [["1", "11TN", "11T & ^11KR & ^12KR"],
      ["2", "11TR1", "11T & ^11KN"],
      ["3", "11TR2", "11T & ^12KN"],
      ["4", "12TN", "12T & ^11KR & ^12KR"],
      ["5", "12TR1", "12T & ^12KN"],
      ["6", "12TR2", "12T & ^11KN"],
      ["7", "1RT", "1RT"],
      ["8", "2RT", "2RT"],
      ["9", "3238T", "3238T"],
      ["10", "3097T", "3097T"],
      ["11", "3125T", "3125T"],
      ["12", "3135T", "3135T"],
      ["13", "3179T", "3179T"],
      ["14", "3201T", "3201T"],
      ["15", "3180T", "3180T"],
      ["16", "3150T", "3150T"],
      ["17", "2981T", "2981T"],
      ["18", "3011T", "3011T"],
      ["19", "3027T", "3027T"],
      ["20", "3069T", "3069T"],
      ["21", "3134T", "3134T"],
      ["22", "3126T", "3126T"],
      ["23", "3070T", "3070T"],
      ["24", "3040T", "3040T"],
      ["25", "3028T", "3028T"],
      ["26", "3012T", "3012T"],
      ["27", "2966T", "2966T"],
      ["28", "3151T", "3151T"],
      ["29", "3218T", "3218T"],
      ["30", "3041T", "3041T"],
      ["31", "3098T", "3098T"],
      ["32", "2990T", "2990T"]]

      format.xlsx {
        response.headers['Content-Disposition'] = 'attachment; filename="Product.xlsx"'
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
