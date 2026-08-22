import 'package:HRlynx/app/model/news/affiliate_model.dart';
import 'package:HRlynx/app/model/news/news_details_model.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:HRlynx/app/utils/app_images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class NewsDetailsWidgets {

  static Widget buildTagChip({
    required TagModel tag,
    required bool isSelected,
    required VoidCallback onTap,
    required int index,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.primarycolor : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primarycolor : Color(0xFFE6ECEB),
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
              (tag.name.toUpperCase()),
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
  }

  static Widget buildSelectedTagInfo(TagModel tag) {
    return Container(
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
            'Name: ${(tag.name)}',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF1B1E28),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'ID: ${tag.id}',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7D848D),
            ),
          ),
          if (tag.description != null) ...[
            SizedBox(height: 4),
            Text(
              'Description: ${tag.description ?? 'No description available'}',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7D848D),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildArticleImage(String imageUrl) {
    final hasImage = imageUrl.isNotEmpty &&
        imageUrl.startsWith('http') &&
        !imageUrl.contains('data:image/svg+xml');

    if (!hasImage) return SizedBox.shrink();

    return ClipRRect(
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
              child: Image(
                image: AssetImage(AppImages.default_news_img),
                height: 198,
                width: double.infinity,
              ),
            ),
          );
        },
      ),
    );
  }

  // Renders only these three summary sections.
  static Widget buildFormattedSummary(String summary) {
    final allowedTitles = [
      'Don\'t Miss This',
      'QuickScan Summary',
      'Implications for HR'
    ];

    Map<String, String> extractedSections = {};

    for (String allowedTitle in allowedTitles) {
      String? content = _extractSectionContent(summary, allowedTitle);
      if (content != null && content.isNotEmpty) {
        extractedSections[allowedTitle] = content;
      }
    }

    List<Widget> sections = [];
    for (String title in allowedTitles) {
      if (extractedSections.containsKey(title)) {
        sections.add(_buildSection(title, extractedSections[title]!));
      }
    }

    if (sections.isEmpty) {
      String cleanedSummary = summary.trim();
      cleanedSummary = cleanedSummary.replaceFirst(RegExp(r'^\*\*SUMMARY:\*\*\s*', caseSensitive: false), '');
      cleanedSummary = cleanedSummary.replaceFirst(RegExp(r'^SUMMARY:\s*', caseSensitive: false), '');
      sections.add(_buildSection('Summary', _cleanBulletPoints(cleanedSummary)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  static String? _extractSectionContent(String text, String targetTitle) {
    String pattern1 = '\\*\\*${RegExp.escape(targetTitle)}:?\\*\\*';
    RegExp regex1 = RegExp(pattern1, caseSensitive: false);

    String pattern2 = '^${RegExp.escape(targetTitle)}:';
    RegExp regex2 = RegExp(pattern2, caseSensitive: false, multiLine: true);

    Match? match = regex1.firstMatch(text) ?? regex2.firstMatch(text);

    if (match != null) {
      int startIndex = match.end;
      String remaining = text.substring(startIndex).trim();

      String contentEnd = _findContentEnd(remaining);
      return contentEnd;
    }

    String? contentInsideSummary = _searchInsideSummary(text, targetTitle);
    if (contentInsideSummary != null) {
      return contentInsideSummary;
    }

    return null;
  }

  static String? _searchInsideSummary(String text, String targetTitle) {
    RegExp summaryRegex = RegExp(r'\*\*SUMMARY:\*\*', caseSensitive: false);
    Match? summaryMatch = summaryRegex.firstMatch(text);

    if (summaryMatch != null) {
      int summaryStart = summaryMatch.end;
      String summaryContent = text.substring(summaryStart);

      RegExp nextTitleRegex = RegExp(r'\*\*[^*]+\*\*');
      Match? nextTitle = nextTitleRegex.firstMatch(summaryContent);

      if (nextTitle != null) {
        summaryContent = summaryContent.substring(0, nextTitle.start);
      }

      String nestedPattern = '\\*\\*${RegExp.escape(targetTitle)}:?\\*\\*';
      RegExp nestedRegex = RegExp(nestedPattern, caseSensitive: false);
      Match? nestedMatch = nestedRegex.firstMatch(summaryContent);

      if (nestedMatch != null) {
        String content = summaryContent.substring(nestedMatch.end).trim();
        return _findContentEnd(content);
      }

      String plainPattern = '${RegExp.escape(targetTitle)}:';
      RegExp plainRegex = RegExp(plainPattern, caseSensitive: false);
      Match? plainMatch = plainRegex.firstMatch(summaryContent);

      if (plainMatch != null) {
        String content = summaryContent.substring(plainMatch.end).trim();
        return _findContentEnd(content);
      }

      if (targetTitle.toLowerCase() == 'don\'t miss this') {
        String cleanContent = summaryContent.trim();
        cleanContent = cleanContent.replaceFirst(RegExp(r'^\s+'), '');
        int newlineIndex = cleanContent.indexOf('\n');
        if (newlineIndex != -1) {
          cleanContent = cleanContent.substring(0, newlineIndex).trim();
        }
        return cleanContent.isNotEmpty ? cleanContent : null;
      }
    }

    return null;
  }

  static String _findContentEnd(String content) {
    List<String> lines = content.split('\n');
    StringBuffer result = StringBuffer();

    RegExp titlePattern = RegExp(r'^\*\*[^*]+\*\*|^[A-Z][^:]+:$');

    for (String line in lines) {
      String trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (titlePattern.hasMatch(trimmed)) {
        bool isAllowedTitle = [
          'Don\'t Miss This',
          'QuickScan Summary',
          'Implications for HR'
        ].any((allowed) =>
        trimmed.toLowerCase().replaceAll('**', '').replaceAll(':', '').trim()
            == allowed.toLowerCase()
        );

        if (isAllowedTitle) {
          break;
        }
      }

      if (result.isNotEmpty) result.write('\n');
      result.write(trimmed);
    }

    return result.toString().trim();
  }

  static Widget _buildSection(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFE6ECEB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primarycolor,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _cleanBulletPoints(content),
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: AppColors.primarycolor,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static String _cleanBulletPoints(String text) {
    String cleaned = text.trim();

    List<String> lines = cleaned.split('\n');

    List<String> processedLines = [];
    for (String line in lines) {
      String trimmedLine = line.trim();

      if (trimmedLine.isEmpty) continue;

      if (trimmedLine.startsWith('•') ||
          trimmedLine.startsWith('-') ||
          trimmedLine.startsWith('*')) {
        String withoutBullet = trimmedLine.substring(1).trim();
        processedLines.add('• $withoutBullet');
      } else {
        processedLines.add(trimmedLine);
      }
    }

    return processedLines.join('\n');
  }
  static Widget buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.primarycolor,
      ),
    );
  }

  static Widget buildErrorWidget(VoidCallback onRetry) {
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
            onPressed: onRetry,
            child: Text('Go Back'),
          ),
        ],
      ),
    );
  }

  static void showDisclaimerDialog() {
    Get.defaultDialog(
      titlePadding: EdgeInsets.only(top: 30),
      contentPadding: EdgeInsets.all(20),
      middleText: "All news content displayed is sourced from third-party providers and publicly available RSS feeds. Article summaries and AI-generated insights are provided for informational purposes only. Full credit and copyright remain with the original publisher. HRlynx is not responsible for the accuracy, timeliness, or completeness of third-party content. For full articles, please refer directly to the source.",
      title: "Disclaimer",
    );
  }

  static String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }


  static Widget buildAffiliateProducts({
    required List<AffiliateProductModel> products,
    required bool isLoading,
    required String error,
    required Function(AffiliateProductModel) onProductClick,
  }) {
    if (isLoading) {
      return Container(
        height: 120,
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primarycolor,
          ),
        ),
      );
    }

    if (error.isNotEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 32),
              SizedBox(height: 8),
              Text(
                'Failed to load products',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      children: products.take(3).map((product) => _buildSingleAdCard(product, onProductClick)).toList(),
    );
  }

  static Widget _buildSingleAdCard(
      AffiliateProductModel product,
      Function(AffiliateProductModel) onProductClick,
      ) {
    return GestureDetector(
      onTap: () => onProductClick(product),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 80,
                      height: 80,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.primarycolor,
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 24,
                              color: Colors.grey[500]),
                          SizedBox(height: 4),
                          Text(
                            'No Image',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1B1E28),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Ad',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Amazon Affiliate',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),

                  Text(
                   product.disclaimer,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
