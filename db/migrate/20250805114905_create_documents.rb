class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.string :title
      t.text :content
      t.string :document_type
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :department
      t.integer :security_level
      t.string :status
      t.integer :version

      t.timestamps
    end
  end
end
