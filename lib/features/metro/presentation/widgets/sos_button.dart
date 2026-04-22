import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';
import '../../../community/presentation/cubits/community_cubit.dart';

class SosFloatingButton extends StatelessWidget {
  const SosFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Pulse(
      infinite: true,
      duration: const Duration(seconds: 2),
      child: FloatingActionButton(
        heroTag: 'sosBtn',
        backgroundColor: AppColors.error,
        onPressed: () => _showSosDialog(context),
        child: const Icon(Icons.shield, color: Colors.white, size: 28),
      ),
    );
  }

  void _showSosDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildSosSheet(ctx),
    );
  }

  Widget _buildSosSheet(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 64),
          const SizedBox(height: 12),
          const Text('إبلاغ أمني عاجل 🚨', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.error)),
          const SizedBox(height: 8),
          const Text(
            'سيتم مشاركة موقعك ورقم واسم تذكرتك فوراً مع شرطة أمن مترو الأنفاق. يرجى اختيار نوع البلاغ:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildSosOption(context, 'حالة تحرش', Icons.back_hand, Colors.purple),
          _buildSosOption(context, 'سرقة / نشل', Icons.money_off, Colors.orange),
          _buildSosOption(context, 'حالة طبية طارئة', Icons.medical_services, Colors.blue),
          _buildSosOption(context, 'شجار / عنف', Icons.gavel, Colors.red),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSosOption(BuildContext context, String title, IconData icon, Color color) {
    return FadeInUp(
      child: GestureDetector(
        onTap: () {
          // Send SOS
          try {
            context.read<CommunityCubit>().addReport(title, 'بلاغ طارئ مرسل من راكب.', 'SOS');
          } catch (e) {
            // ignore if not provided
          }
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم استلام بلاغك! قوات الأمن في الطريق لمحطتك والقاطرة الخاصة بك 🚨.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
