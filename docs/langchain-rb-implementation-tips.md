# Langchain.rb 実装Tips

## 1. ツール定義の詳細パターン

### 複雑なパラメータ構造

```ruby
class AdvancedTool
  extend Langchain::ToolDefinition

  # ネストされたオブジェクトを受け取る
  define_function :complex_search,
    description: "複雑な検索条件での検索" do
    property :filters, type: "object", description: "検索フィルター" do
      property :date_range, type: "object" do
        property :start_date, type: "string", required: true
        property :end_date, type: "string", required: true
      end
      property :categories, type: "array", items: { type: "string" }
      property :price_range, type: "object" do
        property :min, type: "number"
        property :max, type: "number"
      end
    end
    property :options, type: "object" do
      property :sort_by, type: "string", enum: ["price", "date", "popularity"]
      property :limit, type: "integer", default: 20
    end
  end

  def complex_search(filters: {}, options: {})
    # フィルターの処理
    query = build_base_query

    if filters[:date_range]
      query = query.where(created_at: filters[:date_range][:start_date]..filters[:date_range][:end_date])
    end

    if filters[:categories].present?
      query = query.where(category: filters[:categories])
    end

    # 結果を返す
    format_results(query, options)
  end
end
```

### 動的なツール登録

```ruby
class DynamicAssistant
  def initialize(user_preferences)
    @llm = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
    @tools = build_tools_for_user(user_preferences)
  end

  def build_tools_for_user(preferences)
    tools = []

    # ユーザーの設定に基づいてツールを追加
    if preferences[:enable_news]
      tools << Langchain::Tool::NewsRetriever.new(api_key: ENV["NEWS_API_KEY"])
    end

    if preferences[:enable_calculator]
      tools << Langchain::Tool::Calculator.new
    end

    # カスタムツールの条件付き追加
    if preferences[:book_genres].present?
      tools << BookGenreTool.new(allowed_genres: preferences[:book_genres])
    end

    tools
  end

  def create_assistant
    Langchain::Assistant.new(
      llm: @llm,
      tools: @tools,
      instructions: build_instructions
    )
  end
end
```

## 2. Assistant の高度な使い方

### メッセージコールバック

```ruby
assistant = Langchain::Assistant.new(
  llm: llm,
  tools: tools,
  instructions: "...",
  # メッセージ処理のコールバック
  add_message_callback: ->(message) {
    Rails.logger.info "New message: #{message.role} - #{message.content}"
    # メッセージをDBに保存
    ConversationLog.create!(
      role: message.role,
      content: message.content,
      metadata: message.tool_calls
    )
  }
)
```

### トークン使用量の追跡

```ruby
class TokenTrackingService
  def initialize
    @llm = Langchain::LLM::OpenAI.new(
      api_key: ENV["OPENAI_API_KEY"],
      default_options: {
        model: "gpt-4",
        temperature: 0.7
      }
    )
  end

  def create_assistant_with_tracking
    assistant = Langchain::Assistant.new(
      llm: @llm,
      tools: [],
      instructions: "..."
    )

    # レスポンス後のトークン使用量を確認
    assistant.add_message_and_run(content: "Hello") do |response|
      if response.raw_response["usage"]
        usage = response.raw_response["usage"]
        track_usage(
          prompt_tokens: usage["prompt_tokens"],
          completion_tokens: usage["completion_tokens"],
          total_tokens: usage["total_tokens"]
        )
      end
    end

    assistant
  end

  private

  def track_usage(prompt_tokens:, completion_tokens:, total_tokens:)
    TokenUsage.create!(
      prompt_tokens: prompt_tokens,
      completion_tokens: completion_tokens,
      total_tokens: total_tokens,
      cost: calculate_cost(total_tokens)
    )
  end
end
```

### 並列ツール実行の制御

```ruby
class ParallelToolAssistant
  def create_assistant
    Langchain::Assistant.new(
      llm: llm,
      tools: [weather_tool, news_tool, calculator_tool],
      instructions: "複数のツールを効率的に使用してください",
      # 並列実行の設定
      parallel_tool_calls: true,
      max_parallel_calls: 3
    )
  end

  def process_complex_query(query)
    # 例: "東京の天気と最新ニュース、そして100ドルは何円か教えて"
    # アシスタントは3つのツールを並列で実行
    response = assistant.add_message_and_run(
      content: query,
      auto_tool_execution: true
    )

    # 各ツールの結果を整理
    parse_parallel_results(response)
  end
end
```

## 3. エラーハンドリングとリトライ

### 堅牢なツール実装

