class AddHealthCheckupFieldsToPatients < ActiveRecord::Migration[8.0]
  def change
    add_column :patients, :patient_number, :string
    add_column :patients, :occupation, :string
    add_column :patients, :blood_type, :string
    add_column :patients, :height, :decimal
    add_column :patients, :weight, :decimal
    add_column :patients, :smoking_status, :string
    add_column :patients, :drinking_status, :string
    add_column :patients, :exercise_status, :string
    add_column :patients, :last_checkup_date, :date
    add_column :patients, :checkup_cycle, :integer
  end
end
