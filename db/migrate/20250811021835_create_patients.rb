class CreatePatients < ActiveRecord::Migration[8.0]
  def change
    create_table :patients do |t|
      t.string :name
      t.date :birth_date
      t.string :gender
      t.string :phone
      t.string :email
      t.text :address
      t.string :insurance_type
      t.string :insurance_number
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.text :notes
      t.string :status

      t.timestamps
    end
  end
end
