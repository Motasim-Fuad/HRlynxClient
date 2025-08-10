/*import 'package:damaged303/app/modules/subscription_screen/subscription_controller.dart';
import 'package:damaged303/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlanOptionCard extends StatelessWidget {
  final int index;
  final String title;
  final String price;
  final String note;
  final bool isPopular;

  PlanOptionCard({
    required this.index,
    required this.title,
    required this.price,
    required this.note,
    this.isPopular = false,
  });

  final SubscriptionViewModel viewModel = Get.put(SubscriptionViewModel());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Obx(() {
        final isSelected = viewModel.selectedIndex.value == index;

        return GestureDetector(
          onTap: () => viewModel.selectOption(index),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.primarycolor,
                  border: Border.all(
                    color: isSelected ? Colors.white : AppColors.primarycolor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1B1E28),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7D848D),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1B1E28),
                      ),
                    ),
                  ],
                ),
              ),
              if (isPopular)
                Positioned(
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Most Popular',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}*/
