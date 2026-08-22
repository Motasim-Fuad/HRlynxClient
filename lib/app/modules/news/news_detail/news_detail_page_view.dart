import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'news_details_controller.dart';
import 'news_details_widgets.dart';

class NewsDetailsView extends StatelessWidget {
  final int articleId;

  const NewsDetailsView({
    super.key,
    required this.articleId,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(NewsDetailsViewModel());
    viewModel.initializeArticle(articleId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'News Details',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 24,
            color: Color(0xFF1B1E28),
          ),
        ),
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.share),
                onPressed: () async {
                  final RenderBox? box = context.findRenderObject() as RenderBox?;

                  if (box != null) {
                    await viewModel.shareArticle(
                      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
                    );
                  } else {
                    await viewModel.shareArticle();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (viewModel.isLoading.value) {
          return NewsDetailsWidgets.buildLoadingWidget();
        }

        if (viewModel.error.value.isNotEmpty) {
          return _buildErrorWidget(
            errorType: viewModel.errorType.value,
            onRetry: () => viewModel.retryLoadArticle(),
            onBack: () => Get.back(),
          );
        }

        final article = viewModel.article.value;
        if (article == null) {
          return _buildErrorWidget(
            errorType: 'UNKNOWN_ERROR',
            onRetry: () => viewModel.retryLoadArticle(),
            onBack: () => Get.back(),
          );
        }

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

              if (article.tags.isNotEmpty) ...[
                Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: article.tags.take(2).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final tag = entry.value;
                    final isSelected = viewModel.selectedTagIndex.value == index;

                    return NewsDetailsWidgets.buildTagChip(
                      tag: tag,
                      isSelected: isSelected,
                      onTap: () {
                        viewModel.selectTag(index);
                        viewModel.navigateToTaggedArticles(tag);
                      },
                      index: index,
                    );
                  }).toList(),
                )),
                SizedBox(height: 20),

                Obx(() {
                  final selectedIndex = viewModel.selectedTagIndex.value;
                  if (selectedIndex >= 0 && selectedIndex < article.tags.length) {
                    return Column(
                      children: [
                        NewsDetailsWidgets.buildSelectedTagInfo(article.tags[selectedIndex]),
                        SizedBox(height: 20),
                      ],
                    );
                  }
                  return SizedBox.shrink();
                }),
              ],

              NewsDetailsWidgets.buildArticleImage(article.mainImageUrl ?? ''),
              SizedBox(height: 20),

              Text(
                article.aiTitle ?? 'No title available',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xFF1B1E28),
                ),
              ),
              SizedBox(height: 16),

              NewsDetailsWidgets.buildFormattedSummary(
                  article.aiSummary ?? 'No summary available'
              ),
              SizedBox(height: 30),

              Obx(() => NewsDetailsWidgets.buildAffiliateProducts(
                products: viewModel.affiliateProducts.value,
                isLoading: viewModel.isLoadingAffiliateProducts.value,
                error: viewModel.affiliateError.value,
                onProductClick: (product) => viewModel.onAffiliateProductClick(product),
              )),

              SizedBox(height: 20),

              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarycolor,
                    minimumSize: Size(239, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => viewModel.launchOriginalUrl(),
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

              Center(
                child: GestureDetector(
                  onTap: () => NewsDetailsWidgets.showDisclaimerDialog(),
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
      }),
    );
  }

  Widget _buildErrorWidget({
    required String errorType,
    required VoidCallback onRetry,
    required VoidCallback onBack,
  }) {
    IconData icon;
    String title;
    String message;
    Color iconColor;

    switch (errorType) {
      case 'NETWORK_ERROR':
        icon = Icons.wifi_off;
        title = 'No Internet Connection';
        message = 'Please check your internet connection and try again';
        iconColor = Colors.orange;
        break;
      case 'SERVER_ERROR':
        icon = Icons.cloud_off;
        title = 'Server Error';
        message = 'Sorry, please try later. We are working on the server';
        iconColor = Colors.red;
        break;
      case 'SESSION_EXPIRED':
        icon = Icons.lock_clock;
        title = 'Session Expired';
        message = 'Redirecting to login...';
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.error_outline;
        title = 'Failed to Load Article';
        message = 'Something went wrong. Please try again';
        iconColor = Colors.red;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: iconColor),
            SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),

            if (errorType != 'SESSION_EXPIRED')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: Icon(Icons.arrow_back),
                    label: Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primarycolor,
                      side: BorderSide(color: AppColors.primarycolor),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarycolor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back),
                label: Text('Go Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primarycolor,
                  side: BorderSide(color: AppColors.primarycolor),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
