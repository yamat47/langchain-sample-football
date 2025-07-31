# frozen_string_literal: true

class BookRecommendationParser
  class InvalidBlockTypeError < StandardError; end

  VALID_BLOCK_TYPES = ["text", "book_card", "book_spotlight", "book_list", "image"].freeze

  class << self
    def schema
      {
        type: "object",
        properties: {
          blocks: {
            type: "array",
            items: {
              type: "object",
              properties: {
                type: {
                  type: "string",
                  enum: VALID_BLOCK_TYPES,
                  description: "The type of content block"
                },
                content: {
                  type: "object",
                  description: "The content specific to the block type"
                }
              },
              required: ["type", "content"]
            }
          }
        },
        required: ["blocks"]
      }
    end

    def create_parser
      Langchain::OutputParsers::StructuredOutputParser.from_json_schema(schema)
    end

    def format_instructions
      parser = create_parser
      <<~INSTRUCTIONS
        IMPORTANT: You MUST respond with ONLY a JSON object. Do not include any text before or after the JSON.
        DO NOT include any explanatory text before the JSON object.
        DO NOT include any text after the JSON object.
        ONLY output the JSON object starting with { and ending with }

        CRITICAL RULES:
        - ALWAYS respond with blocks, even for non-book queries
        - Non-book queries → Use only text blocks
        - "Show me [any genre] books" → ALWAYS use book_list
        - "Recommend books" → ALWAYS use book_list
        - Multiple books → ALWAYS use book_list
        - Single specific book → Use book_spotlight

        The JSON object MUST contain a "blocks" array as the top-level property.
        Your response must start with { and end with } with no other text.

        Block types you MUST use:
        1. "text" blocks: For ALL explanatory text, context, greetings, and transitions
           - content MUST have a "markdown" property with your text
        2. "book_card" blocks: For compact book displays in lists or comparisons
           - content MUST include: isbn, title, author, rating, genres (array), price, image_url, description
           - NOTE: description can be detailed (100-200 characters) when user asks for explanations
        3. "book_spotlight" blocks: For featuring a SINGLE book with extended description
           - content MUST include: isbn, title, author, rating, genres (array), price, image_url,#{' '}
             description, extended_description, key_themes (array), why_recommended, similar_books (array of titles)
        4. "book_list" blocks: For multiple related books shown together
           - content MUST have: title (string) and books (array of book_card objects)
           - ALWAYS use book_list when showing 2 or more books, even with detailed explanations

        REQUIRED: Always include text blocks to make your response conversational:
        - Start with a text block to greet or acknowledge the user's request
        - Add text blocks between book recommendations to provide context
        - End with a text block to conclude or ask if they need more help

        Usage guidelines:
        - Use "book_spotlight" when user asks for detailed information about ONE specific book
        - Use "book_list" when recommending MULTIPLE books (3 or more)
        - Use "book_card" only inside book_list blocks, never standalone
        - IMPORTANT: For queries like "recommend books", "show me books", "what should I read" → use book_list
        - IMPORTANT: "Show me [genre] books" or "books with detailed explanations" → use book_list
        - The book_card within book_list can include detailed descriptions

        Example with book_spotlight:
        {
          "blocks": [
            {
              "type": "text",
              "content": {
                "markdown": "Based on your interest in psychological thrillers, I have the perfect recommendation:"
              }
            },
            {
              "type": "book_spotlight",
              "content": {
                "isbn": "978-0-385-53978-1",
                "title": "Gone Girl",
                "author": "Gillian Flynn",
                "rating": 4.2,
                "genres": ["Mystery", "Thriller", "Psychological"],
                "price": 16.99,
                "image_url": "https://example.com/gone-girl.jpg",
                "description": "A twisted tale of a marriage gone terribly wrong",
                "extended_description": "When Amy Dunne disappears on her fifth wedding anniversary, her husband Nick becomes the prime suspect. As the police investigation unfolds, the town turns against Nick, and he realizes he's being framed. But who is setting him up, and why?",
                "key_themes": ["Marriage and deception", "Media manipulation", "Unreliable narrators", "Identity and performance"],
                "why_recommended": "This book revolutionized the psychological thriller genre with its shocking twists and complex character study. Flynn's masterful use of dual narration keeps readers guessing until the very end.",
                "similar_books": ["The Girl on the Train", "The Woman in the Window", "Big Little Lies"]
              }
            },
            {
              "type": "text",
              "content": {
                "markdown": "This book is perfect if you enjoy stories that challenge your perceptions and keep you guessing. Would you like to explore similar psychological thrillers?"
              }
            }
          ]
        }

        Example with book_list (including detailed explanations):
        {
          "blocks": [
            {
              "type": "text",
              "content": {
                "markdown": "Here are some great mystery novels with detailed explanations:"
              }
            },
            {
              "type": "book_list",
              "content": {
                "title": "Mystery Books with Detailed Explanations",
                "books": [
                  {
                    "isbn": "978-0-00-752773-7",
                    "title": "The Girl on the Train",
                    "author": "Paula Hawkins",
                    "rating": 4.0,
                    "genres": ["Mystery", "Thriller"],
                    "price": 14.99,
                    "image_url": "https://example.com/book1.jpg",
                    "description": "A gripping psychological thriller about obsession, memory, and the dangerous truths we hide from ourselves. Rachel's daily train commute becomes an obsession with a seemingly perfect couple, until one day everything changes."
                  },
                  {
                    "isbn": "978-0-385-53978-1",
                    "title": "Gone Girl",
                    "author": "Gillian Flynn",
                    "rating": 4.2,
                    "genres": ["Mystery", "Thriller"],
                    "price": 16.99,
                    "image_url": "https://example.com/book2.jpg",
                    "description": "A masterfully crafted psychological thriller that examines the dark side of marriage. When Amy disappears on her anniversary, her husband Nick becomes the prime suspect in a case that reveals shocking secrets."
                  }
                ]
              }
            },
            {
              "type": "text",
              "content": {
                "markdown": "Each of these books offers unique twists and psychological depth. Would you like more recommendations or additional details about any specific book?"
              }
            }
          ]
        }

        Example for non-book queries:
        {
          "blocks": [
            {
              "type": "text",
              "content": {
                "markdown": "Hello! I'm your book recommendation assistant. I can help you discover amazing books, find similar titles to your favorites, and explore new genres. What kind of books are you interested in today?"
              }
            }
          ]
        }

        #{parser.get_format_instructions}
      INSTRUCTIONS
    end

    def extract_text_content(blocks)
      return "" if blocks.nil? || blocks.empty?

      blocks
        .select { |block| block[:type] == "text" || block["type"] == "text" }
        .map { |block| block.dig(:content, :markdown) || block.dig("content", "markdown") }
        .compact
        .join("\n\n")
    end

    def book_to_block(book)
      {
        type: "book_card",
        content: {
          isbn: book.isbn,
          title: book.title,
          author: book.author,
          rating: book.rating,
          review_count: book.review_count,
          genres: book.genres || [],
          price: book.price,
          image_url: book.image_url,
          description: book.description
        }
      }
    end

    def books_to_list_block(books, title: nil)
      {
        type: "book_list",
        content: {
          title: title,
          books: books.map { |book| book_to_block(book)[:content] }
        }
      }
    end

    def book_to_spotlight(book, extended_description: nil, key_themes: [], why_recommended: nil, similar_books: [])
      {
        type: "book_spotlight",
        content: {
          isbn: book.isbn,
          title: book.title,
          author: book.author,
          rating: book.rating,
          review_count: book.review_count,
          genres: book.genres || [],
          price: book.price,
          image_url: book.image_url,
          description: book.description,
          extended_description: extended_description || generate_extended_description(book),
          key_themes: key_themes.presence || extract_themes_from_book(book),
          why_recommended: why_recommended || generate_recommendation_reason(book),
          similar_books: similar_books.presence || find_similar_book_titles(book)
        }
      }
    end

    def generate_extended_description(book)
      # This would ideally come from the book's full description or AI-generated content
      "A detailed exploration of #{book.title} by #{book.author}, " \
        "this #{book.genres&.first&.downcase || 'book'} takes readers on an unforgettable journey."
    end

    def extract_themes_from_book(book)
      # Default themes based on genre
      case book.genres&.first
      when "Mystery", "Thriller"
        ["Suspense and intrigue", "Hidden secrets", "Complex characters", "Unexpected twists"]
      when "Fantasy"
        ["Magic and wonder", "Hero's journey", "Good vs evil", "World-building"]
      when "Science Fiction"
        ["Future technology", "Human nature", "Scientific exploration", "Ethical dilemmas"]
      when "Romance"
        ["Love and relationships", "Personal growth", "Emotional journey", "Happy endings"]
      else
        ["Character development", "Engaging plot", "Thought-provoking themes"]
      end
    end

    def generate_recommendation_reason(book)
      "With a #{book.rating} star rating and #{book.review_count || 'numerous'} positive reviews, " \
        "#{book.title} stands out in the #{book.genres&.first || 'literary'} genre."
    end

    def find_similar_book_titles(_book)
      # In a real implementation, this would query for similar books
      # For now, return empty array to be filled by the AI
      []
    end
  end

  def initialize
    @parser = self.class.create_parser
  end

  def parse_response(json_string, validate: true)
    parsed = JSON.parse(json_string, symbolize_names: true)

    validate_blocks!(parsed[:blocks]) if validate

    parsed
  rescue JSON::ParserError => e
    raise Langchain::OutputParsers::OutputParserException, "Invalid JSON: #{e.message}"
  end

  private

  def validate_blocks!(blocks)
    return if blocks.nil? || blocks.empty?

    blocks.each do |block|
      raise InvalidBlockTypeError, "Invalid block type: #{block[:type]}" unless VALID_BLOCK_TYPES.include?(block[:type])
    end
  end
end
