import 'package:HRlynx/app/api_servies/repository/auth_repo.dart';
import 'package:HRlynx/app/api_servies/repository/news_repo.dart';
import 'package:HRlynx/app/model/news/affiliate_model.dart';
import 'package:HRlynx/app/model/news/news_details_model.dart';
import 'package:HRlynx/app/modules/news/news_controller.dart';
import 'package:HRlynx/app/modules/news/news_detail/affilate_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class NewsDetailsViewModel extends GetxController {
  final NewsRepository _newsRepository = NewsRepository();
  final AuthRepository _authRepository = AuthRepository();

  late AffiliateProductsController _affiliateController;

  final Rx<NewsDetailsModel?> article = Rx<NewsDetailsModel?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxInt selectedTagIndex = RxInt(-1);

  // ✅ NEW: Error type tracking
  final RxString errorType = ''.obs;

  NewsDetailsModel? _cachedArticle;
  int? _currentArticleId; // ✅ Store article ID for retry

  @override
  void onInit() {
    super.onInit();
    _affiliateController = Get.put(AffiliateProductsController());
  }

  void initializeArticle(int articleId) {
    _currentArticleId = articleId; // ✅ Save for retry
    fetchArticleDetails(articleId);
  }

  /// ✅ UPDATED: Better error handling
  Future<void> fetchArticleDetails(int articleId) async {
    try {
      if (_cachedArticle != null) {
        article.value = _cachedArticle;
        isLoading.value = false;

        if (_cachedArticle?.category != null) {
          print('📰 Using cached article with category: ${_cachedArticle!.category!.name}');
          await loadAffiliateProducts(_cachedArticle!.category!);
        } else {
          print('⚠️ Cached article has no category - no affiliate products to load');
        }
        return;
      }

      isLoading.value = true;
      error.value = '';
      errorType.value = '';

      print('🔍 Fetching article details for ID: $articleId');

      final response = await _newsRepository.getArticleDetails(articleId);

      if (response['success'] == true && response['data'] != null) {
        _cachedArticle = NewsDetailsModel.fromJson(response['data']);
        article.value = _cachedArticle;

        print('✅ Article loaded: ${_cachedArticle!.aiTitle}');

        if (_cachedArticle?.category != null) {
          print('📦 Article has category: ${_cachedArticle!.category!.name} - Loading affiliate products');
          await loadAffiliateProducts(_cachedArticle!.category!);
        } else {
          print('⚠️ Article has no category - no affiliate products to load');
        }
      } else {
        throw Exception('Failed to load article details - ${response['error']}');
      }
    } catch (e) {
      String errorMsg = e.toString();
      print('❌ Error fetching article details: $errorMsg');

      // ✅ Categorize errors
      if (errorMsg.contains('NETWORK_ERROR')) {
        error.value = 'No Internet Connection';
        errorType.value = 'NETWORK_ERROR';
      } else if (errorMsg.contains('SERVER_ERROR')) {
        error.value = 'Server Error';
        errorType.value = 'SERVER_ERROR';
      } else if (errorMsg.contains('Session expired')) {
        error.value = 'Session Expired';
        errorType.value = 'SESSION_EXPIRED';
      } else {
        error.value = 'Failed to load article details';
        errorType.value = 'UNKNOWN_ERROR';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAffiliateProducts(CategoryModel category) async {
    print('🔍 Loading affiliate products for category: ${category.name} (Slug: ${category.slug})');

    await _affiliateController.fetchAffiliateProducts(
      categorySlug: category.slug,
      isRefresh: true,
    );
  }

  Future<void> onAffiliateProductClick(AffiliateProductModel product) async {
    await _affiliateController.onAffiliateProductClick(product);
  }

  Future<void> refreshAffiliateProducts() async {
    if (article.value?.category != null) {
      final category = article.value!.category!;
      print('🔄 Refreshing affiliate products for category: ${category.slug}');

      await _affiliateController.refreshProducts(
        categorySlug: category.slug,
      );
    }
  }

  Future<void> loadMoreAffiliateProducts() async {
    if (article.value?.category != null) {
      final category = article.value!.category!;
      print('📄 Loading more affiliate products for category: ${category.slug}');

      await _affiliateController.loadMoreProducts(
        categorySlug: category.slug,
      );
    }
  }

  RxList<AffiliateProductModel> get affiliateProducts => _affiliateController.affiliateProducts;
  RxBool get isLoadingAffiliateProducts => _affiliateController.isLoadingProducts;
  RxString get affiliateError => _affiliateController.error;

  void selectTag(int index) {
    selectedTagIndex.value = index;
  }

  void navigateToTaggedArticles(TagModel tag) {
    try {
      final NewsController newsController = Get.find<NewsController>();

      final tagMap = {
        'id': tag.id,
        'name': tag.name,
        'description': tag.description,
      };

      newsController.filterByTag(tagMap);
      Get.back();
    } catch (e) {
      print('Error navigating to tagged articles: $e');
    }
  }

  Future<void> launchOriginalUrl() async {
    final url = article.value?.originalUrl;
    if (url == null || url.isEmpty) {
      return;
    }

    try {
      await _launchUrl(url);
    } catch (e) {
      print('Error launching URL: $e');
      Get.snackbar(
        'Error',
        'Could not open link',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// ✅ iPad share fix
  Future<void> shareArticle({Rect? sharePositionOrigin}) async {
    final currentArticle = article.value;
    if (currentArticle == null) return;

    try {
      final url = currentArticle.originalUrl ?? '';
      final title = currentArticle.aiTitle ?? 'Check out this article';
      final summary = currentArticle.aiSummary ?? '';

      String shareText = '$title\n\n';

      if (summary.isNotEmpty) {
        String shortSummary = summary.length > 150
            ? '${summary.substring(0, 150)}...'
            : summary;
        shareText += '$shortSummary\n\n';
      }

      if (url.isNotEmpty) {
        shareText += 'Read more: $url\n\n';
      }

      shareText += 'Shared via HRlynx App';

      await Share.share(
        shareText,
        subject: title,
        sharePositionOrigin: sharePositionOrigin, // ✅ iPad fix
      );

    } catch (e) {
      print('Error sharing article: $e');
      Get.snackbar(
        'Error',
        'Could not share article',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) {
      throw Exception('URL is empty');
    }

    try {
      String cleanUrl = url.trim();

      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final Uri uri = Uri.parse(cleanUrl);

      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

      if (!launched) {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      throw Exception('Failed to open link: ${e.toString()}');
    }
  }

  /// ✅ NEW: Retry method
  Future<void> retryLoadArticle() async {
    if (_currentArticleId != null) {
      clearCache();
      await fetchArticleDetails(_currentArticleId!);
    }
  }

  void clearCache() {
    _cachedArticle = null;
    article.value = null;
    error.value = '';
    errorType.value = '';
    _affiliateController.clearData();
  }

  @override
  void onClose() {
    clearCache();
    super.onClose();
  }
}

