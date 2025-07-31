# Rich Content Cards Design

## Architecture Overview

The solution will leverage Langchain.rb's `StructuredOutputParser` to implement a flexible "blocks" system inspired by Perplexity's approach. This allows the assistant to return mixed content types (text, book cards, lists) in a structured format.

## Key Design Decisions

### 1. Blocks-Based Architecture

Implementing a flexible blocks system using Langchain.rb's `StructuredOutputParser`:

```ruby
# Define schema for block-based responses
ASSISTANT_RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    blocks: {
      type: "array",
      items: {
        type: "object",
        properties: {
          type: { 
            type: "string", 
            enum: ["text", "book_card", "book_list", "image"],
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
```

### 2. Service Layer Changes

**BookAssistantService** modifications:
- Add structured output parser when books are being discussed
- Detect book-related queries and apply appropriate schema
- Merge structured data with response

```ruby
def build_assistant_with_parser
  parser = Langchain::OutputParsers::StructuredOutputParser.from_json_schema(
    BOOK_RECOMMENDATION_SCHEMA
  )
  
  # Modify instructions to include parser format
  enhanced_instructions = "#{assistant_instructions}\n\n#{parser.get_format_instructions}"
  
  assistant = Langchain::Assistant.new(
    llm: llm_client,
    instructions: enhanced_instructions,
    tools: available_tools
  )
end
```

### 3. Response Processing Flow

1. User asks about books
2. Assistant searches using BookInfoTool
3. Assistant formats response with structured data
4. Service parses structured output
5. Controller passes both text and structured data to view
6. View renders text with embedded book cards

### 4. Database Schema Update

```ruby
class AddImageUrlToBooks < ActiveRecord::Migration[8.0]
  def change
    add_column :books, :image_url, :string
    add_column :books, :thumbnail_url, :string
  end
end
```

### 5. View Components

**New partial: `_book_card.html.erb`**
```erb
<div class="book-card">
  <div class="book-card-image">
    <%= image_tag book[:image_url] || 'book-placeholder.png',
                  alt: book[:title],
                  loading: 'lazy' %>
  </div>
  <div class="book-card-content">
    <h3><%= book[:title] %></h3>
    <p class="author">by <%= book[:author] %></p>
    <div class="rating">
      <%= render 'rating_stars', rating: book[:rating] %>
      <span><%= book[:rating] %>/5</span>
    </div>
    <div class="genres">
      <% book[:genres]&.each do |genre| %>
        <span class="genre-tag"><%= genre %></span>
      <% end %>
    </div>
    <% if book[:price] %>
      <p class="price">$<%= book[:price] %></p>
    <% end %>
  </div>
</div>
```

**Updated `_assistant_response.html.erb`**
```erb
<div class="message message-assistant">
  <div style="font-weight: bold; margin-bottom: 5px; color: #4caf50;">
    Assistant
  </div>
  <div style="background: #e8f5e9; padding: 15px; border-radius: 8px;">
    <% if response[:success] %>
      <!-- Render text message -->
      <%= simple_format(response[:message] || response[:structured_data]&.dig(:message)) %>
      
      <!-- Render book cards if present -->
      <% if response[:structured_data]&.dig(:books).present? %>
        <div class="book-cards-container">
          <% response[:structured_data][:books].each do |book| %>
            <%= render 'book_card', book: book %>
          <% end %>
        </div>
      <% end %>
      
      <% if response[:tools_used].present? %>
        <small style="color: #666; display: block; margin-top: 10px;">
          Tools used: <%= response[:tools_used].join(", ") %>
        </small>
      <% end %>
    <% else %>
      <p style="color: #f44336;"><%= response[:message] %></p>
    <% end %>
  </div>
</div>
```

### 6. CSS Styling

```css
.book-card {
  display: flex;
  gap: 15px;
  padding: 15px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin: 10px 0;
}

.book-card-image {
  flex-shrink: 0;
  width: 80px;
  height: 120px;
}

.book-card-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 4px;
}

.book-card-content {
  flex: 1;
}

.book-card h3 {
  margin: 0 0 5px 0;
  font-size: 18px;
  color: #333;
}

.author {
  color: #666;
  margin: 0 0 8px 0;
}

.rating {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.genre-tag {
  display: inline-block;
  padding: 2px 8px;
  background: #e3f2fd;
  color: #1976d2;
  border-radius: 12px;
  font-size: 12px;
  margin-right: 5px;
}

.price {
  font-weight: bold;
  color: #4caf50;
  margin-top: 8px;
}

/* Mobile responsive */
@media (max-width: 600px) {
  .book-card {
    flex-direction: column;
  }
  
  .book-card-image {
    width: 100%;
    height: 200px;
  }
}
```

## Implementation Strategy

### Phase 1: Backend Structure (Day 1)
1. Add database migration for image URLs
2. Implement StructuredOutputParser in BookAssistantService
3. Update response format handling
4. Write tests for structured output parsing

### Phase 2: Frontend Components (Day 2)
1. Create book card partial
2. Update assistant response partial
3. Add CSS styling
4. Test responsive design
5. Add placeholder images

## Alternative Approaches Considered

1. **Client-side parsing**: Parse book mentions in JavaScript
   - Rejected: Less reliable, duplicates backend logic

2. **Separate API endpoint**: Fetch book data after response
   - Rejected: Adds latency, complicates flow

3. **Markdown extensions**: Use custom markdown for books
   - Rejected: Less flexible than structured data

## Risk Mitigation

1. **Fallback handling**: If structured parsing fails, show plain text
2. **Performance**: Lazy load images, limit cards per response
3. **Backwards compatibility**: Detect response format version