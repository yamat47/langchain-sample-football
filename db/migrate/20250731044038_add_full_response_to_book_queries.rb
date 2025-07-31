class AddFullResponseToBookQueries < ActiveRecord::Migration[8.0]
  def change
    add_column :book_queries, :full_response, :text
  end
end
