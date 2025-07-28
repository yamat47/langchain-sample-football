# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# 本のデータ
books_data = [
  # 小説・文学
  { title: "ノルウェイの森", author: "村上春樹", genre: "文学" },
  { title: "1Q84", author: "村上春樹", genre: "文学" },
  { title: "海辺のカフカ", author: "村上春樹", genre: "文学" },
  { title: "コンビニ人間", author: "村田沙耶香", genre: "文学" },
  { title: "火花", author: "又吉直樹", genre: "文学" },
  { title: "羊と鋼の森", author: "宮下奈都", genre: "文学" },
  { title: "かがみの孤城", author: "辻村深月", genre: "文学" },
  { title: "流浪の月", author: "凪良ゆう", genre: "文学" },
  
  # ミステリー
  { title: "容疑者Xの献身", author: "東野圭吾", genre: "ミステリー" },
  { title: "白夜行", author: "東野圭吾", genre: "ミステリー" },
  { title: "マスカレード・ホテル", author: "東野圭吾", genre: "ミステリー" },
  { title: "十角館の殺人", author: "綾辻行人", genre: "ミステリー" },
  { title: "medium 霊媒探偵城塚翡翠", author: "相沢沙呼", genre: "ミステリー" },
  { title: "屍人荘の殺人", author: "今村昌弘", genre: "ミステリー" },
  
  # SF・ファンタジー
  { title: "三体", author: "劉慈欣", genre: "SF" },
  { title: "プロジェクト・ヘイル・メアリー", author: "アンディ・ウィアー", genre: "SF" },
  { title: "新世界より", author: "貴志祐介", genre: "SF" },
  { title: "鹿の王", author: "上橋菜穂子", genre: "ファンタジー" },
  { title: "十二国記", author: "小野不由美", genre: "ファンタジー" },
  
  # ビジネス書
  { title: "嫌われる勇気", author: "岸見一郎、古賀史健", genre: "自己啓発" },
  { title: "FACTFULNESS", author: "ハンス・ロスリング", genre: "ビジネス" },
  { title: "サピエンス全史", author: "ユヴァル・ノア・ハラリ", genre: "歴史" },
  { title: "7つの習慣", author: "スティーブン・R・コヴィー", genre: "自己啓発" },
  { title: "思考の整理学", author: "外山滋比古", genre: "エッセイ" },
  
  # ノンフィクション
  { title: "応仁の乱", author: "呉座勇一", genre: "歴史" },
  { title: "ケーキの切れない非行少年たち", author: "宮口幸治", genre: "社会" },
  { title: "バッタを倒しにアフリカへ", author: "前野ウルド浩太郎", genre: "科学" },
  
  # エッセイ・随筆
  { title: "君たちはどう生きるか", author: "吉野源三郎", genre: "哲学" },
  { title: "ぼくはイエローでホワイトで、ちょっとブルー", author: "ブレイディみかこ", genre: "エッセイ" },
  { title: "生き方", author: "稲盛和夫", genre: "ビジネス" }
]

# レビューテキストのバリエーション
review_templates = {
  positive: [
    # 感動系
    "読み終わった後、しばらく放心状態でした。こんなに心を揺さぶられる作品に出会えて幸せです。",
    "涙が止まりませんでした。登場人物の心情が痛いほど伝わってきて、自分のことのように感じました。",
    "人生観が変わりました。この本に出会えて本当によかったです。",
    "心に深く刻まれる一冊でした。何度も読み返したくなります。",
    
    # 知的興奮系
    "知的好奇心を刺激される素晴らしい内容でした。新しい視点を得ることができました。",
    "目から鱗が落ちる思いでした。著者の洞察力に脱帽です。",
    "難しいテーマを分かりやすく解説していて、とても勉強になりました。",
    "この分野の入門書として最適だと思います。初心者にもおすすめできます。",
    
    # エンターテインメント系
    "ページをめくる手が止まりませんでした！一気読みしてしまいました。",
    "次の展開が気になって、夜更かししてしまいました。久々に熱中できる本に出会えました。",
    "ワクワクドキドキが止まらない！エンターテインメントとして最高の作品です。",
    "予想外の展開の連続で、最後まで飽きることなく楽しめました。",
    
    # 実用的評価
    "実践的な内容で、すぐに仕事に活かせそうです。買ってよかったです。",
    "具体例が豊富で理解しやすかったです。実務で役立っています。",
    "体系的にまとまっていて、教科書として使えます。",
    "著者の経験に基づく内容で説得力がありました。"
  ],
  
  neutral: [
    # 良い点と悪い点の両方
    "内容は興味深いですが、少し冗長な部分もありました。もう少しコンパクトにまとまっていればなお良かったです。",
    "前半は引き込まれましたが、後半は少し失速した感じがします。それでも読む価値はあると思います。",
    "期待していたものとは少し違いましたが、それはそれで新しい発見がありました。",
    "好みが分かれる作品だと思います。私には合いませんでしたが、好きな人は好きだと思います。",
    
    # 条件付き推薦
    "この分野に興味がある人にはおすすめですが、初心者には少し難しいかもしれません。",
    "ファンなら楽しめると思いますが、初めての人にはハードルが高いかも。",
    "時間がある時にゆっくり読むのがいいと思います。軽い読み物ではありません。",
    "翻訳は読みやすいですが、原書で読めたらもっと良かったかもしれません。"
  ],
  
  negative: [
    # 期待外れ
    "話題になっていたので期待していましたが、私には合いませんでした。",
    "評判ほどではなかったというのが正直な感想です。",
    "途中で挫折してしまいました。最後まで読む気力が続きませんでした。",
    "内容が薄く、得るものがあまりありませんでした。",
    
    # 構成・文体の問題
    "構成が分かりづらく、何を伝えたいのかよく分かりませんでした。",
    "文章が読みづらく、内容以前の問題だと感じました。",
    "同じことの繰り返しが多く、もっと簡潔にまとめられたのではないでしょうか。",
    "専門用語が多すぎて、一般読者には理解しづらいと思います。"
  ]
}

# シードデータの作成
books_data.each do |book_data|
  book = Book.find_or_create_by!(title: book_data[:title]) do |b|
    b.author = book_data[:author]
    b.genre = book_data[:genre]
  end
  
  # 各本に3-5個のレビューを追加
  num_reviews = rand(3..5)
  
  num_reviews.times do
    # レビューのタイプをランダムに選択（positive多め）
    review_type = [:positive, :positive, :positive, :neutral, :negative].sample
    review_text = review_templates[review_type].sample
    
    # レーティングを決定
    rating = case review_type
    when :positive
      rand(4..5)
    when :neutral
      rand(2..4)
    when :negative
      rand(1..2)
    end
    
    Review.find_or_create_by!(
      book: book,
      content: review_text
    ) do |r|
      r.rating = rating
      r.reviewer_name = ["読書好き", "本の虫", "活字中毒", "ブックレビュアー", "一般読者", "専門家", "学生", "会社員", "主婦", "図書館司書"].sample
    end
  end
end

puts "Created #{Book.count} books with #{Review.count} reviews."
