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
      # Step 1: Extract text from PDF
      extracted_text = extract_text_from_pdf(cv_analysis)

      if extracted_text.blank?
        raise "Could not extract text from PDF. The file might be empty or image-based."
      end

      cv_analysis.update!(extracted_text: extracted_text)

      # Step 2: Analyze with LLM
      analysis_result = analyze_with_llm(extracted_text)

      # Step 3: Save results and mark as completed
      cv_analysis.update!(
        analysis_result: analysis_result,
        status: :completed
      )

      # Step 4: Create notification
      create_success_notification(cv_analysis)

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

  def analyze_with_llm(extracted_text)
    prompt = build_analysis_prompt(extracted_text)

    chat = RubyLLM.chat(provider: :ollama)
    response = chat.ask(prompt)

    # Parse the JSON response from LLM
    parse_llm_response(response.content)
  end

  def build_analysis_prompt(extracted_text)
    <<~PROMPT
      You are an expert HR assistant specialized in analyzing CVs/resumes.
      Analyze the following CV text and extract structured information.

      Return your analysis as a valid JSON object with the following structure:
      {
        "personal_info": {
          "name": "Full name of the candidate",
          "email": "Email address if found",
          "phone": "Phone number if found",
          "location": "City/Country if found",
          "linkedin": "LinkedIn URL if found",
          "portfolio": "Portfolio/Website URL if found"
        },
        "summary": "A brief professional summary (2-3 sentences)",
        "skills": {
          "technical": ["List of technical skills"],
          "soft_skills": ["List of soft skills"],
          "languages": ["List of languages spoken with proficiency level"]
        },
        "experience": [
          {
            "title": "Job title",
            "company": "Company name",
            "period": "Employment period",
            "description": "Brief description of responsibilities and achievements"
          }
        ],
        "education": [
          {
            "degree": "Degree/Certificate name",
            "institution": "School/University name",
            "year": "Graduation year or period",
            "details": "Any additional details like GPA, honors, etc."
          }
        ],
        "certifications": ["List of certifications"],
        "highlights": ["3-5 key highlights or achievements from the CV"],
        "recommendations": ["2-3 suggestions for improving this CV"]
      }

      If any information is not available in the CV, use null for that field.
      Ensure the response is valid JSON only, with no additional text before or after.

      CV TEXT:
      #{extracted_text}
    PROMPT
  end

  def parse_llm_response(content)
    # Try to extract JSON from the response
    json_match = content.match(/\{[\s\S]*\}/)

    if json_match
      JSON.parse(json_match[0])
    else
      # If no JSON found, create a basic structure with the raw response
      {
        "summary" => content,
        "parse_error" => "Could not parse structured response from LLM"
      }
    end
  rescue JSON::ParserError => e
    Rails.logger.warn("Failed to parse LLM response as JSON: #{e.message}")
    {
      "summary" => content,
      "parse_error" => "Invalid JSON in LLM response: #{e.message}"
    }
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
