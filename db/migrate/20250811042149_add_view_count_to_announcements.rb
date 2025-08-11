class AddViewCountToAnnouncements < ActiveRecord::Migration[8.0]
  def change
    add_column :announcements, :view_count, :integer, default: 0, null: false
    add_index :announcements, :view_count
  end
end
