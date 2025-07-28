# frozen_string_literal: true

class BookDataGenerator
  GENRES = [
    "Fantasy", "Science Fiction", "Mystery", "Thriller", "Romance",
    "Literary Fiction", "Historical Fiction", "Young Adult", "Horror",
    "Non-Fiction", "Biography", "Self-Help", "Business", "Philosophy",
    "Psychology", "History", "Science", "Technology", "Art", "Music",
    "Poetry", "Drama", "Humor", "Travel", "Cooking", "Health",
    "Sports", "Religion", "Politics", "Economics", "Education",
    "Children's", "Graphic Novel", "Crime", "Adventure", "Western",
    "Dystopian", "Magical Realism", "Contemporary", "Classic", "Memoir"
  ].freeze

  FIRST_NAMES = [
    "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
    "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
    "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa",
    "Haruki", "Yuki", "Takashi", "Akiko", "Kenji", "Miho", "Hiroshi", "Yoko",
    "Gabriel", "Maria", "Carlos", "Ana", "Luis", "Sofia", "Antonio", "Elena",
    "Pierre", "Marie", "Jean", "Sophie", "Hans", "Emma", "Giovanni", "Lucia"
  ].freeze

  LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
    "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Thompson", "White",
    "Murakami", "Tanaka", "Yamamoto", "Suzuki", "Watanabe", "Ito", "Nakamura", "Sato",
    "García Márquez", "Borges", "Allende", "Cortázar", "Neruda", "Vargas Llosa",
    "Eco", "Calvino", "Ferrante", "Müller", "Larsson", "Knausgård", "Houellebecq"
  ].freeze

  PUBLISHERS = [
    "Penguin Random House", "HarperCollins", "Macmillan", "Simon & Schuster",
    "Hachette Livre", "Pearson", "Scholastic", "John Wiley & Sons", "Oxford University Press",
    "Cambridge University Press", "MIT Press", "Yale University Press", "Norton",
    "Bloomsbury", "Faber & Faber", "Vintage", "Knopf", "Farrar Straus Giroux",
    "Grove Atlantic", "Graywolf Press", "Coffee House Press", "Melville House",
    "Kodansha", "Shueisha", "Shinchosha", "Bungeishunju", "Iwanami Shoten"
  ].freeze

  TITLE_PATTERNS = [
    "The %s of %s", "A %s in %s", "%s and %s", "The %s's %s",
    "Beyond the %s", "When %s Met %s", "The Last %s", "First %s",
    "%s Under the %s", "The %s Who %s", "%s: A Story of %s",
    "Letters from %s", "The %s Keeper", "%s's Journey", "Finding %s",
    "The Art of %s", "In Search of %s", "The %s Paradox", "%s Rising",
    "Chronicles of %s", "The %s Diaries", "Echoes of %s", "%s Unbound"
  ].freeze

  TITLE_WORDS = [
    "Shadow", "Light", "Dream", "Memory", "Time", "Love", "War", "Peace",
    "Journey", "Secret", "Truth", "Destiny", "Hope", "Fear", "Courage",
    "Wisdom", "Beauty", "Darkness", "Dawn", "Twilight", "Storm", "Silence",
    "Voice", "Heart", "Soul", "Mind", "Spirit", "Fire", "Water", "Earth",
    "Wind", "Star", "Moon", "Sun", "Night", "Day", "Life", "Death",
    "Beginning", "End", "Path", "Bridge", "Door", "Window", "Mirror",
    "Garden", "Forest", "Mountain", "Ocean", "River", "Desert", "Island"
  ].freeze

  LANGUAGES = ["en", "ja", "es", "fr", "de", "it", "pt", "ru", "zh", "ko"].freeze

  def self.generate_books(count = 1000)
    # Use deterministic random seed for consistent data
    rng = Random.new(12_345)

    books = []
    used_isbns = Set.new

    count.times do |i|
      isbn = generate_unique_isbn(i)
      used_isbns.add(isbn)

      books << {
        isbn: isbn,
        title: generate_title(rng),
        author: generate_author(rng),
        description: generate_description(rng),
        genres: generate_genres(rng),
        rating: generate_rating(rng),
        price: generate_price(rng),
        publisher: PUBLISHERS[rng.rand(PUBLISHERS.size)],
        page_count: rng.rand(100..800),
        published_at: generate_published_date(rng),
        language: weighted_language(rng),
        is_trending: generate_trending_status(i),
        trending_score: generate_trending_score(i)
      }
    end

    books
  end

  def self.generate_unique_isbn(index)
    # Generate deterministic ISBNs based on the index
    prefix = index < 500 ? "978" : "979"
    group = index % 10
    publisher = 10_000 + (index / 10)
    title = 10_000 + index
    check = index % 10

    "#{prefix}-#{group}-#{publisher}-#{title}-#{check}"
  end

  def self.generate_title(rng = Random)
    pattern = TITLE_PATTERNS[rng.rand(TITLE_PATTERNS.size)]
    word_count = pattern.count("%s")
    words = word_count.times.map { TITLE_WORDS[rng.rand(TITLE_WORDS.size)] }

    if pattern.count("%s") == 2
      pattern % words
    elsif pattern.count("%s") == 1
      pattern % words.first
    else
      TITLE_WORDS.sample(2).join(" ")
    end
  end

  def self.generate_author(rng = Random)
    first = FIRST_NAMES[rng.rand(FIRST_NAMES.size)]
    last = LAST_NAMES[rng.rand(LAST_NAMES.size)]
    "#{first} #{last}"
  end

  def self.generate_description(rng = Random)
    templates = [
      "A compelling story about %s that explores the depths of %s.",
      "An intimate portrait of %s set against the backdrop of %s.",
      "When %s meets %s, everything changes in this unforgettable tale.",
      "A groundbreaking work that examines %s through the lens of %s.",
      "This masterful narrative weaves together %s and %s in unexpected ways.",
      "A thought-provoking exploration of %s in modern society.",
      "The definitive guide to understanding %s and its impact on %s.",
      "A haunting tale of %s that will stay with you long after the last page.",
      "Discover the secrets of %s in this page-turning adventure.",
      "An essential read for anyone interested in %s and %s."
    ]

    template = templates[rng.rand(templates.size)]
    topics = [
      "human nature", "love and loss", "family dynamics", "social justice",
      "personal growth", "cultural identity", "technological change", "environmental crisis",
      "political upheaval", "artistic expression", "scientific discovery", "philosophical inquiry",
      "historical events", "future possibilities", "moral dilemmas", "psychological complexity"
    ]

    topic_count = template.count("%s")
    selected_topics = topic_count.times.map { topics[rng.rand(topics.size)] }
    template % selected_topics
  end

  def self.generate_genres(rng = Random)
    # Most books have 1-3 genres
    count_options = [1, 1, 2, 2, 2, 3, 3, 4]
    count = count_options[rng.rand(count_options.size)]
    count.times.map { GENRES[rng.rand(GENRES.size)] }.uniq
  end

  def self.generate_rating(rng = Random)
    # Generate realistic rating distribution
    # Most books cluster around 3.5-4.5
    base = 3.5 + (rng.rand * 1.0)
    variation = (rng.rand - 0.5)
    rating = base + variation

    # Ensure within bounds and round to 2 decimal places
    [[rating, 5.0].min, 3.0].max.round(2)
  end

  def self.generate_price(rng = Random)
    # Price in yen, realistic distribution
    price_ranges = [
      (800..1200),   # Paperback
      (1200..1800),  # Trade paperback
      (1800..2500),  # Hardcover
      (2500..3500),  # Premium/Special edition
      (500..800),    # Mass market
      (3500..5000)   # Collectible/Art book
    ]

    range = price_ranges[rng.rand(price_ranges.size)]
    price = range.min + rng.rand(range.max - range.min + 1)
    (price / 100).round * 100
  end

  def self.generate_published_date(rng = Random)
    # Weighted towards recent years but includes classics
    year_weights = {
      (1900..1950) => 0.05,
      (1951..1980) => 0.10,
      (1981..2000) => 0.15,
      (2001..2010) => 0.20,
      (2011..2020) => 0.30,
      (2021..2024) => 0.20
    }

    range = weighted_choice(year_weights, rng)
    year = range.min + rng.rand(range.max - range.min + 1)
    month = 1 + rng.rand(12)
    day = 1 + rng.rand(28) # Avoid invalid dates

    Date.new(year, month, day)
  end

  def self.weighted_language(rng = Random)
    # 70% English, 20% Japanese, 10% others
    rand_val = rng.rand
    if rand_val < 0.7
      "en"
    elsif rand_val < 0.9
      "ja"
    else
      LANGUAGES[rng.rand(LANGUAGES.size)]
    end
  end

  def self.generate_trending_status(index)
    # About 1% of books are trending (10 out of 1000)
    index < 10
  end

  def self.generate_trending_score(index)
    if index < 10
      100 - (index * 10) # Score from 100 down to 10
    else
      0
    end
  end

  def self.weighted_choice(weights, rng = Random)
    total = weights.values.sum
    random_val = rng.rand * total

    cumulative = 0
    weights.each do |range, weight|
      cumulative += weight
      return range if random_val <= cumulative
    end

    weights.keys.last # Fallback
  end
end
