class CreateMedicalHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :medical_histories do |t|
      t.references :patient, null: false, foreign_key: true
      t.string :disease_name
      t.date :diagnosis_date
      t.string :treatment_status
      t.text :medication
      t.text :notes

      t.timestamps
    end
  end
end
