class Quote {
  final String text;
  final String author;

  const Quote({required this.text, required this.author});

  Map<String, Object?> toMap() {
    return {'text': text, 'author': author};
  }

  factory Quote.fromMap(Map<String, Object?> map) {
    return Quote(
      text: map['text'] as String,
      author: map['author'] as String,
    );
  }
}
