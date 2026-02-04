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

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final isDesktop = constraints.maxWidth > 1024;

          final horizontalPadding = isDesktop ? 40.0 : (isTablet ? 30.0 : 20.0);

          return RefreshIndicator(
            onRefresh: () async {
              await is_SubcribedController.checkAndUpdateSubscriptionStatus();
              await controller.fetchAllAiPersona();
            },
            color: AppColors.primarycolor,
            backgroundColor: Colors.white,
            child: Column(
              children: [
                SizedBox(height: 20,),
                // Fixed Header Section
                _buildFixedHeader(
                  horizontalPadding: horizontalPadding,
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),

                // Scrollable GridView Section
                Expanded(
                  child: _buildPersonaGridSection(
                    controller: controller,
                    is_SubcribedController: is_SubcribedController,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                    horizontalPadding: horizontalPadding,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFixedHeader({
    required double horizontalPadding,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: isDesktop ? 40 : (isTablet ? 30 : 20)),

          // Header Card with MediaQuery Height
          LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.of(context).size.height;
              final screenWidth = MediaQuery.of(context).size.width;
              final cardHeight = screenHeight * 0.20;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  width: double.infinity,
                  height: cardHeight,
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
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.02,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: screenWidth * 0.9,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Your HR Guidance, Reimagined',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: screenWidth * 0.055,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      'AI HR Assistants modeled after real-world HR professionals—ready to help you lead smarter.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: screenWidth * 0.038,
                                        color: Colors.white.withOpacity(0.95),
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: isDesktop ? 32 : (isTablet ? 28 : 24)),

          // Section Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chat with your AI HR Assistants:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isDesktop ? 24 : (isTablet ? 22 : 18),
                  color: AppColors.primarycolor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          SizedBox(height: isDesktop ? 24 : (isTablet ? 20 : 16)),
        ],
      ),
    );
  }

  Widget _buildPersonaGridSection({
    required ChatAllAiPersona controller,
    required UserIsSubcribedController is_SubcribedController,
    required bool isTablet,
    required bool isDesktop,
    required double horizontalPadding,
  }) {
    int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    double spacing = isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0);
    double childAspectRatio = isDesktop ? 0.8 : (isTablet ? 0.75 : 0.7);

    return Obx(() {
      // Loading State
      if (controller.isLoading.value || is_SubcribedController.isLoading.value) {
        return _buildLoadingIndicator(isDesktop: isDesktop, isTablet: isTablet);
      }

      // Error State
      if (controller.hasError.value) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildErrorWidget(
            errorType: controller.errorMessage.value,
            onRetry: () async {
              await controller.fetchAllAiPersona();
              await is_SubcribedController.checkAndUpdateSubscriptionStatus();
            },
            isDesktop: isDesktop,
            isTablet: isTablet,
          ),
        );
      }

      // Empty State
      if (controller.personaList.isEmpty) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildEmptyState(isDesktop: isDesktop, isTablet: isTablet),
        );
      }

      _printDebugInfo(is_SubcribedController);

      // GridView with Personas
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
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              isDesktop ? 40 : (isTablet ? 30 : 20),
            ),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
            children: snapshot.data ?? [],
          );
        },
      );
    });
  }

  Widget _buildLoadingIndicator({required bool isDesktop, required bool isTablet}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 80 : (isTablet ? 60 : 40)),
        child: const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primarycolor),
        ),
      ),
    );
  }

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
        icon = Icons.wifi_off_rounded;
        title = 'No Internet Connection';
        message = 'Please check your internet connection and try again';
        iconColor = Colors.orange;
        break;
      case 'SERVER_ERROR':
        icon = Icons.cloud_off_rounded;
        title = 'Server Error';
        message = 'Sorry, please try later. We are working on the server';
        iconColor = Colors.red;
        break;
      case 'SESSION_EXPIRED':
        icon = Icons.lock_clock_rounded;
        title = 'Session Expired';
        message = 'Redirecting to login...';
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.error_outline_rounded;
        title = 'Something went wrong';
        message = 'Please try again';
        iconColor = Colors.red;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 80 : (isTablet ? 60 : 40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: isDesktop ? 64 : (isTablet ? 56 : 48),
                color: iconColor,
              ),
            ),
            SizedBox(height: isDesktop ? 24 : (isTablet ? 20 : 16)),
            Text(
              title,
              style: TextStyle(
                fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isDesktop ? 12 : (isTablet ? 10 : 8)),
            Text(
              message,
              style: TextStyle(
                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (errorType != 'SESSION_EXPIRED') ...[
              SizedBox(height: isDesktop ? 32 : (isTablet ? 28 : 24)),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarycolor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : (isTablet ? 28 : 24),
                    vertical: isDesktop ? 16 : (isTablet ? 14 : 12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: TextStyle(
                    fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
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

  Widget _buildEmptyState({required bool isDesktop, required bool isTablet}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 80 : (isTablet ? 60 : 40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_outlined,
                size: isDesktop ? 64 : (isTablet ? 56 : 48),
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: isDesktop ? 24 : (isTablet ? 20 : 16)),
            Text(
              'No Persona Available',
              style: TextStyle(
                fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isDesktop ? 12 : (isTablet ? 10 : 8)),
            Text(
              'There are no AI personas available at the moment',
              style: TextStyle(
                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    final iconSize = isDesktop ? 36.0 : (isTablet ? 32.0 : 28.0);
    final lockTextSize = isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0);
    final cardPadding = isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0);

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
          color: isPersonaActive ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPersonaActive ? Colors.grey.shade300 : Colors.grey.shade400,
            width: isPersonaActive ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isPersonaActive
                  ? Colors.black.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isPersonaActive ? 6 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildPersonaImage(
                persona: persona,
                isPersonaActive: isPersonaActive,
                is_SubcribedController: is_SubcribedController,
                iconSize: iconSize,
                lockTextSize: lockTextSize,
                isDesktop: isDesktop,
                isTablet: isTablet,
              ),
            ),
            _buildPersonaTitle(
              title: persona.title ?? 'No Title',
              isPersonaActive: isPersonaActive,
              titleFontSize: titleFontSize,
              cardPadding: cardPadding,
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
        topLeft: Radius.circular(11),
        topRight: Radius.circular(11),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: "${persona.avatar}",
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primarycolor),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade200,
              child: Icon(
                Icons.broken_image_rounded,
                size: isDesktop ? 48 : (isTablet ? 44 : 40),
                color: Colors.grey.shade400,
              ),
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
      lockIcon = Icons.refresh_rounded;
      lockText = 'Reactivate';
    } else if (is_SubcribedController.isCanceled.value) {
      lockIcon = Icons.person_outline_rounded;
      lockText = 'Limited';
    } else {
      lockIcon = Icons.lock_rounded;
      lockText = 'Subscribe';
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(11),
            topRight: Radius.circular(11),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(lockIcon, color: Colors.white, size: iconSize),
              const SizedBox(height: 6),
              Text(
                lockText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: lockTextSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
  }) {
    return Padding(
      padding: EdgeInsets.all(cardPadding),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w600,
          color: isPersonaActive ? Colors.black87 : Colors.grey.shade600,
          height: 1.3,
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
    IconData icon = Icons.lock_outline_rounded;

    if (controller.canReactivateSubscription) {
      title = 'Reactivate Subscription';
      message = 'Reactivate your subscription to access all personas';
      backgroundColor = Colors.blue;
      icon = Icons.refresh_rounded;
    } else if (!controller.isActive.value) {
      title = 'Subscription Required';
      message = 'Subscribe to access all AI personas';
      backgroundColor = AppColors.primarycolor;
      icon = Icons.star_rounded;
    } else if (controller.isCanceled.value) {
      title = 'Limited Access';
      message = 'Only your selected persona is available after cancellation';
      backgroundColor = Colors.orange;
      icon = Icons.person_outline_rounded;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: Icon(icon, color: Colors.white, size: 24),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}