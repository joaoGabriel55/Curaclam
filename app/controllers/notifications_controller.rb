class NotificationsController < ApplicationController
  before_action :set_notification, only: [:mark_as_read]

  # GET /notifications
  def index
    @notifications = Notification.recent.includes(:notifiable)
  end

  # POST /notifications/:id/mark_as_read
  def mark_as_read
    @notification.mark_as_read!

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.turbo_stream
      format.json { head :ok }
    end
  end

  # POST /notifications/mark_all_as_read
  def mark_all_as_read
    Notification.mark_all_as_read!

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "All notifications marked as read." }
      format.turbo_stream
      format.json { head :ok }
    end
  end

  # GET /notifications/unread_count
  def unread_count
    count = Notification.unread.count

    respond_to do |format|
      format.json { render json: { count: count } }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("unread-count", partial: "notifications/unread_count", locals: { count: count }) }
    end
  end

  private

  def set_notification
    @notification = Notification.find(params[:id])
  end
end