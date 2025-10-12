import 'package:HRlynx/app/modules/home/user_isSubcriptionController.dart';
import 'package:HRlynx/app/modules/profile/profile_controller.dart';
import 'package:cached_network_image/cached_network_image.dart' show CachedNetworkImage;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_images.dart';
import '../../modules/news/news_view.dart';
import 'chat_al_ai_persona_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.put(ProfileController());
    final UserIsSubcribedController is_SubcribedController = Get.put(UserIsSubcribedController());
    final controller = Get.put(ChatAllAiPersona());

    // ✅ FIXED: শুধু একবার call করুন, এটাই সব handle করবে
    WidgetsBinding.instance.addPostFrameCallback((_) {
      is_SubcribedController.checkAndUpdateSubscriptionStatus();
    });

    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Obx(() => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: _buildProfilePicture(profileController),
          )),
        ),
        title: const Text(
          'HRlynx',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF1B1E28),
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Breaking HR News Card ---
                Container(
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
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'HR QuickScan™ News',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Stay updated with the latest HR insights, trends and policy changes.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              // const SizedBox(height: 20),
                              // GestureDetector(
                              //   onTap: () => Get.to(() => const NewsView()),
                              //   child: Container(
                              //     width: 120,
                              //     height: 40,
                              //     decoration: BoxDecoration(
                              //       color: const Color(0xFF013D3B),
                              //       borderRadius: BorderRadius.circular(6),
                              //     ),
                              //     child: const Center(
                              //       child: Text(
                              //         'View Feed',
                              //         style: TextStyle(
                              //           fontWeight: FontWeight.w500,
                              //           fontSize: 16,
                              //           color: Colors.white,
                              //         ),
                              //       ),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Chat with your AI HR Assistants:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: isTablet ? 24 : 20,
                    color: AppColors.primarycolor,
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ Persona Grid with subscription check
                Obx(() {
                  // Show loading for both persona and subscription
                  if (controller.isLoading.value || is_SubcribedController.isLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (controller.personaList.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No personas available'),
                      ),
                    );
                  }

                  // Debug logs
                  print("📊 Subscription status in HomeView:");
                  print("   isActive: ${is_SubcribedController.isActive.value}");
                  print("   isSubscribed: ${is_SubcribedController.isSubscribed.value}");
                  print("   isCanceled: ${is_SubcribedController.isCanceled.value}");
                  print("   hasPremiumAccess: ${is_SubcribedController.hasPremiumAccess.value}");
                  print("   selectedPersona: ${is_SubcribedController.selectedPersona.value?.id}");

                  return FutureBuilder<List<Widget>>(
                    future: _buildPersonaGrid(
                      controller,
                      is_SubcribedController,
                      isTablet,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 10),
                                Text('Error loading personas: ${snapshot.error}'),
                              ],
                            ),
                          ),
                        );
                      }

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isTablet ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.7,
                        children: snapshot.data ?? [],
                      );
                    },
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build persona grid with subscription check
  Future<List<Widget>> _buildPersonaGrid(
      ChatAllAiPersona controller,
      UserIsSubcribedController is_SubcribedController,
      bool isTablet,
      ) async {
    List<Widget> personaCards = [];

    for (int index = 0; index < controller.personaList.length; index++) {
      final persona = controller.personaList[index];
      final personaId = persona.id ?? 0;

      // ✅ Check if this persona is accessible
      bool isPersonaActive = await is_SubcribedController.isPersonaAccessible(personaId);

      print("🎭 Persona ${persona.title} (ID: $personaId) - Active: $isPersonaActive");

      personaCards.add(
        GestureDetector(
          onTap: () async {
            if (isPersonaActive) {
              print("✅ Starting chat for accessible persona: ${persona.title}");
              await controller.startChatSession(persona);
            } else {
              print("❌ Persona not accessible: ${persona.title}");

              // Show appropriate message based on subscription status
              String title = 'Access Restricted';
              String message = 'This persona is not available';
              Color backgroundColor = Colors.orange;
              IconData icon = Icons.lock_outline;

              if (is_SubcribedController.canReactivateSubscription) {
                title = 'Reactivate Subscription';
                message = 'Reactivate your subscription to access all personas';
                backgroundColor = Colors.blue;
                icon = Icons.refresh;
              } else if (!is_SubcribedController.isActive.value) {
                title = 'Subscription Required';
                message = 'Subscription to access all AI personas';
                backgroundColor = Colors.purple;
                icon = Icons.star;
              } else if (is_SubcribedController.isCanceled.value) {
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
          },
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
                ClipRRect(
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
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                        // Lock overlay for inaccessible personas
                        if (!isPersonaActive)
                          Positioned.fill(
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
                                    Icon(
                                      is_SubcribedController.canReactivateSubscription
                                          ? Icons.refresh
                                          : is_SubcribedController.isCanceled.value
                                          ? Icons.person_outline
                                          : Icons.lock,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      is_SubcribedController.canReactivateSubscription
                                          ? 'Reactivate'
                                          : is_SubcribedController.isCanceled.value
                                          ? 'Limited'
                                          : 'Subscribe',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                  child: Text(
                    persona.title ?? 'No Title',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPersonaActive ? Colors.black : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return personaCards;
  }

  // Build Profile Picture Widget
  Widget _buildProfilePicture(ProfileController profileController) {
    if (profileController.userProfilePicture.value.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.person,
          size: 24,
          color: Colors.white,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: profileController.userProfilePicture.value,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        print('❌ Failed to load profile image: $error');
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
          ),
          child: Icon(
            Icons.person,
            size: 24,
            color: Colors.red.shade400,
          ),
        );
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}