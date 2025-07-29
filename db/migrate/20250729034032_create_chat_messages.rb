class CreateChatMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_messages do |t|
      t.references :chat_session, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.integer :position, null: false
      t.timestamps
    end

    add_index :chat_messages, [:chat_session_id, :position], unique: true
    add_index :chat_messages, :created_at
  end
end
