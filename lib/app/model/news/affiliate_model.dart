class AffiliateProductsResponse {
  final PaginationModel pagination;
  final List<AffiliateProductModel> results;

  AffiliateProductsResponse({
    required this.pagination,
    required this.results,
  });

  factory AffiliateProductsResponse.fromJson(Map<String, dynamic> json) {
    return AffiliateProductsResponse(
      pagination: PaginationModel.fromJson(json['pagination'] ?? {}),
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => AffiliateProductModel.fromJson(item))
          .toList(),
    );
  }
}

class PaginationModel {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;
  final int? nextPage;
  final int? previousPage;

  PaginationModel({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
    this.nextPage,
    this.previousPage,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalItems: json['total_items'] ?? 0,
      pageSize: json['page_size'] ?? 20,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
      nextPage: json['next_page'],
      previousPage: json['previous_page'],
    );
  }
}

class AffiliateProductModel {
  final int id;
  final int category;
  final String title;
  final String image;
  final String affiliateUrl;
  final String disclaimer;
  final bool isActive;
  final int totalClicks;
  final int clickCount;
  final String createdAt;
  final String updatedAt;

  AffiliateProductModel({
    required this.id,
    required this.category,
    required this.title,
    required this.image,
    required this.affiliateUrl,
    required this.disclaimer,
    required this.isActive,
    required this.totalClicks,
    required this.clickCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AffiliateProductModel.fromJson(Map<String, dynamic> json) {
    return AffiliateProductModel(
      id: json['id'] ?? 0,
      category: json['category'] ?? 0,
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      affiliateUrl: json['affiliate_url']?.toString() ?? '',
      disclaimer: json['disclaimer']?.toString() ?? '',
      isActive: json['is_active'] ?? false,
      totalClicks: json['total_clicks'] ?? 0,
      clickCount: json['click_count'] ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}
