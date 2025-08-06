class CreateApprovals < ActiveRecord::Migration[8.0]
  def change
    create_table :approvals do |t|
      t.references :document, null: false, foreign_key: true
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.string :status
      t.text :comments
      t.datetime :approved_at
      t.integer :order_index

      t.timestamps
    end
  end
end
