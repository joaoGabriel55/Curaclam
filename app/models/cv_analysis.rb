class CvAnalysis < ApplicationRecord
  # Include Turbo broadcasts
  include Turbo::Broadcastable

  # ActiveStorage association for the PDF file
  has_one_attached :cv_file

  # Notifications association
  has_many :notifications, as: :notifiable, dependent: :destroy

  # Status enum for tracking analysis progress
  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, default: :pending

  # Validations
  validates :status, presence: true
  validates :cv_file, presence: { message: "must be attached" }
  validate :cv_file_must_be_pdf, if: -> { cv_file.attached? }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: :completed) }
  scope :pending_or_processing, -> { where(status: [ :pending, :processing ]) }

  # Broadcast status changes to the show page
  after_update_commit :broadcast_status_change, if: :status_changed_to_final?

  # Check if analysis is complete and has results
  def has_results?
    completed? && analysis_result.present?
  end

  # Get parsed analysis result
  def parsed_result
    return {} unless analysis_result.present?
    analysis_result.is_a?(Hash) ? analysis_result : JSON.parse(analysis_result)
  rescue JSON::ParserError
    {}
  end

  private

  def cv_file_must_be_pdf
    unless cv_file.content_type == "application/pdf"
      errors.add(:cv_file, "must be a PDF file")
    end
  end

  def status_changed_to_final?
    saved_change_to_status? && (completed? || failed?)
  end

  def broadcast_status_change
    broadcast_replace_to(
      "cv_analysis_#{id}",
      target: "cv-analysis-content",
      partial: "cv_analyses/analysis_content",
      locals: { cv_analysis: self }
    )
  end
end
