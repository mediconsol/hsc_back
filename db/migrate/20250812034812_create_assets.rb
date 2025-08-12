class CreateAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :assets do |t|
      t.string :name, null: false
      t.string :asset_type, null: false
      t.string :category
      t.string :model
      t.string :serial_number, null: false
      t.date :purchase_date
      t.decimal :purchase_price, precision: 12, scale: 2
      t.string :vendor
      t.date :warranty_expiry
      t.string :status, default: 'active'
      t.references :facility, null: true, foreign_key: true
      t.references :manager, null: true, foreign_key: { to_table: :users }
      t.text :description

      t.timestamps
    end
    
    add_index :assets, :serial_number, unique: true
    add_index :assets, :asset_type
    add_index :assets, :category
    add_index :assets, :status
    add_index :assets, :purchase_date
    add_index :assets, :warranty_expiry
  end
end
