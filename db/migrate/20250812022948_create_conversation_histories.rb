class CreateConversationHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :conversation_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :persona, null: false, default: 'default'
      t.string :message_type, null: false # 'user' or 'ai'
      t.text :content, null: false
      t.datetime :timestamp, null: false
      t.string :session_id # 대화 세션 그룹핑용

      t.timestamps
    end
    
    add_index :conversation_histories, [:user_id, :timestamp]
    add_index :conversation_histories, [:user_id, :persona]
    add_index :conversation_histories, :session_id
  end
end
