class Content {
  final String content;
  final String author;
  final String category;
  final String name;
  final String image;
  final String id;
  final String type;
  final String authorImagePath;
  final String cultureImagePath;
  final String culture;

  Content({
    required this.content,
    required this.author,
    required this.category,
    required this.name,
    required this.image,
    required this.id,
    required this.type,
    this.authorImagePath = '',
    this.cultureImagePath ='',
    this.culture = '', // Assign the default value for 'culture'
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      content: json['content'] ?? '',
      author: json['author'] ?? '',
      category: json['category'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      authorImagePath: json['authorImagePath'] ?? '',
      cultureImagePath: json['cultureImagePath'] ?? '',
      culture: json['culture'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'author': author,
      'category': category,
      'name': name,
      'image': image,
      'id': id,
      'type': type,
      'authorImagePath': authorImagePath,
      'cultureImagePath': cultureImagePath,
      'culture': culture, // Include 'culture' in the JSON representation
    };
  }

  Content copyWith({
    String? content,
    String? author,
    String? category,
    String? name,
    String? image,
    String? id,
    String? type,
    String? authorImagePath,
    String? cultureImagePath,
    String? culture,
  }) {
    return Content(
      content: content ?? this.content,
      author: author ?? this.author,
      category: category ?? this.category,
      name: name ?? this.name,
      image: image ?? this.image,
      id: id ?? this.id,
      type: type ?? this.type,
      authorImagePath: authorImagePath ?? this.authorImagePath,
      cultureImagePath: cultureImagePath ?? this.cultureImagePath,
      culture: culture ?? this.culture,
    );
  }
}
