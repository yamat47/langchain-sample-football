# frozen_string_literal: true

namespace :books do
  desc "Update books with placeholder images to use real book cover URLs"
  task update_placeholder_images: :environment do
    # Book image mapping
    image_updates = {
      "The Girl with the Dragon Tattoo" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1684638853i/2429135.jpg",
      "Gone Girl" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1554086139i/19288043.jpg",
      "The Da Vinci Code" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1579621267i/968.jpg",
      "And Then There Were None" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1638425885i/16299.jpg",
      "The Silent Patient" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1668782119i/40097951.jpg",
      "Big Little Lies" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1601552234i/19486412.jpg",
      "The Three-Body Problem" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1415428227i/20518872.jpg",
      "Project Hail Mary" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1597695864i/54493401.jpg",
      "Dune" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1555447414i/44767458.jpg",
      "The Lord of the Rings" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1566425108i/33.jpg",
      "Harry Potter and the Sorcerer's Stone" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1598823299i/42844155.jpg",
      "The Hobbit" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1546071216i/5907.jpg",
      "Atomic Habits" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1655988385i/40121378.jpg",
      "The 7 Habits of Highly Effective People" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1421842784i/36072.jpg",
      "Thinking, Fast and Slow" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1317793965i/11468377.jpg",
      "How to Win Friends and Influence People" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1442726934i/4865.jpg",
      "The Lean Startup" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1629999184i/10127019.jpg",
      "Sapiens: A Brief History of Humankind" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1595674533i/23692271.jpg",
      "Educated" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1506026635i/35133922.jpg",
      "Becoming" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1528206996i/38746485.jpg",
      "Factfulness" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1544963815i/34890015.jpg",
      "Steve Jobs" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1511288482i/11084145.jpg",
      "When Breath Becomes Air" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1492677644i/25899336.jpg",
      "The Art of War" => "https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1630683326i/10534.jpg"
    }

    updated_count = 0
    
    Book.find_each do |book|
      # Update if book has placeholder image or no image
      if book.image_url.nil? || book.image_url.include?("via.placeholder.com")
        if new_image_url = image_updates[book.title]
          book.update!(
            image_url: new_image_url,
            thumbnail_url: new_image_url.gsub(/\.jpg$/, '_thumb.jpg')
          )
          updated_count += 1
          puts "Updated: #{book.title}"
        else
          puts "No image mapping found for: #{book.title}"
        end
      end
    end
    
    puts "\nUpdated #{updated_count} books with real cover images."
  end
end