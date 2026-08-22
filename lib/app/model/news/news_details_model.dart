class NewsDetailsModel {
  final int id;
  final String? aiTitle;
  final String? aiSummary;
  final String? originalUrl;
  final String? mainImageUrl;
  final List<TagModel> tags;
  final CategoryModel? category;

  NewsDetailsModel({
    required this.id,
    this.aiTitle,
    this.aiSummary,
    this.originalUrl,
    this.mainImageUrl,
    this.tags = const [],
    this.category,
  });

  factory NewsDetailsModel.fromJson(Map<String, dynamic> json) {
    return NewsDetailsModel(
      id: json['id'] ?? 0,
      aiTitle: json['ai_title']?.toString(),
      aiSummary: json['ai_summary']?.toString(),
      originalUrl: json['original_url']?.toString(),
      mainImageUrl: json['main_image_url']?.toString(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((tag) => TagModel.fromJson(tag))
          .toList(),
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
    );
  }
}

class TagModel {
  final int id;
  final String name;
  final String? description;

  TagModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

class CategoryModel {
  final String slug;
  final String? name;

  CategoryModel({
    required this.slug,
    this.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }
}
