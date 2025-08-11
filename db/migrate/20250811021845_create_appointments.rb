class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.datetime :appointment_date
      t.string :appointment_type
      t.string :department
      t.text :chief_complaint
      t.string :status
      t.text :notes
      t.boolean :created_by_patient

      t.timestamps
    end
  end
end
