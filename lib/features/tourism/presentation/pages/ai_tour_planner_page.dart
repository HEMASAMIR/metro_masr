import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/connectivity_service.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/gemini_ai_service.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../metro/domain/entities/station.dart';
import '../../../../core/utils/ad_service.dart';

class AiTourPlannerPage extends StatefulWidget {
  const AiTourPlannerPage({super.key});

  @override
  State<AiTourPlannerPage> createState() => _AiTourPlannerPageState();
}

class _AiTourPlannerPageState extends State<AiTourPlannerPage> {
  Station? _selectedStation;
  double _budget = 150;
  double _hours = 4;
  final List<String> _selectedInterests = ['historical'];
  
  bool _isLoading = false;
  bool _isAdLoaded = false;
  String? _errorMessage;
  BannerAd? _bannerAd;

  // Plan Details
  int? _totalCost;
  double? _totalDuration;
  String? _summaryAr;
  String? _summaryEn;
  List<Map<String, dynamic>> _timeline = [];

  final List<Station> _allStations = [];

  @override
  void initState() {
    super.initState();
    _bannerAd = AdService.createBannerAd(
      onAdLoaded: (ad) {
        if (mounted) setState(() => _isAdLoaded = true);
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
            _bannerAd = null;
          });
        }
      },
    );
    // Load and sort stations
    _allStations.addAll(MetroData.stations.values);
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        if (_selectedInterests.length > 1) {
          _selectedInterests.remove(interest);
        }
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  void _onPlanPressed(bool isAr) {
    if (_selectedStation == null) {
      setState(() {
        _errorMessage = isAr ? "من فضلك اختار محطة البداية أولاً! 🚇" : "Please select a starting station first! 🚇";
      });
      return;
    }
    AdService.showInterstitialAd(() {
      _generateItinerary(isAr);
    });
  }

  Future<void> _generateItinerary(bool isAr) async {
    if (_selectedStation == null) {
      setState(() {
        _errorMessage = isAr ? "من فضلك اختار محطة البداية أولاً! 🚇" : "Please select a starting station first! 🚇";
      });
      return;
    }

    if (ConnectivityService.instance.isOffline) {
      setState(() {
        _errorMessage = isAr 
            ? "الخدمة دي محتاجة اتصال بالإنترنت لتخطيط الرحلة بالذكاء الاصطناعي! 🌐" 
            : "This service requires an active internet connection to plan your trip! 🌐";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _timeline.clear();
    });

    try {
      final model = GeminiAiService.getModel();
      final interestsString = _selectedInterests.map((e) {
        switch (e) {
          case 'historical': return 'Historical & Cultural Monuments';
          case 'nature': return 'Parks & Outdoors';
          case 'food': return 'Restaurants & Egyptian Street Food';
          case 'entertainment': return 'Art, Theaters & Entertainment';
          case 'shopping': return 'Khan El Khalili & Modern Shopping';
          default: return e;
        }
      }).join(', ');

      final prompt = 
          "You are 'Rafiq' Cairo Metro AI Tour Guide. Plan a custom tourist itinerary in Cairo, Egypt.\n"
          "Starting station: ${_selectedStation!.nameEn} (${_selectedStation!.nameAr}).\n"
          "Budget: ${_budget.round()} EGP.\n"
          "Available Duration: ${_hours.round()} hours.\n"
          "Interests: $interestsString.\n\n"
          "Create a sequential, timed trip itinerary utilizing Cairo Metro lines for transportation. "
          "Return ONLY a raw JSON response. Do not use any markdown enclosure like ```json or backticks. The JSON structure MUST be:\n"
          "{\n"
          "  \"totalCost\": 120,\n"
          "  \"totalDurationHours\": 4.5,\n"
          "  \"summaryAr\": \"ملخص بلغة مصرية خفيفة الظل ومرحة للفسحة ونقاطها البارزة\",\n"
          "  \"summaryEn\": \"Brief interesting tour description in English\",\n"
          "  \"timeline\": [\n"
          "    {\n"
          "      \"time\": \"10:00 AM - 11:00 AM\",\n"
          "      \"titleAr\": \"اسم الخطوة أو المكان بالعربية\",\n"
          "      \"titleEn\": \"Step name in English\",\n"
          "      \"descAr\": \"نصائح ووصف رفيق للخطوة بالعربية (مثلا زيارة المعلم الفلاني أو ركوب مترو الخط التالت)\",\n"
          "      \"descEn\": \"Rafiq instructions and details in English\",\n"
          "      \"stationAr\": \"المحطة المستخدمة للخطوة دي\",\n"
          "      \"stationEn\": \"Associated metro station in English\",\n"
          "      \"costEgp\": 15,\n"
          "      \"icon\": \"museum\"\n"
          "    }\n"
          "  ]\n"
          "}\n"
          "Icon must be one of: train, museum, restaurant, park, theater, shopping, landmark.";

      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = response.text?.trim() ?? '';

      String cleanJson = rawText;
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```(json)?|```$'), '').trim();
      }

      final Map<String, dynamic> data = json.decode(cleanJson);

      setState(() {
        _isLoading = false;
        _totalCost = data['totalCost'];
        _totalDuration = data['totalDurationHours'] != null ? double.tryParse(data['totalDurationHours'].toString()) : null;
        _summaryAr = data['summaryAr'];
        _summaryEn = data['summaryEn'];
        
        if (data['timeline'] != null) {
          _timeline = List<Map<String, dynamic>>.from(data['timeline']);
        }
      });
    } catch (e) {
      debugPrint("❌ Tour Planner Error: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = isAr 
            ? "حصل خطأ أثناء تخطيط الرحلة. جرب تختار محطة تانية أو قلل الوقت والطلبات!" 
            : "An error occurred while generating the plan. Try another station or adjust inputs!";
      });
    }
  }

  IconData _getTimelineIcon(String iconType) {
    switch (iconType) {
      case 'train': return Icons.directions_subway_rounded;
      case 'museum': return Icons.museum_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'park': return Icons.park_rounded;
      case 'theater': return Icons.theater_comedy_rounded;
      case 'shopping': return Icons.shopping_bag_outlined;
      case 'landmark': return Icons.location_on_outlined;
      default: return Icons.explore_outlined;
    }
  }

  Color _getTimelineIconColor(String iconType) {
    switch (iconType) {
      case 'train': return Colors.blue;
      case 'museum': return Colors.indigo;
      case 'restaurant': return Colors.green;
      case 'park': return Colors.teal;
      case 'theater': return Colors.deepPurple;
      case 'shopping': return Colors.pink;
      case 'landmark': return Colors.orange[800]!;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    
    // Sort stations dynamically based on active language
    final sortedStations = List<Station>.from(_allStations);
    sortedStations.sort((a, b) => (isAr ? a.nameAr : a.nameEn).compareTo(isAr ? b.nameAr : b.nameEn));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(isAr ? "مخطط خروجات الـ AI 🗺️" : "AI Tour Planner 🗺️"),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const OfflineBanner(),
                      const SizedBox(height: 10),

                      // Input config card
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
                                isAr ? "خطط فسحتك مع رفيق الذكي" : "Plan Your Tour with Rafiq",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Starting Station Dropdown
                              DropdownButtonFormField<Station>(
                                value: _selectedStation,
                                decoration: InputDecoration(
                                  labelText: isAr ? "محطة البداية 🚇" : "Starting Station 🚇",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: sortedStations.map((station) {
                                  return DropdownMenuItem<Station>(
                                    value: station,
                                    child: Text(isAr ? station.nameAr : station.nameEn),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedStation = val);
                                },
                              ),
                              const SizedBox(height: 16),

                              // Time Slider
                              Text(
                                '${isAr ? "المدة المتاحة للفسحة" : "Available Time"}: ${_hours.round()} ${isAr ? "ساعات" : "hours"}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Slider(
                                value: _hours,
                                min: 2,
                                max: 12,
                                divisions: 10,
                                activeColor: AppColors.primary,
                                label: '${_hours.round()}',
                                onChanged: (val) {
                                  setState(() => _hours = val);
                                },
                              ),
                              const SizedBox(height: 8),

                              // Budget Slider
                              Text(
                                '${isAr ? "الميزانية المتوقعة" : "Expected Budget"}: ${_budget.round()} EGP',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Slider(
                                value: _budget,
                                min: 50,
                                max: 1000,
                                divisions: 19,
                                activeColor: Colors.green,
                                label: '${_budget.round()} EGP',
                                onChanged: (val) {
                                  setState(() => _budget = val);
                                },
                              ),
                              const SizedBox(height: 16),

                              // Interests Chips
                              Text(
                                isAr ? "اهتماماتك في الخروجة 🤩" : "Your Interests 🤩",
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildInterestChip('historical', isAr ? "🏛️ آثار وتاريخ" : "🏛️ History", isAr),
                                  _buildInterestChip('nature', isAr ? "🌳 منتزهات" : "🌳 Parks", isAr),
                                  _buildInterestChip('food', isAr ? "🍔 أكل وكافيهات" : "🍔 Food/Cafes", isAr),
                                  _buildInterestChip('entertainment', isAr ? "🎭 ترفيه وفنون" : "🎭 Entertainment", isAr),
                                  _buildInterestChip('shopping', isAr ? "🛍️ تسوق ومحلات" : "🛍️ Shopping", isAr),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Trigger button
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
                                  onPressed: _isLoading ? null : () => _onPlanPressed(isAr),
                                  icon: _isLoading 
                                      ? const SizedBox(
                                          width: 20, 
                                          height: 20, 
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                        )
                                      : const Icon(Icons.auto_awesome_rounded),
                                  label: Text(
                                    _isLoading 
                                        ? (isAr ? "جاري التخطيط الذكي..." : "Planning Trip...")
                                        : (isAr ? "خطط فسحتي ✨" : "Plan My Trip ✨"),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Error Message
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

                      // Loader Skeleton Shimmer
                      if (_isLoading)
                        _buildLoaderSkeleton(isAr),

                      // Planned Itinerary Details
                      if (_timeline.isNotEmpty && !_isLoading)
                        FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Summary Title Card
                              Card(
                                elevation: 0,
                                color: AppColors.primary.withOpacity(0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: AppColors.primary, width: 1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildSummaryStats(
                                            Icons.payments_outlined, 
                                            isAr ? "التكلفة التقديرية" : "Estimated Cost",
                                            '${_totalCost ?? 0} EGP',
                                            Colors.green,
                                          ),
                                          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
                                          _buildSummaryStats(
                                            Icons.access_time_rounded, 
                                            isAr ? "المدة الإجمالية" : "Total Duration",
                                            '${_totalDuration ?? _hours.round()} ${isAr ? "ساعات" : "hrs"}',
                                            Colors.blue,
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),
                                      Text(
                                        (isAr ? _summaryAr : _summaryEn) ?? '',
                                        style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),

                              // Vertical Timeline
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _timeline.length,
                                itemBuilder: (context, index) {
                                  final step = _timeline[index];
                                  final iconType = step['icon'] ?? 'explore';
                                  final time = step['time'] ?? '';
                                  final title = (isAr ? step['titleAr'] : step['titleEn']) ?? '';
                                  final desc = (isAr ? step['descAr'] : step['descEn']) ?? '';
                                  final station = (isAr ? step['stationAr'] : step['stationEn']) ?? '';
                                  final cost = step['costEgp'] ?? 0;

                                  final isLast = index == _timeline.length - 1;

                                  return IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Timeline Line & Dot Indicator
                                        Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: _getTimelineIconColor(iconType).withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _getTimelineIcon(iconType),
                                                color: _getTimelineIconColor(iconType),
                                                size: 20,
                                              ),
                                            ),
                                            if (!isLast)
                                              Expanded(
                                                child: Container(
                                                  width: 2,
                                                  color: Colors.grey.withOpacity(0.3),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),

                                        // Timeline Step Card
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 20.0),
                                            child: Card(
                                              elevation: 0,
                                              color: Theme.of(context).cardColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          time,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.grey[500],
                                                          ),
                                                        ),
                                                        if (cost > 0)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.green.withOpacity(0.15),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: Text(
                                                              '$cost EGP',
                                                              style: const TextStyle(
                                                                color: Colors.green,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                               ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      title,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      desc,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: Colors.grey[600],
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                    if (station.toString().isNotEmpty) ...[
                                                      const Divider(height: 16),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.directions_subway_outlined, size: 14, color: AppColors.primary),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            '${isAr ? "المحطة" : "Station"}: $station',
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: AppColors.primary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
          ),
          if (_bannerAd != null && _isAdLoaded)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
              ),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildInterestChip(String code, String label, bool isAr) {
    final isSelected = _selectedInterests.contains(code);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.25),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      onSelected: (_) => _toggleInterest(code),
    );
  }

  Widget _buildSummaryStats(IconData icon, String label, String val, Color iconCol) {
    return Column(
      children: [
        Icon(icon, color: iconCol, size: 24),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLoaderSkeleton(bool isAr) {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(3, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
