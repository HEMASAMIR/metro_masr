import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';

class TripRatingDialog extends StatefulWidget {
  const TripRatingDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TripRatingDialog(),
    );
  }

  @override
  State<TripRatingDialog> createState() => _TripRatingDialogState();
}

class _TripRatingDialogState extends State<TripRatingDialog> {
  int _rating = 0;
  final List<String> _selectedChips = [];

  final List<String> _chips = ['مزدحم جداً', 'تكييف لا يعمل', 'نظيف', 'هادئ', 'تأخير طويل', 'سريع'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Text(
              'كيف كانت رحلتك؟ ⭐',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('ساعدنا في تحسين وتطوير منظومة المترو.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: 48,
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < _rating ? const Color(0xFFFFD700) : Colors.grey[400],
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            if (_rating > 0)
              FadeInUp(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _chips.map((chip) {
                    final isSelected = _selectedChips.contains(chip);
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(chip),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedChips.add(chip);
                          } else {
                            _selectedChips.remove(chip);
                          }
                        });
                      },
                      selectedColor: AppColors.accent.withValues(alpha: 0.2),
                      side: BorderSide(color: isSelected ? AppColors.accent : Colors.grey[300]!),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _rating > 0 ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('شكراً لتقييمك! تم إرسال ملاحظاتك.'), backgroundColor: AppColors.success),
                  );
                } : null,
                child: const Text('إرسال التقييم', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
