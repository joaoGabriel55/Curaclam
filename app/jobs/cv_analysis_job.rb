class CvAnalysisJob < ApplicationJob
  queue_as :default

  # Retry on transient failures
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  # Discard job if the record no longer exists
  discard_on ActiveRecord::RecordNotFound

  def perform(cv_analysis_id)
    cv_analysis = CvAnalysis.find(cv_analysis_id)

    # Update status to processing
    cv_analysis.update!(status: :processing)

    begin
      extracted_text = extract_text_from_pdf(cv_analysis)

      if extracted_text.blank?
        raise "Could not extract text from PDF. The file might be empty or image-based."
      end

      cv_analysis.update!(extracted_text: extracted_text)

      analyze_with_llm(extracted_text, cv_analysis)
    rescue => e
      Rails.logger.error("CV Analysis failed for ID #{cv_analysis_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      cv_analysis.update!(
        status: :failed,
        error_message: e.message
      )

      create_failure_notification(cv_analysis, e.message)

      # Re-raise to trigger retry mechanism for retryable errors
      raise e unless e.message.include?("Could not extract text")
    end
  end

  private

  def extract_text_from_pdf(cv_analysis)
    return nil unless cv_analysis.cv_file.attached?

    # Download the file to a temp location and extract text
    cv_analysis.cv_file.open do |file|
      reader = PDF::Reader.new(file.path)
      text_parts = []

      reader.pages.each do |page|
        text_parts << page.text
      end

      text_parts.join("\n\n")
    end
  end

  def analyze_with_llm(extracted_text, cv_analysis)
    prompt = build_analysis_prompt(extracted_text)

    tool = McpTools::NormalizeResumeTool.new(cv_analysis)

    chat = RubyLLM.chat(provider: :ollama)
      .with_tool(tool)
      .on_tool_call do |tool_call|
        puts "Calling tool: #{tool_call.name}"
        puts "Arguments: #{tool_call.arguments}"
      end
      .on_tool_result do |result|
        create_success_notification(cv_analysis)
      end

    response = chat.ask(prompt)

    response.content
  end

  def build_analysis_prompt(extracted_text)
    prompt = File.read("app/jobs/prompt.md")

    <<~PROMPT
      #{prompt}

      ## raw curriculum text:
      #{extracted_text}
    PROMPT
  end

  def create_success_notification(cv_analysis)
    Notification.create!(
      notifiable: cv_analysis,
      message: "Your CV analysis is complete! Click to view the results.",
      link: "/cv_analyses/#{cv_analysis.id}"
    )
  end

  def create_failure_notification(cv_analysis, error_message)
    Notification.create!(
      notifiable: cv_analysis,
      message: "CV analysis failed: #{error_message.truncate(100)}",
      link: "/cv_analyses/#{cv_analysis.id}"
    )
  end
end
