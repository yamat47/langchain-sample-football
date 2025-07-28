# Langchain.rb 実装ガイド

## 概要
Langchain.rb (langchainrb) は、Ruby用のLangChainフレームワークです。LLMを使用したアプリケーションを構築するための包括的なツールセットを提供します。

## リポジトリ情報
- **GitHub**: https://github.com/patterns-ai-core/langchainrb
- **Gem**: `gem 'langchainrb'`

## 主要コンポーネント

### 1. Assistant（アシスタント）

アシスタントは、LLMとツールを組み合わせて対話型AIを構築するための中心的なクラスです。

```ruby
# 基本的な使い方
assistant = Langchain::Assistant.new(
  llm: llm_instance,
  instructions: "あなたは親切なアシスタントです",
  tools: [tool1, tool2]
)

# メッセージの追加と実行
response = assistant.add_message_and_run(
  content: "ユーザーの質問",
  auto_tool_execution: true  # ツールの自動実行
)
```

#### Assistant の主要メソッド
- `add_message_and_run` - メッセージを追加して処理実行
- `chat` - シンプルなチャットインターフェース
- `messages` - メッセージ履歴の取得
- `clear_messages` - メッセージ履歴のクリア

### 2. Tool（ツール）

ツールは、LLMが実行できる機能を定義します。

#### ツールの定義方法

```ruby
class MyCustomTool
  extend Langchain::ToolDefinition

  # 関数の定義
  define_function :search_data,
    description: "データを検索します" do
    property :query, type: "string", description: "検索クエリ", required: true
    property :limit, type: "integer", description: "結果の上限", default: 10
    property :filters, type: "array", description: "フィルター条件"
  end

  def initialize(api_key: nil)
    @api_key = api_key
  end

  def search_data(query:, limit: 10, filters: nil)
    # 実装
    # 戻り値は任意のRubyオブジェクト（通常はHash）
    {
      results: [...],
      count: 5
    }
  end
end
```

#### プロパティの型
- `string` - 文字列
- `number` - 数値（小数含む）
- `integer` - 整数
- `boolean` - 真偽値
- `array` - 配列
- `object` - ハッシュ/オブジェクト

#### プロパティのオプション
- `required: true/false` - 必須パラメータか
- `default: value` - デフォルト値
- `enum: [...]` - 許可される値のリスト
- `description: "..."` - パラメータの説明

### 3. 組み込みツール

#### NewsRetriever
ニュース記事を検索するツール（NewsAPI.org使用）

```ruby
news_tool = Langchain::Tool::NewsRetriever.new(
  api_key: ENV["NEWS_API_KEY"]
)

# 使用可能なメソッド
news_tool.get_everything(
  q: "検索クエリ",
  language: "ja",
  sort_by: "publishedAt",  # relevancy, popularity, publishedAt
  page_size: 20
)

news_tool.get_top_headlines(
  category: "technology",  # business, entertainment, general, health, science, sports, technology
  country: "jp",
  q: "追加の検索クエリ"
)

news_tool.get_sources(
  category: "technology",
  language: "ja",
  country: "jp"
)
```

#### その他の組み込みツール
- `Calculator` - 数学計算
- `Database` - SQLデータベース操作
- `FileSystem` - ファイル操作
- `GoogleSearch` - Google検索（SerpAPI経由）
- `Weather` - 天気情報（OpenWeatherMap）
- `Wikipedia` - Wikipedia検索
- `RubyCodeInterpreter` - Rubyコード実行

### 4. LLMプロバイダー

```ruby
# OpenAI
llm = Langchain::LLM::OpenAI.new(
  api_key: ENV["OPENAI_API_KEY"],
  default_options: {
    model: "gpt-4",
    temperature: 0.7,
    max_tokens: 1000
  }
)

# Anthropic Claude
llm = Langchain::LLM::Anthropic.new(
  api_key: ENV["ANTHROPIC_API_KEY"],
  default_options: {
    model: "claude-3-opus-20240229",
    temperature: 0.7
  }
)

# Google Gemini
llm = Langchain::LLM::GoogleGemini.new(
  api_key: ENV["GOOGLE_API_KEY"]
)
```

## 実装パターン

### 1. 基本的なアシスタント

```ruby
# シンプルなQ&Aアシスタント
llm = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])

assistant = Langchain::Assistant.new(
  llm: llm,
  instructions: "あなたは知識豊富なアシスタントです。"
)

response = assistant.chat(message: "Ruby on Railsとは何ですか？")
puts response.content
```

