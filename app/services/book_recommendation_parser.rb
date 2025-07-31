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
        You MUST respond with a JSON object containing a "blocks" array.
        Each block represents a distinct piece of content.

        Block types:
        - text: For explanatory text, use markdown formatting
        - book_card: For individual book recommendations
        - book_list: For multiple related books
        - image: For standalone images

        Rules:
        1. Start with a text block explaining what you're showing
        2. Use book_card for detailed individual recommendations
        3. Use book_list when showing multiple options
        4. End with a text block if additional context needed

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
