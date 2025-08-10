import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/repository/news_repo.dart' show NewsRepository;


class NewsController extends GetxController {
  final NewsRepository _newsRepository = NewsRepository();

  // Observable variables
  var isLoading = false.obs;
  var articles = <dynamic>[].obs;
  var categories = <dynamic>[].obs;
  var allTags = <dynamic>[].obs; // For all available tags
  var selectedCategory = Rxn<Map<String, dynamic>>();
  var selectedTag = Rxn<Map<String, dynamic>>(); // For currently selected tag
  var searchController = TextEditingController();
  var searchText = ''.obs;
  var currentPage = 1.obs;
  var hasNextPage = true.obs;
  var isLoadingMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchText.value = searchController.text;
    });
    loadInitialData();
    loadAllTags();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        loadCategories(),
        loadArticles(),
      ]);
    } catch (e) {
      print('Error loading initial data: $e');
      Get.snackbar(
        'Error',
        'Failed to load news data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAllTags() async {
    try {
      final response = await _newsRepository.getTags();
      if (response['success'] == true && response['data'] != null) {
        allTags.value = response['data'];
      }
    } catch (e) {
      print('Error loading tags: $e');
    }
  }

  Future<void> loadCategories() async {
    try {
      final response = await _newsRepository.getCategories();
      if (response['success'] == true && response['data'] != null) {
        categories.value = response['data'];
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> loadArticles({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      articles.clear();
    }

    try {
      dynamic response;

      if (selectedCategory.value != null) {
        response = await _newsRepository.getArticlesByCategory(
          categoryId: selectedCategory.value!['id'],
          page: currentPage.value,
          pageSize: 10,
        );
      } else if (selectedTag.value != null) {
        response = await _newsRepository.getArticlesByTag(
          tagId: selectedTag.value!['id'],
          page: currentPage.value,
          pageSize: 10,
        );
      } else {
        response = await _newsRepository.getArticles(
          page: currentPage.value,
          pageSize: 10,
        );
      }

      if (response['success'] == true && response['data'] != null) {
        final newArticles = response['data']['results'] ?? [];
        if (refresh) {
          articles.value = newArticles;
        } else {
          articles.addAll(newArticles);
        }
        final pagination = response['data']['pagination'];
        hasNextPage.value = pagination['has_next'] ?? false;
      }
    } catch (e) {
      print('Error loading articles: $e');
      Get.snackbar(
        'Error',
        'Failed to load articles',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> filterByTag(Map<String, dynamic> tag) async {
    isLoading.value = true;
    selectedTag.value = tag;
    selectedCategory.value = null;
    searchController.clear();
    await loadArticles(refresh: true);
    isLoading.value = false;
  }

  Future<void> loadMoreArticles() async {
    if (isLoadingMore.value || !hasNextPage.value) return;
    isLoadingMore.value = true;
    currentPage.value++;
    try {
      await loadArticles();
    } catch (e) {
      currentPage.value--;
      print('Error loading more articles: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> searchArticles(String query) async {
    if (query.trim().isEmpty) {
      selectedCategory.value = null;
      selectedTag.value = null;
      await loadArticles(refresh: true);
      return;
    }

    isLoading.value = true;
    try {
      final response = await _newsRepository.searchArticles(
        query: query.trim(),
        page: 1,
        pageSize: 20,
      );

      if (response['success'] == true && response['data'] != null) {
        articles.value = response['data']['results'] ?? [];
        currentPage.value = 1;
        hasNextPage.value = response['data']['pagination']['has_next'] ?? false;
        selectedCategory.value = null;
        selectedTag.value = null;
      }
    } catch (e) {
      print('Error searching articles: $e');
      Get.snackbar(
        'Error',
        'Failed to search articles',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void filterByCategory(Map<String, dynamic> category) {
    selectedCategory.value = category;
    selectedTag.value = null;
    searchController.clear();
    loadArticles(refresh: true);
  }

  void clearCategoryFilter() {
    selectedCategory.value = null;
    loadArticles(refresh: true);
  }

  void clearTagFilter() {
    selectedTag.value = null;
    loadArticles(refresh: true);
  }

  Future<void> refreshData() async {
    await loadInitialData();
  }

  String formatPublishedDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inMinutes < 60) return '${difference.inMinutes}min ago';
      else if (difference.inHours < 24) return '${difference.inHours}h ago';
      else if (difference.inDays < 7) return '${difference.inDays}d ago';
      else return '${(difference.inDays / 7).floor()}w ago';
    } catch (e) {
      return '';
    }
  }
}