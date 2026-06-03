import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/live_metro_status_service.dart';

/// Feature #6: Live Metro Status Banner — fetches live delay info per line
class LiveStatusBanner extends StatefulWidget {
  const LiveStatusBanner({super.key});

  @override
  State<LiveStatusBanner> createState() => _LiveStatusBannerState();
}

class _LiveStatusBannerState extends State<LiveStatusBanner> {
  Map<int, String>? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final result = await LiveMetroStatusService.fetchLiveStatus();
      if (mounted) setState(() { _status = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              isAr ? 'جاري فحص حالة الخطوط...' : 'Checking line status...',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_status == null) return const SizedBox.shrink();

    final hasDelay = _status!.values.any((v) => v != 'normal');

    if (!hasDelay) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Text(
              isAr ? '✅ جميع الخطوط تعمل بانتظام' : '✅ All lines running normally',
              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // Has delays
    final lineColors = {1: AppColors.line1, 2: AppColors.line2, 3: AppColors.line3};
    final delayedLines = _status!.entries.where((e) => e.value != 'normal').toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                isAr ? '⚠️ تنبيه حالة الخطوط' : '⚠️ Line Status Alert',
                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...delayedLines.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: lineColors[e.key] ?? Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isAr ? 'الخط ${e.key}: تأخير / عطل' : 'Line ${e.key}: Delay / Issue',
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
