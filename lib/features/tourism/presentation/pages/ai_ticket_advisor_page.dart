import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/connectivity_service.dart';
import '../../../../core/utils/gemini_ai_service.dart';
import '../../../../core/widgets/offline_banner.dart';

class AiTicketAdvisorPage extends StatefulWidget {
  const AiTicketAdvisorPage({super.key});

  @override
  State<AiTicketAdvisorPage> createState() => _AiTicketAdvisorPageState();
}

class _AiTicketAdvisorPageState extends State<AiTicketAdvisorPage> {
  double _tripsPerWeek = 10;
  double _stationsPerTrip = 8;
  String _userCategory = 'regular';
  
  bool _isLoading = false;
  String? _errorMessage;

  // Advisor Result details
  int? _monthlyCostSingle;
  int? _monthlyCostAdvisor;
  int? _savings;
  String? _recTitleAr;
  String? _recTitleEn;
  String? _recDescAr;
  String? _recDescEn;
  String? _howToGetAr;
  String? _howToGetEn;

  final Map<String, String> _categoriesAr = {
    'regular': 'عادي (جمهور)',
    'student': 'طالب (مدارس وجامعات)',
    'senior60': 'كبار سن (60-70 سنة)',
    'senior70': 'كبار سن (فوق 70 سنة - مجاني غالباً)',
    'special': 'ذوي الاحتياجات الخاصة',
  };

  final Map<String, String> _categoriesEn = {
    'regular': 'Regular (Public)',
    'student': 'Student',
    'senior60': 'Senior (60-70 Years)',
    'senior70': 'Senior (70+ Years)',
    'special': 'Special Needs',
  };

