class CreateMaintenances < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenances do |t|
      t.references :asset, null: false, foreign_key: true
      t.string :maintenance_type, null: false
      t.date :scheduled_date, null: false
      t.date :completed_date
      t.text :description
      t.decimal :cost, precision: 10, scale: 2
      t.string :technician
      t.string :status, default: 'scheduled'
      t.text :notes

      t.timestamps
    end
    
    add_index :maintenances, :maintenance_type
    add_index :maintenances, :scheduled_date
    add_index :maintenances, :completed_date
    add_index :maintenances, :status
  end
end
