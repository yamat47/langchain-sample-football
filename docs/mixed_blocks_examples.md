# Mixed Blocks Response Examples

This document shows various patterns for mixing text and book blocks in responses.

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

## Implementation Notes

1. **Flexibility**: The system can handle any combination of blocks in any order
2. **Context**: Text blocks provide context, transitions, and additional information
3. **Visual Appeal**: Book cards provide rich visual information
4. **Grouping**: Book lists are perfect for showing multiple related options
5. **Natural Flow**: Structure responses to feel conversational and helpful