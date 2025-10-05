import 'package:HRlynx/app/api_servies/repository/auth_repo.dart';
import 'package:HRlynx/app/model/news/affiliate_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:url_launcher/url_launcher.dart';
class AffiliateProductsController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  // Observables for affiliate products
  final RxList<AffiliateProductModel> affiliateProducts = <AffiliateProductModel>[].obs;
  final RxBool isLoadingProducts = false.obs;
  final RxString error = ''.obs;
  final RxBool hasMoreData = true.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  PaginationModel? pagination;

  @override
  void onInit() {
    super.onInit();
    // Initialize if needed
  }

// In affiliate_controller.dart - Replace the existing fetchAffiliateProducts method

  Future<void> fetchAffiliateProducts({
    required String categorySlug,
    bool isRefresh = false,
  }) async {
    try {
      if (isRefresh) {
        currentPage.value = 1;
        affiliateProducts.clear();
        hasMoreData.value = true;
      }

      if (isLoadingProducts.value || !hasMoreData.value) return;

      isLoadingProducts.value = true;
      error.value = '';

      // print('📦 Fetching affiliate products for category: $categorySlug (ID: $categoryId) - Page: ${currentPage.value}');

      final response = await _authRepository.getAffiliateProducts(
        categorySlug: categorySlug,
        page: currentPage.value, // Add page parameter
      );

      if (response['success'] == true && response['data'] != null) {
        final affiliateResponse = AffiliateProductsResponse.fromJson(response['data']);

        // Update pagination info
        pagination = affiliateResponse.pagination;
        hasMoreData.value = affiliateResponse.pagination.hasNext;

        if (isRefresh) {
          affiliateProducts.value = affiliateResponse.results;
        } else {
          affiliateProducts.addAll(affiliateResponse.results);
        }

        currentPage.value++;

        // Show success message if products loaded
        if (affiliateResponse.results.isNotEmpty) {
          print('✅ Loaded ${affiliateResponse.results.length} affiliate products');
        } else if (isRefresh) {
          print('ℹ️ No affiliate products found for this category');
        }

      } else {
        error.value = response['error'] ?? 'Failed to load affiliate products';
        print('❌ Error loading affiliate products: ${error.value}');
      }
    } catch (e) {
      error.value = 'Error loading affiliate products: $e';
      print('❌ Exception in fetchAffiliateProducts: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

// Update the onAffiliateProductClick method to ensure proper tracking
  Future<void> onAffiliateProductClick(AffiliateProductModel product) async {
    try {
      print('🔗 @@@@@@@@@@@@@@@@@@@@@@@@@User clicked on product: ${product.title} (ID: ${product.id})');

      // Track the click first
      final response = await _authRepository.trackClick(product.id);

      if (response['success'] == true) {
        // Update local click count for immediate UI feedback
        _updateLocalClickCount(product.id);

        // Get redirect URL from response or use product's affiliate URL
        String redirectUrl = response['data']?['redirect_url'] ?? product.affiliateUrl;

        if (redirectUrl.isNotEmpty) {
          await _launchUrl(redirectUrl);
          print('✅ Successfully tracked click and opened product URL');
        } else {
          print('⚠️ No redirect URL found');
        }

      } else {
        // If tracking fails, still try to open the URL
        print('⚠️ Click tracking failed, opening direct URL');
        if (product.affiliateUrl.isNotEmpty) {
          await _launchUrl(product.affiliateUrl);
        }
      }

    } catch (e) {
      print('❌ Error handling affiliate click: $e');

      // Final fallback: try direct URL
      try {
        if (product.affiliateUrl.isNotEmpty) {
          await _launchUrl(product.affiliateUrl);
        }
      } catch (fallbackError) {
        print('❌ Fallback URL launch failed: $fallbackError');
      }
    }
  }


  // Update local click count for UI feedback
  void _updateLocalClickCount(int productId) {
    final index = affiliateProducts.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final product = affiliateProducts[index];
      final updatedProduct = AffiliateProductModel(
        id: product.id,
        category: product.category,
        title: product.title,
        image: product.image,
        affiliateUrl: product.affiliateUrl,
        disclaimer: product.disclaimer,
        isActive: product.isActive,
        totalClicks: product.totalClicks + 1,
        clickCount: product.clickCount + 1,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );
      affiliateProducts[index] = updatedProduct;
    }
  }

  // Launch URL with multiple fallback options
  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) {
      throw Exception('URL is empty');
    }

    try {
      String cleanUrl = url.trim();

      // Ensure URL has protocol
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final Uri uri = Uri.parse(cleanUrl);
      print('Launching URL: $cleanUrl');

      // Try external application first (opens in default browser/app)
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      // If external app fails, try platform default
      if (!launched) {
        print('External launch failed, trying platform default');
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

      // Last resort: in-app web view
      if (!launched) {
        print('Platform default failed, trying in-app web view');
        launched = await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
      }

      if (!launched) {
        throw Exception('Could not launch URL: $cleanUrl');
      }

      print('✅ Successfully launched URL: $cleanUrl');

    } catch (e) {
      print('❌ Error launching URL: $e');
      throw Exception('Failed to open link: ${e.toString()}');
    }
  }

  // Refresh products
  Future<void> refreshProducts({
    required String categorySlug,

  }) async {
    await fetchAffiliateProducts(
      categorySlug: categorySlug,
      isRefresh: true,
    );
  }

  // Load more products (for pagination)
  Future<void> loadMoreProducts({
    required String categorySlug,
  }) async {
    if (hasMoreData.value && !isLoadingProducts.value) {
      await fetchAffiliateProducts(
        categorySlug: categorySlug,

        isRefresh: false,
      );
    }
  }

  // Get product by ID
  AffiliateProductModel? getProductById(int productId) {
    try {
      return affiliateProducts.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Clear all data
  void clearData() {
    affiliateProducts.clear();
    error.value = '';
    currentPage.value = 1;
    hasMoreData.value = true;
    pagination = null;
  }

  // Utility methods for user feedback
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

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
      duration: const Duration(seconds: 4),
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
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.warning, color: Colors.orange),
    );
  }

  void _showInfoSnackbar(String message) {
    Get.snackbar(
      'Info',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue[100],
      colorText: Colors.blue[800],
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.info, color: Colors.blue),
    );
  }

  // Dispose resources
  @override
  void onClose() {
    clearData();
    super.onClose();
  }
}