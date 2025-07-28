class CreateBookRecommendationTables < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :isbn, null: false, index: { unique: true }
      t.string :title, null: false
      t.string :author, null: false
      t.string :publisher
      t.text :description
      t.decimal :price, precision: 10, scale: 2
      t.text :genres # Will store as JSON in SQLite
      t.decimal :rating, precision: 3, scale: 2, default: 0.0
      t.integer :page_count
      t.string :language, default: "en"
      t.date :published_at
      t.string :availability_status, default: "available"
      t.boolean :is_trending, default: false
      t.integer :trending_score, default: 0

      t.timestamps
    end

    create_table :book_similarities do |t|
      t.references :book, null: false, foreign_key: true
      t.references :similar_book, null: false, foreign_key: { to_table: :books }
      t.decimal :similarity_score, precision: 3, scale: 2, null: false

      t.timestamps
    end

    create_table :reviews do |t|
      t.references :book, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :content
      t.string :reviewer_name

      t.timestamps
    end

    create_table :book_queries do |t|
      t.text :query_text, null: false
      t.text :response_text
      t.boolean :success, default: false
      t.string :error_message
      t.integer :response_time_ms

      t.timestamps
    end

    # Indexes
    add_index :books, :title
    add_index :books, :author
    add_index :books, [:is_trending, :trending_score]
    add_index :book_similarities, [:book_id, :similar_book_id], unique: true
    add_index :book_queries, :created_at
  end
end
