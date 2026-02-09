require "test_helper"

class NotificationTest < ActiveSupport::TestCase
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
    @cv_analysis = create_cv_analysis_with_file(status: :completed)
  end

  test "should validate message presence" do
    notification = Notification.new(notifiable: @cv_analysis, message: nil)
    assert_not notification.valid?
    assert_includes notification.errors[:message], "can't be blank"
  end

  test "should have default read value of false" do
    notification = Notification.new(notifiable: @cv_analysis, message: "Test")
    assert_equal false, notification.read
  end

  test "should belong to notifiable" do
    notification = Notification.create!(
      notifiable: @cv_analysis,
      message: "Test notification"
    )
    assert_equal @cv_analysis, notification.notifiable
  end

  test "mark_as_read! sets read to true" do
    notification = Notification.create!(
      notifiable: @cv_analysis,
      message: "Test",
      read: false
    )
    notification.mark_as_read!
    assert notification.read
  end

  test "mark_as_unread! sets read to false" do
    notification = Notification.create!(
      notifiable: @cv_analysis,
      message: "Test",
      read: true
    )
    notification.mark_as_unread!
    assert_not notification.read
  end

  test "unread scope returns only unread notifications" do
    unread = Notification.create!(notifiable: @cv_analysis, message: "Unread", read: false)
    Notification.create!(notifiable: @cv_analysis, message: "Read", read: true)

    assert_equal [unread], Notification.unread.to_a
  end

  test "recent scope orders by created_at desc" do
    old = Notification.create!(notifiable: @cv_analysis, message: "Old")
    new = Notification.create!(notifiable: @cv_analysis, message: "New")

    notifications = Notification.recent
    assert_equal new, notifications.first
    assert_equal old, notifications.last
  end

  test "latest scope limits results" do
    5.times { |i| Notification.create!(notifiable: @cv_analysis, message: "Notification #{i}") }

    assert_equal 3, Notification.latest(3).count
  end

  test "mark_all_as_read! marks all unread notifications as read" do
    Notification.create!(notifiable: @cv_analysis, message: "Unread 1", read: false)
    Notification.create!(notifiable: @cv_analysis, message: "Unread 2", read: false)
    Notification.create!(notifiable: @cv_analysis, message: "Read", read: true)

    Notification.mark_all_as_read!

    assert_equal 0, Notification.unread.count
  end

  test "has_link? returns true when link is present" do
    notification = Notification.new(link: "/cv_analyses/1")
    assert notification.has_link?
  end

  test "has_link? returns false when link is blank" do
    notification = Notification.new(link: nil)
    assert_not notification.has_link?

    notification.link = ""
    assert_not notification.has_link?
  end
end