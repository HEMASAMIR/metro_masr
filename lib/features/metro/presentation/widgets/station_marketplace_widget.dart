import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class StationMarketplaceWidget extends StatelessWidget {
  final String stationName;

  const StationMarketplaceWidget({super.key, required this.stationName});

  @override
  Widget build(BuildContext context) {
    final deals = [
      {'store': 'McDonald\'s', 'deal': 'خصم 20% على وجبات الماك', 'icon': Icons.fastfood, 'color': Colors.red},
      {'store': 'Vodafone', 'deal': '1 جيجا هدية شحن السريع', 'icon': Icons.wifi_calling_3, 'color': Colors.redAccent},
      {'store': 'Starbucks', 'deal': 'Buy 1 Get 1 (فروع المترو)', 'icon': Icons.local_cafe, 'color': Colors.green},
    ];

    final isAr = context.locale.languageCode == 'ar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? 'عروض حصرية في $stationName 🛍️' : 'Exclusive Deals at $stationName 🛍️',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: deals.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final deal = deals[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 150 * index),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: (deal['color'] as Color).withValues(alpha: 0.1),
                          child: Icon(deal['icon'] as IconData, color: deal['color'] as Color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(deal['store'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(deal['deal'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
