class CreateBudgets < ActiveRecord::Migration[8.0]
  def change
    create_table :budgets do |t|
      t.string :department, null: false
      t.string :category, null: false
      t.integer :fiscal_year, null: false
      t.string :period_type, null: false, default: 'annual'
      t.decimal :allocated_amount, precision: 15, scale: 2, null: false, default: 0
      t.decimal :used_amount, precision: 15, scale: 2, null: false, default: 0
      t.string :status, null: false, default: 'active'
      t.references :manager, null: false, foreign_key: { to_table: :users }
      t.text :description

      t.timestamps
    end
    
    add_index :budgets, [:department, :category, :fiscal_year], unique: true
    add_index :budgets, :fiscal_year
    add_index :budgets, :status
  end
end
