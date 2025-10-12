import 'package:HRlynx/app/model/news/affiliate_model.dart';
import 'package:HRlynx/app/model/news/news_details_model.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:HRlynx/app/utils/app_images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class NewsDetailsWidgets {

  // Tag widget
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

  // Selected tag info widget
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

  // Article image widget
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

  // Formatted summary widget
  static Widget buildFormattedSummary(String summary) {
    List<String> parts = summary.split('**');
    List<Widget> sections = [];

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1 && parts[i].isNotEmpty) {
        String title = parts[i];

        if (i + 1 < parts.length && parts[i + 1].isNotEmpty) {
          sections.add(
            Container(
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
                    title.trim(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primarycolor,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    parts[i + 1].trim(),
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: AppColors.primarycolor,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
          i++; // Skip next part as it's already used
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  // Loading widget
  static Widget buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.primarycolor,
      ),
    );
  }

  // Error widget
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

  // Disclaimer dialog
  static void showDisclaimerDialog() {
    Get.defaultDialog(
      titlePadding: EdgeInsets.only(top: 30),
      contentPadding: EdgeInsets.all(20),
      middleText: "All news content displayed is sourced from third-party providers and publicly available RSS feeds. Article summaries and AI-generated insights are provided for informational purposes only. Full credit and copyright remain with the original publisher. HRlynx is not responsible for the accuracy, timeliness, or completeness of third-party content. For full articles, please refer directly to the source.",
      title: "Disclaimer",
    );
  }

  // Helper method
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
      return SizedBox.shrink(); // Don't show anything if no products
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
            // Product Image
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

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title
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
                  // Affiliate Disclaimer
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

                  // Amazon Associate Disclaimer
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

            // Arrow Icon
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
