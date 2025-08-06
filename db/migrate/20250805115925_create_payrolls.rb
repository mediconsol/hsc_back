class CreatePayrolls < ActiveRecord::Migration[8.0]
  def change
    create_table :payrolls do |t|
      t.references :employee, null: false, foreign_key: true
      t.date :pay_period_start
      t.date :pay_period_end
      t.decimal :base_pay
      t.decimal :overtime_pay
      t.decimal :night_pay
      t.decimal :allowances
      t.decimal :deductions
      t.decimal :tax
      t.decimal :net_pay
      t.string :status

      t.timestamps
    end
  end
end
