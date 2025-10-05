import 'package:HRlynx/app/api_servies/repository/auth_repo.dart';
import 'package:HRlynx/app/api_servies/repository/news_repo.dart';
import 'package:HRlynx/app/model/news/affiliate_model.dart';
import 'package:HRlynx/app/model/news/news_details_model.dart';
import 'package:HRlynx/app/modules/news/news_controller.dart';
import 'package:HRlynx/app/modules/news/news_detail/affilate_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailsViewModel extends GetxController {
  final NewsRepository _newsRepository = NewsRepository();
  final AuthRepository _authRepository = AuthRepository(); // Add auth repository

  // Get affiliate controller instance
  late AffiliateProductsController _affiliateController;

  // Observables for news
  final Rx<NewsDetailsModel?> article = Rx<NewsDetailsModel?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxInt selectedTagIndex = RxInt(-1);

  // Cache for article data
  NewsDetailsModel? _cachedArticle;

  @override
  void onInit() {
    super.onInit();
    // Initialize affiliate controller
    _affiliateController = Get.put(AffiliateProductsController());
  }

  // Initialize with article ID
  void initializeArticle(int articleId) {
    fetchArticleDetails(articleId);
  }

  // Update the fetchArticleDetails method to add better debugging
  Future<void> fetchArticleDetails(int articleId) async {
    try {
      if (_cachedArticle != null) {
        article.value = _cachedArticle;
        isLoading.value = false;

        // Load affiliate products if category exists
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

      print('🔍 Fetching article details for ID: $articleId');

      final response = await _newsRepository.getArticleDetails(articleId);

      if (response['success'] == true && response['data'] != null) {
        _cachedArticle = NewsDetailsModel.fromJson(response['data']);
        article.value = _cachedArticle;

        print('✅ Article loaded: ${_cachedArticle!.aiTitle}');

        // Load affiliate products if category exists
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
      error.value = 'Failed to load article details: $e';
      print('❌ Error fetching article details: $e');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> loadAffiliateProducts(CategoryModel category) async {
    print('🔍 Loading affiliate products for category: ${category.name} (Slug: ${category.slug},');

    await _affiliateController.fetchAffiliateProducts(
      categorySlug: category.slug,

      isRefresh: true,
    );
  }

  // Handle affiliate product click - Delegate to affiliate controller
  Future<void> onAffiliateProductClick(AffiliateProductModel product) async {
    await _affiliateController.onAffiliateProductClick(product);
  }
// Also update the refresh and load more methods
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


  // Get affiliate products from controller
  RxList<AffiliateProductModel> get affiliateProducts => _affiliateController.affiliateProducts;
  RxBool get isLoadingAffiliateProducts => _affiliateController.isLoadingProducts;
  RxString get affiliateError => _affiliateController.error;

  // Select tag
  void selectTag(int index) {
    selectedTagIndex.value = index;
  }

  // Navigate to tagged articles
  void navigateToTaggedArticles(TagModel tag) {
    try {
      final NewsController newsController = Get.find<NewsController>();

      // Create tag map for navigation
      final tagMap = {
        'id': tag.id,
        'name': tag.name,
        'description': tag.description,
      };

      newsController.filterByTag(tagMap);
      Get.back();
    } catch (e) {
      print('Error navigating to tagged articles: $e');
      _showErrorSnackbar('Failed to navigate to tagged articles');
    }
  }

  // Launch original article URL
  Future<void> launchOriginalUrl() async {
    final url = article.value?.originalUrl;
    if (url == null || url.isEmpty) {
      _showErrorSnackbar('No URL available for this article');
      return;
    }

    try {
      await _launchUrl(url);
      _showSuccessSnackbar('Opening article in browser...');
    } catch (e) {
      print('Error launching URL: $e');
      _showErrorSnackbar('Could not open the link. Please check your internet connection and try again.');
    }
  }

  // Share article
  Future<void> shareArticle() async {
    final currentArticle = article.value;
    if (currentArticle == null) {
      _showWarningSnackbar('No article to share');
      return;
    }

    try {
      final url = currentArticle.originalUrl ?? '';
      final title = currentArticle.aiTitle ?? '';
      final summary = currentArticle.aiSummary ?? '';

      if (url.isNotEmpty && title.isNotEmpty) {
        String shareText = '$title\n\n';

        if (summary.isNotEmpty) {
          String shortSummary = summary.length > 100
              ? '${summary.substring(0, 100)}...'
              : summary;
          shareText += '$shortSummary\n\n';
        }

        shareText += 'Read full article: $url\n\n';
        shareText += 'Shared via HRlynx App';

        await _shareViaIntent(shareText, title);
        _showSuccessSnackbar('Article shared successfully!');
      } else {
        _showWarningSnackbar('No content available to share');
      }
    } catch (e) {
      print('Error sharing article: $e');
      // Fallback to clipboard
      await _copyToClipboard(currentArticle.originalUrl ?? '');
    }
  }

  // Launch URL helper
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

  // Share via intent
  Future<void> _shareViaIntent(String text, String subject) async {
    try {
      const platform = MethodChannel('com.example.share');
      await platform.invokeMethod('share', {
        'title': 'Share Article',
        'text': text,
        'subject': subject,
      });
    } catch (e) {
      print('Native share failed: $e');
      try {
        const platform = MethodChannel('android_intent');
        await platform.invokeMethod('share', {
          'text': text,
          'subject': subject,
        });
      } catch (e2) {
        print('Intent sharing failed: $e2');
        await _copyToClipboard(text);
      }
    }
  }

  // Copy to clipboard
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _showSuccessSnackbar('Copied to clipboard! You can now paste it in any app.');
    } catch (e) {
      _showErrorSnackbar('Could not copy to clipboard');
    }
  }

  // Utility methods for snackbars
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
      icon: const Icon(Icons.error, color: Colors.red),
    );
  }

  void _showWarningSnackbar(String message) {
    Get.snackbar(
      'Warning',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange[100],
      colorText: Colors.orange[800],
      icon: const Icon(Icons.warning, color: Colors.orange),
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[800],
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  // Clear cached data
  void clearCache() {
    _cachedArticle = null;
    article.value = null;
    error.value = '';
    _affiliateController.clearData();
  }

  @override
  void onClose() {
    clearCache();
    super.onClose();
  }
}