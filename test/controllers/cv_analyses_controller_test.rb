require "test_helper"

class CvAnalysesControllerTest < ActionDispatch::IntegrationTest
  def create_cv_analysis_with_file(attributes = {})
    cv_analysis = CvAnalysis.new(attributes)
    cv_analysis.cv_file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test.pdf")),
      filename: "test.pdf",
      content_type: "application/pdf"
    )
    cv_analysis.save!
    cv_analysis
  end

  setup do
    @cv_analysis = create_cv_analysis_with_file(status: :completed, analysis_result: { "summary" => "Test" })
  end

  test "should get index" do
    get cv_analyses_url
    assert_response :success
  end

  test "should get new" do
    get new_cv_analysis_url
    assert_response :success
  end

  test "should show cv_analysis" do
    get cv_analysis_url(@cv_analysis)
    assert_response :success
  end

  test "should create cv_analysis with valid PDF" do
    pdf_file = fixture_file_upload("test.pdf", "application/pdf")

    assert_difference("CvAnalysis.count") do
      post cv_analyses_url, params: { cv_analysis: { cv_file: pdf_file } }
    end

    assert_redirected_to cv_analysis_url(CvAnalysis.last)
    assert_equal "pending", CvAnalysis.last.status
  end

  test "should not create cv_analysis without file" do
    assert_no_difference("CvAnalysis.count") do
      post cv_analyses_url, params: { cv_analysis: {} }
    end

    assert_response :bad_request
  end

  test "should not create cv_analysis with non-PDF file" do
    text_file = fixture_file_upload("test.txt", "text/plain")

    assert_no_difference("CvAnalysis.count") do
      post cv_analyses_url, params: { cv_analysis: { cv_file: text_file } }
    end

    assert_response :unprocessable_entity
  end

  test "should enqueue CvAnalysisJob after successful create" do
    pdf_file = fixture_file_upload("test.pdf", "application/pdf")

    assert_enqueued_with(job: CvAnalysisJob) do
      post cv_analyses_url, params: { cv_analysis: { cv_file: pdf_file } }
    end
  end

  test "should destroy cv_analysis" do
    assert_difference("CvAnalysis.count", -1) do
      delete cv_analysis_url(@cv_analysis)
    end

    assert_redirected_to cv_analyses_url
  end

  test "index should display cv analyses list" do
    create_cv_analysis_with_file(status: :pending)
    create_cv_analysis_with_file(status: :processing)

    get cv_analyses_url
    assert_response :success
    assert_select ".cv-analysis-card", minimum: 2
  end

  test "show should display processing state when processing" do
    processing = create_cv_analysis_with_file(status: :processing)
    get cv_analysis_url(processing)

    assert_response :success
    assert_select ".processing-state"
  end

  test "show should display error state when failed" do
    failed = create_cv_analysis_with_file(status: :failed, error_message: "Test error")
    get cv_analysis_url(failed)

    assert_response :success
    assert_select ".error-state"
  end

  test "show should display dashboard when completed with results" do
    completed = create_cv_analysis_with_file(
      status: :completed,
      analysis_result: {
        "personal_info" => { "name" => "John Doe" },
        "summary" => "Experienced developer"
      }
    )
    get cv_analysis_url(completed)

    assert_response :success
    assert_select ".dashboard-grid"
  end
end