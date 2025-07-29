# Implementation Task List: Chat History Persistence

## Overview
This task list follows TDD (Test-Driven Development) approach. Each task includes writing tests first, then implementation.

## Phase 1: Database and Models (Day 1)

### Task 1.1: Create User Model
- [ ] Write user model tests (test/models/user_test.rb)
  - Validation tests (identifier format, uniqueness)
  - Normalization tests (case insensitive)
  - Association tests
- [ ] Create user migration (db/migrate/xxx_create_users.rb)
- [ ] Implement User model (app/models/user.rb)
- [ ] Run tests and ensure all pass

### Task 1.2: Create ChatSession Model
- [ ] Write chat session model tests (test/models/chat_session_test.rb)
  - Validation tests
  - Association tests
  - Scope tests (recent)
  - Callback tests (title, last_activity)
- [ ] Create chat_sessions migration (db/migrate/xxx_create_chat_sessions.rb)
- [ ] Implement ChatSession model (app/models/chat_session.rb)
- [ ] Run tests and ensure all pass

### Task 1.3: Create ChatMessage Model
- [ ] Write chat message model tests (test/models/chat_message_test.rb)
  - Validation tests (role, content, position)
  - Association tests
  - Position auto-increment tests
  - Counter cache tests
- [ ] Create chat_messages migration (db/migrate/xxx_create_chat_messages.rb)
- [ ] Implement ChatMessage model (app/models/chat_message.rb)
- [ ] Run tests and ensure all pass

### Task 1.4: Run Migrations and Verify Schema
- [ ] Run migrations: `rails db:migrate`
- [ ] Verify schema.rb is updated correctly
- [ ] Run all model tests together

## Phase 2: Service Layer (Day 1-2)

### Task 2.1: Create UserService
- [ ] Write UserService tests (test/services/user_service_test.rb)
  - find_or_create_by_identifier tests
  - Edge cases (blank, invalid format)
- [ ] Implement UserService (app/services/user_service.rb)
- [ ] Run tests

### Task 2.2: Create ChatPersistenceService
- [ ] Write ChatPersistenceService tests (test/services/chat_persistence_service_test.rb)
  - create_session tests
  - get_session tests
  - get_messages tests
  - add_message tests
  - list_sessions tests
- [ ] Implement ChatPersistenceService (app/services/chat_persistence_service.rb)
- [ ] Run tests

### Task 2.3: Update BookAssistantService
- [ ] Write tests for database integration
- [ ] Modify BookAssistantService to accept ChatSession
- [ ] Update process_query to save messages to database
- [ ] Run tests

## Phase 3: Controller Updates (Day 2)

### Task 3.1: Update Routes
- [ ] Add new routes for user identification and chat sessions
- [ ] Update config/routes.rb
- [ ] Run `rails routes` to verify

### Task 3.2: Update BookAssistantController
- [ ] Write controller tests (test/controllers/book_assistant_controller_test.rb)
  - User identification tests
  - Session management tests
  - Message persistence tests
- [ ] Implement controller changes
  - Add identify action
  - Add show action for specific sessions
  - Update index for session list
  - Update query to use database
- [ ] Run tests

### Task 3.3: Create Session Management Actions
- [ ] Write tests for new/create session
- [ ] Write tests for session switching
- [ ] Implement actions
- [ ] Run tests

## Phase 4: UI Implementation (Day 2-3)

### Task 4.1: Create Identification UI
- [ ] Write system tests for user identification flow
- [ ] Create _identify_form.html.erb partial
- [ ] Update index.html.erb to show form or sessions
- [ ] Style with appropriate CSS
- [ ] Run system tests

### Task 4.2: Create Sessions List UI
- [ ] Write system tests for sessions list
- [ ] Create _sessions_list.html.erb partial
- [ ] Create _session_card.html.erb partial
- [ ] Add styling for session cards
- [ ] Run system tests

### Task 4.3: Update Chat Interface
- [ ] Write system tests for chat persistence
- [ ] Update show.html.erb for individual sessions
- [ ] Add session info to chat header
- [ ] Update Stimulus controller if needed
- [ ] Run system tests

### Task 4.4: Update Navigation
- [ ] Add user identifier display
- [ ] Add logout/switch user option
- [ ] Add breadcrumbs for navigation
- [ ] Test navigation flow

## Phase 5: Migration and Cleanup (Day 3)

### Task 5.1: Remove Cache Dependencies
- [ ] Write tests to ensure database persistence works
- [ ] Remove ChatSessionService cache implementation
- [ ] Update all references to use new service
- [ ] Run full test suite

### Task 5.2: Data Migration (if needed)
- [ ] Create rake task for migrating active sessions
- [ ] Test migration process
- [ ] Document migration steps

### Task 5.3: Performance Testing
- [ ] Add database indexes if missing
- [ ] Test with large datasets
- [ ] Add pagination if needed
- [ ] Profile and optimize queries

## Phase 6: Final Testing and Polish (Day 3)

### Task 6.1: Integration Testing
- [ ] Full user journey tests
- [ ] Edge case testing
- [ ] Error handling tests
- [ ] Concurrent user tests

### Task 6.2: UI Polish
- [ ] Responsive design verification
- [ ] Loading states
- [ ] Error messages
- [ ] Success feedback

### Task 6.3: Documentation
- [ ] Update README with new features
- [ ] Add CLAUDE.md notes about persistence
- [ ] Create user guide

## Checklist Before Completion

- [ ] All tests passing (`bundle exec rails test`)
- [ ] RuboCop passing (`bundle exec rubocop`)
- [ ] Brakeman passing (`bundle exec brakeman`)
- [ ] System tests passing
- [ ] Manual testing completed
- [ ] Documentation updated
- [ ] Performance verified

## Risk Mitigation

1. **Database Growth**: Monitor message table size, implement archiving if needed
2. **Concurrent Access**: Test multiple browser sessions
3. **Data Privacy**: Ensure users can only access their own chats
4. **Migration Rollback**: Keep cache system until fully verified

## Implementation Order

1. Start with Phase 1 (Models) - Critical foundation
2. Then Phase 2 (Services) - Business logic
3. Then Phase 3 (Controllers) - Request handling
4. Then Phase 4 (UI) - User interface
5. Finally Phase 5-6 (Cleanup and Polish)

Each phase should be completed and tested before moving to the next.