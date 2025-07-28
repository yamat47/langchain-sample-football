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
- RuboCop（コードスタイルチェック）: `bundle exec rubocop`
- RuboCop（自動修正）: `bundle exec rubocop -a`
- Brakeman（セキュリティチェック）: `bundle exec brakeman`
- すべてのチェックを実行: `bundle exec rubocop && bundle exec brakeman`

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

## 言語設定

### 英語主体の開発
- **すべてのUI文言は英語で実装する**
- データベースのサンプルデータ（seeds.rb）も英語で作成
- コメントやドキュメントは日本語可（開発者向けのため）
- エラーメッセージ、通知、ユーザー向けテキストはすべて英語
- 英語は自然で読みやすい表現を心がける（ネイティブスピーカーが違和感を感じない程度）

### 英語化の範囲
- ビューファイルのすべての表示テキスト
- モデルのバリデーションメッセージ
- フラッシュメッセージ
- JavaScript のアラートやコンソールメッセージ
- seed データ（本のタイトルは原語のまま、レビューは英語）