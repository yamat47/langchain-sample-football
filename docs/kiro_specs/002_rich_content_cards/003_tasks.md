# Implementation Tasks

## Task Breakdown

### Phase 1: Backend Implementation (Priority: High)

#### Task 1.1: Database Migration for Image URLs
**Estimated time**: 30 minutes
1. Write migration test
2. Create migration to add `image_url` and `thumbnail_url` to books
3. Run migration
4. Update Book model tests for new attributes
5. Update seed data with sample image URLs

**Files to modify**:
- New: `db/migrate/XXX_add_image_urls_to_books.rb`
- `test/models/book_test.rb`
- `db/seeds.rb`

#### Task 1.2: Implement Structured Output Parser
**Estimated time**: 2 hours
1. Write tests for structured output parsing
2. Create `BookRecommendationParser` module
3. Define JSON schema for book recommendations
4. Integrate parser with BookAssistantService
5. Handle parsing errors gracefully

**Files to modify**:
- New: `app/services/book_recommendation_parser.rb`
- New: `test/services/book_recommendation_parser_test.rb`
- `app/services/book_assistant_service.rb`
- `test/services/book_assistant_service_test.rb`

#### Task 1.3: Update BookInfoTool Response Format
**Estimated time**: 1 hour
1. Write tests for enhanced book data format
2. Update tool to include image URLs in responses
3. Ensure backward compatibility

**Files to modify**:
- `app/tools/book_info_tool.rb`
- `test/tools/book_info_tool_test.rb`

#### Task 1.4: Modify Assistant Response Processing
**Estimated time**: 1.5 hours
1. Write tests for structured response handling
2. Update BookAssistantService#format_response
3. Add structured_data to response hash
4. Implement fallback for non-structured responses

**Files to modify**:
- `app/services/book_assistant_service.rb`
- `test/services/book_assistant_service_test.rb`

### Phase 2: Frontend Implementation (Priority: High)

#### Task 2.1: Create Book Card Components
**Estimated time**: 1.5 hours
1. Write view component tests
2. Create `_book_card.html.erb` partial
3. Create `_rating_stars.html.erb` partial
4. Add placeholder image asset

**Files to create**:
- New: `app/views/book_assistant/_book_card.html.erb`
- New: `app/views/book_assistant/_rating_stars.html.erb`
- New: `app/assets/images/book-placeholder.png`
- New: `test/views/book_assistant/book_card_test.rb`

#### Task 2.2: Update Response Rendering
**Estimated time**: 1 hour
1. Write tests for updated response view
2. Modify `_assistant_response.html.erb`
3. Handle both text and structured responses
4. Ensure smooth turbo stream updates

**Files to modify**:
- `app/views/book_assistant/_assistant_response.html.erb`
- `test/controllers/book_assistant_controller_test.rb`

#### Task 2.3: Add Styling
**Estimated time**: 1 hour
1. Create book card styles
2. Ensure mobile responsiveness
3. Add hover effects and transitions
4. Test across browsers

**Files to create/modify**:
- New: `app/assets/stylesheets/book_cards.css`
- `app/assets/stylesheets/application.css` (import new styles)

### Phase 3: Testing & Polish (Priority: Medium)

#### Task 3.1: Integration Testing
**Estimated time**: 1 hour
1. Write system tests for book recommendations
2. Test mixed content responses
3. Test error scenarios
4. Test mobile responsiveness

**Files to create/modify**:
- `test/system/book_assistant_test.rb`
- New: `test/integration/rich_content_cards_test.rb`

#### Task 3.2: Performance Optimization
**Estimated time**: 30 minutes
1. Implement image lazy loading
2. Add response caching if needed
3. Optimize CSS delivery

#### Task 3.3: Documentation
**Estimated time**: 30 minutes
1. Update README with new feature
2. Add inline documentation
3. Create example responses

## Testing Checklist

- [ ] All unit tests pass
- [ ] Integration tests cover happy path
- [ ] Error scenarios handled gracefully
- [ ] Mobile responsive design verified
- [ ] Performance benchmarks acceptable
- [ ] Rubocop and Brakeman pass

## Rollback Plan

If issues arise:
1. Feature flag to disable structured responses
2. Fallback to plain text rendering
3. Database migration is reversible

## Total Estimated Time

- Phase 1: ~5 hours
- Phase 2: ~3.5 hours  
- Phase 3: ~2 hours
- **Total**: ~10.5 hours (1.5 days)

## Dependencies

- Langchain.rb gem (already installed)
- No additional gems required
- Image hosting solution (use URLs for now)

## Next Steps

1. Get approval for this plan
2. Create feature branch
3. Start with Task 1.1 (Database Migration)
4. Follow TDD approach throughout