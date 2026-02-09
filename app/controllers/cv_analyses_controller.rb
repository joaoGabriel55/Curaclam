class CvAnalysesController < ApplicationController
  before_action :set_cv_analysis, only: [:show, :destroy]

  # GET /cv_analyses
  def index
    @cv_analyses = CvAnalysis.recent.includes(:cv_file_attachment)
  end

  # GET /cv_analyses/:id
  def show
    # Analysis result will be displayed in the view
  end

  # GET /cv_analyses/new
  def new
    @cv_analysis = CvAnalysis.new
  end

  # POST /cv_analyses
  def create
    @cv_analysis = CvAnalysis.new(cv_analysis_params)

    if @cv_analysis.save
      # Enqueue the background job for analysis
      CvAnalysisJob.perform_later(@cv_analysis.id)

      redirect_to @cv_analysis, notice: "Your CV has been uploaded and is being analyzed. You'll receive a notification when it's ready."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /cv_analyses/:id
  def destroy
    @cv_analysis.destroy
    redirect_to cv_analyses_path, notice: "CV analysis was successfully deleted."
  end

  private

  def set_cv_analysis
    @cv_analysis = CvAnalysis.find(params[:id])
  end

  def cv_analysis_params
    params.require(:cv_analysis).permit(:cv_file)
  end
end