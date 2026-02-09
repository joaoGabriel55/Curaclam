class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.string :message, null: false
      t.string :link
      t.boolean :read, null: false, default: false
      t.references :notifiable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :notifications, :read
    add_index :notifications, :created_at
  end
end