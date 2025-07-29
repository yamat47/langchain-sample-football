# Design Document: Chat History Persistence

## Architecture Overview

### Component Diagram
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Browser       │────▶│  Controllers     │────▶│   Services      │
│  (Stimulus.js)  │     │                  │     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │                          │
                               ▼                          ▼
                        ┌──────────────────┐     ┌─────────────────┐
                        │     Models       │────▶│    Database     │
                        │ (User, Session,  │     │   (SQLite)      │
                        │    Message)      │     └─────────────────┘
                        └──────────────────┘
```

## Database Design

### Entity Relationship Diagram
```
users (1) ─────────────▶ (n) chat_sessions
                                    │
                                    │ (1)
                                    ▼
                                   (n)
                              chat_messages
```

### Tables

#### 1. users
```ruby
create_table :users do |t|
  t.string :identifier, null: false
  t.timestamps
  
  t.index :identifier, unique: true
  t.index :created_at
end
```

#### 2. chat_sessions
```ruby
create_table :chat_sessions do |t|
  t.references :user, null: false, foreign_key: true
  t.integer :session_number, null: false
  t.datetime :last_activity_at, null: false
  t.integer :messages_count, default: 0
  t.timestamps
  
  t.index [:user_id, :session_number], unique: true
  t.index [:user_id, :last_activity_at]
  t.index :created_at
end
```

#### 3. chat_messages
```ruby
create_table :chat_messages do |t|
  t.references :chat_session, null: false, foreign_key: true
  t.string :role, null: false # user, assistant, system
  t.text :content, null: false
  t.integer :position, null: false
  t.timestamps
  
  t.index [:chat_session_id, :position]
  t.index :created_at
end
```

## Model Design

### User Model
```ruby
class User < ApplicationRecord
  has_many :chat_sessions, dependent: :destroy
  
  validates :identifier, presence: true, uniqueness: { case_sensitive: false }
  validates :identifier, format: { with: /\A[a-zA-Z0-9]+\z/ }
  
  before_validation :normalize_identifier
  
  private
  def normalize_identifier
    self.identifier = identifier&.downcase
  end
end
```

### ChatSession Model
```ruby
class ChatSession < ApplicationRecord
  belongs_to :user
  has_many :chat_messages, dependent: :destroy
  
  validates :last_activity_at, presence: true
  validates :session_number, presence: true, uniqueness: { scope: :user_id }
  
  before_validation :set_last_activity
  before_validation :set_session_number, on: :create
  
  scope :recent, -> { order(last_activity_at: :desc) }
  scope :ordered, -> { order(session_number: :desc) }
  
  def display_name
    "Session ##{session_number}"
  end
  
  private
  def set_last_activity
    self.last_activity_at ||= Time.current
  end
  
  def set_session_number
    return if session_number.present?
    
    max_number = user.chat_sessions.maximum(:session_number) || 0
    self.session_number = max_number + 1
  end
end
```

### ChatMessage Model
```ruby
class ChatMessage < ApplicationRecord
  belongs_to :chat_session, counter_cache: :messages_count
  
  validates :role, presence: true, inclusion: { in: %w[user assistant system] }
  validates :content, presence: true
  validates :position, presence: true, uniqueness: { scope: :chat_session_id }
  
  before_validation :set_position
  after_create :update_session_activity
  
  scope :ordered, -> { order(:position) }
  
  private
  def set_position
    self.position ||= (chat_session.chat_messages.maximum(:position) || 0) + 1
  end
  
  def update_session_activity
    chat_session.update(last_activity_at: Time.current)
  end
end
```

## Service Layer Design

### UserService
```ruby
class UserService
  def self.find_or_create_by_identifier(identifier)
    return nil if identifier.blank?
    
    normalized = identifier.downcase
    User.find_or_create_by(identifier: normalized)
  end
end
```

### ChatPersistenceService
```ruby
class ChatPersistenceService
  def initialize(user)
    @user = user
  end
  
  def create_session
    @user.chat_sessions.create!
  end
  
  def get_session(session_id)
    @user.chat_sessions.find(session_id)
  end
  
  def get_messages(session_id)
    session = get_session(session_id)
    session.chat_messages.ordered
  end
  
  def add_message(session_id, role, content)
    session = get_session(session_id)
    session.chat_messages.create!(role: role, content: content)
  end
  
  def list_sessions
    @user.chat_sessions.recent.includes(:chat_messages)
  end
