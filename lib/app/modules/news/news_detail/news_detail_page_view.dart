
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/repository/news_repo.dart';
import 'package:hr/app/modules/news/news_controller.dart';
import 'package:hr/app/utils/app_colors.dart';
import 'package:hr/app/utils/app_images.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
// Using Intent for Android sharing

class NewsDetailsView extends StatefulWidget {
  const NewsDetailsView({
    super.key,
    required this.articleId,
  });

  final int articleId;

  @override
  State<NewsDetailsView> createState() => _NewsDetailsViewState();
}

class _NewsDetailsViewState extends State<NewsDetailsView> {
  int? selectedTagIndex; // Track which tag is selected
  Map<String, dynamic>? articleData; // Cache article data

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<Map<String, dynamic>> _fetchArticleDetails() async {
    if (articleData != null) return articleData!; // Return cached data

    final NewsRepository newsRepo = NewsRepository();
    try {
      final response = await newsRepo.getArticleDetails(widget.articleId);
      if (response['success'] == true && response['data'] != null) {
        articleData = response['data'];
        return articleData!;
      }
      throw Exception('Failed to load article details');
    } catch (e) {
      print('Error fetching article details: $e');
      throw e;
    }
  }

  Future<void> _launchOriginalUrl(String url) async {
    try {
      // Clean and validate the URL
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final Uri uri = Uri.parse(cleanUrl);

      // Use the newer launchUrl method with explicit mode
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Forces opening in external browser
      );

      if (!launched) {
        // Fallback: try with platform default mode
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

      if (!launched) {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      print('Error launching URL: $e');
      Get.snackbar(
        'Error',
        'Could not open the link. Please check your internet connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }

  // Native sharing using platform channels
  Future<void> _shareArticle() async {
    try {
      final article = await _fetchArticleDetails();
      final url = article['original_url']?.toString() ?? '';
      final title = article['ai_title']?.toString() ?? '';
      final summary = article['ai_summary']?.toString() ?? '';

      if (url.isNotEmpty && title.isNotEmpty) {
        // Create a formatted share text
        String shareText = '$title\n\n';

        // Add a brief summary if available (limit to 100 characters)
        if (summary.isNotEmpty) {
          String shortSummary = summary.length > 100
              ? '${summary.substring(0, 100)}...'
              : summary;
          shareText += '$shortSummary\n\n';
        }

        shareText += 'Read full article: $url\n\n';
        shareText += 'Shared via HRlynx App';

        // Try native sharing using platform channels
        const platform = MethodChannel('com.example.share');
        try {
          await platform.invokeMethod('share', {
            'title': 'Share Article',
            'text': shareText,
            'subject': title,
          });
        } catch (e) {
          print('Native share failed: $e');
          // Fallback: Use Android Intent directly
          await _shareViaIntent(shareText, title);
        }
      } else {
        Get.snackbar(
          'Error',
          'No content available to share',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
        );
      }
    } catch (e) {
      print('Error sharing article: $e');
      // Fallback to copy option
      final article = await _fetchArticleDetails();
      final url = article['original_url']?.toString() ?? '';
      await _copyToClipboard(url);
    }
  }

  // Android Intent sharing
  Future<void> _shareViaIntent(String text, String subject) async {
    try {
      const platform = MethodChannel('android_intent');
      await platform.invokeMethod('share', {
        'text': text,
        'subject': subject,
      });
    } catch (e) {
      print('Intent sharing failed: $e');
      // Final fallback - copy to clipboard
      await _copyToClipboard(text);
    }
  }
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      Get.snackbar(
        'Success',
        'Copied to clipboard! You can now paste it in any app.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not copy to clipboard',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }

  void _onTagTapped(int index, Map<String, dynamic> tag) {
    _navigateToTaggedArticles(tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Breaking HR News',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 24,
            color: Color(0xFF1B1E28),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareArticle, // Updated to use the new share function
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchArticleDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primarycolor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load article details',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final article = snapshot.data!;
          final tags = article['tags'] as List<dynamic>? ?? [];
          final imageUrl = article['main_image_url']?.toString() ?? '';
          final hasImage = imageUrl.isNotEmpty &&
              imageUrl.startsWith('http') &&
              !imageUrl.contains('data:image/svg+xml');

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  'Summarized by your AI\nHR Assistant',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 22,
                    color: Color(0xff1B1E28),
                  ),
                ),
                SizedBox(height: 20),

                // Tags
                if (tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.take(2).toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final tag = entry.value;
                      final isSelected = selectedTagIndex == index;

                      return GestureDetector(
                        onTap: () => _onTagTapped(index, tag),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? AppColors.primarycolor
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primarycolor
                                  : Color(0xFFE6ECEB),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppColors.primarycolor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _capitalizeFirstLetter(tag['name']?.toString() ?? ''),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : Color(0xFF050505),
                                ),
                              ),
                              if (isSelected) ...[
                                SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),

                  // Selected tag info
                  if (selectedTagIndex != null && selectedTagIndex! < tags.length) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primarycolor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primarycolor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tag,
                                size: 18,
                                color: AppColors.primarycolor,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Selected Tag Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.primarycolor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Name: ${_capitalizeFirstLetter(tags[selectedTagIndex!]['name']?.toString() ?? '')}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1B1E28),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ID: ${tags[selectedTagIndex!]['id']?.toString() ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7D848D),
                            ),
                          ),
                          if (tags[selectedTagIndex!]['description'] != null) ...[
                            SizedBox(height: 4),
                            Text(
                              'Description: ${tags[selectedTagIndex!]['description']?.toString() ?? 'No description available'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7D848D),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ],

                // Article Image
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primarycolor,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                               Image(image: AssetImage(AppImages.default_news_img),height: 198,width: double.infinity,)

                                // Icon(
                                //   Icons.image_not_supported_outlined,
                                //   size: 40,
                                //   color: Colors.grey[400],
                                // ),
                                // SizedBox(height: 8),
                                // Text(
                                //   'Image not available',
                                //   style: TextStyle(
                                //     color: Colors.grey[500],
                                //     fontSize: 12,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                SizedBox(height: 20),

                // Article Title
                Text(
                  article['ai_title']?.toString() ?? 'No title available',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: Color(0xFF1B1E28),
                  ),
                ),

                SizedBox(height: 16),

                // Article Summary
                Text(
                  article['ai_summary']?.toString() ?? 'No summary available',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF7D848D),
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 30),

                // Original Content Button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarycolor,
                      minimumSize: Size(239, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final url = article['original_url']?.toString();
                      if (url != null && url.isNotEmpty) {
                        _launchOriginalUrl(url);
                      } else {
                        Get.snackbar(
                          'Error',
                          'No URL available for this article',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange[100],
                          colorText: Colors.orange[800],
                        );
                      }
                    },
                    child: Text(
                      'Link to the original content',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Disclaimer
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Get.defaultDialog(
                        title: 'Disclaimer',
                        content: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'All news content displayed is sourced from third-party providers and publicly available RSS feeds. Article summaries and AI-generated insights are provided for informational purposes only. Full credit and copyright remain with the original publisher. HRlynx is not responsible for the accuracy, timeliness, or completeness of third-party content. For full articles, please refer directly to the source.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Disclaimer',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: AppColors.primarycolor,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToTaggedArticles(Map<String, dynamic> tag) {
    // Get the NewsController instance
    final NewsController newsController = Get.find<NewsController>();

    // Set the selected tag and load articles
    newsController.filterByTag(tag);

    // Navigate back to NewsView which will now show filtered articles
    Get.back();
  }
}