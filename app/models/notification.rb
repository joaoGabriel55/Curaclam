class Notification < ApplicationRecord
  # Include Turbo broadcasts
  include Turbo::Broadcastable

  # Polymorphic association - can belong to any notifiable model
  belongs_to :notifiable, polymorphic: true

  # Validations
  validates :message, presence: true

  # Scopes
  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :latest, ->(count = 10) { recent.limit(count) }

  # Broadcast to navbar notifications when created
  after_create_commit :broadcast_navbar_update

  # Mark notification as read
  def mark_as_read!
    update!(read: true)
  end

  # Mark notification as unread
  def mark_as_unread!
    update!(read: false)
  end

  # Class method to mark all notifications as read
  def self.mark_all_as_read!
    unread.update_all(read: true)
  end

  # Check if notification has a valid link
  def has_link?
    link.present?
  end

  private

  def broadcast_navbar_update
    broadcast_replace_to(
      "global_notifications",
      target: "navbar-notifications-content",
      partial: "shared/navbar_notifications"
    )
  end
end
