class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses do |t|
      t.string :title, null: false
      t.text :description
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.date :expense_date, null: false
      t.string :category, null: false
      t.string :department, null: false
      t.string :vendor
      t.string :payment_method, null: false, default: 'card'
      t.string :receipt_number
      t.string :status, null: false, default: 'pending'
      t.references :budget, null: true, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :approver, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
    
    add_index :expenses, :expense_date
    add_index :expenses, :category
    add_index :expenses, :department
    add_index :expenses, :status
  end
end
