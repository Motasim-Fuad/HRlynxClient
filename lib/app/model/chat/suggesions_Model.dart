class SuggesionsModel {
  bool success;
  List<String> suggestions;

  SuggesionsModel({
    required this.success,
    required this.suggestions,
  });

  factory SuggesionsModel.fromJson(Map<String, dynamic> json) {
    return SuggesionsModel(
      success: json['success'] ?? false,
      suggestions: (json['suggestions'] as List?)
          ?.whereType<String>()
          .toList() ??
          [],
    );
  }
}
