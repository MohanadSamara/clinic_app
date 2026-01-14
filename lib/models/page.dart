class Page {
  final int? id;
  final String slug;
  final String title;
  final String content;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Page({
    this.id,
    required this.slug,
    required this.title,
    required this.content,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Page.fromMap(Map<String, dynamic> map) {
    return Page(
      id: map['id'] as int?,
      slug: map['slug'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      isPublished: (map['is_published'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'slug': slug,
      'title': title,
      'content': content,
      'is_published': isPublished ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Page copyWith({
    int? id,
    String? slug,
    String? title,
    String? content,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Page(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      content: content ?? this.content,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
