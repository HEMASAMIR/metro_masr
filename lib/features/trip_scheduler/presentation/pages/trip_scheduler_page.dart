import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/gamification_service.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/offline_storage.dart';

class ScheduledTrip {
  final String id;
  final String fromStation;
  final String toStation;
  final TimeOfDay time;
  final List<bool> days; // 7 days Mon-Sun
  bool isActive;

  ScheduledTrip({
    required this.id,
    required this.fromStation,
    required this.toStation,
    required this.time,
    required this.days,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': fromStation,
        'to': toStation,
        'hour': time.hour,
        'minute': time.minute,
        'days': days,
        'active': isActive,
      };

  factory ScheduledTrip.fromJson(Map<String, dynamic> j) => ScheduledTrip(
        id: j['id'],
        fromStation: j['from'],
        toStation: j['to'],
        time: TimeOfDay(hour: j['hour'], minute: j['minute']),
        days: List<bool>.from(j['days']),
        isActive: j['active'] ?? true,
      );
}

class TripSchedulerPage extends StatefulWidget {
  const TripSchedulerPage({super.key});

  @override
  State<TripSchedulerPage> createState() => _TripSchedulerPageState();
}

class _TripSchedulerPageState extends State<TripSchedulerPage> {
  List<ScheduledTrip> _trips = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  String _formatTime(TimeOfDay time, bool isAr) {
    int h = time.hour;
    String p = h >= 12 ? (isAr ? 'م' : 'PM') : (isAr ? 'ص' : 'AM');
    if (h == 0) h = 12;
    else if (h > 12) h -= 12;
    return '${h.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $p';
  }

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final raw = AppStorage.getRawScheduledTrips();
    setState(() {
      _trips = raw.map((s) => ScheduledTrip.fromJson(jsonDecode(s))).toList();
    });
  }

  Future<void> _saveTrips() async {
    await AppStorage.saveRawScheduledTrips(
      _trips.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  Future<void> _addTrip() async {
    final isAr = context.locale.languageCode == 'ar';
    final stationNames = MetroData.stations.values.map((s) => s.nameAr).toList();
    String? from;
    String? to;
    TimeOfDay selectedTime = TimeOfDay.now();
    List<bool> days = List.filled(7, false)..[0] = true..[1] = true..[2] = true..[3] = true..[4] = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          builder: (_, sc) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  isAr ? 'جدولة رحلة جديدة' : "Schedule New Trip",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // From Station
                _dropdownField(
                  isAr ? 'محطة الانطلاق' : "From Station",
                  Icons.circle,
                  Colors.green,
                  stationNames,
                  from,
                  (v) => setModalState(() => from = v),
                ),
                const SizedBox(height: 12),

                // To Station
                _dropdownField(
                  isAr ? 'محطة الوصول' : "To Station",
                  Icons.location_on,
                  Colors.red,
                  stationNames,
                  to,
                  (v) => setModalState(() => to = v),
                ),
                const SizedBox(height: 20),

                // Time picker
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.access_time, color: AppColors.primary),
                  ),
                  title: Text(isAr ? 'وقت التذكير' : "Reminder Time"),
                  subtitle: Text(_formatTime(selectedTime, isAr)),
                  onTap: () async {
                    final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                    if (t != null) setModalState(() => selectedTime = t);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                const SizedBox(height: 20),

                // Days selection
                Text(isAr ? 'أيام التكرار' : "Repeat Days",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDaySelector(days, isAr, setModalState),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (from == null || to == null) return;
                      final trip = ScheduledTrip(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        fromStation: from!,
                        toStation: to!,
                        time: selectedTime,
                        days: days,
                      );
                      setState(() => _trips.add(trip));
                      _listKey.currentState?.insertItem(_trips.length - 1);
                      await _saveTrips();
                      await GamificationService.recordSchedule();
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(isAr ? '✅ تم جدولة الرحلة!' : "✅ Trip scheduled!"),
                          backgroundColor: Colors.green,
                        ));
                      }
                    },
                    child: Text(isAr ? 'حفظ الموعد' : "Save Schedule",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdownField(String label, IconData icon, Color iconColor,
      List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: Colors.grey[500])),
            ],
          ),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDaySelector(List<bool> days, bool isAr, StateSetter setModalState) {
    final dayLabels = isAr
        ? ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح']
        : ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        return GestureDetector(
          onTap: () => setModalState(() => days[i] = !days[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: days[i] ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: days[i] ? AppColors.primary : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Text(
                dayLabels[i],
                style: TextStyle(
                  color: days[i] ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final dayLabels = isAr
        ? ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح']
        : ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'مُجدول الرحلات' : "Trip Scheduler"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTrip,
        icon: const Icon(Icons.add),
        label: Text(isAr ? 'جدولة رحلة' : "Schedule Trip"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _trips.isEmpty
          ? _buildEmpty(isAr)
          : AnimatedList(
              key: _listKey,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              initialItemCount: _trips.length,
              itemBuilder: (ctx, i, animation) {
                final trip = _trips[i];
                return SizeTransition(
                  sizeFactor: animation,
                  child: _buildTripCard(trip, isAr, dayLabels, i),
                );
              },
            ),
    );
  }

  Widget _buildEmpty(bool isAr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            isAr ? 'لا توجد رحلات مجدولة' : "No scheduled trips yet",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'اضغط على "جدولة رحلة" لإضافة رحلتك اليومية!' : 'Tap "Schedule Trip" to add your daily commute and get reminders!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(ScheduledTrip trip, bool isAr, List<String> dayLabels, int index) {
    return Dismissible(
      key: Key(trip.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final removed = _trips.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => const SizedBox(), // Dismissible handles UI, so don't double animate
        );
        await _saveTrips();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: trip.isActive
              ? AppColors.primary.withOpacity(0.05)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: trip.isActive
                ? AppColors.primary.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 10),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip.fromStation,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatTime(trip.time, isAr),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: trip.isActive,
                  activeColor: AppColors.primary,
                  onChanged: (v) async {
                    setState(() => trip.isActive = v);
                    await _saveTrips();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    final removed = _trips.removeAt(index);
                    _listKey.currentState?.removeItem(
                      index,
                      (context, animation) => SizeTransition(
                        sizeFactor: animation,
                        child: _buildTripCard(removed, isAr, dayLabels, index),
                      ),
                    );
                    _saveTrips();
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
              child: Row(
                children: [
                  Container(width: 2, height: 16, color: Colors.grey[300]),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 10),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip.toStation,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(7, (i) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: trip.days[i]
                        ? AppColors.primary
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      dayLabels[i],
                      style: TextStyle(
                        color: trip.days[i] ? Colors.white : Colors.grey[400],
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
