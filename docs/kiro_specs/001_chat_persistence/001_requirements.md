# Requirements Analysis: Chat History Persistence

## Overview
Transform the current ephemeral chat system (using Rails.cache) into a persistent chat system with user accounts. Users can access their chat history using an alphanumeric identifier (e.g., yamat47).

## Current State Analysis

### Existing Implementation
- **Storage**: Rails.cache (memory store) with 30-minute expiration
- **Session Management**: Random UUID stored in browser session
- **Message Limit**: 20 messages per session
- **Components**:
  - `ChatSessionService`: Manages cache-based sessions
  - `BookAssistantController`: Handles chat interactions
  - `BookAssistantService`: Processes messages with Langchain

### Limitations
- Chat history lost on browser reload
- No user identification
- Cannot resume past conversations
- No way to view chat history

## Requirements

### Functional Requirements

#### 1. User Management
- **User Identifier**: Alphanumeric string (e.g., yamat47)
- **No Authentication**: Simple identifier-based access (no password)
- **User Creation**: Automatic on first use of identifier
- **Case Sensitivity**: Case-insensitive identifiers

#### 2. Chat Persistence
- **Permanent Storage**: All chats saved to database
- **Chat Sessions**: Multiple sessions per user
- **Message History**: Complete conversation history
- **No Message Limit**: Remove 20-message limitation

#### 3. Chat Management
- **Resume Chat**: Continue any previous conversation
- **New Chat**: Start fresh conversation
- **List Chats**: View all past chat sessions with sequential numbering
- **Chat Metadata**: Session number, creation datetime, last activity, message count
- **No Titles**: Sessions identified by number and datetime only (no user-defined titles)

#### 4. User Experience
- **Enter Identifier**: Simple form to enter user ID
- **Session Persistence**: Remember user across browser sessions
- **Chat Selection**: UI to browse and select past chats
- **Clear Visual Separation**: Between different chat sessions

### Non-Functional Requirements

#### 1. Performance
- **Fast Loading**: Efficient queries for chat history
- **Pagination**: For long chat histories
- **Lazy Loading**: Load messages on demand

#### 2. Data Integrity
- **Consistent State**: Ensure messages are saved correctly
- **Order Preservation**: Maintain message sequence
- **No Data Loss**: Reliable persistence

#### 3. Scalability
- **Database Indexes**: Optimize for common queries
- **Efficient Storage**: Consider message compression for long-term

## Technical Approach

### Database Schema
```
users
- id (primary key)
- identifier (string, unique, indexed)
- created_at
- updated_at

chat_sessions
- id (primary key)
- user_id (foreign key)
- session_number (integer, unique per user)
- last_activity_at (datetime)
- messages_count (integer)
- created_at
- updated_at

chat_messages
- id (primary key)
- chat_session_id (foreign key)
- role (string: user/assistant/system)
- content (text)
- position (integer)
- created_at
```

### Key Changes
1. Replace `ChatSessionService` with database-backed service
2. Add user identification flow
3. Update UI for session management
4. Migrate from cache to database storage

## Migration Strategy
1. Keep existing cache-based system during development
2. Build new persistence layer alongside
3. Provide migration path for active sessions
4. Switch over when ready

## Out of Scope
- User authentication (passwords)
- User profiles beyond identifier
- Chat sharing between users
- Export functionality
- Search within chat history