import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _sosCalled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerSOS(bool isAr) {
    HapticFeedback.heavyImpact();
    setState(() => _sosCalled = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🆘 SOS', textAlign: TextAlign.center, style: TextStyle(fontSize: 28)),
        content: Text(
          isAr
              ? 'تم إرسال موقعك لإدارة المترو!\n\nرقم الطوارئ: 19258\nالإسعاف: 123\nالشرطة: 122\n\nابقَ في مكانك وانتظر المساعدة.'
              : 'Your location has been sent to Metro Control!\n\nMetro Emergency: 19258\nAmbulance: 123\nPolice: 122\n\nStay in place and wait for help.',
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.6),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() => _sosCalled = false);
              Navigator.pop(ctx);
            },
            child: Text(isAr ? 'إلغاء الإنذار' : 'Cancel Alert'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final emergencyContacts = [
      (isAr ? 'إدارة المترو' : 'Metro Control', '19258', Icons.train, Colors.blue),
      (isAr ? 'الإسعاف' : 'Ambulance', '123', Icons.local_hospital, Colors.red),
      (isAr ? 'الشرطة' : 'Police', '122', Icons.local_police, Colors.indigo),
      (isAr ? 'الإطفاء' : 'Fire Dept.', '180', Icons.fireplace, Colors.orange),
    ];

    final exits = [
      (isAr ? 'مخرج رئيسي' : 'Main Exit', isAr ? 'المدخل الأمامي للمحطة' : 'Front station entrance', Icons.door_front_door),
      (isAr ? 'مخرج الطوارئ ١' : 'Emergency Exit 1', isAr ? 'الجانب الأيمن من الرصيف' : 'Right side of platform', Icons.exit_to_app),
      (isAr ? 'مخرج الطوارئ ٢' : 'Emergency Exit 2', isAr ? 'نهاية القطار' : 'End of the train', Icons.directions_walk),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        title: Text(isAr ? 'خدمات الطوارئ' : 'Emergency Services'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SOS button
            Center(
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, child) => Transform.scale(
                      scale: _sosCalled ? _pulseAnimation.value : 1.0,
                      child: child,
                    ),
                    child: GestureDetector(
                      onTap: () => _triggerSOS(isAr),
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emergency, color: Colors.white, size: 48),
                            Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? 'اضغط للإبلاغ عن طوارئ' : 'Tap to report emergency',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency contacts
            Text(
              isAr ? 'أرقام الطوارئ' : 'Emergency Numbers',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: emergencyContacts.map((c) {
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isAr ? 'جاري الاتصال بـ ${c.$2}' : 'Calling ${c.$2}...'),
                      backgroundColor: c.$4,
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.$4.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.$4.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(c.$3, color: c.$4, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(c.$1, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: c.$4)),
                              Text(c.$2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                            ],
                          ),
                        ),
                        Icon(Icons.phone, color: c.$4.withOpacity(0.7), size: 16),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Exit guide
            Text(
              isAr ? 'دليل مخارج الطوارئ' : 'Emergency Exit Guide',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...exits.map((exit) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(exit.$3, color: Colors.orange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exit.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(exit.$2, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange),
                    ],
                  ),
                )),
            const SizedBox(height: 20),

            // Safety tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Colors.red, size: 20),
                      const SizedBox(width: 6),
                      Text(isAr ? 'نصائح السلامة' : 'Safety Tips',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...(isAr
                          ? [
                              'ابتعد عن الأبواب أثناء حركة القطار',
                              'تمسك بالحواجز الأمامية داخل القطار',
                              'في حالة حريق، لا تستخدم المصعد',
                              'اتجه لفتحة الطوارئ المجاورة',
                              'أبلغ عن أي أمتعة مشبوهة فوراً',
                            ]
                          : [
                              'Stay away from doors while the train is moving',
                              'Hold the handrails inside the train',
                              'In case of fire, never use the elevator',
                              'Head to the nearest emergency exit',
                              'Report any suspicious baggage immediately',
                            ])
                      .map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('⚠️ ', style: TextStyle(fontSize: 13)),
                              Expanded(child: Text(tip, style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
