class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.string :title
      t.text :content
      t.integer :priority
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :department
      t.datetime :published_at
      t.boolean :is_published

      t.timestamps
    end
  end
end
