
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/modules/main_screen/main_screen_controller.dart';
import 'package:hr/app/modules/news/news_controller.dart';
import 'package:hr/app/utils/app_colors.dart';
import 'package:hr/app/utils/app_images.dart';

import 'news_detail/news_detail_page_view.dart';

class NewsView extends StatelessWidget {
  const NewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final NewsController controller = Get.put(NewsController());

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Get.put<BottomNavController>(BottomNavController()).changeTab(0);
            Get.back();
          },
          child: Icon(Icons.arrow_back),
        ),
        title: Text(
          'Breaking HR News',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 24,
            color: Color(0xFF1B1E28),
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Color(0xFFB0C3C2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextFormField(
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search News',
                    suffixIcon: Obx(() =>
                    controller.searchText.value.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        controller.searchController.clear();
                        controller.loadArticles(refresh: true);
                      },
                    )
                        : SizedBox.shrink(),
                    ),
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

            SizedBox(height: 20),

            // Category Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(() => Container(
                height: 45,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Color(0xFFB0C3C2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>?>(
                    isExpanded: true,
                    value: controller.selectedCategory.value,
                    hint: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text('Select a category'),
                    ),
                    items: [
                      DropdownMenuItem<Map<String, dynamic>?>(
                        value: null,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text('All Categories'),
                        ),
                      ),
                      ...controller.categories.map<DropdownMenuItem<Map<String, dynamic>?>>(
                            (category) => DropdownMenuItem<Map<String, dynamic>?>(
                          value: category,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              category['name'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ).toList(),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        controller.clearCategoryFilter();
                      } else {
                        controller.filterByCategory(value);
                      }
                    },
                  ),
                ),
              )),
            ),


            SizedBox(height: 20,),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.articles.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primarycolor,
                    ),
                  );
                }

                if (controller.articles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No articles found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!controller.isLoadingMore.value &&
                        controller.hasNextPage.value &&
                        scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                      controller.loadMoreArticles();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: controller.articles.length + (controller.hasNextPage.value ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == controller.articles.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primarycolor,
                            ),
                          ),
                        );
                      }

                      final article = controller.articles[index];
                      final tags = article['tags'] ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tags
                          // Replace your existing tags code with this:
                          if (tags.isNotEmpty)
                            Container(
                              width: double.infinity,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tags.take(2).map<Widget>((tag) {
                                  final isSelected = controller.selectedTag.value?['id'] == tag['id'];
                                  final tagName = tag['name']?.toString() ?? '';
                                  final capitalizedTagName = tagName.isNotEmpty
                                      ? tagName[0].toUpperCase() + tagName.substring(1).toLowerCase()
                                      : '';

                                  return GestureDetector(
                                    onTap: () => controller.filterByTag(tag),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Reduced padding
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16), // More rounded corners
                                        color: isSelected ? AppColors.primarycolor : Colors.white,
                                        border: Border.all(
                                          color: isSelected ? AppColors.primarycolor : Color(0xFFE6ECEB),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        capitalizedTagName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                          color: isSelected ? Colors.white : Color(0xFF050505),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                          SizedBox(height: 10),

                          // Article Content
                          GestureDetector(
                            onTap: () {
                              if (article['id'] != null) {
                                Get.to(
                                  NewsDetailsView(articleId: article['id']),
                                );
                              } else {
                                // Fallback if ID is missing (shouldn't happen with your API)
                                Get.to(
                                  NewsDetailsView(
                                    articleId: 0, // Provide default
                                  ),
                                );
                                Get.snackbar('Error', 'Article ID missing');
                              }
                            },
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Article Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: article['main_image_url'] != null
                                        ? Image.network(
                                      article['main_image_url'],
                                      height: 100,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 100,
                                          width: 80,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Image(image: AssetImage(AppImages.default_news_img),fit: BoxFit.cover,)
                                        );
                                      },
                                    )
                                        : Container(
                                      height: 100,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.article,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 12),

                                  // Article Text Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          article['ai_title'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                            color: Color(0xFF1B1E28),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          article['ai_summary'] ?? '',
                                          style: TextStyle(
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

                          SizedBox(height: 10),
                          Divider(height: 1, color: Color(0xffE6ECEB)),
                          SizedBox(height: 8),

                          // Time and Reading Duration
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  controller.formatPublishedDate(article['published_date']),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    color: Color(0xff7D848D),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '3min',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xff7D848D),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 20),
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
}