import 'package:HRlynx/app/modules/home/user_isSubcriptionController.dart';
import 'package:cached_network_image/cached_network_image.dart' show CachedNetworkImage;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_images.dart';
import 'chat_al_ai_persona_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final UserIsSubcribedController is_SubcribedController = Get.put(UserIsSubcribedController());
    final controller = Get.put(ChatAllAiPersona());

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final isDesktop = constraints.maxWidth > 1024;

          final horizontalPadding = isDesktop ? 40.0 : (isTablet ? 30.0 : 20.0);
          final topPadding = isDesktop ? 40.0 : (isTablet ? 30.0 : 20.0);

          return RefreshIndicator(
            onRefresh: () async {
              await is_SubcribedController.checkAndUpdateSubscriptionStatus();
              await controller.fetchAllAiPersona();
            },
            color: AppColors.primarycolor,
            backgroundColor: Colors.white,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: _getHeaderHeight(isDesktop, isTablet, horizontalPadding, topPadding),
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: topPadding),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPersonaGridSection(
                                controller: controller,
                                is_SubcribedController: is_SubcribedController,
                                isTablet: isTablet,
                                isDesktop: isDesktop,
                              ),
                              SizedBox(height: isDesktop ? 30 : (isTablet ? 25 : 20)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      SizedBox(height: isDesktop ? 39 : (isTablet ? 34 : 29)),
                      _buildFixedHeaderCard(
                        horizontalPadding: horizontalPadding,
                        topPadding: topPadding,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _getHeaderHeight(bool isDesktop, bool isTablet, double horizontalPadding, double topPadding) {
    final cardPadding = isDesktop ? 30.0 : (isTablet ? 25.0 : 20.0);
    final titleHeight = isDesktop ? 26.0 : (isTablet ? 22.0 : 20.0);
    final spacing = isDesktop ? 24.0 : 20.0;
    final descriptionHeight = isDesktop ? 18.0 * 2 : (isTablet ? 17.0 * 2 : 16.0 * 2);
    final topSpacing = isDesktop ? 39.0 : (isTablet ? 34.0 : 100.0);

    return topSpacing + (cardPadding * 2) + titleHeight + spacing + descriptionHeight + 20;
  }

  Widget _buildFixedHeaderCard({
    required double horizontalPadding,
    required double topPadding,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 10),
        child: Column(
          children: [
            SizedBox(height: isDesktop ? 20 : (isTablet ? 15 : 10)),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                    Padding(
                      padding: EdgeInsets.all(isDesktop ? 30 : (isTablet ? 25 : 30)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your HR Guidance, Reimagined',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: isDesktop ? 26 : (isTablet ? 22 : 20),
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 24 : 20),
                          Text(
                            'AI HR Assistants modeled after real-world HR professionals—ready to help you lead smarter.',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: isDesktop ? 18 : (isTablet ? 17 : 16),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 30 : (isTablet ? 25 : 20)),
            _buildSectionTitle(isDesktop: isDesktop, isTablet: isTablet),
            SizedBox(height: isDesktop ? 30 : (isTablet ? 25 : 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required bool isDesktop, required bool isTablet}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40.0 : (isTablet ? 30.0 : 20.0)),
      child: Text(
        'Chat with your AI HR Assistants:',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: isDesktop ? 26 : (isTablet ? 24 : 20),
          color: AppColors.primarycolor,
        ),
      ),
    );
  }

  /// ✅ UPDATED: Persona Grid with proper error handling
  Widget _buildPersonaGridSection({
    required ChatAllAiPersona controller,
    required UserIsSubcribedController is_SubcribedController,
    required bool isTablet,
    required bool isDesktop,
  }) {
    int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    double spacing = isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0);
    double aspectRatio = isDesktop ? 0.75 : (isTablet ? 0.72 : 0.7);

    return Obx(() {
      // ✅ Show loading
      if (controller.isLoading.value || is_SubcribedController.isLoading.value) {
        return _buildLoadingIndicator(isDesktop: isDesktop, isTablet: isTablet);
      }

      // ✅ Show error states
      if (controller.hasError.value) {
        return _buildErrorWidget(
          errorType: controller.errorMessage.value,
          onRetry: () async {
            await controller.fetchAllAiPersona();
            await is_SubcribedController.checkAndUpdateSubscriptionStatus();
          },
          isDesktop: isDesktop,
          isTablet: isTablet,
        );
      }

      // ✅ Show empty state
      if (controller.personaList.isEmpty) {
        return _buildEmptyState(isDesktop: isDesktop, isTablet: isTablet);
      }

      _printDebugInfo(is_SubcribedController);

      return FutureBuilder<List<Widget>>(
        future: _buildPersonaCards(
          controller: controller,
          is_SubcribedController: is_SubcribedController,
          isTablet: isTablet,
          isDesktop: isDesktop,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator(isDesktop: isDesktop, isTablet: isTablet);
          }

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
            children: snapshot.data ?? [],
          );
        },
      );
    });
  }

  Widget _buildLoadingIndicator({required bool isDesktop, required bool isTablet}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 60 : (isTablet ? 50 : 40)),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primarycolor),
        ),
      ),
    );
  }

  /// ✅ NEW: Error Widget with specific messages
  Widget _buildErrorWidget({
    required String errorType,
    required VoidCallback onRetry,
    required bool isDesktop,
    required bool isTablet,
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
        padding: EdgeInsets.all(isDesktop ? 60 : (isTablet ? 50 : 40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isDesktop ? 80 : (isTablet ? 70 : 60),
              color: iconColor,
            ),
            SizedBox(height: isDesktop ? 24 : 20),
            Text(
              title,
              style: TextStyle(
                fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isDesktop ? 12 : 10),
            Text(
              message,
              style: TextStyle(
                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (errorType != 'SESSION_EXPIRED') ...[
              SizedBox(height: isDesktop ? 32 : 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarycolor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 24,
                    vertical: isDesktop ? 16 : 12,
                  ),
                  textStyle: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ UPDATED: Empty State
  Widget _buildEmptyState({required bool isDesktop, required bool isTablet}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 60 : (isTablet ? 50 : 40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: isDesktop ? 80 : (isTablet ? 70 : 60),
              color: Colors.grey.shade400,
            ),
            SizedBox(height: isDesktop ? 24 : 20),
            Text(
              'No Persona Available',
              style: TextStyle(
                fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: isDesktop ? 12 : 10),
            Text(
              'There are no AI personas available at the moment',
              style: TextStyle(
                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _printDebugInfo(UserIsSubcribedController controller) {
    print("📊 Subscription status in HomeView:");
    print("   isActive: ${controller.isActive.value}");
    print("   isSubscribed: ${controller.isSubscribed.value}");
    print("   isCanceled: ${controller.isCanceled.value}");
    print("   hasPremiumAccess: ${controller.hasPremiumAccess.value}");
    print("   selectedPersona: ${controller.selectedPersona.value?.id}");
  }

  Future<List<Widget>> _buildPersonaCards({
    required ChatAllAiPersona controller,
    required UserIsSubcribedController is_SubcribedController,
    required bool isTablet,
    required bool isDesktop,
  }) async {
    List<Widget> personaCards = [];

    final titleFontSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);
    final iconSize = isDesktop ? 32.0 : (isTablet ? 30.0 : 28.0);
    final lockTextSize = isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0);
    final cardPadding = isDesktop ? 12.0 : (isTablet ? 10.0 : 8.0);
    final verticalPadding = isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0);

    for (int index = 0; index < controller.personaList.length; index++) {
      final persona = controller.personaList[index];
      final personaId = persona.id ?? 0;

      bool isPersonaActive = await is_SubcribedController.isPersonaAccessible(personaId);

      print("🎭 Persona ${persona.title} (ID: $personaId) - Active: $isPersonaActive");

      personaCards.add(
        _buildPersonaCard(
          persona: persona,
          isPersonaActive: isPersonaActive,
          controller: controller,
          is_SubcribedController: is_SubcribedController,
          titleFontSize: titleFontSize,
          iconSize: iconSize,
          lockTextSize: lockTextSize,
          cardPadding: cardPadding,
          verticalPadding: verticalPadding,
          isDesktop: isDesktop,
          isTablet: isTablet,
        ),
      );
    }

    return personaCards;
  }

  Widget _buildPersonaCard({
    required dynamic persona,
    required bool isPersonaActive,
    required ChatAllAiPersona controller,
    required UserIsSubcribedController is_SubcribedController,
    required double titleFontSize,
    required double iconSize,
    required double lockTextSize,
    required double cardPadding,
    required double verticalPadding,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: () => _handlePersonaTap(
        persona: persona,
        isPersonaActive: isPersonaActive,
        controller: controller,
        is_SubcribedController: is_SubcribedController,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isPersonaActive ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPersonaActive ? Colors.grey.shade300 : Colors.grey.shade400,
            width: isPersonaActive ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isPersonaActive ? Colors.black12 : Colors.black.withOpacity(0.05),
              blurRadius: isPersonaActive ? 4 : 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPersonaImage(
              persona: persona,
              isPersonaActive: isPersonaActive,
              is_SubcribedController: is_SubcribedController,
              iconSize: iconSize,
              lockTextSize: lockTextSize,
              isDesktop: isDesktop,
              isTablet: isTablet,
            ),
            _buildPersonaTitle(
              title: persona.title ?? 'No Title',
              isPersonaActive: isPersonaActive,
              titleFontSize: titleFontSize,
              cardPadding: cardPadding,
              verticalPadding: verticalPadding,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaImage({
    required dynamic persona,
    required bool isPersonaActive,
    required UserIsSubcribedController is_SubcribedController,
    required double iconSize,
    required double lockTextSize,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: "${persona.avatar}",
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primarycolor),
                ),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.broken_image,
                size: isDesktop ? 48 : (isTablet ? 44 : 40),
                color: Colors.grey,
              ),
            ),
            if (!isPersonaActive)
              _buildLockOverlay(
                is_SubcribedController: is_SubcribedController,
                iconSize: iconSize,
                lockTextSize: lockTextSize,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockOverlay({
    required UserIsSubcribedController is_SubcribedController,
    required double iconSize,
    required double lockTextSize,
  }) {
    IconData lockIcon;
    String lockText;

    if (is_SubcribedController.canReactivateSubscription) {
      lockIcon = Icons.refresh;
      lockText = 'Reactivate';
    } else if (is_SubcribedController.isCanceled.value) {
      lockIcon = Icons.person_outline;
      lockText = 'Limited';
    } else {
      lockIcon = Icons.lock;
      lockText = 'Subscribe';
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(lockIcon, color: Colors.white, size: iconSize),
              const SizedBox(height: 4),
              Text(
                lockText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: lockTextSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaTitle({
    required String title,
    required bool isPersonaActive,
    required double titleFontSize,
    required double cardPadding,
    required double verticalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: cardPadding,
        vertical: verticalPadding,
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w600,
          color: isPersonaActive ? Colors.black : Colors.grey.shade600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Future<void> _handlePersonaTap({
    required dynamic persona,
    required bool isPersonaActive,
    required ChatAllAiPersona controller,
    required UserIsSubcribedController is_SubcribedController,
  }) async {
    if (isPersonaActive) {
      print("✅ Starting chat for accessible persona: ${persona.title}");
      await controller.startChatSession(persona);
    } else {
      print("❌ Persona not accessible: ${persona.title}");
      _showAccessRestrictedMessage(is_SubcribedController);
    }
  }

  void _showAccessRestrictedMessage(UserIsSubcribedController controller) {
    String title = 'Access Restricted';
    String message = 'This persona is not available';
    Color backgroundColor = Colors.orange;
    IconData icon = Icons.lock_outline;

    if (controller.canReactivateSubscription) {
      title = 'Reactivate Subscription';
      message = 'Reactivate your subscription to access all personas';
      backgroundColor = Colors.blue;
      icon = Icons.refresh;
    } else if (!controller.isActive.value) {
      title = 'Subscription Required';
      message = 'Subscribe to access all AI personas';
      backgroundColor = AppColors.primarycolor;
      icon = Icons.star;
    } else if (controller.isCanceled.value) {
      title = 'Limited Access';
      message = 'Only your selected persona is available after cancellation';
      backgroundColor = Colors.orange;
      icon = Icons.person_outline;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: Icon(icon, color: Colors.white),
    );
  }
}