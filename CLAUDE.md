# 実装用メモ

## 開発方針

### TDD (Test-Driven Development)
- **t-wada の TDD を常に ON にする**
- すべての新機能実装において、テストファーストアプローチを採用
- Red → Green → Refactor のサイクルを厳守
- テストは実装の前に書く
- テストが失敗することを確認してから実装を行う
- 実装後は必ずテストが通ることを確認する

### テスト実行コマンド
- 全テスト実行: `bundle exec rails test`
- モデルテスト: `bundle exec rails test test/models/`
- コントローラーテスト: `bundle exec rails test test/controllers/`
- 特定のテストファイル: `bundle exec rails test test/models/book_test.rb`

### リント・型チェックコマンド
- まだ設定されていません（必要に応じて追加してください）

## プロジェクト固有の注意事項

### API キー
- OpenAI API キーが必要（環境変数 `OPENAI_API_KEY` または Rails credentials）
- News API キーはオプション（環境変数 `NEWS_API_KEY` または Rails credentials）

### データベース
- SQLite を使用しているため、配列型は JSON シリアライズで対応
- GIN インデックスは使用不可

### Langchain.rb
- グローバル設定は使用せず、インスタンスごとに設定
- ToolDefinition の default パラメータは現在サポートされていない

### テストのモック
- API 呼び出しは Minitest::Mock を使用してモック化
- 実際の API キーを使用するテストは skip する