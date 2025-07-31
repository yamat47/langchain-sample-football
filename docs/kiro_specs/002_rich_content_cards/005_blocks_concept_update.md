# Blocks Concept Update - Rich Content Cards

## Overview
Based on Perplexity's implementation, we should adopt a "blocks" concept rather than simple card embedding. This provides more flexibility and better separation of content types.

## Key Concepts from References

### 1. Perplexity's Block System
- **blocks**: Array of content blocks with different types
- **intended_usage**: Describes the purpose of each block
- **diff_block**: Contains the actual content and patches for streaming
- Block types include: markdown, place (entity), web_results, sources

### 2. ChatGPT's Chunk System
- **chunks**: Array of content chunks
- Types: text, image, component
- Strict ordering rules (text first/last)
- JSON schema enforcement

## Revised Architecture

### Response Structure
```ruby
# Updated schema for book assistant responses
BOOK_ASSISTANT_RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    blocks: {
      type: "array",
      items: {
        type: "object",
        properties: {
          type: { 
            type: "string", 
            enum: ["text", "book_card", "book_list", "image"] 
          },
          content: { type: "object" }
        },
        required: ["type", "content"]
      }
    }
  },
  required: ["blocks"]
}

# Block type definitions
TEXT_BLOCK = {
  type: "text",
  content: {
    markdown: "string"
  }
}

BOOK_CARD_BLOCK = {
  type: "book_card", 
  content: {
    isbn: "string",
    title: "string",
    author: "string",
    rating: "number",
    review_count: "integer",
    genres: ["array", "string"],
    price: "number",
    image_url: "string",
    description: "string"
  }
}

BOOK_LIST_BLOCK = {
  type: "book_list",
  content: {
    title: "string",
    books: ["array", "book_card"]
  }
}
```

### Service Implementation Update
```ruby
class BookAssistantService
  def process_query(message)
    # Detect if this is a book-related query
    if book_related_query?(message)
      process_with_blocks(message)
    else
      process_standard(message)
    end
  end

  private

  def process_with_blocks(message)
    # Create parser with blocks schema
    parser = Langchain::OutputParsers::StructuredOutputParser.from_json_schema(
      BOOK_ASSISTANT_RESPONSE_SCHEMA
    )
    
    # Enhanced instructions for block-based responses
    block_instructions = <<~INSTRUCTIONS
      #{assistant_instructions}
      
      You MUST respond with a JSON object containing a "blocks" array.
      Each block represents a distinct piece of content.
      
      Block types:
      - text: For explanatory text, use markdown formatting
      - book_card: For individual book recommendations
      - book_list: For multiple related books
      
      Rules:
      1. Start with a text block explaining what you're showing
      2. Use book_card for detailed individual recommendations
      3. Use book_list when showing multiple options
      4. End with a text block if additional context needed
      
      #{parser.get_format_instructions}
    INSTRUCTIONS

    # Process with enhanced assistant
    assistant = Langchain::Assistant.new(
      llm: llm_client,
      instructions: block_instructions,
      tools: available_tools
    )
    
    # Get response
    response = assistant.add_message_and_run(
      content: message,
      auto_tool_execution: true
    )
    
    # Parse blocks
    begin
      structured_response = parser.parse(response.content)
      format_blocks_response(structured_response)
    rescue Langchain::OutputParsers::OutputParserException => e
      # Fallback to text-only response
      format_text_response(response.content)
    end
  end
  
  def format_blocks_response(structured_response)
    {
      message: extract_text_content(structured_response[:blocks]),
      blocks: structured_response[:blocks],
      success: true,
      timestamp: Time.current
    }
  end
end
```

### View Implementation
```erb
<!-- _assistant_response.html.erb -->
<div class="message message-assistant">
  <div style="font-weight: bold; margin-bottom: 5px; color: #4caf50;">
    Assistant
  </div>
  <div style="background: #e8f5e9; padding: 15px; border-radius: 8px;">
    <% if response[:success] %>
      <% if response[:blocks].present? %>
        <% response[:blocks].each do |block| %>
          <%= render "blocks/#{block[:type]}", block: block[:content] %>
        <% end %>
      <% else %>
        <!-- Fallback to simple text -->
        <%= simple_format(response[:message]) %>
      <% end %>
    <% else %>
      <p style="color: #f44336;"><%= response[:message] %></p>
    <% end %>
  </div>
</div>
```

### Block Partials
```erb
<!-- app/views/book_assistant/blocks/_text.html.erb -->
<div class="text-block">
  <%= sanitize(markdown(block[:markdown])) %>
</div>

<!-- app/views/book_assistant/blocks/_book_card.html.erb -->
<div class="book-card">
  <div class="book-card-image">
    <%= image_tag block[:image_url] || 'book-placeholder.png',
                  alt: block[:title],
                  loading: 'lazy' %>
  </div>
  <div class="book-card-content">
    <h3><%= block[:title] %></h3>
    <p class="author">by <%= block[:author] %></p>
    <div class="rating">
      <%= render 'shared/rating_stars', rating: block[:rating] %>
      <span><%= block[:rating] %>/5 (<%= block[:review_count] %> reviews)</span>
    </div>
    <div class="genres">
      <% block[:genres]&.each do |genre| %>
        <span class="genre-tag"><%= genre %></span>
      <% end %>
    </div>
    <% if block[:price] %>
      <p class="price">$<%= number_with_precision(block[:price], precision: 2) %></p>
    <% end %>
    <p class="description"><%= truncate(block[:description], length: 150) %></p>
  </div>
</div>

<!-- app/views/book_assistant/blocks/_book_list.html.erb -->
<div class="book-list">
  <% if block[:title].present? %>
    <h3><%= block[:title] %></h3>
  <% end %>
  <div class="book-list-items">
    <% block[:books].each do |book| %>
      <%= render 'blocks/book_card', block: book %>
    <% end %>
  </div>
</div>
```

## Benefits of Blocks Approach

1. **Flexibility**: Can mix different content types naturally
2. **Extensibility**: Easy to add new block types
3. **Structure**: Clear separation between content types
4. **Streaming-ready**: Can be adapted for streaming responses later
5. **Graceful degradation**: Falls back to text if parsing fails

## Implementation Priority

1. Implement blocks structure in backend
2. Create block rendering system
3. Update assistant instructions for block generation
4. Add robust error handling
5. Create comprehensive tests

## Future Considerations

- **Streaming**: Blocks can be streamed individually
- **Interactive blocks**: Add actions to book cards
- **Rich media**: Support for book previews, author info
- **Analytics**: Track which blocks users interact with