import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';
import '../../features/metro/domain/entities/station.dart';

class StationSearchSheet extends StatefulWidget {
  final List<dynamic> stations; // Can be List<Station>
  
  const StationSearchSheet({super.key, required this.stations});

  static Future<String?> show(BuildContext context, List<dynamic> stations) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StationSearchSheet(stations: stations),
    );
  }

  @override
  State<StationSearchSheet> createState() => _StationSearchSheetState();
}

class _StationSearchSheetState extends State<StationSearchSheet> {
  late List<dynamic> _filtered;
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.stations;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + keyboardHeight,
      padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardHeight + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Search Field
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Search station...".tr(),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (val) {
              final query = val.toLowerCase().trim();
              setState(() {
                if (query.isEmpty) {
                  _filtered = widget.stations;
                } else {
                  _filtered = widget.stations.where((s) {
                    return s.nameAr.toLowerCase().contains(query) || 
                           s.nameEn.toLowerCase().contains(query);
                  }).toList();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          
          // List of stations
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text("No stations found".tr(), style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                    itemBuilder: (context, i) {
                      final s = _filtered[i];
                      final name = isAr ? s.nameAr : s.nameEn;
                      final lineColor = s.line == 1 ? AppColors.line1 : s.line == 2 ? AppColors.line2 : AppColors.line3;
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: lineColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.train_rounded, size: 18, color: lineColor),
                        ),
                        title: Text(
                          name, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          isAr ? "الخط ${s.line}" : "Line ${s.line}",
                          style: TextStyle(color: lineColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        trailing: s.isTransfer 
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.swap_calls_rounded, color: Colors.purple, size: 16),
                            )
                          : null,
                        onTap: () => Navigator.pop(context, s.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
