class CellarFilesController < ApplicationController
  before_action :set_cellar_file, only: [:show, :edit, :update, :destroy]

  # GET /cellar_files
  # GET /cellar_files.json
  def index
    @cellar_files = CellarFile.all
  end

  # GET /cellar_files/1
  # GET /cellar_files/1.json
  def show
  end

  # GET /cellar_files/new
  def new
    @cellar_file = CellarFile.new
  end

  # GET /cellar_files/1/edit
  def edit
  end

  # POST /cellar_files
  # POST /cellar_files.json
  def create
    @cellar_file = CellarFile.new(cellar_file_params)

    respond_to do |format|
      if @cellar_file.save
        format.html { redirect_to @cellar_file, notice: 'Cellar file was successfully created.' }
        format.json { render :show, status: :created, location: @cellar_file }
      else
        format.html { render :new }
        format.json { render json: @cellar_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cellar_files/1
  # PATCH/PUT /cellar_files/1.json
  def update
    respond_to do |format|
      @cellar_file.excel.attach(params[:cellar_file][:excel])
      if @cellar_file.update(cellar_file_params)
        format.html { redirect_to @cellar_file, notice: 'Cellar file was successfully updated.' }
        format.json { render :show, status: :ok, location: @cellar_file }
      else
        format.html { render :edit }
        format.json { render json: @cellar_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cellar_files/1
  # DELETE /cellar_files/1.json
  def destroy
    @cellar_file.destroy
    respond_to do |format|
      format.html { redirect_to cellar_files_url, notice: 'Cellar file was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cellar_file
      @cellar_file = CellarFile.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def cellar_file_params
      params.fetch(:cellar_file, {}).permit(:excel)
    end
end
