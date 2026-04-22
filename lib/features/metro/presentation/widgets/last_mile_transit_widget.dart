import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/station.dart';

class LastMileTransitWidget extends StatelessWidget {
  final Station destination;

  const LastMileTransitWidget({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final rides = [
      {'icon': Icons.local_taxi, 'name': 'UberX', 'price': '65 EGP', 'eta': '2 mins', 'color': Colors.black},
      {'icon': Icons.directions_car, 'name': 'Careem', 'price': '50 EGP', 'eta': '4 mins', 'color': Colors.green},
      {'icon': Icons.electric_rickshaw, 'name': 'محطة توك توك', 'price': '15 EGP', 'eta': 'Now', 'color': Colors.orange},
    ];

    final isAr = context.locale.languageCode == 'ar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'عطلان بره المحطة؟ 🚕' : 'Stuck outside the station? 🚕',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isAr ? 'احجز مواصلتك من مخرج ${isAr ? destination.nameAr : destination.nameEn}' : 'Book your ride from ${isAr ? destination.nameAr : destination.nameEn} exit',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rides.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final ride = rides[index];
                return FadeInRight(
                  delay: Duration(milliseconds: 100 * index),
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (ride['color'] as Color).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (ride['color'] as Color).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(ride['icon'] as IconData, color: ride['color'] as Color, size: 28),
                        const SizedBox(height: 8),
                        Text(ride['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(ride['price'] as String, style: TextStyle(color: ride['color'] as Color, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(ride['eta'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