```ruby
class RobustTool
  extend Langchain::ToolDefinition

  define_function :api_call,
    description: "外部APIを呼び出す" do
    property :endpoint, type: "string", required: true
    property :params, type: "object"
  end

  def api_call(endpoint:, params: {})
    retries = 0
    max_retries = 3

    begin
      response = make_api_request(endpoint, params)

      # レスポンスの検証
      validate_response!(response)

      { success: true, data: response }
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      retries += 1
      if retries < max_retries
        sleep(2 ** retries)  # Exponential backoff
        retry
      else
        handle_timeout_error(e)
      end
    rescue ApiError => e
      handle_api_error(e)
    rescue StandardError => e
      handle_unexpected_error(e)
    end
  end

  private

  def validate_response!(response)
    raise ApiError, "Invalid response format" unless response.is_a?(Hash)
    raise ApiError, "Empty response" if response.empty?
  end

  def handle_timeout_error(error)
    Rails.logger.error "API timeout after retries: #{error.message}"
    { success: false, error: "Service temporarily unavailable", error_type: "timeout" }
  end

  def handle_api_error(error)
    Rails.logger.error "API error: #{error.message}"
    { success: false, error: error.message, error_type: "api_error" }
  end

  def handle_unexpected_error(error)
    Rails.logger.error "Unexpected error: #{error.class} - #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    { success: false, error: "An unexpected error occurred", error_type: "unknown" }
  end
end
```

## 4. テスト戦略

### ツールのモック

```ruby
# spec/support/langchain_helpers.rb
module LangchainHelpers
  def mock_tool(tool_class, methods = {})
    instance = instance_double(tool_class)

    methods.each do |method_name, return_value|
      allow(instance).to receive(method_name).and_return(return_value)
    end

    allow(tool_class).to receive(:new).and_return(instance)
    instance
  end

  def mock_llm_response(content)
    double(
      content: content,
      raw_response: {
        "choices" => [{ "message" => { "content" => content } }],
        "usage" => { "total_tokens" => 100 }
      }
    )
  end
end

# 使用例
RSpec.describe BookAssistantService do
  include LangchainHelpers

  let(:book_tool) do
    mock_tool(BookInfoTool, {
      search_books: [{ title: "Test Book", author: "Test Author" }],
      get_book_details: { isbn: "123", title: "Test Book", rating: 4.5 }
    })
  end

  let(:news_tool) do
    mock_tool(Langchain::Tool::NewsRetriever, {
      get_everything: { articles: [{ title: "Book News" }] }
    })
  end

  before do
    allow(Langchain::LLM::OpenAI).to receive(:new).and_return(
      double(chat: mock_llm_response("Here are some book recommendations"))
    )
  end
end
```

### 統合テスト

```ruby
# spec/integration/book_assistant_integration_spec.rb
RSpec.describe "Book Assistant Integration", type: :integration do
  let(:service) { BookAssistantService.new }

  context "with real tools" do
    before do
      # テスト用のデータを準備
      create(:book, title: "Ruby Programming", author: "Matz", genres: ["Programming"])
      create(:book, title: "Rails Guide", author: "DHH", genres: ["Programming"])
    end

    it "searches and recommends books" do
      VCR.use_cassette("book_assistant_integration") do
        response = service.process_query("プログラミングの本を探して")

        expect(response[:success]).to be true
        expect(response[:message]).to include("Ruby Programming")
        expect(response[:message]).to include("Rails Guide")
      end
    end

    it "handles complex queries with multiple tools" do
      VCR.use_cassette("complex_book_query") do
        response = service.process_query(
          "最新のプログラミング本のニュースと、高評価の本を教えて"
        )

        expect(response[:success]).to be true
        # NewsRetrieverとBookInfoToolの両方が使われたことを確認
        expect(response[:tools_used]).to include("NewsRetriever", "BookInfoTool")
      end
    end
  end
end
```

## 5. プロダクション考慮事項

### レート制限の実装

```ruby
class RateLimitedAssistant
  def initialize
    @rate_limiter = RateLimiter.new(
      max_requests: 60,
      time_window: 1.minute
    )
  end

  def process_query(user_id, query)
    # ユーザーごとのレート制限
    unless @rate_limiter.allow?(user_id)
      return {
        success: false,
        error: "Rate limit exceeded. Please try again later."
      }
    end

    # 通常の処理
    assistant.chat(message: query)
  rescue => e
    @rate_limiter.release(user_id)  # エラー時はカウントを戻す
    raise
  end
end
```

### 非同期処理

```ruby
class AsyncBookAssistant
  include Sidekiq::Worker

  def perform(query_id)
    query = BookQuery.find(query_id)

    # 長時間かかる可能性のある処理
    service = BookAssistantService.new
    response = service.process_query(query.query_text)

    # 結果を保存
    query.update!(
      response_text: response[:message],
      success: response[:success],
      processed_at: Time.current
    )

    # 通知（WebSocket, メール等）
    notify_user(query.user, response)
  rescue => e
    query.update!(
      success: false,
      error_message: e.message
    )
    raise  # Sidekiqのリトライ機能を使う
  end
end
```

## まとめ

Langchain.rbは柔軟で拡張性の高いフレームワークです。これらのパターンを参考に、本番環境でも安定して動作するAIアプリケーションを構築できます。

重要なポイント：
1. エラーハンドリングを適切に実装
2. レート制限とコスト管理
3. テスト可能な設計
4. 非同期処理の活用
5. ログとモニタリング
