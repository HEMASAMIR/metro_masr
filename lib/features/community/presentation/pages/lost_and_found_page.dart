import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class LostAndFoundPage extends StatelessWidget {
  const LostAndFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final items = [
      {
        'titleEn': 'Found Black Wallet',
        'titleAr': 'تم العثور على محفظة سوداء',
        'descAr': 'لقيت محفظة سوداء فيها بطاقة باسم "أحمد" عند محطة أنور السادات، سلمتها لمكتب الأمن.',
        'descEn': 'Found a black wallet with an ID for "Ahmed" at Anwar El Sadat station, returned to security.',
        'station': 'Anwar El Sadat',
        'time': '10 mins ago',
        'category': 'Wallet',
        'icon': Icons.wallet,
        'color': Colors.blue
      },
      {
        'titleEn': 'Lost Keys',
        'titleAr': 'مفاتيح ضايعة',
        'descAr': 'ميدالية مفاتيح ضاعت مني على الخط الثالث اتجاه عدلي منصور، ياريت اللي يلاقيها يكلمني.',
        'descEn': 'Lost a keychain on Line 3 towards Adly Mansour. Please contact if found.',
        'station': 'Line 3',
        'time': '2 hours ago',
        'category': 'Keys',
        'icon': Icons.vpn_key,
        'color': Colors.orange
      },
      {
        'titleEn': 'Found Student Bag',
        'titleAr': 'لقيت شنطة مدرسة',
        'descAr': 'تم العثور على شنطة مدرسة في محطة الشهداء، موجودة مع عامل النظافة ع الرصيف.',
        'descEn': 'Found a school bag at El Shohada. Left it with the cleaning staff.',
        'station': 'El Shohada',
        'time': 'Yesterday',
        'category': 'Bag',
        'icon': Icons.backpack,
        'color': Colors.purple
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'شبكة المفقودات' : 'Lost & Found Network', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        label: Text(isAr ? 'إبلاغ عن مفقود/معثور' : 'Report Item'),
        icon: const Icon(Icons.add),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isAr ? 'قريباً: إضافة عنصر' : 'Coming soon: Add item')),
          );
        },
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return FadeInUp(
            delay: Duration(milliseconds: 100 * index),
            child: _buildItemCard(
              title: isAr ? item['titleAr'] as String : item['titleEn'] as String,
              description: isAr ? item['descAr'] as String : item['descEn'] as String,
              station: item['station'] as String,
              time: item['time'] as String,
              icon: item['icon'] as IconData,
              color: item['color'] as Color,
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard({required String title, required String description, required String station, required String time, required IconData icon, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))),
                Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(height: 1.5, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(station, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
