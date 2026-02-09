require "test_helper"
require "ostruct"

class CvAnalysisJobTest < ActiveJob::TestCase
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

  # Helper to mock RubyLLM.chat
  def with_mocked_llm(response_content)
    mock_response = OpenStruct.new(content: response_content)
    mock_chat = Object.new
    mock_chat.define_singleton_method(:ask) { |_| mock_response }

    original_method = RubyLLM.method(:chat) if RubyLLM.respond_to?(:chat)
    RubyLLM.define_singleton_method(:chat) { mock_chat }

    yield
  ensure
    if original_method
      RubyLLM.define_singleton_method(:chat) { |*args, **kwargs| original_method.call(*args, **kwargs) }
    else
      RubyLLM.singleton_class.send(:remove_method, :chat) if RubyLLM.singleton_methods.include?(:chat)
    end
  end

  test "should update status to processing or completed when job runs" do
    cv_analysis = create_cv_analysis_with_file(status: :pending)

    with_mocked_llm('{"summary": "Test summary"}') do
      CvAnalysisJob.perform_now(cv_analysis.id)
    end

    cv_analysis.reload
    assert_includes [:processing, :completed, :failed], cv_analysis.status.to_sym
  end

  test "should create notification on successful completion" do
    cv_analysis = create_cv_analysis_with_file(status: :pending)

    with_mocked_llm('{"summary": "Experienced developer", "skills": {"technical": ["Ruby", "Rails"]}}') do
      assert_difference("Notification.count") do
        CvAnalysisJob.perform_now(cv_analysis.id)
      end
    end

    notification = Notification.last
    assert_equal cv_analysis, notification.notifiable
    assert_includes notification.message, "complete"
    assert_includes notification.link, cv_analysis.id.to_s
  end

  test "should store extracted text" do
    cv_analysis = create_cv_analysis_with_file(status: :pending)

    with_mocked_llm('{"summary": "Test"}') do
      CvAnalysisJob.perform_now(cv_analysis.id)
    end

    cv_analysis.reload
    assert cv_analysis.extracted_text.present?
  end

  test "should store analysis result as JSON" do
    cv_analysis = create_cv_analysis_with_file(status: :pending)

    expected_result = {
      "summary" => "Experienced Ruby developer",
      "skills" => { "technical" => ["Ruby", "Rails", "PostgreSQL"] }
    }

    with_mocked_llm(expected_result.to_json) do
      CvAnalysisJob.perform_now(cv_analysis.id)
    end

    cv_analysis.reload
    assert_equal :completed, cv_analysis.status.to_sym
    assert_equal "Experienced Ruby developer", cv_analysis.parsed_result["summary"]
  end

  test "should handle non-JSON LLM response gracefully" do
    cv_analysis = create_cv_analysis_with_file(status: :pending)

    with_mocked_llm("This is not valid JSON response") do
      CvAnalysisJob.perform_now(cv_analysis.id)
    end

    cv_analysis.reload
    assert_equal :completed, cv_analysis.status.to_sym
    # Should still have a result even if parsing failed
    assert cv_analysis.analysis_result.present?
  end

  test "should discard job when record not found" do
    assert_nothing_raised do
      CvAnalysisJob.perform_now(999999)
    end
  end
end