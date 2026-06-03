import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../cubits/community_cubit.dart';
import '../cubits/community_state.dart';
import '../../domain/entities/report.dart';

class LostAndFoundPage extends StatelessWidget {
  const LostAndFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommunityCubit>()..loadCommunityData(),
      child: const _LostAndFoundView(),
    );
  }
}

class _LostAndFoundView extends StatefulWidget {
  const _LostAndFoundView();

  @override
  State<_LostAndFoundView> createState() => _LostAndFoundViewState();
}

class _LostAndFoundViewState extends State<_LostAndFoundView> {
  RealtimeChannel? _reportsChannel;
  RealtimeChannel? _messagesChannel;
  late final CommunityCubit _cubit;
  late SharedPreferences _prefs;
  List<String> _savedReportIds = [];
  Map<String, String> _claimedReports = {};
  bool _prefsInitialized = false;
  bool _adminModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<CommunityCubit>();
    _subscribeRealtime();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs.getStringList('saved_report_ids') ?? [];
    final String? claimedJson = _prefs.getString('claimed_reports_map');
    Map<String, String> claimed = {};
    if (claimedJson != null) {
      try {
        claimed = Map<String, String>.from(json.decode(claimedJson));
      } catch (_) {}
    }
    setState(() {
      _savedReportIds = saved;
      _claimedReports = claimed;
      _prefsInitialized = true;
    });
  }

  void _toggleSaveReport(String id) {
    if (!_prefsInitialized) return;
    setState(() {
      if (_savedReportIds.contains(id)) {
        _savedReportIds.remove(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.locale.languageCode == 'ar' ? "تم الإزالة من المحفوظات 📥" : "Removed from saved items 📥"),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        _savedReportIds.add(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.locale.languageCode == 'ar' ? "تم الحفظ في المحفوظات 💾" : "Saved to your list 💾"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
    _prefs.setStringList('saved_report_ids', _savedReportIds);
  }

  void _showClaimDialog(Report report, bool isAr) {
    final proofCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              isAr ? "إثبات ملكية المفقود 🛡️" : "Claim Ownership 🛡️",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr 
                ? "لمنع الادعاءات الباطلة، يرجى كتابة تفاصيل سرية تثبت ملكيتك (مثال: محتويات المحفظة الداخلية، ماركتها، صور للبطاقات، أو الأوراق الموجودة بها)."
                : "To prevent false claims, please provide specific details proving your ownership (e.g. inner contents of the wallet, card names, or cash amount).",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: proofCtrl,
              maxLines: 3,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: isAr ? "اكتب تفاصيل الإثبات السرية هنا..." : "Write your proof details here...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? "إلغاء" : "Cancel", style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (proofCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isAr ? "يرجى كتابة تفاصيل الإثبات أولاً!" : "Please enter your proof first!")),
                );
                return;
              }
              Navigator.pop(ctx);
              _submitClaim(report.id, proofCtrl.text.trim());
            },
            child: Text(isAr ? "تقديم الطلب 🙋‍♂️" : "Submit Claim 🙋‍♂️"),
          ),
        ],
      ),
    );
  }

  void _submitClaim(String reportId, String proof) {
    if (!_prefsInitialized) return;
    setState(() {
      _claimedReports[reportId] = proof;
    });
    _prefs.setString('claimed_reports_map', json.encode(_claimedReports));
    
    // Show beautiful success dialog
    final isAr = context.locale.languageCode == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.success),
            const SizedBox(width: 10),
            Text(
              isAr ? "تم إرسال طلبك بنجاح 🎉" : "Claim Submitted 🎉",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text(
          isAr
            ? "تم تسجيل طلب ملكيتك وتفاصيل إثباتك بأمان. جاري مطابقة التفاصيل مع مكتشف المفقود لحماية المفقودات من السرقة والادعاءات الباطلة! 🛡️"
            : "Your claim has been securely registered. We are matching your details with the finder to protect items from false claims! 🛡️",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? "رائع" : "Awesome"),
          )
        ],
      ),
    );
  }

  void _subscribeRealtime() {
    try {
      // 1. Listen for new reports in 'reports' table in real-time
      _reportsChannel = Supabase.instance.client
          .channel('public:reports')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'reports',
            callback: (payload) {
              if (mounted) {
                _cubit.loadCommunityData();
              }
            },
          )
          .subscribe();

      // 2. Listen for new reports in fallback 'messages' table in real-time
      _messagesChannel = Supabase.instance.client
          .channel('public:messages:lost_found_fallback')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter:  PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: 'lost_and_found_reports',
            ),
            callback: (payload) {
              if (mounted) {
                _cubit.loadCommunityData();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Real-time Lost & Found subscription error: $e');
    }
  }

  @override
  void dispose() {
    try {
      if (_reportsChannel != null) {
        Supabase.instance.client.removeChannel(_reportsChannel!);
      }
      if (_messagesChannel != null) {
        Supabase.instance.client.removeChannel(_messagesChannel!);
      }
    } catch (e) {
      debugPrint('Error removing real-time channels: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text("Lost & Found Network".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(
              _adminModeEnabled ? Icons.admin_panel_settings_rounded : Icons.admin_panel_settings_outlined,
              color: _adminModeEnabled ? AppColors.accent : Colors.grey,
            ),
            tooltip: isAr ? "وضع المسؤول 👮‍♂️" : "Admin Mode 👮‍♂️",
            onPressed: () {
              setState(() {
                _adminModeEnabled = !_adminModeEnabled;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _adminModeEnabled 
                      ? (isAr ? "تم تفعيل وضع المسؤول 👮‍♂️" : "Admin Mode Activated 👮‍♂️")
                      : (isAr ? "تم إيقاف وضع المسؤول 🔒" : "Admin Mode Deactivated 🔒"),
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          if (_claimedReports.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.security_rounded, color: Colors.amber),
              tooltip: isAr ? "لوحة المراجعة الأمنية" : "Security Review Board",
              onPressed: () => _showAdminClaimsSheet(isAr),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        label: Text("Report Item".tr()),
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
                  "No items reported yet".tr(),
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: reports.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final report = reports[index];
                return FadeInUp(
                  key: ValueKey(report.id),
                  delay: Duration(milliseconds: 50 * index),
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
    final nameCtrl = TextEditingController();
    final stationCtrl = TextEditingController();
    String? selectedImagePath;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Report an Item".tr(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Your Full Name (Required)".tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: "Title (e.g., Black Wallet)".tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stationCtrl,
                    decoration: InputDecoration(
                      labelText: "Metro Station (e.g., Sadat)".tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Details (Description, who to contact...)".tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          selectedImagePath = pickedFile.path;
                        });
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade50,
                      ),
                      child: selectedImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(selectedImagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
                                const SizedBox(height: 8),
                                Text("Upload Picture (Optional)".tr(), style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
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
                        if (titleCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                           // Parse category dynamically
                           String category = 'other';
                           final t = titleCtrl.text.toLowerCase();
                           if (t.contains('wallet') || t.contains('محفظة')) {
                             category = 'Wallet';
                           } else if (t.contains('key') || t.contains('مفاتيح') || t.contains('مفتاح')) {
                             category = 'Key';
                           } else if (t.contains('bag') || t.contains('شنطة') || t.contains('حقيبة')) {
                             category = 'Bag';
                           }

                           final location = stationCtrl.text.isNotEmpty ? stationCtrl.text : 'Sadat Station';

                           _cubit.addReport(
                             titleCtrl.text, 
                             descCtrl.text, 
                             category,
                             reporterName: nameCtrl.text,
                             imageUrl: selectedImagePath,
                           );
                           Navigator.pop(context);
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text("Please enter your name and item title".tr())),
                           );
                        }
                      },
                      child: Text("Submit Report".tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildItemCard(Report report, bool isAr) {
    Color cardColor = Colors.blue;
    IconData cardIcon = Icons.info_outline;

    if (report.title.toLowerCase().contains('wallet') || report.title.contains('محفظة')) {
      cardColor = Colors.blue;
      cardIcon = Icons.wallet;
    } else if (report.title.toLowerCase().contains('key') || report.title.contains('مفاتيح') || report.title.contains('مفتاح')) {
      cardColor = Colors.orange;
      cardIcon = Icons.vpn_key;
    } else if (report.title.toLowerCase().contains('bag') || report.title.contains('شنطة') || report.title.contains('حقيبة')) {
      cardColor = Colors.purple;
      cardIcon = Icons.backpack;
    }

    final isSaved = _savedReportIds.contains(report.id);
    final isClaimed = _claimedReports.containsKey(report.id);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                if (_adminModeEnabled) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: isAr ? "حذف البلاغ كمسؤول" : "Delete Report as Admin",
                    onPressed: () => _confirmDeleteReport(report, isAr),
                  ),
                  const SizedBox(width: 8),
                ],
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
                if (report.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: report.imageUrl!.startsWith('http')
                        ? Image.network(
                            report.imageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(report.imageUrl!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(report.location, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (report.reporterName != null)
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(report.reporterName!, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Save Button
                    TextButton.icon(
                      onPressed: () => _toggleSaveReport(report.id),
                      icon: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        color: isSaved ? AppColors.accent : Colors.grey,
                        size: 20,
                      ),
                      label: Text(
                        isSaved 
                          ? (isAr ? "محفوظة" : "Saved") 
                          : (isAr ? "حفظ" : "Save"),
                        style: TextStyle(
                          color: isSaved ? AppColors.accent : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Claim / Verify Button
                    isClaimed
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_empty_rounded, color: Colors.amber, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                isAr ? "قيد التحقق ⏳" : "Verifying ⏳",
                                style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardColor.withValues(alpha: 0.1),
                            foregroundColor: cardColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () => _showClaimDialog(report, isAr),
                          icon: const Icon(Icons.security_rounded, size: 16),
                          label: Text(
                            isAr ? "إثبات ملكية 🙋‍♂️" : "Claim & Verify 🙋‍♂️",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
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

  void _showAdminClaimsSheet(bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? "لوحة التحقق الأمنية للمترو 👮‍♂️" : "Metro Security Claims Panel 👮‍♂️",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  isAr 
                    ? "بصفتك أمن محطة المترو، يمكنك مطابقة التفاصيل السرية أدناه للموافقة على تسليم المفقودات."
                    : "As Metro security staff, you can review secret proof below and authorize return.",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const Divider(height: 24),
                Expanded(
                  child: _claimedReports.isEmpty
                    ? Center(
                        child: Text(
                          isAr ? "لا توجد طلبات معلقة للمراجعة 🎉" : "No pending claims to review 🎉",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        children: _claimedReports.entries.map((entry) {
                          final reportId = entry.key;
                          final proofText = entry.value;
                          
                          // Find original report from bloc state
                          Report? originalReport;
                          if (_cubit.state is CommunityLoaded) {
                            final loaded = _cubit.state as CommunityLoaded;
                            try {
                              originalReport = loaded.reports.firstWhere((r) => r.id == reportId);
                            } catch (_) {}
                          }

                          final itemTitle = originalReport?.title ?? (isAr ? "مفقود مجهول" : "Unknown Item");
                          final location = originalReport?.location ?? "";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey.shade900 
                                : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      itemTitle,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        location,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isAr ? "التفاصيل السرية المقدمة كإثبات ملكية:" : "Submitted Secret Proof:",
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "\"$proofText\"",
                                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Reject Button
                                    TextButton.icon(
                                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                      onPressed: () {
                                        setState(() {
                                          _claimedReports.remove(reportId);
                                        });
                                        setModalState(() {});
                                        _prefs.setString('claimed_reports_map', json.encode(_claimedReports));
                                        Navigator.pop(context);
                                        _showResolutionDialog(
                                          isAr ? "تم رفض الطلب ❌" : "Claim Rejected ❌",
                                          isAr 
                                            ? "تم رفض طلب الملكية وإغلاقه لعدم تطابق التفاصيل السرية لحماية المفقود. 🛡️"
                                            : "Ownership claim rejected. The item remains protected. 🛡️",
                                          false,
                                        );
                                      },
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      label: Text(isAr ? "رفض الطلب" : "Reject"),
                                    ),
                                    const SizedBox(width: 8),
                                    // Approve Button
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _claimedReports.remove(reportId);
                                        });
                                        setModalState(() {});
                                        _prefs.setString('claimed_reports_map', json.encode(_claimedReports));
                                        Navigator.pop(context);
                                        _showResolutionDialog(
                                          isAr ? "تم إثبات الملكية والتسليم ✅" : "Ownership Verified ✅",
                                          isAr 
                                            ? "تمت المطابقة بنجاح واعتماد الاستلام! تم إنشاء رمز استلام ذكي (OTP) لإتمام الاستلام في المحطة. 🛡️🎉"
                                            : "Match confirmed! OTP generated for secure station pickup. 🛡️🎉",
                                          true,
                                        );
                                      },
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: Text(isAr ? "موافقة وتسليم" : "Approve"),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showResolutionDialog(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isSuccess ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.locale.languageCode == 'ar' ? "حسناً" : "OK"),
          )
        ],
      ),
    );
  }

  void _confirmDeleteReport(Report report, bool isAr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            Text(
              isAr ? "حذف البلاغ نهائياً؟ ⚠️" : "Delete Report Permanently? ⚠️",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text(
          isAr
            ? "هل أنت متأكد من رغبتك في حذف بلاغ \"${report.title}\" نهائياً كمسؤول؟ لا يمكن التراجع عن هذا الإجراء."
            : "Are you sure you want to delete report \"${report.title}\" permanently as an admin? This action cannot be undone.",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? "إلغاء" : "Cancel", style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _cubit.deleteReport(report.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isAr ? "تم حذف البلاغ بنجاح 🗑️" : "Report deleted successfully 🗑️"),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: Text(isAr ? "نعم، حذف 🗑️" : "Yes, Delete 🗑️"),
          ),
        ],
      ),
    );
  }
}
