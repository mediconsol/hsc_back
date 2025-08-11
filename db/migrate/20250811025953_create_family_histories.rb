class CreateFamilyHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :family_histories do |t|
      t.references :patient, null: false, foreign_key: true
      t.string :relationship
      t.string :disease_name
      t.text :notes

      t.timestamps
    end
  end
end
