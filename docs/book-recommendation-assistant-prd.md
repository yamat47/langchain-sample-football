# 読書推薦アシスタント PRD

## 概要
最新の書籍トレンドと詳細な書籍情報を組み合わせて、ユーザーの興味に合った本を推薦するAIアシスタント

## 主要機能

### 1. NewsRetriever: 最新書籍トレンド取得
- 新刊リリース情報の検索
- 文学賞受賞ニュース
- 著者インタビューや書評記事
- 話題の本やベストセラー情報

### 2. 外部書籍API: 詳細情報取得
- 書籍基本情報（ISBN、タイトル、著者、出版社、価格）
- ジャンル・タグ情報
- レビュー評価（評点、レビュー数）
- 関連書籍・類似作品
- 購入可能な書店情報

## 技術実装

### アシスタント構成
```ruby
# LLM初期化
llm = Langchain::LLM::OpenAI.new(
  api_key: ENV["OPENAI_API_KEY"],
  default_options: { temperature: 0.7, chat_model: "gpt-4" }
)

# カスタムツール定義
class BookInfoTool
  extend Langchain::ToolDefinition
  
  define_function :search_books,
    description: "Search for books by title, author, or ISBN" do
    property :query, type: "string", required: true
    property :search_type, type: "string", enum: ["title", "author", "isbn"]
  end
  
  define_function :get_book_details,
    description: "Get detailed information about a specific book" do
    property :isbn, type: "string", required: true
  end
  
  define_function :get_similar_books,
    description: "Find books similar to a given book" do
    property :isbn, type: "string", required: true
    property :limit, type: "integer", default: 5
  end
end

# アシスタント作成
assistant = Langchain::Assistant.new(
  llm: llm,
  instructions: "You are a knowledgeable book recommendation assistant...",
  tools: [
    Langchain::Tool::NewsRetriever.new(api_key: ENV["NEWS_API_KEY"]),
    BookInfoTool.new(api_key: ENV["BOOK_API_KEY"])
  ]
)
```

### NewsRetriever活用方法
```ruby
# 最新の本に関するニュース取得
news_tool.get_everything(
  q: "new book releases fiction",
  language: "en",
  sort_by: "publishedAt",
  page_size: 10
)

# 文学賞関連のトップニュース
news_tool.get_top_headlines(
  category: "entertainment",
  q: "book award winner",
  country: "us"
)
```

### 外部API レスポンス例
```json
{
  "book": {
    "isbn": "978-4-XXXX-XXXX-X",
    "title": "タイトル",
    "author": "著者名",
    "genre": ["ミステリー", "サスペンス"],
    "rating": 4.2,
    "review_count": 1523,
    "price": 1800,
    "availability": "在庫あり"
  },
  "similar_books": [
    {"isbn": "978-4-YYYY-YYYY-Y", "title": "類似本1", "similarity": 0.85}
  ],
  "purchase_links": [
    {"store": "Amazon", "url": "https://...", "price": 1700}
  ]
}
```

## ユースケース例

### 1. 最新トレンドの確認
```
User: 「今月話題になっている小説を教えて」
Assistant: NewsRetrieverで最新ニュースを検索 → 話題の本をリストアップ → 各本の詳細情報を外部APIで取得 → 整理して回答
```

### 2. 特定著者の新作情報
```
User: 「東野圭吾の最新作について知りたい」
Assistant: NewsRetrieverで著者名検索 → 新作情報を取得 → 外部APIで詳細情報取得 → レビュー情報も含めて回答
```

### 3. ジャンル別推薦
```
User: 「最近のミステリー小説でおすすめは？」
Assistant: NewsRetrieverでジャンル指定検索 → 新刊・話題作を特定 → 外部APIで評価確認 → 高評価作品を推薦
```

## 期待される成果
- リアルタイム性: 最新の書籍トレンドを即座に反映
- 情報の充実度: ニュースと詳細情報の組み合わせ
- 推薦精度: ユーザーの好みに合った的確な提案