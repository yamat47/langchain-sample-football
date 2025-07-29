class CreateChatSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :session_number, null: false
      t.datetime :last_activity_at, null: false
      t.integer :messages_count, default: 0, null: false
      t.timestamps
    end

    add_index :chat_sessions, [:user_id, :session_number], unique: true
    add_index :chat_sessions, [:user_id, :last_activity_at]
    add_index :chat_sessions, :created_at
  end
end
