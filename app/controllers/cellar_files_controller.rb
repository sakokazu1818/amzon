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