end
```

## Controller Updates

### BookAssistantController
```ruby
class BookAssistantController < ApplicationController
  before_action :require_user
  before_action :set_chat_session, only: [:show, :query]
  
  def index
    # Show user identification form if no user
    # Otherwise show chat sessions list
    if @current_user
      @chat_sessions = @current_user.chat_sessions.recent
    end
  end
  
  def identify
    # Handle user identification
    @user = UserService.find_or_create_by_identifier(params[:identifier])
    if @user
      session[:user_id] = @user.id
      redirect_to book_assistant_index_path
    else
      flash[:error] = "Invalid identifier"
      redirect_to book_assistant_index_path
    end
  end
  
  def show
    # Show specific chat session
    @messages = @chat_session.chat_messages.ordered
  end
  
  def new
    # Create new chat session
    @chat_session = @persistence_service.create_session
    redirect_to book_assistant_path(@chat_session)
  end
  
  def query
    # Process message in context of chat session
    # Similar to existing implementation but saves to DB
  end
  
  private
  
  def require_user
    @current_user = User.find_by(id: session[:user_id])
    @persistence_service = ChatPersistenceService.new(@current_user) if @current_user
  end
  
  def set_chat_session
    @chat_session = @current_user.chat_sessions.find(params[:id])
  end
end
```

## UI/UX Design

### User Flow
1. **Initial Visit**: Show identifier input form
2. **After Identification**: Show chat sessions list
3. **Session List**: Display recent chats with preview
4. **Chat Interface**: Similar to current with session info

### Views Structure
```
app/views/book_assistant/
├── index.html.erb          # User identification or sessions list
├── _identify_form.html.erb # Form to enter identifier
├── _sessions_list.html.erb # List of chat sessions
├── show.html.erb          # Individual chat session
├── _message.html.erb      # Single message (existing)
└── _session_card.html.erb # Session preview card
```

### Key UI Components

#### 1. Identifier Form
```erb
<div class="identifier-form">
  <%= form_with url: identify_book_assistant_index_path do |f| %>
    <%= f.text_field :identifier, 
        placeholder: "Enter your identifier (e.g., yamat47)",
        pattern: "[a-zA-Z0-9]+",
        required: true %>
    <%= f.submit "Continue" %>
  <% end %>
</div>
```

#### 2. Sessions List
```erb
<div class="sessions-list">
  <div class="header">
    <h2>Your Chat History</h2>
    <%= link_to "New Chat", new_book_assistant_path, class: "btn-primary" %>
  </div>
  
  <div class="sessions">
    <% @chat_sessions.each do |session| %>
      <%= render "session_card", session: session %>
    <% end %>
  </div>
</div>
```

#### 3. Session Card
```erb
<div class="session-card" onclick="location.href='<%= book_assistant_path(session) %>'">
  <h3>Session #<%= session.session_number %></h3>
  <p class="datetime"><%= session.created_at.strftime("%B %d, %Y at %I:%M %p") %></p>
  <p class="preview"><%= truncate(session.chat_messages.last&.content, length: 100) %></p>
  <div class="metadata">
    <span><%= session.messages_count %> messages</span>
    <span>Last active <%= time_ago_in_words(session.last_activity_at) %> ago</span>
  </div>
</div>
```

## Migration Path

### Phase 1: Database Setup
1. Create migrations for new tables
2. Add models with validations
3. Create service classes

### Phase 2: Parallel Implementation
1. Keep existing cache-based system
2. Build new persistence alongside
3. Add feature flag for testing

### Phase 3: UI Updates
1. Add user identification flow
2. Create session management UI
3. Update chat interface

### Phase 4: Switchover
1. Enable for new users first
2. Provide migration for existing sessions
3. Deprecate cache-based system

## Testing Strategy

### Unit Tests
- Model validations and associations
- Service class methods
- Controller actions

### Integration Tests
- User identification flow
- Chat session creation and management
- Message persistence

### System Tests
- End-to-end user journey
- Session switching
- Message continuity

## Performance Considerations

1. **Indexes**: Proper database indexes for queries
2. **Eager Loading**: Prevent N+1 queries
3. **Pagination**: For long message histories
4. **Caching**: Consider read-through cache for active sessions