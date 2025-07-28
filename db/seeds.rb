# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Book data
books_data = [
  # Fiction & Literature
  { title: "Norwegian Wood", author: "Haruki Murakami", genre: "Fiction" },
  { title: "1Q84", author: "Haruki Murakami", genre: "Fiction" },
  { title: "Kafka on the Shore", author: "Haruki Murakami", genre: "Fiction" },
  { title: "The Great Gatsby", author: "F. Scott Fitzgerald", genre: "Classic" },
  { title: "To Kill a Mockingbird", author: "Harper Lee", genre: "Classic" },
  { title: "1984", author: "George Orwell", genre: "Dystopian" },
  { title: "Pride and Prejudice", author: "Jane Austen", genre: "Romance" },
  { title: "The Catcher in the Rye", author: "J.D. Salinger", genre: "Fiction" },
  
  # Mystery & Thriller
  { title: "The Girl with the Dragon Tattoo", author: "Stieg Larsson", genre: "Mystery" },
  { title: "Gone Girl", author: "Gillian Flynn", genre: "Thriller" },
  { title: "The Da Vinci Code", author: "Dan Brown", genre: "Mystery" },
  { title: "And Then There Were None", author: "Agatha Christie", genre: "Mystery" },
  { title: "The Silent Patient", author: "Alex Michaelides", genre: "Thriller" },
  { title: "Big Little Lies", author: "Liane Moriarty", genre: "Mystery" },
  
  # Science Fiction & Fantasy
  { title: "The Three-Body Problem", author: "Liu Cixin", genre: "Science Fiction" },
  { title: "Project Hail Mary", author: "Andy Weir", genre: "Science Fiction" },
  { title: "Dune", author: "Frank Herbert", genre: "Science Fiction" },
  { title: "The Lord of the Rings", author: "J.R.R. Tolkien", genre: "Fantasy" },
  { title: "Harry Potter and the Sorcerer's Stone", author: "J.K. Rowling", genre: "Fantasy" },
  { title: "The Hobbit", author: "J.R.R. Tolkien", genre: "Fantasy" },
  
  # Business & Self-Help
  { title: "Atomic Habits", author: "James Clear", genre: "Self-Help" },
  { title: "The 7 Habits of Highly Effective People", author: "Stephen R. Covey", genre: "Self-Help" },
  { title: "Thinking, Fast and Slow", author: "Daniel Kahneman", genre: "Psychology" },
  { title: "How to Win Friends and Influence People", author: "Dale Carnegie", genre: "Self-Help" },
  { title: "The Lean Startup", author: "Eric Ries", genre: "Business" },
  
  # Non-Fiction
  { title: "Sapiens: A Brief History of Humankind", author: "Yuval Noah Harari", genre: "History" },
  { title: "Educated", author: "Tara Westover", genre: "Memoir" },
  { title: "Becoming", author: "Michelle Obama", genre: "Memoir" },
  { title: "Factfulness", author: "Hans Rosling", genre: "Science" },
  
  # Biography & Essays
  { title: "Steve Jobs", author: "Walter Isaacson", genre: "Biography" },
  { title: "When Breath Becomes Air", author: "Paul Kalanithi", genre: "Memoir" },
  { title: "The Art of War", author: "Sun Tzu", genre: "Philosophy" }
]

