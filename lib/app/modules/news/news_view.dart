import 'package:HRlynx/app/modules/news/news_controller.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:HRlynx/app/utils/app_images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'news_detail/news_detail_page_view.dart';

class NewsView extends StatelessWidget {
  const NewsView({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ isRegistered check — controller আগে থেকে থাকলে নতুন বানাবে না
    // এটাই crash এর fix: navigate করলে পুরনো disposed controller reuse হতো
    final NewsController controller = Get.isRegistered<NewsController>()
        ? Get.find<NewsController>()
        : Get.put(NewsController());

    final size = MediaQuery.of(context).size;

    String extractDontMissContent(String summary) {
      int startIndex = summary.indexOf('Don\'t Miss This:');
      if (startIndex == -1) return summary;
      int contentStart = summary.indexOf('\n', startIndex);
      if (contentStart == -1) contentStart = startIndex + 'Don\'t Miss This:'.length;
      int contentEnd = summary.indexOf('**', contentStart);
      if (contentEnd == -1) contentEnd = summary.length;
      return summary.substring(contentStart, contentEnd).trim();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// Header Card
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Container(
                height: size.height * 0.20,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          AppImages.home_container,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.6),
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.05,
                            vertical: size.height * 0.02,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'HR QuickScan™ News',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: size.width * 0.055,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: size.height * 0.01),
                              Text(
                                'Stay updated with the latest HR insights, trends and policy changes.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: size.width * 0.038,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: const Color(0xFFB0C3C2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextFormField(
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search News',
                    suffixIcon: Obx(() =>
                    controller.searchText.value.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.searchController.clear();
                        controller.loadArticles(refresh: true);
                      },
                    )
                        : const SizedBox.shrink()),
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      controller.loadArticles(refresh: true);
                    }
                  },
                  onFieldSubmitted: (value) {
                    controller.searchArticles(value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Category Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(() => Container(
                height: 45,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                      width: 1, color: const Color(0xFFB0C3C2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    isExpanded: true,
                    value: controller.selectedCategoryId.value,
                    dropdownColor: Colors.white,
                    hint: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text('Select a category'),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text('All Categories'),
                        ),
                      ),
                      ...controller.categories
                          .map<DropdownMenuItem<int?>>((category) {
                        final isLocked =
                            category['is_subscription_required'] == true;
                        final categoryId = category['id'] as int;
                        return DropdownMenuItem<int?>(
                          value: categoryId,
                          child: GestureDetector(
                            onTap: isLocked
                                ? () {
                              Navigator.of(context).pop();
                              Future.delayed(
                                  const Duration(milliseconds: 100),
                                      () {
                                    Get.snackbar(
                                      'Subscription Required',
                                      'Please subscribe to access this category',
                                      snackPosition: SnackPosition.TOP,
                                      backgroundColor:
                                      AppColors.primarycolor,
                                      colorText: Colors.white,
                                      duration:
                                      const Duration(seconds: 3),
                                      margin: const EdgeInsets.all(16),
                                    );
                                  });
                            }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category['name'] ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isLocked
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (isLocked)
                                    const Icon(Icons.lock,
                                        size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        controller.clearCategoryFilter();
                      } else {
                        final category = controller.categories.firstWhere(
                              (cat) => cat['id'] == value,
                          orElse: () => null,
                        );
                        if (category != null) {
                          final isLocked =
                              category['is_subscription_required'] == true;
                          if (!isLocked) {
                            controller.filterByCategory(value);
                          }
                        }
                      }
                    },
                  ),
                ),
              )),
            ),

            const SizedBox(height: 20),

            // Articles List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.articles.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primarycolor),
                  );
                }

                if (controller.hasError.value) {
                  return _buildErrorWidget(
                    errorType: controller.errorMessage.value,
                    onRetry: () => controller.refreshData(),
                  );
                }

                if (controller.articles.isEmpty) {
                  return _buildEmptyState();
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!controller.isLoadingMore.value &&
                        controller.hasNextPage.value &&
                        scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                      controller.loadMoreArticles();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: controller.articles.length +
                        (controller.hasNextPage.value ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == controller.articles.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primarycolor),
                          ),
                        );
                      }

                      final article = controller.articles[index];
                      final tags = article['tags'] ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tags.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tags.take(2).map<Widget>((tag) {
                                  final isSelected =
                                      controller.selectedTag.value?['id'] ==
                                          tag['id'];
                                  final tagName =
                                      tag['name']?.toString() ?? '';
                                  final capitalizedTagName = tagName.isNotEmpty
                                      ? tagName.toUpperCase()
                                      : '';
                                  return GestureDetector(
                                    onTap: () => controller.filterByTag(tag),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                        color: isSelected
                                            ? AppColors.primarycolor
                                            : Colors.white,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primarycolor
                                              : const Color(0xFFE6ECEB),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        capitalizedTagName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF050505),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                          const SizedBox(height: 10),

                          GestureDetector(
                            onTap: () {
                              if (article['id'] != null) {
                                Get.to(
                                    NewsDetailsView(articleId: article['id']));
                              } else {
                                Get.snackbar('Error', 'Article ID missing');
                              }
                            },
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: article['main_image_url'] != null
                                        ? Image.network(
                                      article['main_image_url'],
                                      height: 100,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: 100,
                                          width: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: Image(
                                            image: AssetImage(
                                                AppImages.default_news_img),
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    )
                                        : Container(
                                      height: 100,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius:
                                        BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.article,
                                          color: Colors.grey[600]),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          article['ai_title'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                            color: Color(0xFF1B1E28),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          extractDontMissContent(
                                              article['ai_summary'] ?? ''),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                            color: Color(0xFF7D848D),
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xffE6ECEB)),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  controller.formatPublishedDate(
                                      article['published_date']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    color: Color(0xff7D848D),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget({
    required String errorType,
    required VoidCallback onRetry,
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
        title = 'Something went wrong';
        message = 'Please try again';
        iconColor = Colors.red;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
            if (errorType != 'SESSION_EXPIRED') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarycolor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No Articles Found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text('There are no articles available at the moment',
              style:
              TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}