### 2. ツール付きアシスタント

```ruby
# 複数のツールを使用するアシスタント
assistant = Langchain::Assistant.new(
  llm: llm,
  instructions: "ユーザーの質問に対して、利用可能なツールを使って回答してください。",
  tools: [
    Langchain::Tool::Calculator.new,
    Langchain::Tool::Weather.new(api_key: ENV["WEATHER_API_KEY"]),
    MyCustomTool.new
  ]
)

# ツールの自動実行を有効にして実行
response = assistant.add_message_and_run(
  content: "東京の天気を教えて、気温を華氏から摂氏に変換して",
  auto_tool_execution: true
)
```

### 3. カスタムツールの高度な例

```ruby
class BookSearchTool
  extend Langchain::ToolDefinition

  define_function :search_by_genre,
    description: "ジャンルで本を検索" do
    property :genre, type: "string", required: true
    property :sort_by, type: "string", enum: ["rating", "date", "title"]
    property :limit, type: "integer", default: 10
  end

  define_function :get_book_details,
    description: "本の詳細情報を取得" do
    property :isbn, type: "string", required: true
    property :include_reviews, type: "boolean", default: false
  end

  def search_by_genre(genre:, sort_by: "rating", limit: 10)
    books = Book.by_genre(genre)
    books = apply_sorting(books, sort_by)
    books.limit(limit).map(&:to_h)
  end

  def get_book_details(isbn:, include_reviews: false)
    book = Book.find_by(isbn: isbn)
    return { error: "Book not found" } unless book

    result = book.to_detailed_h
    result[:reviews] = book.reviews.recent.limit(5) if include_reviews
    result
  end

  private

  def apply_sorting(scope, sort_by)
    case sort_by
    when "rating" then scope.order(rating: :desc)
    when "date" then scope.order(published_at: :desc)
    when "title" then scope.order(:title)
    else scope
    end
  end
end
```

## ベストプラクティス

### 1. エラーハンドリング

```ruby
class SafeTool
  extend Langchain::ToolDefinition

  define_function :risky_operation,
    description: "エラーが発生する可能性のある操作" do
    property :input, type: "string", required: true
  end

  def risky_operation(input:)
    # 入力検証
    return { error: "Invalid input" } if input.blank?

    begin
      # 危険な操作
      result = perform_operation(input)
      { success: true, result: result }
    rescue StandardError => e
      Rails.logger.error "Tool error: #{e.message}"
      { success: false, error: e.message }
    end
  end
end
```

### 2. パフォーマンス最適化

```ruby
class CachedTool
  extend Langchain::ToolDefinition

  define_function :expensive_search,
    description: "重い検索処理" do
    property :query, type: "string", required: true
  end

  def expensive_search(query:)
    # キャッシュを使用
    Rails.cache.fetch("tool:search:#{query}", expires_in: 1.hour) do
      perform_expensive_search(query)
    end
  end
end
```

### 3. テスト可能な設計

```ruby
# ツールのテスト
RSpec.describe BookSearchTool do
  let(:tool) { described_class.new }

  describe "#search_by_genre" do
    it "returns books for the given genre" do
      create(:book, genre: ["Fiction"], title: "Test Book")

      result = tool.search_by_genre(genre: "Fiction")

      expect(result).to be_an(Array)
      expect(result.first[:title]).to eq("Test Book")
    end
  end
end

# アシスタントのテスト
RSpec.describe BookAssistantService do
  let(:service) { described_class.new }

  it "processes book queries" do
    VCR.use_cassette("openai_book_query") do
      response = service.process_query("おすすめの本を教えて")

      expect(response[:success]).to be true
      expect(response[:message]).to include("本")
    end
  end
end
```

## 注意事項

1. **API制限**: 各LLMプロバイダーのレート制限に注意
2. **コスト管理**: トークン使用量を監視
3. **セキュリティ**: APIキーは環境変数で管理
4. **並行処理**: ツールの並列実行時の考慮
5. **タイムアウト**: 長時間実行されるツールの制御

## 参考リンク

- [Langchain.rb GitHub](https://github.com/patterns-ai-core/langchainrb)
- [RubyGems](https://rubygems.org/gems/langchainrb)
- [公式ドキュメント](https://github.com/patterns-ai-core/langchainrb#readme)
