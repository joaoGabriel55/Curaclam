require "test_helper"

class CvAnalysisTest < ActiveSupport::TestCase
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

  test "should have default pending status" do
    cv_analysis = CvAnalysis.new
    assert_equal "pending", cv_analysis.status
  end

  test "should validate status presence" do
    cv_analysis = CvAnalysis.new(status: nil)
    cv_analysis.cv_file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test.pdf")),
      filename: "test.pdf",
      content_type: "application/pdf"
    )
    assert_not cv_analysis.valid?
    assert_includes cv_analysis.errors[:status], "can't be blank"
  end

  test "should validate cv_file presence" do
    cv_analysis = CvAnalysis.new(status: :pending)
    assert_not cv_analysis.valid?
    assert_includes cv_analysis.errors[:cv_file], "must be attached"
  end

  test "should have valid status values" do
    %w[pending processing completed failed].each do |status|
      cv_analysis = CvAnalysis.new(status: status)
      cv_analysis.cv_file.attach(
        io: File.open(Rails.root.join("test/fixtures/files/test.pdf")),
        filename: "test.pdf",
        content_type: "application/pdf"
      )
      assert cv_analysis.valid?, "#{status} should be a valid status"
    end
  end

  test "should have many notifications" do
    assert_respond_to CvAnalysis.new, :notifications
  end

  test "has_results? returns true when completed with analysis_result" do
    cv_analysis = CvAnalysis.new(status: :completed, analysis_result: { "summary" => "Test" })
    assert cv_analysis.has_results?
  end

  test "has_results? returns false when not completed" do
    cv_analysis = CvAnalysis.new(status: :pending, analysis_result: { "summary" => "Test" })
    assert_not cv_analysis.has_results?
  end

  test "has_results? returns false when completed without analysis_result" do
    cv_analysis = CvAnalysis.new(status: :completed, analysis_result: nil)
    assert_not cv_analysis.has_results?
  end

  test "parsed_result returns hash from analysis_result" do
    cv_analysis = CvAnalysis.new(analysis_result: { "summary" => "Test summary" })
    result = cv_analysis.parsed_result
    assert_equal "Test summary", result["summary"]
  end

  test "parsed_result returns empty hash when analysis_result is nil" do
    cv_analysis = CvAnalysis.new(analysis_result: nil)
    assert_equal({}, cv_analysis.parsed_result)
  end

  test "recent scope orders by created_at desc" do
    old = create_cv_analysis_with_file(status: :completed)
    new = create_cv_analysis_with_file(status: :pending)

    analyses = CvAnalysis.recent
    assert_equal new, analyses.first
    assert_equal old, analyses.last
  end

  test "completed scope returns only completed analyses" do
    create_cv_analysis_with_file(status: :pending)
    create_cv_analysis_with_file(status: :processing)
    completed = create_cv_analysis_with_file(status: :completed)
    create_cv_analysis_with_file(status: :failed)

    assert_equal [completed], CvAnalysis.completed.to_a
  end

  test "pending_or_processing scope returns pending and processing analyses" do
    pending = create_cv_analysis_with_file(status: :pending)
    processing = create_cv_analysis_with_file(status: :processing)
    create_cv_analysis_with_file(status: :completed)
    create_cv_analysis_with_file(status: :failed)

    result = CvAnalysis.pending_or_processing.to_a
    assert_includes result, pending
    assert_includes result, processing
    assert_equal 2, result.count
  end

  test "should reject non-PDF files" do
    cv_analysis = CvAnalysis.new(status: :pending)
    cv_analysis.cv_file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test.txt")),
      filename: "test.txt",
      content_type: "text/plain"
    )
    assert_not cv_analysis.valid?
    assert_includes cv_analysis.errors[:cv_file], "must be a PDF file"
  end
end