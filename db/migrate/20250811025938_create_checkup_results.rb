class CreateCheckupResults < ActiveRecord::Migration[8.0]
  def change
    create_table :checkup_results do |t|
      t.references :health_checkup, null: false, foreign_key: true
      t.string :test_category
      t.string :test_name
      t.string :result_value
      t.string :reference_range
      t.string :result_status
      t.text :notes

      t.timestamps
    end
  end
end
