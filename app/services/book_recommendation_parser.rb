# frozen_string_literal: true

class BookRecommendationParser
  class InvalidBlockTypeError < StandardError; end

  VALID_BLOCK_TYPES = ["text", "book_card", "book_list", "image"].freeze

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
        
        The JSON object MUST contain a "blocks" array as the top-level property.
        
        Block types you MUST use:
        1. "text" blocks: For ALL explanatory text, context, greetings, and transitions
           - content MUST have a "markdown" property with your text
        2. "book_card" blocks: For individual book recommendations
           - content MUST include: isbn, title, author, rating, genres (array), price, image_url, description
        3. "book_list" blocks: For multiple related books
           - content MUST have: title (string) and books (array of book objects)

        REQUIRED: Always include text blocks to make your response conversational:
        - Start with a text block to greet or acknowledge the user's request
        - Add text blocks between book recommendations to provide context
        - End with a text block to conclude or ask if they need more help

        Example of a complete response:
        {
          "blocks": [
            {
              "type": "text",
              "content": {
                "markdown": "I'd be happy to recommend some mystery novels for you!"
              }
            },
            {
              "type": "book_card",
              "content": {
                "isbn": "978-0-00-000000-0",
                "title": "The Mystery Book",
                "author": "John Doe",
                "rating": 4.5,
                "genres": ["Mystery", "Thriller"],
                "price": 19.99,
                "image_url": "https://example.com/book.jpg",
                "description": "A thrilling mystery novel"
              }
            },
            {
              "type": "text",
              "content": {
                "markdown": "This book is perfect for fans of psychological thrillers. Would you like more recommendations?"
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
