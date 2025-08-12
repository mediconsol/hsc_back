class CreateFacilities < ActiveRecord::Migration[8.0]
  def change
    create_table :facilities do |t|
      t.string :name, null: false
      t.string :facility_type, null: false
      t.string :building
      t.integer :floor
      t.string :room_number
      t.integer :capacity
      t.string :status, default: 'active'
      t.references :manager, null: true, foreign_key: { to_table: :users }
      t.text :description

      t.timestamps
    end
    
    add_index :facilities, [:building, :floor, :room_number], unique: true
    add_index :facilities, :facility_type
    add_index :facilities, :status
  end
end
