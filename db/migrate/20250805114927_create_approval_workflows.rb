class CreateApprovalWorkflows < ActiveRecord::Migration[8.0]
  def change
    create_table :approval_workflows do |t|
      t.references :document, null: false, foreign_key: true
      t.string :workflow_name
      t.text :approvers_data
      t.string :workflow_type
      t.boolean :is_sequential

      t.timestamps
    end
  end
end
