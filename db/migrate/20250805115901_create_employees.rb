class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.string :name
      t.string :department
      t.string :position
      t.string :employment_type
      t.date :hire_date
      t.string :phone
      t.string :email
      t.decimal :base_salary
      t.decimal :hourly_rate
      t.string :salary_type
      t.string :status

      t.timestamps
    end
  end
end
