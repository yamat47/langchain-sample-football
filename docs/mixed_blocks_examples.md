# Mixed Blocks Response Examples

This document shows various patterns for mixing text and book blocks in responses.

## Block Types Available

1. **text** - Markdown-formatted explanatory text
2. **book_card** - Compact book display for lists
3. **book_spotlight** - Featured single book with extended details
4. **book_list** - Collection of related books
5. **image** - Standalone images

## Pattern 1: Alternating Text and Book Cards

**User Query**: "Show me some mystery books with detailed explanations"

**Response Structure**:
```json
{
  "blocks": [
    {
      "type": "text",
      "content": {
        "markdown": "I've found some excellent mystery novels that match your interests:"
      }
    },
    {
      "type": "book_card",
      "content": {
        "isbn": "978-...",
        "title": "The Girl with the Dragon Tattoo",
        "author": "Stieg Larsson",
        "rating": 4.5,
        "genres": ["Mystery", "Thriller"],
        "price": 24.99,
        "image_url": "https://...",
        "description": "A gripping mystery..."
      }
    },
    {
      "type": "text",
      "content": {
        "markdown": "This book is particularly notable for its complex plot and strong character development. If you enjoy Nordic noir, you might also appreciate:"
      }
    },
    {
      "type": "book_card",
      "content": {
        "isbn": "978-...",
        "title": "The Snowman",
        "author": "Jo Nesbø",
        "rating": 4.3,
        "genres": ["Mystery", "Nordic Noir"],
        "price": 22.99,
        "image_url": "https://...",
        "description": "Another Nordic thriller..."
      }
    },
    {
      "type": "text",
      "content": {
        "markdown": "Both authors are masters of the Nordic noir genre, known for their atmospheric settings and psychological depth."
      }
    }
  ]
}
```

## Pattern 2: Introduction, Featured Book, Context, Related Books

**User Query**: "I want to get into science fiction"

**Response Structure**:
```json
{
  "blocks": [
    {
      "type": "text",
      "content": {
        "markdown": "## Getting Started with Science Fiction\n\nScience fiction is a fantastic genre for exploring big ideas about technology, society, and human nature. Here's my top recommendation for beginners:"
      }
    },
    {
      "type": "book_card",
      "content": {
        "isbn": "978-...",
        "title": "The Martian",
        "author": "Andy Weir",
        "rating": 4.7,
        "genres": ["Science Fiction", "Adventure"],
        "price": 19.99,
        "image_url": "https://...",
        "description": "A thrilling survival story..."
      }
    },
    {
      "type": "text",
      "content": {
        "markdown": "### Why Start Here?\n\n'The Martian' is perfect for sci-fi beginners because:\n- Hard science made accessible\n- Humor mixed with tension\n- Character-driven narrative\n\n### Ready for More?\n\nOnce you've enjoyed 'The Martian', here are some excellent follow-up reads:"
      }
    },
    {
      "type": "book_list",
      "content": {
        "title": "Next Steps in Your Sci-Fi Journey",
        "books": [
          {
            "isbn": "978-...",
            "title": "Project Hail Mary",
            "author": "Andy Weir",
            "rating": 4.8,
            "genres": ["Science Fiction"],
            "image_url": "https://..."
          },
          {
            "isbn": "978-...",
            "title": "Ender's Game",
            "author": "Orson Scott Card",
            "rating": 4.5,
            "genres": ["Science Fiction", "Military"],
            "image_url": "https://..."
          },
          {
            "isbn": "978-...",
            "title": "Ready Player One",
            "author": "Ernest Cline",
            "rating": 4.3,
            "genres": ["Science Fiction", "Dystopian"],
            "image_url": "https://..."
          }
        ]
      }
    },
    {
      "type": "text",
      "content": {
        "markdown": "These books gradually introduce more complex sci-fi concepts while maintaining engaging storylines. Happy reading!"
      }
    }
  ]
}
```

## Pattern 3: Comparison Format

**User Query**: "Compare Harry Potter and Lord of the Rings"