  Map<String, dynamic> _calculateOfflineAdvice(int tripsPerWeek, int stationsPerTrip, String category) {
    // 1. Calculate price of single ticket
    int ticketPrice = 10;
    if (stationsPerTrip <= 9) {
      ticketPrice = 10;
    } else if (stationsPerTrip <= 16) {
      ticketPrice = 13;
    } else if (stationsPerTrip <= 23) {
      ticketPrice = 17;
    } else {
      ticketPrice = 20;
    }

    // 2. Calculate monthly trips (4 weeks)
    int monthlyTrips = tripsPerWeek * 4;
    int monthlyCostSingle = ticketPrice * monthlyTrips;

    // 3. Recommend subscription based on category
    int monthlyCostAdvisor = monthlyCostSingle;
    String recTitleAr = "خليك على التذاكر الفردية";
    String recTitleEn = "Stick to Single Tickets";
    String recDescAr = "بناءً على معدل استخدامك الخفيف، التذاكر الفردية هي الأوفر ليك حالياً.";
    String recDescEn = "Based on your low usage, single tickets are the most cost-effective for you.";
    String howToGetAr = "اشتري تذكرة فردية من الشباك أو ماكينات TVM قبل كل رحلة.";
    String howToGetEn = "Buy single tickets from the counter or TVM machines before each trip.";

    // Subscriptions logic
    if (category == 'student') {
      if (monthlyCostSingle > 150) {
        monthlyCostAdvisor = 150;
        recTitleAr = "الاشتراك الطلابي هو الأوفر! 🎓";
        recTitleEn = "Student Subscription is Best! 🎓";
        recDescAr = "بما إنك طالب، تقدر تعمل اشتراك ربع سنوي (3 شهور) مخفض جداً. تكلفة الشهر هتقف عليك بحوالي 150 جنيه بدلاً من $monthlyCostSingle جنيه.";
        recDescEn = "As a student, you can get a highly discounted subscription. The monthly share is about 150 EGP instead of $monthlyCostSingle EGP.";
        howToGetAr = "توجه لمكتب الاشتراكات بالمحطة، واسحب استمارة اشتراك طلبة، واختمها من مدرستك أو كليتك وقدمها مع صورتين شخصيتين.";
        howToGetEn = "Go to the subscription office, get a student form, stamp it from your school/university, and submit with two photos.";
      }
    } else if (category == 'senior70') {
      monthlyCostAdvisor = 0;
      recTitleAr = "الركوب المجاني لكبار السن! 👵👴";
      recTitleEn = "Free Ride for Seniors 70+! 👵👴";
      recDescAr = "المواطنين فوق سن 70 سنة ليهم حق الركوب المجاني تماماً في جميع الخطوط بموجب بطاقة الرقم القومي.";
      recDescEn = "Seniors over 70 can ride completely free on all lines by presenting their National ID.";
      howToGetAr = "اظهر بطاقتك الشخصية السارية لموظف بوابة العبور للمرور مجاناً.";
      howToGetEn = "Show your valid National ID to the gate officer to pass for free.";
    } else if (category == 'senior60') {
      monthlyCostAdvisor = (monthlyCostSingle * 0.5).round();
      recTitleAr = "اشتراك كبار السن (خصم 50%) 👴";
      recTitleEn = "Senior Subscription (50% Off) 👴";
      recDescAr = "كبار السن (من 60 لـ 70 سنة) ليهم خصم 50% على التذاكر والاشتراكات. التكلفة الشهرية هتكون حوالي $monthlyCostAdvisor جنيه بدلاً من $monthlyCostSingle جنيه.";
      recDescEn = "Seniors (60-70 years) get a 50% discount. The monthly cost will be around $monthlyCostAdvisor EGP instead of $monthlyCostSingle EGP.";
      howToGetAr = "توجه لمكتب الاشتراكات وقدم صورة بطاقة الرقم القومي لإثبات السن واستخراج كارت كبار السن المخفض.";
      howToGetEn = "Go to the subscription office and present a copy of your National ID to issue the discounted senior card.";
    } else if (category == 'special') {
      monthlyCostAdvisor = 50;
      if (monthlyCostSingle > 50) {
        recTitleAr = "اشتراك ذوي الهمم المميز! ♿";
        recTitleEn = "Special Needs Subscription! ♿";
        recDescAr = "ذوي الاحتياجات الخاصة ليهم اشتراك شهري رمزي جداً (حوالي 50 جنيه لـ 180 رحلة). التكلفة الشهرية $monthlyCostAdvisor جنيه بدلاً من $monthlyCostSingle جنيه.";
        recDescEn = "Special needs users get a symbolic monthly subscription (around 50 EGP for 180 trips). The monthly cost is $monthlyCostAdvisor EGP instead of $monthlyCostSingle EGP.";
        howToGetAr = "قدم كارنيه وزارة التضامن الاجتماعي (كارت الخدمات المتكاملة) لمكتب الاشتراكات مع صورتين شخصيتين.";
        howToGetEn = "Present your Ministry of Social Solidarity card (Integrated Services Card) to the subscription office with two photos.";
      }
    } else {
      if (monthlyTrips > 20) {
        int subscriptionCost = 230;
        if (stationsPerTrip <= 9) subscriptionCost = 230;
        else if (stationsPerTrip <= 16) subscriptionCost = 290;
        else if (stationsPerTrip <= 23) subscriptionCost = 380;
        else subscriptionCost = 450;

        if (monthlyCostSingle > subscriptionCost) {
          monthlyCostAdvisor = subscriptionCost;
          recTitleAr = "الاشتراك الشهري الذكي (60 رحلة) 💳";
          recTitleEn = "Smart Monthly Subscription (60 Trips) 💳";
          recDescAr = "بما إنك بتسافر كتير، اشتراك الـ 60 رحلة الشهري هو الأوفر ليك. هيكلفك حوالي $subscriptionCost جنيه بدلاً من $monthlyCostSingle جنيه.";
          recDescEn = "Since you travel frequently, the 60-trip monthly subscription is best. It will cost around $subscriptionCost EGP instead of $monthlyCostSingle EGP.";
          howToGetAr = "توجه لمكتب الاشتراكات في أي محطة رئيسية (مثل السادات، العتبة، رمسيس) واطلب استمارة اشتراك جمهور، وادفع الرسوم لاستلام الكارت الذكي.";
          howToGetEn = "Go to the subscription office at any major station (like Sadat, Attaba, Ramses) and apply for a public subscription card.";
        }
      }
    }

    int savings = (monthlyCostSingle - monthlyCostAdvisor).clamp(0, 9999);

    return {
      "monthlyCostSingle": monthlyCostSingle,
      "monthlyCostAdvisor": monthlyCostAdvisor,
      "savings": savings,
      "recTitleAr": recTitleAr,
      "recTitleEn": recTitleEn,
      "recDescAr": recDescAr,
      "recDescEn": recDescEn,
      "howToGetAr": howToGetAr,
      "howToGetEn": howToGetEn,
    };
  }

