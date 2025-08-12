class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string :invoice_number, null: false
      t.string :vendor, null: false
      t.date :issue_date, null: false
      t.date :due_date, null: false
      t.decimal :total_amount, precision: 15, scale: 2, null: false
      t.decimal :tax_amount, precision: 15, scale: 2, null: false, default: 0
      t.decimal :net_amount, precision: 15, scale: 2, null: false
      t.string :status, null: false, default: 'received'
      t.date :payment_date
      t.text :notes
      t.references :processor, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
    
    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :vendor
    add_index :invoices, :issue_date
    add_index :invoices, :due_date
    add_index :invoices, :status
  end
end
