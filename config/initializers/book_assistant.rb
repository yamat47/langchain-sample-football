# frozen_string_literal: true

# Book Assistant configuration
Rails.application.config.book_assistant = {
  max_search_results: 20,
  max_similar_books: 10,
  default_page_size: 20,

  # Fixed initial greeting
  initial_greeting: "Hello! I'm your personal book recommendation assistant. I can help you discover amazing books, find similar titles, check what's trending, and even search for the latest book news. What would you like to explore today?",

  # Sample queries for users
  sample_queries: [
    # Genre-based queries
    "What are the best science fiction books of 2024?",
    "Show me highly rated mystery novels",
    "I love fantasy books with strong female leads",
    "Recommend some page-turning thrillers",
    "What are some good romance novels for beginners?",
    "Find me literary fiction that won awards",
    "I want to read more diverse authors in fantasy",
    "What are the must-read classics I should know?",

    # Author-based queries
    "Find books by Stephen King",
    "What's the latest from Haruki Murakami?",
    "Show me books similar to J.K. Rowling's style",
    "Who writes like Agatha Christie?",
    "Recommend authors similar to Brandon Sanderson",

    # Similarity queries
    "What's similar to Harry Potter?",
    "I loved The Hunger Games, what should I read next?",
    "Books like Gone Girl but less dark",
    "Find me books similar to The Lord of the Rings",
    "What's like Pride and Prejudice but modern?",

    # Trending and news queries
    "What books are trending right now?",
    "Show me this week's bestsellers",
    "What won the Booker Prize this year?",
    "Any new book releases this month?",
    "What are critics recommending lately?",
    "Check the latest book news",

    # Specific criteria queries
    "Books under 300 pages that are highly rated",
    "Recent books about climate change",
    "Business books published in the last year",
    "Short story collections with 5-star ratings",
    "Non-fiction books about space exploration",

    # Mood-based queries
    "I need a feel-good book to cheer me up",
    "Something dark and atmospheric for winter",
    "Light beach reads for vacation",
    "Inspiring books about overcoming challenges",
    "Cozy mysteries for a rainy day",

    # Learning queries
    "Best books to learn about investing",
    "Beginner-friendly philosophy books",
    "Books to understand quantum physics",
    "History books that read like novels",
    "Psychology books for general readers",

    # Specific situations
    "Good book club picks for diverse groups",
    "YA books appropriate for 13-year-olds",
    "Audiobook recommendations for commuting",
    "Books to gift a book lover",
    "Series I can binge read"
  ]
}
