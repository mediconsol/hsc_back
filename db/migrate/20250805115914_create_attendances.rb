class CreateAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.references :employee, null: false, foreign_key: true
      t.datetime :check_in
      t.datetime :check_out
      t.date :work_date
      t.decimal :regular_hours
      t.decimal :overtime_hours
      t.decimal :night_hours
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
