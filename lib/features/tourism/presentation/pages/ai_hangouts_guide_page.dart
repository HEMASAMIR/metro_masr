import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/connectivity_service.dart';
import '../../../../core/utils/metro_data.dart';
import '../../../../core/utils/gemini_ai_service.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../metro/domain/entities/station.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../ai_assistant/presentation/pages/ai_chat_page.dart';

class AiHangoutsGuidePage extends StatefulWidget {
  const AiHangoutsGuidePage({super.key});

  @override
  State<AiHangoutsGuidePage> createState() => _AiHangoutsGuidePageState();
}

class _AiHangoutsGuidePageState extends State<AiHangoutsGuidePage> {
  Station? _selectedStation;
  final TextEditingController _queryController = TextEditingController();

  bool _isLoading = false;
  bool _isLocating = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _places = [];

  final List<Station> _allStations = [];

  @override
  void initState() {
    super.initState();
    _allStations.addAll(MetroData.stations.values);
    _detectNearestStation();
  }

  Future<void> _detectNearestStation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _isLocating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      Station? nearest;
      double minDist = double.infinity;
      for (final station in _allStations) {
        final dist = _haversine(
          pos.latitude, pos.longitude,
          station.latitude, station.longitude,
        );
        if (dist < minDist) {
          minDist = dist;
          nearest = station;
        }
      }
      if (nearest != null && mounted) {
        setState(() {
          _selectedStation = nearest;
          _isLocating = false;
        });
      } else {
        setState(() => _isLocating = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _searchHangouts(bool isAr) async {
    final query = _queryController.text.trim();
    if (_selectedStation == null) {
      setState(() {
        _errorMessage = isAr ? "اختار محطة المترو الأول يا ريس! 🚇" : "Please select a metro station first! 🚇";
      });
      return;
    }

    if (ConnectivityService.instance.isOffline) {
      setState(() {
        _errorMessage = isAr 
            ? "الخدمة دي محتاجة اتصال بالإنترنت للبحث بالذكاء الاصطناعي! 🌐" 
            : "This feature requires an active internet connection to search outings! 🌐";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _places.clear();
    });

    try {
      final model = GeminiAiService.getModel();

      // If query is empty, ask AI for ALL types of nearby places
      final vibeSection = query.isNotEmpty
          ? "The user is specifically looking for: $query.\n"
          : "The user wants to explore EVERYTHING nearby. Suggest a diverse mix of: cafes, restaurants, malls/shopping centers, parks/gardens, gyms/sports clubs, cinemas, museums, cultural spots, and any other interesting hangout spots.\n";

      final prompt = 
          "You are 'Rafiq' Cairo Metro AI Hangouts Guide. Find real or highly accurate local venues and hangout spots within walking distance of this metro station:\n"
          "Metro Station: ${_selectedStation!.nameEn} (${_selectedStation!.nameAr}).\n"
          "$vibeSection\n"
          "Return 6 to 10 diverse places. Return ONLY a raw JSON response. Do not use markdown enclosures like ```json. The JSON structure MUST be exactly:\n"
          "{\n"
          "  \"places\": [\n"
          "    {\n"
          "      \"nameAr\": \"اسم المكان بالعربية\",\n"
          "      \"nameEn\": \"Place name in English\",\n"
          "      \"category\": \"cafe / restaurant / park / shopping / gym / cinema / museum / mall\",\n"
          "      \"descAr\": \"وصف دقيق وشيق بأسلوب رفيق المصري للجو العام وسعر التذكرة أو المشروبات ونوعية الخدمة\",\n"
          "      \"descEn\": \"Details in English\",\n"
          "      \"walkingMinutes\": 5,\n"
          "      \"avgCostEgp\": 80,\n"
          "      \"lat\": 30.0444,\n"
          "      \"lng\": 31.2357\n"
          "    }\n"
          "  ]\n"
          "}";

      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = response.text?.trim() ?? '';

      String cleanJson = rawText;
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```(json)?|```$'), '').trim();
      }

      final Map<String, dynamic> data = json.decode(cleanJson);
      
      setState(() {
        _isLoading = false;
        if (data['places'] != null) {
          _places = List<Map<String, dynamic>>.from(data['places']);
        }
        if (_places.isEmpty) {
          _errorMessage = isAr 
              ? "ملقناش خروجات مناسبة للطلب ده جنب المحطة دي. جرب تكتب كلمات تانية!" 
              : "No matches found near this station. Try writing other keywords!";
        }
      });
    } catch (e) {
      debugPrint("❌ Hangouts Guide Error: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = isAr 
            ? "حصلت مشكلة أثناء البحث الذكي. جرب تعيد البحث مجدداً!" 
            : "An error occurred during search. Please try again!";
      });
    }
  }

  void _openInMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _askRafiq(String placeName, bool isAr) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiChatPage(
          initialMessage: isAr 
              ? "قولي تفاصيل أكتر عن مكان '$placeName' وازاي أروحله بالمترو؟" 
              : "Tell me more about '$placeName' and how to go there by metro?",
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'cafe': return Icons.local_cafe_outlined;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'park': return Icons.park_outlined;
      case 'shopping': return Icons.shopping_bag_outlined;
      case 'mall': return Icons.store_mall_directory_outlined;
      case 'museum': return Icons.museum_outlined;
      case 'gym': return Icons.fitness_center_outlined;
      case 'cinema': return Icons.movie_outlined;
      default: return Icons.explore_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final isAr = context.locale.languageCode == 'ar';
    
    final sortedStations = List<Station>.from(_allStations);
    sortedStations.sort((a, b) => (isAr ? a.nameAr : a.nameEn).compareTo(isAr ? b.nameAr : b.nameEn));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(isAr ? "دليل الخروجات بالـ AI 🔍" : "AI Hangouts Guide 🔍"),
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

                // Search Box Card
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
                          isAr ? "اختار المحطة وهنجيبلك كل الأماكن الحلوة جنبها 🔥" : "Pick a station & discover everything nearby 🔥",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Auto-detected station chip
                        if (_isLocating)
                          Row(
                            children: [
                              const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? "جاري تحديد موقعك..." : "Detecting your location...",
                                style: const TextStyle(fontSize: 13, color: AppColors.primary),
                              ),
                            ],
                          )
                        else if (_selectedStation != null)
                          Row(
                            children: [
                              const Icon(Icons.my_location_rounded, color: Colors.green, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isAr
                                      ? "أقرب محطة: ${_selectedStation!.nameAr}"
                                      : "Nearest: ${_selectedStation!.nameEn}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _detectNearestStation,
                                child: Text(
                                  isAr ? "تحديث" : "Refresh",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        // Dropdown Selector (to override auto-detect)
                        DropdownButtonFormField<Station>(
                          value: _selectedStation,
                          decoration: InputDecoration(
                            labelText: isAr ? "أو اختار محطة يدوياً 🚇" : "Or select manually 🚇",
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

                        // Search Input (optional - to filter results)
                        TextField(
                          controller: _queryController,
                          decoration: InputDecoration(
                            labelText: isAr ? "عايز حاجة معينة؟ (اختياري)" : "Looking for something specific? (optional)",
                            hintText: isAr 
                                ? "سيبها فاضية وهنجيبلك كل حاجة، أو اكتب: كافيه، مول، سينما..."
                                : "Leave empty for all, or type: cafe, mall, cinema...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _queryController.text.isNotEmpty 
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setState(() => _queryController.clear()),
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _searchHangouts(isAr),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),

                        // Search Button
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
                            onPressed: _isLoading ? null : () => _searchHangouts(isAr),
                            icon: _isLoading 
                                ? const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : const Icon(Icons.radar_rounded),
                            label: Text(
                              _queryController.text.trim().isEmpty
                                  ? (isAr ? "اكتشف كل الأماكن 🚀" : "Discover All Places 🚀")
                                  : (isAr ? "ابحث عن خروجة 🚀" : "Find Outing 🚀"),
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

                // Loader Skeleton
                if (_isLoading)
                  _buildLoaderSkeleton(),

                // Results list
                if (_places.isNotEmpty && !_isLoading)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _places.length,
                    itemBuilder: (context, index) {
                      final place = _places[index];
                      final name = (isAr ? place['nameAr'] : place['nameEn']) ?? '';
                      final desc = (isAr ? place['descAr'] : place['descEn']) ?? '';
                      final cat = place['category'] ?? 'explore';
                      final minutes = place['walkingMinutes'] ?? 5;
                      final cost = place['avgCostEgp'] ?? 0;
                      final lat = double.tryParse(place['lat'].toString()) ?? 30.0444;
                      final lng = double.tryParse(place['lng'].toString()) ?? 31.2357;

                      return FadeInUp(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          color: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                // Title and Chips
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(_getCategoryIcon(cat), color: AppColors.primary, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$cost EGP',
                                            style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$minutes ${isAr ? "دقائق مشي" : "min"}',
                                            style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Text(
                                  desc,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () => _openInMaps(lat, lng),
                                        icon: const Icon(Icons.location_on_outlined, size: 16),
                                        label: Text(isAr ? "موقع الخريطة" : "View Map"),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary.withOpacity(0.1),
                                          foregroundColor: AppColors.primary,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () => _askRafiq(name, isAr),
                                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                        label: Text(isAr ? "اسأل رفيق" : "Ask Rafiq"),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaderSkeleton() {
    return FadeInUp(
      child: Column(
        children: List.generate(2, (idx) {
          return Container(
            height: 140,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }),
      ),
    );
  }

}
