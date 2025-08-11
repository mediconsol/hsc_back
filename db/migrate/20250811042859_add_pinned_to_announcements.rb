class AddPinnedToAnnouncements < ActiveRecord::Migration[8.0]
  def change
    add_column :announcements, :is_pinned, :boolean, default: false, null: false
    add_column :announcements, :pinned_at, :datetime
    add_index :announcements, [:is_pinned, :pinned_at]
  end
end
