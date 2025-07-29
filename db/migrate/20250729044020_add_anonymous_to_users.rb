class AddAnonymousToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :anonymous, :boolean, default: false, null: false
    add_index :users, :anonymous
  end
end
