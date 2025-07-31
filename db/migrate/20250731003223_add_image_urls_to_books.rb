# frozen_string_literal: true

class AddImageUrlsToBooks < ActiveRecord::Migration[8.0]
  def change
    add_column :books, :image_url, :string
    add_column :books, :thumbnail_url, :string
  end
end