# Review text variations
review_templates = {
  positive: [
    # Emotional impact
    "This book left me speechless. I sat in stunned silence after finishing it, processing the profound impact it had on me.",
    "I couldn't stop the tears from flowing. The characters felt so real, their emotions became my own.",
    "Life-changing. This book fundamentally altered how I see the world.",
    "A masterpiece that will stay with me forever. I'll be rereading this for years to come.",
    "Absolutely breathtaking. The author's ability to capture the human experience is unparalleled.",
    "This touched my soul in ways I didn't expect. Pure literary magic.",
    
    # Intellectual stimulation
    "Brilliantly thought-provoking. Every page challenged my assumptions and expanded my worldview.",
    "Mind-blowing insights throughout. The author's research and analysis are impeccable.",
    "Complex ideas made beautifully accessible. This should be required reading.",
    "The perfect introduction to this field. Clear, comprehensive, and engaging.",
    "Intellectually satisfying on every level. I learned something new with each chapter.",
    "Eye-opening and educational without being preachy. Perfectly balanced.",
    
    # Page-turner qualities
    "Couldn't put it down! I devoured this in one sitting.",
    "Stayed up all night reading. Haven't been this engrossed in a book in years.",
    "Thrilling from start to finish. My heart was racing the entire time.",
    "Unexpected twists kept me guessing until the very last page.",
    "Addictive storytelling at its finest. Clear your schedule before starting this one.",
    "Un-put-downable! Cancelled all my plans to finish this masterpiece.",
    
    # Practical value
    "Immediately applicable advice. I've already implemented several strategies with great results.",
    "Practical, actionable, and transformative. Worth every penny.",
    "The examples and case studies made everything crystal clear. Incredibly useful.",
    "This book paid for itself within a week. The ROI on this knowledge is incredible.",
    "Finally, a book that delivers on its promises. Concrete tools I use daily.",
    "Evidence-based and practical. The perfect combination for real-world application.",
    
    # Writing quality
    "Exquisite prose that flows like poetry. A joy to read every sentence.",
    "The author's voice is distinctive and compelling. Couldn't get it out of my head.",
    "Beautifully written with vivid imagery that transported me completely.",
    "Perfect pacing and structure. A masterclass in storytelling.",
    "Elegant, witty, and profound. The writing alone makes this worth reading."
  ],
  
  neutral: [
    # Mixed feelings
    "Interesting concepts but somewhat repetitive. Could have been more concise.",
    "Strong start but lost momentum halfway through. Still worth reading overall.",
    "Not quite what I expected, but discovered some valuable insights anyway.",
    "This will resonate strongly with some readers. It wasn't entirely my cup of tea.",
    "Good ideas buried under unnecessary complexity. Requires patience.",
    "Some brilliant chapters mixed with filler. Inconsistent but has its moments.",
    
    # Conditional recommendations
    "Recommended for serious students of the subject. Casual readers might struggle.",
    "Fans of the author will love this. Newcomers should start with their earlier work.",
    "Best read when you have time to digest it slowly. Not light reading.",
    "The translation is serviceable but misses some nuances of the original.",
    "Genre enthusiasts will appreciate this more than general readers.",
    "Requires background knowledge to fully appreciate. Do your homework first.",
    
    # Specific audiences
    "Perfect for academics, perhaps too dense for leisure reading.",
    "Young adults will relate strongly. Older readers might find it simplistic.",
    "Business professionals will find value here. Others may find it dry.",
    "Dated in some ways but the core message remains relevant."
  ],
  
  negative: [
    # Disappointment
    "The hype led me to expect much more. Sadly underwhelming.",
    "Doesn't live up to its reputation. I'm genuinely puzzled by the praise.",
    "DNF at 40%. Life's too short for books that don't grab you.",
    "Felt like a waste of time. Nothing new or insightful here.",
    "Expected so much more from this author. A real letdown.",
    "All style, no substance. Pretty words hiding empty ideas.",
    
    # Structural issues
    "Poorly organized and confusing. The main argument gets lost.",
    "The writing style is a significant barrier to understanding the content.",
    "Repetitive to the point of frustration. This could have been an article.",
    "Too much jargon and not enough clarity. Inaccessible to most readers.",
    "Needed a better editor. Rambling and unfocused throughout.",
    "Plot holes you could drive a truck through. Lazy storytelling.",
    
    # Credibility problems
    "Cherry-picked data to support predetermined conclusions. Not credible.",
    "The author's bias is overwhelming and undermines the message.",
    "Outdated information presented as current. Do your fact-checking.",
    "Gross oversimplification of complex issues. Insulting to readers' intelligence."
  ]
}

# Create seed data
books_data.each_with_index do |book_data, index|
  book = Book.find_or_create_by!(title: book_data[:title]) do |b|
    b.author = book_data[:author]
    b.genres = [book_data[:genre]]
    b.isbn = "978-#{1000000000 + index}"  # Generate deterministic ISBN
  end
  
  # Add deterministic reviews for each book
  reviewer_names = ["BookLover123", "AvdReader", "LiteraryNerd", "PageTurner", "CasualReader", "BookExpert", "StudentLife", "BusyProfessional", "BookishMom", "LibrarianReads", "Fiction_Fanatic", "Mystery_Maven", "SciFiGeek", "HistoryBuff", "PhilosophyProf", "NovelNovice", "CriticalReader", "BookwormBeth", "ReadingRita", "JustFinishedThis"]
  
  # Use book index to determine number of reviews (3-5) deterministically
  num_reviews = 3 + (index % 3)
  
  num_reviews.times do |review_index|
    # Use deterministic selection based on indices
    review_type_index = (index + review_index) % 5
    review_type = [:positive, :positive, :positive, :neutral, :negative][review_type_index]
    
    # Select review text deterministically
    review_texts = review_templates[review_type]
    review_text = review_texts[(index + review_index) % review_texts.length]
    
    # Determine rating deterministically
    rating = case review_type
    when :positive
      4 + (review_index % 2)  # 4 or 5
    when :neutral
      2 + (review_index % 3)  # 2, 3, or 4
    when :negative
      1 + (review_index % 2)  # 1 or 2
    end
    
    # Select reviewer name deterministically
    reviewer_name = reviewer_names[(index + review_index) % reviewer_names.length]
    
    Review.find_or_create_by!(
      book: book,
      reviewer_name: reviewer_name
    ) do |r|
      r.content = review_text
      r.rating = rating
    end
  end
end

puts "Created #{Book.count} books with #{Review.count} reviews."
