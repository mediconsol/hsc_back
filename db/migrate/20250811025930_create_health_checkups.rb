class CreateHealthCheckups < ActiveRecord::Migration[8.0]
  def change
    create_table :health_checkups do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :appointment, foreign_key: true
      t.datetime :checkup_date
      t.string :checkup_type
      t.string :package_name
      t.string :status
      t.decimal :total_cost, precision: 10, scale: 2
      t.boolean :insurance_covered, default: false
      t.references :assigned_doctor, foreign_key: { to_table: :employees }

      t.timestamps
    end
    
    add_index :health_checkups, :checkup_date
    add_index :health_checkups, :status
    add_index :health_checkups, :checkup_type
  end
end