**Response Structure**:
```json
{
  "blocks": [
    {
      "type": "text",
      "content": {
        "markdown": "## Harry Potter vs. Lord of the Rings\n\nBoth are beloved fantasy series, but they offer very different reading experiences:"
      }
    },
    {
      "type": "book_card",
      "content": {
        "isbn": "978-...",
        "title": "Harry Potter and the Sorcerer's Stone",
        "author": "J.K. Rowling",
        "rating": 4.8,
        "genres": ["Fantasy", "Young Adult"],
        "price": 12.99,
        "image_url": "https://...",
        "description": "The beginning of Harry's magical journey..."
      }
    },
    {
      "type": "text",
      "content": {
        "markdown": "### Harry Potter Series\n- **Target Audience**: Originally young adult, appeals to all ages\n- **Writing Style**: Accessible, gradually matures with readers\n- **World**: Contemporary setting with hidden magical world\n- **Themes**: Coming of age, good vs evil, friendship\n\nNow let's look at Tolkien's masterpiece:"
      }
    },
    {
      "type": "book_card",
      "content": {
        "isbn": "978-...",
        "title": "The Fellowship of the Ring",
        "author": "J.R.R. Tolkien",
        "rating": 4.6,
        "genres": ["Fantasy", "Epic"],
        "price": 15.99,
        "image_url": "https://...",
        "description": "The epic journey begins..."
      }
    },
    {
      "type": "text",
      "content": {
        "markdown": "### Lord of the Rings\n- **Target Audience**: Adult readers, fantasy enthusiasts\n- **Writing Style**: Dense, poetic, detailed world-building\n- **World**: Complete secondary world with deep history\n- **Themes**: Power and corruption, sacrifice, hope vs despair\n\n### Which Should You Read?\n- Choose **Harry Potter** if you want: Fast-paced adventure, relatable characters, easier entry into fantasy\n- Choose **Lord of the Rings** if you want: Epic scope, detailed world-building, classic high fantasy"
      }
    }
  ]
}
```

## Pattern 4: Quick Answer First

**User Query**: "What's that book about Mars survival?"

**Response Structure**:
```json
{
  "blocks": [
    {
      "type": "book_card",
      "content": {
        "isbn": "978-...",
        "title": "The Martian",
        "author": "Andy Weir",
        "rating": 4.7,
        "genres": ["Science Fiction", "Survival"],
        "price": 19.99,
        "image_url": "https://...",
        "description": "An astronaut's fight for survival on Mars"
      }
    },
    {
      "type": "text",
      "content": {
        "markdown": "Yes! You're thinking of 'The Martian' by Andy Weir. It follows Mark Watney, an astronaut stranded on Mars who must use his wit and engineering skills to survive until rescue."
      }
    }
  ]
}
```

## Pattern 5: Book Spotlight for Deep Dives

**User Query**: "Tell me everything about Dune by Frank Herbert"

**Response Structure**:
```json
{
  "blocks": [
    {
      "type": "text",
      "content": {
        "markdown": "## Dune: A Science Fiction Masterpiece\n\nLet me share why this book is considered one of the greatest science fiction novels ever written:"
      }
    },
    {
      "type": "book_spotlight",
      "content": {
        "isbn": "978-0-441-17271-9",
        "title": "Dune",
        "author": "Frank Herbert",
        "rating": 4.7,
        "genres": ["Science Fiction", "Epic", "Political"],
        "price": 18.99,
        "image_url": "https://...",
        "description": "A science fiction masterpiece about politics, religion, and ecology",
        "extended_description": "Set in the distant future amidst a feudal interstellar society, Dune tells the story of young Paul Atreides, whose family accepts the stewardship of the planet Arrakis. The story explores the complex interactions of politics, religion, ecology, technology, and human emotion, as the factions of the empire confront each other for control of Arrakis and its 'spice'.",
        "key_themes": [
          "Power and politics",
          "Ecology and environment",
          "Religion and mysticism",
          "Human potential and evolution",
          "The dangers of messianic leadership"
        ],
        "why_recommended": "Dune is not just a novel, it's a complete universe. Herbert created one of the most detailed and believable future societies in all of science fiction. The book works on multiple levels - as an adventure story, a political thriller, an ecological parable, and a philosophical meditation on power and human nature.",
        "similar_books": [
          "Foundation by Isaac Asimov",
          "The Left Hand of Darkness by Ursula K. Le Guin",
          "Hyperion by Dan Simmons",
          "The Book of the New Sun by Gene Wolfe"
        ]
      }
    },
    {
      "type": "text",
      "content": {
        "markdown": "### Reading Tips\n\n- Don't be intimidated by the terminology - there's a glossary at the back\n- Pay attention to the chapter epigraphs - they provide context\n- The first 100 pages are setup - the payoff is worth it\n\nWould you like to know about the sequels or explore similar epic science fiction?"
      }
    }
  ]
}
```

