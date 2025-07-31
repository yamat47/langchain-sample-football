# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_31_003223) do
  create_table "book_queries", force: :cascade do |t|
    t.text "query_text", null: false
    t.text "response_text"
    t.boolean "success", default: false
    t.string "error_message"
    t.integer "response_time_ms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_book_queries_on_created_at"
  end

  create_table "book_similarities", force: :cascade do |t|
    t.integer "book_id", null: false
    t.integer "similar_book_id", null: false
    t.decimal "similarity_score", precision: 3, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "similar_book_id"], name: "index_book_similarities_on_book_id_and_similar_book_id", unique: true
    t.index ["book_id"], name: "index_book_similarities_on_book_id"
    t.index ["similar_book_id"], name: "index_book_similarities_on_similar_book_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "isbn", null: false
    t.string "title", null: false
    t.string "author", null: false
    t.string "publisher"
    t.text "description"
    t.decimal "price", precision: 10, scale: 2
    t.text "genres"
    t.decimal "rating", precision: 3, scale: 2, default: "0.0"
    t.integer "page_count"
    t.string "language", default: "en"
    t.date "published_at"
    t.string "availability_status", default: "available"
    t.boolean "is_trending", default: false
    t.integer "trending_score", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_url"
    t.string "thumbnail_url"
    t.index ["author"], name: "index_books_on_author"
    t.index ["is_trending", "trending_score"], name: "index_books_on_is_trending_and_trending_score"
    t.index ["isbn"], name: "index_books_on_isbn", unique: true
    t.index ["title"], name: "index_books_on_title"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.integer "chat_session_id", null: false
    t.string "role", null: false
    t.text "content", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_session_id", "position"], name: "index_chat_messages_on_chat_session_id_and_position", unique: true
    t.index ["chat_session_id"], name: "index_chat_messages_on_chat_session_id"
    t.index ["created_at"], name: "index_chat_messages_on_created_at"
  end

  create_table "chat_sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "session_number", null: false
    t.datetime "last_activity_at", null: false
    t.integer "messages_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_chat_sessions_on_created_at"
    t.index ["user_id", "last_activity_at"], name: "index_chat_sessions_on_user_id_and_last_activity_at"
    t.index ["user_id", "session_number"], name: "index_chat_sessions_on_user_id_and_session_number", unique: true
    t.index ["user_id"], name: "index_chat_sessions_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "book_id", null: false
    t.integer "rating", null: false
    t.text "content"
    t.string "reviewer_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_reviews_on_book_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "anonymous", default: false, null: false
    t.index ["anonymous"], name: "index_users_on_anonymous"
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["identifier"], name: "index_users_on_identifier", unique: true
  end

  add_foreign_key "book_similarities", "books"
  add_foreign_key "book_similarities", "books", column: "similar_book_id"
  add_foreign_key "chat_messages", "chat_sessions"
  add_foreign_key "chat_sessions", "users"
  add_foreign_key "reviews", "books"
end
