# Rich Content Cards for Book Recommendations

## Task Overview
Enhance the chat interface to display book recommendations as rich content cards instead of plain text. Cards should include book images, ratings, and other key information in a visually appealing format.

## Current State Analysis

### Existing Implementation
1. **Chat System**: Uses turbo streams for real-time updates
2. **Assistant Service**: Returns plain text responses with `response[:message]`
3. **Response Rendering**: Uses `simple_format` helper in `_assistant_response.html.erb`
4. **Book Data Available**: 
   - Title, Author, ISBN
   - Rating (decimal 0-5)
   - Genres (JSON array)
   - Price, Description
   - Publisher, Page count
   - Published date
   - Review count (via method)
   - **Missing**: Image URLs

### Key Components
- `BookAssistantService`: Processes queries using Langchain.rb
- `BookAssistantController#query`: Handles chat requests
- `_assistant_response.html.erb`: Renders messages
- `BookInfoTool`: Searches and retrieves book data

## Requirements

### Functional Requirements

1. **Structured Response Format**
   - Assistant should detect when books are being recommended
   - Return structured JSON data alongside the text response
   - Include book details: title, author, rating, genres, price, image_url

2. **Rich Card Display**
   - Display book information in card format
   - Show book cover image (placeholder if unavailable)
   - Display rating with star visualization
   - Show key metadata (author, genres, price)
   - Maintain responsive design

3. **Mixed Content Support**
   - Support both plain text and rich cards in same response
   - Preserve conversational flow
   - Cards should be embedded naturally within assistant responses

4. **Image Handling**
   - Add image_url field to books table
   - Support external image URLs
   - Provide fallback placeholder image
   - Consider lazy loading for performance

### Non-Functional Requirements

1. **Performance**
   - No significant increase in response time
   - Efficient rendering of multiple cards
   - Optimize image loading

2. **User Experience**
   - Smooth transition from text to cards
   - Consistent visual design
   - Mobile-friendly cards

3. **Backwards Compatibility**
   - Existing conversations should continue to work
   - Graceful degradation if structured data unavailable

## Technical Considerations

### Langchain.rb Structured Output
Based on the hint from the user, we need to investigate:
- OpenAI's response_format parameter for JSON mode
- Langchain.rb support for structured outputs
- JSON schema specification for responses

### Database Changes
- Migration to add `image_url` to books table
- Consider adding `thumbnail_url` for performance
- Update seed data with sample images

### Frontend Updates
- New partial `_book_card.html.erb`
- CSS for card styling
- JavaScript for interactions (if needed)

## Constraints

1. Must use existing Langchain.rb framework
2. Maintain current turbo stream architecture
3. Follow TDD approach (tests first)
4. All UI text must be in English
5. No breaking changes to existing chat functionality

## Success Criteria

1. Books are displayed as visually appealing cards
2. Cards show images, ratings, and key information
3. Mixed text and card responses work seamlessly
4. No degradation in chat performance
5. Mobile responsive design
6. All tests pass