## Pattern 6: Comparison with Multiple Spotlights

**User Query**: "Compare 1984 and Brave New World in detail"

**Response Structure**:
```json
{
  "blocks": [
    {
      "type": "text",
      "content": {
        "markdown": "## Two Visions of Dystopia\n\nBoth novels present terrifying visions of the future, but their approaches couldn't be more different:"
      }
    },
    {
      "type": "book_spotlight",
      "content": {
        "isbn": "978-0-452-28423-4",
        "title": "1984",
        "author": "George Orwell",
        "rating": 4.6,
        "genres": ["Dystopian", "Political Fiction", "Classic"],
        "price": 15.99,
        "image_url": "https://...",
        "description": "A totalitarian nightmare of surveillance and thought control",
        "extended_description": "Winston Smith lives in a world of perpetual war, omnipresent surveillance, and public manipulation. The Party controls everything - even the truth. Winston's rebellion begins with a diary and a love affair, both crimes punishable by death.",
        "key_themes": [
          "Totalitarian control",
          "Language as thought control",
          "The malleability of truth",
          "Individual vs. state",
          "The destruction of privacy"
        ],
        "why_recommended": "Orwell's vision has proven prophetic in many ways. Terms like 'Big Brother', 'thoughtcrime', and 'doublethink' have entered our language because they describe real phenomena. Essential reading for understanding modern surveillance states and information warfare.",
        "similar_books": ["Animal Farm", "Fahrenheit 451", "The Handmaid's Tale"]
      }
    },
    {
      "type": "text",
      "content": {
        "markdown": "### The Iron Fist Approach\nOrwell shows control through fear, pain, and oppression. Now contrast this with Huxley's vision:"
      }
    },
    {
      "type": "book_spotlight",
      "content": {
        "isbn": "978-0-06-085052-4",
        "title": "Brave New World",
        "author": "Aldous Huxley",
        "rating": 4.5,
        "genres": ["Dystopian", "Science Fiction", "Classic"],
        "price": 16.99,
        "image_url": "https://...",
        "description": "A dystopia of pleasure, conditioning, and engineered happiness",
        "extended_description": "In the World State, everyone is happy - because they're genetically engineered and conditioned to be. Bernard Marx feels something is wrong with a world where people take soma to escape any discomfort and where 'everyone belongs to everyone else'.",
        "key_themes": [
          "Pleasure as control",
          "Technology and dehumanization",
          "The price of stability",
          "Individuality vs. happiness",
          "Consumer culture critique"
        ],
        "why_recommended": "Huxley's vision is arguably more relevant today than Orwell's. We're not controlled by pain but by pleasure - endless entertainment, social media dopamine hits, and consumer culture. A chilling look at how we might surrender freedom for comfort.",
        "similar_books": ["Island (Huxley)", "We by Yevgeny Zamyatin", "The Giver"]
      }
    },
    {
      "type": "text",
      "content": {
        "markdown": "### The Velvet Glove Approach\n\n**Key Differences:**\n- **Control Method**: Orwell uses fear; Huxley uses pleasure\n- **Knowledge**: In 1984, information is restricted; in Brave New World, it's irrelevant\n- **Love**: Forbidden in 1984; meaningless in Brave New World\n- **Rebellion**: Crushed in 1984; impossible to conceive in Brave New World\n\nWhich vision do you find more frightening? Which seems more like our world today?"
      }
    }
  ]
}
```

## Implementation Notes

1. **Flexibility**: The system can handle any combination of blocks in any order
2. **Context**: Text blocks provide context, transitions, and additional information
3. **Visual Appeal**: Book cards provide rich visual information
4. **Grouping**: Book lists are perfect for showing multiple related options
5. **Natural Flow**: Structure responses to feel conversational and helpful