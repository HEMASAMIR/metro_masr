import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubits/community_cubit.dart';
import '../cubits/community_state.dart';
import '../../domain/entities/report.dart';

class LostAndFoundPage extends StatelessWidget {
  const LostAndFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'شبكة المفقودات' : 'Lost & Found Network', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        label: Text(isAr ? 'إبلاغ عن مفقود/معثور' : 'Report Item'),
        icon: const Icon(Icons.add),
        onPressed: () => _showAddReportDialog(context, isAr),
      ),
      body: BlocBuilder<CommunityCubit, CommunityState>(
        builder: (context, state) {
          if (state is CommunityLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CommunityError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }
          if (state is CommunityLoaded) {
            final reports = state.reports;
            if (reports.isEmpty) {
              return Center(
                child: Text(
                  isAr ? 'لا توجد مفقودات مسجلة بعد' : 'No items reported yet',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final report = reports[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index),
                  child: _buildItemCard(report, isAr),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _showAddReportDialog(BuildContext context, bool isAr) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'إبلاغ عن شيء' : 'Report an Item',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'عنوان البلاغ (مثل: محفظة سوداء)' : 'Title (e.g., Black Wallet)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: isAr ? 'التفاصيل (المحطة، المواصفات...)' : 'Details (Station, Specs...)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                     context.read<CommunityCubit>().addReport(titleCtrl.text, descCtrl.text, 'Wallet');
                     Navigator.pop(context);
                  }
                },
                child: Text(isAr ? 'نشر البلاغ' : 'Submit Report', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Report report, bool isAr) {
    Color cardColor = Colors.blue;
    IconData cardIcon = Icons.info_outline;

    if (report.title.toLowerCase().contains('wallet') || report.title.contains('محفظة')) {
      cardColor = Colors.blue;
      cardIcon = Icons.wallet;
    } else if (report.title.toLowerCase().contains('key') || report.title.contains('مفاتيح')) {
      cardColor = Colors.orange;
      cardIcon = Icons.vpn_key;
    } else if (report.title.toLowerCase().contains('bag') || report.title.contains('شنطة')) {
      cardColor = Colors.purple;
      cardIcon = Icons.backpack;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: cardColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(cardIcon, color: cardColor),
                const SizedBox(width: 12),
                Expanded(child: Text(report.title, style: TextStyle(color: cardColor, fontWeight: FontWeight.bold, fontSize: 16))),
                Text(_formatDate(report.timestamp, isAr), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.description, style: const TextStyle(height: 1.5, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(report.location, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, bool isAr) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return isAr ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return isAr ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours} hours ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
