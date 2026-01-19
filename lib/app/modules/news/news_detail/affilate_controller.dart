import 'package:HRlynx/app/api_servies/repository/auth_repo.dart';
import 'package:HRlynx/app/model/news/affiliate_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AffiliateProductsController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  final RxList<AffiliateProductModel> affiliateProducts = <AffiliateProductModel>[].obs;
  final RxBool isLoadingProducts = false.obs;
  final RxString error = ''.obs;
  final RxBool hasMoreData = true.obs;

  // ✅ NEW: Error type
  final RxString errorType = ''.obs;

  final RxInt currentPage = 1.obs;
  PaginationModel? pagination;

  @override
  void onInit() {
    super.onInit();
  }

  /// ✅ UPDATED: Better error handling
  Future<void> fetchAffiliateProducts({
    required String categorySlug,
    bool isRefresh = false,
  }) async {
    try {
      if (isRefresh) {
        currentPage.value = 1;
        affiliateProducts.clear();
        hasMoreData.value = true;
        error.value = '';
        errorType.value = '';
      }

      if (isLoadingProducts.value || !hasMoreData.value) return;

      isLoadingProducts.value = true;
      error.value = '';
      errorType.value = '';

      final response = await _authRepository.getAffiliateProducts(
        categorySlug: categorySlug,
        page: currentPage.value,
      );

      if (response['success'] == true && response['data'] != null) {
        final affiliateResponse = AffiliateProductsResponse.fromJson(response['data']);

        pagination = affiliateResponse.pagination;
        hasMoreData.value = affiliateResponse.pagination.hasNext;

        if (isRefresh) {
          affiliateProducts.value = affiliateResponse.results;
        } else {
          affiliateProducts.addAll(affiliateResponse.results);
        }

        currentPage.value++;

        if (affiliateResponse.results.isNotEmpty) {
          print('✅ Loaded ${affiliateResponse.results.length} affiliate products');
        } else if (isRefresh) {
          print('ℹ️ No affiliate products found for this category');
        }

      } else {
        error.value = response['error'] ?? 'Failed to load affiliate products';
        errorType.value = 'UNKNOWN_ERROR';
        print('❌ Error loading affiliate products: ${error.value}');
      }
    } catch (e) {
      String errorMsg = e.toString();
      print('❌ Exception in fetchAffiliateProducts: $errorMsg');

      // ✅ Categorize errors (but don't show to user - affiliate products are not critical)
      if (errorMsg.contains('NETWORK_ERROR')) {
        error.value = 'Network error loading products';
        errorType.value = 'NETWORK_ERROR';
      } else if (errorMsg.contains('SERVER_ERROR')) {
        error.value = 'Server error loading products';
        errorType.value = 'SERVER_ERROR';
      } else {
        error.value = 'Error loading affiliate products';
        errorType.value = 'UNKNOWN_ERROR';
      }
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> onAffiliateProductClick(AffiliateProductModel product) async {
    try {
      print('🔗 User clicked on product: ${product.title} (ID: ${product.id})');

      final response = await _authRepository.trackClick(product.id);

      if (response['success'] == true) {
        _updateLocalClickCount(product.id);

        String redirectUrl = response['data']?['redirect_url'] ?? product.affiliateUrl;

        if (redirectUrl.isNotEmpty) {
          await _launchUrl(redirectUrl);
          print('✅ Successfully tracked click and opened product URL');
        } else {
          print('⚠️ No redirect URL found');
        }

      } else {
        print('⚠️ Click tracking failed, opening direct URL');
        if (product.affiliateUrl.isNotEmpty) {
          await _launchUrl(product.affiliateUrl);
        }
      }

    } catch (e) {
      print('❌ Error handling affiliate click: $e');

      try {
        if (product.affiliateUrl.isNotEmpty) {
          await _launchUrl(product.affiliateUrl);
        }
      } catch (fallbackError) {
        print('❌ Fallback URL launch failed: $fallbackError');
      }
    }
  }

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
      print('Launching URL: $cleanUrl');

      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        print('External launch failed, trying platform default');
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

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

  Future<void> refreshProducts({
    required String categorySlug,
  }) async {
    await fetchAffiliateProducts(
      categorySlug: categorySlug,
      isRefresh: true,
    );
  }

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

  AffiliateProductModel? getProductById(int productId) {
    try {
      return affiliateProducts.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  void clearData() {
    affiliateProducts.clear();
    error.value = '';
    errorType.value = '';
    currentPage.value = 1;
    hasMoreData.value = true;
    pagination = null;
  }

  @override
  void onClose() {
    clearData();
    super.onClose();
  }
}
