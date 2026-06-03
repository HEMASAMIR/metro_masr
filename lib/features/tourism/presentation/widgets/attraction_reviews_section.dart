import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/models/user_review.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC ENTRY POINT – drop this anywhere in the scroll view
// ─────────────────────────────────────────────────────────────────────────────
class AttractionReviewsSection extends StatefulWidget {
  final String attractionId;
  final bool isAr;
  final Color accentColor;
  final VoidCallback? onReviewsChanged;

  const AttractionReviewsSection({
    super.key,
    required this.attractionId,
    required this.isAr,
    required this.accentColor,
    this.onReviewsChanged,
  });

  @override
  State<AttractionReviewsSection> createState() =>
      _AttractionReviewsSectionState();
}

class _AttractionReviewsSectionState extends State<AttractionReviewsSection> {
  List<UserReview> _reviews = [];
  bool _loading = true;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await UserReviewService.getReviews(widget.attractionId);
    if (mounted) setState(() { _reviews = r; _loading = false; });
  }

  Future<void> _onHelpful(String reviewId) async {
    await UserReviewService.markHelpful(widget.attractionId, reviewId);
    await _load();
  }

  void _openWriteReview() async {
    final result = await showModalBottomSheet<UserReview>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(
        attractionId: widget.attractionId,
        isAr: widget.isAr,
        accentColor: widget.accentColor,
      ),
    );
    if (result != null && mounted) {
      // Post-review questionnaire
      final answered = await showModalBottomSheet<UserReview>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PostReviewSheet(
          review: result,
          isAr: widget.isAr,
          accentColor: widget.accentColor,
        ),
      );
      final finalReview = answered ?? result;
      await UserReviewService.addReview(finalReview);
      await _load();
      widget.onReviewsChanged?.call(); // refresh parent live rating
      if (mounted) _showSuccessSnack();
    }
  }

  void _showSuccessSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Text('🎉', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(
            "Thanks! Review added ✓".tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ]),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor;
    final isAr = widget.isAr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.35), blurRadius: 10)
                  ],
                ),
                child: const Text('⭐', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Visitor Reviews".tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    if (_reviews.isNotEmpty)
                      Text(
                        isAr
                            ? '${_reviews.length} تقييم'
                            : '${_reviews.length} review${_reviews.length > 1 ? 's' : ''}',
                        style: TextStyle(
                            color: color, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Write review button ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: color.withOpacity(0.4),
              ),
              icon: const Icon(Icons.rate_review_rounded, size: 20),
              label: Text(
                "Write a Review".tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: _openWriteReview,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Review list ───────────────────────────────────────────────────
        if (_loading)
          Padding(
            padding: EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(0),
                itemCount: 2,
                itemBuilder: (context, i) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Shimmer.fromColors(
                    baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                    child: Container(
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        else if (_reviews.isEmpty)
          _EmptyReviews(isAr: isAr, color: color)
        else
          _ReviewList(
            reviews: _showAll ? _reviews : _reviews.take(3).toList(),
            isAr: isAr,
            color: color,
            onHelpful: _onHelpful,
          ),

        // ── Show more ─────────────────────────────────────────────────────
        if (_reviews.length > 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GestureDetector(
              onTap: () => setState(() => _showAll = !_showAll),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: color.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showAll
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showAll
                          ? ("Show less".tr())
                          : (isAr
                              ? 'عرض كل التقييمات (${_reviews.length})'
                              : 'Show all reviews (${_reviews.length})'),
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyReviews extends StatelessWidget {
  final bool isAr;
  final Color color;
  const _EmptyReviews({required this.isAr, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text('💬', style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              "No reviews yet".tr(),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).textTheme.titleMedium?.color),
            ),
            const SizedBox(height: 4),
            Text(
              "Be the first to share your experience!".tr(),
              style:
                  const TextStyle(color: Color(0xFF8899BB), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review list
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewList extends StatelessWidget {
  final List<UserReview> reviews;
  final bool isAr;
  final Color color;
  final Future<void> Function(String) onHelpful;

  const _ReviewList({
    required this.reviews,
    required this.isAr,
    required this.color,
    required this.onHelpful,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: reviews
          .map((r) => _ReviewCard(
                review: r,
                isAr: isAr,
                color: color,
                onHelpful: () => onHelpful(r.id),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single review card
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewCard extends StatefulWidget {
  final UserReview review;
  final bool isAr;
  final Color color;
  final VoidCallback onHelpful;

  const _ReviewCard({
    required this.review,
    required this.isAr,
    required this.color,
    required this.onHelpful,
  });

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _tappedHelpful = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1), const Color(0xFF059669), const Color(0xFFD97706),
      const Color(0xFFDB2777), const Color(0xFF0284C7), const Color(0xFFDC2626),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return "Today".tr();
    if (diff.inDays == 1) return "Yesterday".tr();
    if (diff.inDays < 7) {
      return widget.isAr ? 'منذ ${diff.inDays} أيام' : '${diff.inDays}d ago';
    }
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final avatarColor = _avatarColor(r.userName);
    final isAr = widget.isAr;

    return ScaleTransition(
      scale: _anim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarColor,
                  child: Text(
                    _initials(r.userName),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(r.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(_formatDate(r.date),
                          style: const TextStyle(
                              color: Color(0xFF8899BB), fontSize: 11)),
                    ],
                  ),
                ),
                // Stars
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < r.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Comment
            Text(
              r.comment,
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
                height: 1.55,
              ),
            ),

            // Post-answer chips (if any)
            if (r.postAnswers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _buildAnswerChips(r.postAnswers, isAr),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Helpful row
            Row(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              children: [
                GestureDetector(
                  onTap: _tappedHelpful
                      ? null
                      : () {
                          setState(() => _tappedHelpful = true);
                          widget.onHelpful();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _tappedHelpful
                          ? widget.color.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _tappedHelpful
                            ? widget.color
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_up_rounded,
                          size: 14,
                          color: _tappedHelpful
                              ? widget.color
                              : const Color(0xFF8899BB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Helpful".tr(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _tappedHelpful
                                ? widget.color
                                : const Color(0xFF8899BB),
                          ),
                        ),
                        if (r.helpfulCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${r.helpfulCount})',
                            style: TextStyle(
                                fontSize: 11, color: widget.color),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnswerChips(Map<String, dynamic> answers, bool isAr) {
    final chips = <Widget>[];

    final recommend = answers['recommend'] as String?;
    if (recommend != null) {
      final label = {
        'yes': "✅ Recommends".tr(),
        'maybe': "🤔 Maybe".tr(),
        'no': "❌ Not recommended".tr(),
      }[recommend];
      if (label != null) chips.add(_chip(label));
    }

    final liked = answers['liked'] as List?;
    if (liked != null) {
      for (final item in liked) {
        chips.add(_chip('❤️ $item'));
      }
    }

    final easy = answers['easyToFind'] as bool?;
    if (easy != null) {
      chips.add(_chip(easy
          ? ("📍 Easy to find".tr())
          : ("📍 Hard to find".tr())));
    }

    return chips;
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.color.withOpacity(0.2)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                color: widget.color,
                fontWeight: FontWeight.w600)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Write Review Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _WriteReviewSheet extends StatefulWidget {
  final String attractionId;
  final bool isAr;
  final Color accentColor;

  const _WriteReviewSheet({
    required this.attractionId,
    required this.isAr,
    required this.accentColor,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  double _rating = 0;
  final _nameCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please select a rating".tr()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please enter your name".tr()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please write a comment".tr()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _submitted = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(
          context,
          UserReview(
            id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
            attractionId: widget.attractionId,
            userName: _nameCtrl.text.trim(),
            rating: _rating,
            comment: _commentCtrl.text.trim(),
            date: DateTime.now(),
          ),
        );
      }
    });
  }

  String get _ratingLabel {
    final isAr = widget.isAr;
    if (_rating == 0) return "Tap to rate".tr();
    if (_rating <= 1) return "Very bad 😞".tr();
    if (_rating <= 2) return "Not good 😐".tr();
    if (_rating <= 3) return "Okay 🙂".tr();
    if (_rating <= 4) return "Very good 😊".tr();
    return "Excellent! 🤩".tr();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;
    final color = widget.accentColor;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Text(
              "✍️ Write Your Review".tr(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              "Share your experience with this place".tr(),
              style: const TextStyle(color: Color(0xFF8899BB), fontSize: 13),
            ),

            const SizedBox(height: 24),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starVal = i + 1.0;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starVal),
                  child: AnimatedScale(
                    scale: _rating >= starVal ? 1.25 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        _rating >= starVal
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 42,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _ratingLabel,
                key: ValueKey(_rating),
                style: TextStyle(
                  color: _rating > 0 ? color : const Color(0xFF8899BB),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Name field
            TextField(
              controller: _nameCtrl,
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                hintText: "Your Name".tr(),
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: color.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: color.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Comment field
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                hintText: "Write your experience... (highlights, tips, what to improve)".tr(),
                filled: true,
                fillColor: color.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: color.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _submitted
                    ? Container(
                        key: const ValueKey('loading'),
                        height: 52,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(color),
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        key: const ValueKey('submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: color.withOpacity(0.4),
                        ),
                        onPressed: _submit,
                        child: Text(
                          "Submit Review ✓".tr(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post-Review Questionnaire Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _PostReviewSheet extends StatefulWidget {
  final UserReview review;
  final bool isAr;
  final Color accentColor;

  const _PostReviewSheet({
    required this.review,
    required this.isAr,
    required this.accentColor,
  });

  @override
  State<_PostReviewSheet> createState() => _PostReviewSheetState();
}

class _PostReviewSheetState extends State<_PostReviewSheet> {
  int _step = 0; // 0, 1, 2
  String? _recommend;
  final Set<String> _liked = {};
  bool? _easyToFind;

  void _nextOrFinish() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      final answers = <String, dynamic>{};
      if (_recommend != null) answers['recommend'] = _recommend;
      if (_liked.isNotEmpty) answers['liked'] = _liked.toList();
      if (_easyToFind != null) answers['easyToFind'] = _easyToFind;

      Navigator.pop(
        context,
        UserReview(
          id: widget.review.id,
          attractionId: widget.review.attractionId,
          userName: widget.review.userName,
          rating: widget.review.rating,
          comment: widget.review.comment,
          date: widget.review.date,
          postAnswers: answers,
        ),
      );
    }
  }

  void _skip() => Navigator.pop(context, widget.review);

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;
    final color = widget.accentColor;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: i == _step ? 28 : 10,
              decoration: BoxDecoration(
                color: i <= _step ? color : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
          const SizedBox(height: 4),
          Text(
            '${_step + 1}/3',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Step content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(isAr, color),
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              TextButton(
                onPressed: _skip,
                child: Text(
                  "Skip".tr(),
                  style: const TextStyle(color: Color(0xFF8899BB)),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _nextOrFinish,
                child: Text(
                  _step < 2
                      ? ("Next →".tr())
                      : ("Finish ✓".tr()),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(bool isAr, Color color) {
    switch (_step) {
      case 0:
        return _buildQ1(isAr, color);
      case 1:
        return _buildQ2(isAr, color);
      default:
        return _buildQ3(isAr, color);
    }
  }

  // Q1: Recommend?
  Widget _buildQ1(bool isAr, Color color) {
    final opts = [
      ('yes', "✅ Yes, recommend".tr()),
      ('maybe', "🤔 Maybe".tr()),
      ('no', "❌ No".tr()),
    ];
    return Column(
      key: const ValueKey('q1'),
      children: [
        Text(
          "Would you recommend visiting this place?".tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: opts.map((o) {
            final selected = _recommend == o.$1;
            return GestureDetector(
              onTap: () => setState(() => _recommend = o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? color : color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? color : color.withOpacity(0.3),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  o.$2,
                  style: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Q2: What did you like?
  Widget _buildQ2(bool isAr, Color color) {
    final opts = isAr
        ? ['المكان', 'الأسعار', 'الهدوء', 'الطعام', 'التاريخ', 'الناس', 'النظافة']
        : ['Location', 'Prices', 'Atmosphere', 'Food', 'History', 'People', 'Cleanliness'];
    return Column(
      key: const ValueKey('q2'),
      children: [
        Text(
          "What did you like most?".tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 4),
        Text(
          "(Multiple choices allowed)".tr(),
          style: const TextStyle(color: Color(0xFF8899BB), fontSize: 12),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: opts.map((o) {
            final selected = _liked.contains(o);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) _liked.remove(o);
                else _liked.add(o);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? color : color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? color : color.withOpacity(0.3),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  o,
                  style: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Q3: Easy to find?
  Widget _buildQ3(bool isAr, Color color) {
    return Column(
      key: const ValueKey('q3'),
      children: [
        Text(
          "Was it easy to find / get to?".tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _yesNoBtn(
              label: "✅ Yes, easy".tr(),
              value: true,
              color: color,
            ),
            const SizedBox(width: 12),
            _yesNoBtn(
              label: "😕 No, a bit hard".tr(),
              value: false,
              color: color,
            ),
          ],
        ),
      ],
    );
  }

  Widget _yesNoBtn({required String label, required bool value, required Color color}) {
    final selected = _easyToFind == value;
    return GestureDetector(
      onTap: () => setState(() => _easyToFind = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : color.withOpacity(0.3),
              width: selected ? 2 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
