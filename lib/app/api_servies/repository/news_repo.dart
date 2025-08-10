import '../api_Constant.dart';
import '../neteork_api_services.dart';

class NewsRepository {
  final _api = NetworkApiServices();

  // Get all articles with pagination
  Future<dynamic> getArticles({int page = 1, int pageSize = 10}) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/news/articles/?page=$page&page_size=$pageSize";
      return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
    } catch (e) {
      print('Error fetching articles: $e');
      rethrow;
    }
  }

  // Get articles by category
  Future<dynamic> getArticlesByCategory({
    required int categoryId,
    int page = 1,
    int pageSize = 10
  }) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/news/categories/$categoryId/articles/?page=$page&page_size=$pageSize";
      return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
    } catch (e) {
      print('Error fetching articles by category: $e');
      rethrow;
    }
  }

  // Get articles by tag - Fixed version
  Future<dynamic> getArticlesByTag({
    required int tagId,
    int page = 1,
    int pageSize = 10
  }) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/news/tags/$tagId/articles/?page=$page&page_size=$pageSize";
      print('Fetching articles for tag ID: $tagId');
      print('URL: $url');

      final response = await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
      print('Tag articles response: $response');
      return response;
    } catch (e) {
      print('Error fetching articles by tag: $e');
      rethrow;
    }
  }

  // Alternative method using tag slug instead of ID
  Future<dynamic> getArticlesByTagSlug({
    required String tagSlug,
    int page = 1,
    int pageSize = 10
  }) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/news/tags/$tagSlug/articles/?page=$page&page_size=$pageSize";
      return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
    } catch (e) {
      print('Error fetching articles by tag slug: $e');
      rethrow;
    }
  }

  // Search articles
  Future<dynamic> searchArticles({
    required String query,
    int page = 1,
    int pageSize = 10
  }) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/news/articles/search/?q=$query&page=$page&page_size=$pageSize";
      return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
    } catch (e) {
      print('Error searching articles: $e');
      rethrow;
    }
  }

  // Get single article details
  Future<dynamic> getArticleDetails(int articleId) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/news/articles/$articleId/";
      return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
    } catch (e) {
      print('Error fetching article details: $e');
      rethrow;
    }
  }

  // Get all categories
  Future<dynamic> getCategories() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/news/categories/";
      return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  // Get all tags
  Future<dynamic> getTags() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/news/tags/";
      return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
    } catch (e) {
      print('Error fetching tags: $e');
      rethrow;
    }
  }
}