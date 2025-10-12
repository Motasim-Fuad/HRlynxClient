// 5. UPDATED VIEW - news_details_view.dart
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
    // Initialize ViewModel
    final viewModel = Get.put(NewsDetailsViewModel());
    viewModel.initializeArticle(articleId);

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
            onPressed: () => viewModel.shareArticle(),
          ),
        ],
      ),
      body: Obx(() {
        if (viewModel.isLoading.value) {
          return NewsDetailsWidgets.buildLoadingWidget();
        }

        if (viewModel.error.value.isNotEmpty) {
          return NewsDetailsWidgets.buildErrorWidget(() => Get.back());
        }

        final article = viewModel.article.value;
        if (article == null) {
          return NewsDetailsWidgets.buildErrorWidget(() => Get.back());
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

              // Tags Section
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

                // Selected tag info
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

              // Article Image
              NewsDetailsWidgets.buildArticleImage(article.mainImageUrl ?? ''),
              SizedBox(height: 20),

              // Article Title
              Text(
                article.aiTitle ?? 'No title available',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xFF1B1E28),
                ),
              ),
              SizedBox(height: 16),

              // Article Summary
              NewsDetailsWidgets.buildFormattedSummary(
                  article.aiSummary ?? 'No summary available'
              ),
              SizedBox(height: 30),

              // Affiliate Products Section
              Obx(() => NewsDetailsWidgets.buildAffiliateProducts(
                products: viewModel.affiliateProducts.value,
                isLoading: viewModel.isLoadingAffiliateProducts.value,
                error: viewModel.affiliateError.value,
                onProductClick: (product) => viewModel.onAffiliateProductClick(product),
              )),

              SizedBox(height: 20),

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

              // Disclaimer
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
}