  Future<void> _calculateAdvice(bool isAr) async {
    if (ConnectivityService.instance.isOffline) {
      final offlineResult = _calculateOfflineAdvice(
        _tripsPerWeek.round(),
        _stationsPerTrip.round(),
        _userCategory,
      );
      setState(() {
        _isLoading = false;
        _errorMessage = isAr 
            ? "💡 وضع أوفلاين: تم الحساب محلياً بدقة!" 
            : "💡 Offline Mode: Calculated locally successfully!";
        _monthlyCostSingle = offlineResult['monthlyCostSingle'];
        _monthlyCostAdvisor = offlineResult['monthlyCostAdvisor'];
        _savings = offlineResult['savings'];
        _recTitleAr = offlineResult['recTitleAr'];
        _recTitleEn = offlineResult['recTitleEn'];
        _recDescAr = offlineResult['recDescAr'];
        _recDescEn = offlineResult['recDescEn'];
        _howToGetAr = offlineResult['howToGetAr'];
        _howToGetEn = offlineResult['howToGetEn'];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _monthlyCostSingle = null;
    });

    try {
      final model = GeminiAiService.getModel();
      final categoryText = _categoriesEn[_userCategory] ?? _userCategory;

      final prompt = 
          "You are 'Rafiq' Cairo Metro AI Adviser. Determine the absolute cheapest ticket/subscription option for this user:\n"
          "- Weekly trips count: ${_tripsPerWeek.round()}\n"
          "- Average stations crossed per trip: ${_stationsPerTrip.round()}\n"
          "- User status: $categoryText\n\n"
          "Use the 2026 official Cairo metro pricing decrees:\n"
          "Single tickets cost: <=9 stations: 10 EGP, <=16 stations: 13 EGP, <=23 stations: 17 EGP, >23 stations: 20 EGP.\n"
          "Subscriptions: Students, Seniors, and Special Needs get extreme discounts (e.g. Student monthly subscription is around 120-150 EGP for regular zones, Seniors 60-70 get 50% off, 70+ get free public passes, Special needs pay flat 50 EGP per month, etc.).\n\n"
          "Calculate estimated monthly cost using normal single tickets vs recommended subscription/card. Return ONLY a raw JSON response. Do not use markdown enclosures like ```json. The JSON structure MUST be:\n"
          "{\n"
          "  \"monthlyCostSingle\": 280,\n"
          "  \"monthlyCostAdvisor\": 130,\n"
          "  \"savings\": 150,\n"
          "  \"recTitleAr\": \"عنوان النصيحة بالعربية (مثلا الاشتراك الطلابي هو الأوفر!)\",\n"
          "  \"recTitleEn\": \"Recommendation Title in English\",\n"
          "  \"recDescAr\": \"وصف النصيحة بالتفصيل للأرقام والمقارنة بأسلوب مصري مرح وودود جداً\",\n"
          "  \"recDescEn\": \"Description in English\",\n"
          "  \"howToGetAr\": \"الخطوات المطلوبة لعمل هذا الاشتراك بالتفصيل من شباك التذاكر بالعربية\",\n"
          "  \"howToGetEn\": \"Detailed steps to get this subscription in English\"\n"
          "}";

      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = response.text?.trim() ?? '';

      // Extract JSON using regex for maximum robustness
      final jsonRegex = RegExp(r'\{[\s\S]*\}');
      final match = jsonRegex.firstMatch(rawText);
      if (match == null) throw Exception("No JSON block found in response");
      final cleanJson = match.group(0)!;
      final Map<String, dynamic> data = json.decode(cleanJson);

      setState(() {
        _isLoading = false;
        _monthlyCostSingle = data['monthlyCostSingle'];
        _monthlyCostAdvisor = data['monthlyCostAdvisor'];
        _savings = data['savings'];
        _recTitleAr = data['recTitleAr'];
        _recTitleEn = data['recTitleEn'];
        _recDescAr = data['recDescAr'];
        _recDescEn = data['recDescEn'];
        _howToGetAr = data['howToGetAr'];
        _howToGetEn = data['howToGetEn'];
      });
    } catch (e) {
      debugPrint("❌ Ticket Advisor Error: $e");
      
      // Dynamic fallback to offline local calculator so the user always gets their advice!
      final offlineResult = _calculateOfflineAdvice(
        _tripsPerWeek.round(),
        _stationsPerTrip.round(),
        _userCategory,
      );

      setState(() {
        _isLoading = false;
        _errorMessage = isAr 
            ? "⚠️ تم الحساب محلياً لعدم استقرار الاتصال بالذكاء الاصطناعي!" 
            : "⚠️ Calculated locally due to AI service connection instability!";
        _monthlyCostSingle = offlineResult['monthlyCostSingle'];
        _monthlyCostAdvisor = offlineResult['monthlyCostAdvisor'];
        _savings = offlineResult['savings'];
        _recTitleAr = offlineResult['recTitleAr'];
        _recTitleEn = offlineResult['recTitleEn'];
        _recDescAr = offlineResult['recDescAr'];
        _recDescEn = offlineResult['recDescEn'];
        _howToGetAr = offlineResult['howToGetAr'];
        _howToGetEn = offlineResult['howToGetEn'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    final activeCategories = isAr ? _categoriesAr : _categoriesEn;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(isAr ? "مستشار التذاكر بالـ AI 💳" : "AI Ticket Advisor 💳"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OfflineBanner(),
                const SizedBox(height: 10),

                // Config Input Form Card
                Card(
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? "احسب ووفر مع رفيق" : "Calculate & Save with Rafiq",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dropdown Category
                        DropdownButtonFormField<String>(
                          value: _userCategory,
                          decoration: InputDecoration(
                            labelText: isAr ? "فئتك في المترو" : "User Category",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: activeCategories.entries.map((e) {
                            return DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(e.value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _userCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Weekly Trips Slider
                        Text(
                          '${isAr ? "عدد الرحلات في الأسبوع" : "Weekly Trips"}: ${_tripsPerWeek.round()}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Slider(
                          value: _tripsPerWeek,
                          min: 1,
                          max: 14,
                          divisions: 13,
                          activeColor: AppColors.primary,
                          label: '${_tripsPerWeek.round()}',
                          onChanged: (val) {
                            setState(() => _tripsPerWeek = val);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Stations Per Trip Slider
                        Text(
                          '${isAr ? "متوسط عدد المحطات في الرحلة" : "Avg Stations Crossed"}: ${_stationsPerTrip.round()}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Slider(
                          value: _stationsPerTrip,
                          min: 1,
                          max: 30,
                          divisions: 29,
                          activeColor: Colors.blue,
                          label: '${_stationsPerTrip.round()}',
                          onChanged: (val) {
                            setState(() => _stationsPerTrip = val);
                          },
                        ),
                        const SizedBox(height: 20),

                        // Button Calculate
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isLoading ? null : () => _calculateAdvice(isAr),
                            icon: _isLoading 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : const Icon(Icons.calculate_outlined),
                            label: Text(
                              _isLoading 
                                  ? (isAr ? "جاري احتساب التوفير..." : "Calculating Savings...")
                                  : (isAr ? "احسب ووفر 💸" : "Calculate & Optimize 💸"),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Error message
                if (_errorMessage != null)
                  FadeInUp(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Shimmer Loader
                if (_isLoading)
                  _buildLoaderSkeleton(),

                // Results Layout
                if (_monthlyCostSingle != null && !_isLoading)
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Savings Card
                        Card(
                          elevation: 0,
                          color: Colors.green.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.green, width: 1.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text(
                                  isAr ? "التوفير الشهري المتوقع" : "Expected Monthly Savings",
                                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '+$_savings EGP',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Comparison Chart
                        Card(
                          elevation: 0,
                          color: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? "مقارنة التكلفة الشهرية" : "Monthly Cost Comparison",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 20),
                                _buildComparisonBar(
                                  isAr ? "تذاكر عادية" : "Single Tickets",
                                  _monthlyCostSingle ?? 0,
                                  Colors.redAccent,
                                  _monthlyCostSingle!,
                                ),
                                const SizedBox(height: 16),
                                _buildComparisonBar(
                                  isAr ? "عرض رفيق" : "Rafiq Advice",
                                  _monthlyCostAdvisor ?? 0,
                                  Colors.green,
                                  _monthlyCostSingle!,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recommendation Detail Card
                        Card(
                          elevation: 0,
                          color: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ((isAr ? _recTitleAr : _recTitleEn) ?? ''),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Text(
                                  ((isAr ? _recDescAr : _recDescEn) ?? ''),
                                  style: const TextStyle(fontSize: 13.5, height: 1.5),
                                ),
                                if (_howToGetAr != null && _howToGetAr!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    isAr ? "💡 إزاي تعمل الاشتراك ده؟" : "💡 How to get this subscription?",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ((isAr ? _howToGetAr : _howToGetEn) ?? ''),
                                    style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.4),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBar(String label, int val, Color color, int maxVal) {
    final pct = maxVal > 0 ? (val / maxVal).clamp(0.1, 1.0) : 0.1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$val EGP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoaderSkeleton() {
    return FadeInUp(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }
}
