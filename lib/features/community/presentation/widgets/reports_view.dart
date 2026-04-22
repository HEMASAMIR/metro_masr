import 'package:flutter/material.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';
import '../../domain/entities/report.dart';
import '../cubits/community_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

class ReportsView extends StatefulWidget {
  final List<Report> reports;

  const ReportsView({super.key, required this.reports});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  void _showAddReportDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'issue';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'report_issue'.tr(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'issue', child: Text('عطل (Issue)')),
                      DropdownMenuItem(value: 'overcrowd', child: Text('زحام شديد (Overcrowded)')),
                      DropdownMenuItem(value: 'harassment', child: Text('مضايقات (Harassment)')),
                      DropdownMenuItem(value: 'other', child: Text('أخرى (Other)')),
                    ],
                    onChanged: (val) => setState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'title'.tr(),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'details'.tr(),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          context.read<CommunityCubit>().addReport(
                            titleController.text,
                            descController.text,
                            selectedCategory,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        'submit_offline'.tr(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReportDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: Text('new_report'.tr(), style: const TextStyle(color: Colors.white)),
      ),
      body: widget.reports.isEmpty
          ? const Center(
              child: Text(
                'لا توجد بلاغات حالية.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.reports.length,
              itemBuilder: (context, index) {
                final report = widget.reports.reversed.toList()[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                report.category.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  report.isSynced ? Icons.cloud_done : Icons.cloud_off,
                                  size: 16,
                                  color: report.isSynced ? AppColors.success : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  report.isSynced ? 'Synced' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: report.isSynced ? AppColors.success : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          report.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.description,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd MMM, yyyy - HH:mm').format(report.timestamp),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
