class CreateDepartmentPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :department_posts do |t|
      t.string :title
      t.text :content
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :department
      t.string :category
      t.integer :priority
      t.boolean :is_public
      t.integer :views_count

      t.timestamps
    end
  end
end
