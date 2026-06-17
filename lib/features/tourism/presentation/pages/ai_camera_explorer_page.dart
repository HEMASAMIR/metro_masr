import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/connectivity_service.dart';
import '../../../../core/utils/gemini_ai_service.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../ai_assistant/presentation/pages/ai_chat_page.dart';

class AiCameraExplorerPage extends StatefulWidget {
  const AiCameraExplorerPage({super.key});

  @override
  State<AiCameraExplorerPage> createState() => _AiCameraExplorerPageState();
}

class _AiCameraExplorerPageState extends State<AiCameraExplorerPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  String? _errorMessage;

  // Resolved landmark details
  bool _isLandmark = false;
  String? _nameAr;
  String? _nameEn;
  String? _descAr;
  String? _descEn;
  String? _nearestStationAr;
  String? _nearestStationEn;
  int? _walkingMinutes;
  String? _admissionAr;
  String? _admissionEn;
  String? _safetyTipsAr;
  String? _safetyTipsEn;
  double? _lat;
  double? _lng;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    if (ConnectivityService.instance.isOffline) {
      setState(() {
        _errorMessage = "offline_camera_error".tr() == "offline_camera_error"
            ? "الخدمة دي محتاجة اتصال بالإنترنت لتحليل الصور يا غالي! 🌐"
            : "offline_camera_error".tr();
      });
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) return;

      setState(() {
        _selectedImage = File(file.path);
        _isAnalyzing = true;
        _isLandmark = false;
      });

      await _analyzeImage();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = "error_picking_image".tr() == "error_picking_image"
            ? "حصل مشكلة أثناء اختيار الصورة. جرب تاني!"
            : "error_picking_image".tr();
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final model = GeminiAiService.getModel();

      final prompt = [
        Content.multi([
          TextPart(
            "You are 'Rafiq' Cairo Metro AI Tour Guide. Analyze this image. If it is a Cairo/Egypt landmark or any historical/tourist place in Egypt, identify it. "
            "Return a JSON response only. If it is not a landmark or place in Egypt, set 'isLandmark' to false. Otherwise set it to true and fill the fields:\n"
            "{\n"
            "  \"isLandmark\": true,\n"
            "  \"nameAr\": \"اسم المعلم بالعربية دقيق ومحدد\",\n"
            "  \"nameEn\": \"Exact landmark name in English\",\n"
            "  \"descriptionAr\": \"وصف تاريخي مفصل وشيق بأسلوب مصري ودود (3-4 جمل)\",\n"
            "  \"descriptionEn\": \"Detailed historical description in English\",\n"
            "  \"nearestStationAr\": \"أقرب محطة مترو للمكان ده\",\n"
            "  \"nearestStationEn\": \"Nearest metro station in English\",\n"
            "  \"walkingMinutes\": 10,\n"
            "  \"admissionAr\": \"سعر تذكرة الدخول بالتفصيل للمصريين والأجانب والطلبة\",\n"
            "  \"admissionEn\": \"Ticket admission details in English\",\n"
            "  \"safetyTipsAr\": \"نصيحة هامة أو سرية للزيارة بأسلوب ابن بلد ودود\",\n"
            "  \"safetyTipsEn\": \"Safety tip/insight in English\",\n"
            "  \"lat\": 30.0444,\n"
            "  \"lng\": 31.2357\n"
            "}\n"
            "Ensure the response is raw JSON only, without any markdown enclosing like ```json or backticks."
          ),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(prompt);
      final rawText = response.text?.trim() ?? '';

      // Clean up markdown block if model ignored request
      String cleanJson = rawText;
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```(json)?|```$'), '').trim();
      }

      final Map<String, dynamic> data = json.decode(cleanJson);

      setState(() {
        _isAnalyzing = false;
        _isLandmark = data['isLandmark'] ?? false;
        if (_isLandmark) {
          _nameAr = data['nameAr'];
          _nameEn = data['nameEn'];
          _descAr = data['descriptionAr'];
          _descEn = data['descriptionEn'];
          _nearestStationAr = data['nearestStationAr'];
          _nearestStationEn = data['nearestStationEn'];
          _walkingMinutes = data['walkingMinutes'];
          _admissionAr = data['admissionAr'];
          _admissionEn = data['admissionEn'];
          _safetyTipsAr = data['safetyTipsAr'];
          _safetyTipsEn = data['safetyTipsEn'];
          _lat = data['lat'] != null ? double.tryParse(data['lat'].toString()) : null;
          _lng = data['lng'] != null ? double.tryParse(data['lng'].toString()) : null;
        } else {
          _errorMessage = "not_landmark_error".tr() == "not_landmark_error"
              ? "يا ريس، دي متظهرش إنها معلم سياحي أو مكان في مصر. جرب تصور مكان تاني أو محطة مترو! 🏛️"
              : "not_landmark_error".tr();
        }
      });
    } catch (e) {
      debugPrint("❌ Camera Explorer Error: $e");
      setState(() {
        _isAnalyzing = false;
        _errorMessage = "analysis_failed_error".tr() == "analysis_failed_error"
            ? "رفيق مقدرش يتعرف على الصورة دي. اتأكد من جودة الصورة والشبكة وجرب تاني! 🤖"
            : "analysis_failed_error".tr();
      });
    }
  }

  void _openInMaps() async {
    if (_lat == null || _lng == null) return;
    final url = 'https://www.google.com/maps/search/?api=1&query=$_lat,$_lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _askRafiq(bool isAr) {
    final name = isAr ? _nameAr : _nameEn;
    if (name == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiChatPage(
          initialMessage: isAr 
              ? "قولي معلومات زيادة عن $name وازاي اقضي يوم حلو هناك؟" 
              : "Tell me more about $name and how to enjoy a day there?",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(isAr ? "مستكشف المعالم بالـ AI 📸" : "AI Landmark Explorer 📸"),
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

                // Camera display/Trigger area
                GestureDetector(
                  onTap: _isAnalyzing ? null : () => _showPickerOptions(context, isAr),
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                                if (_isAnalyzing)
                                  Container(
                                    color: Colors.black54,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(height: 16),
                                          FadeInDown(
                                            duration: const Duration(seconds: 2),
                                            child: Text(
                                              isAr 
                                                  ? "🤖 رفيق بيحلل الصورة يسطا..."
                                                  : "🤖 Rafiq is analyzing photo...",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 60,
                                color: AppColors.primary.withOpacity(0.8),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isAr 
                                    ? "اضغط لتصوير أو اختيار معلم سياحي 🏛️"
                                    : "Tap to capture or pick a landmark 🏛️",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isAr 
                                    ? "برج القاهرة، المتحف، القلعة، الحسين..."
                                    : "Cairo Tower, Museum, Citadel, Hussein...",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
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
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Result content
                if (_isLandmark && !_isAnalyzing)
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Landmark Header Card
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
                                  (isAr ? _nameAr : _nameEn) ?? '',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  (isAr ? _descAr : _descEn) ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nearest station card
                        _buildDetailRow(
                          context,
                          Icons.train_rounded,
                          isAr ? "أقرب محطة مترو" : "Nearest Metro",
                          '${isAr ? _nearestStationAr : _nearestStationEn} (${_walkingMinutes ?? 0} ${isAr ? "دقائق مشي" : "min walk"})',
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),

                        // Ticket pricing card
                        _buildDetailRow(
                          context,
                          Icons.confirmation_number_outlined,
                          isAr ? "أسعار التذاكر" : "Admission Ticket",
                          (isAr ? _admissionAr : _admissionEn) ?? '',
                          Colors.green,
                        ),
                        const SizedBox(height: 12),

                        // Safety/Tips card
                        _buildDetailRow(
                          context,
                          Icons.tips_and_updates_outlined,
                          isAr ? "نصيحة رفيق" : "Rafiq's Tip",
                          (isAr ? _safetyTipsAr : _safetyTipsEn) ?? '',
                          Colors.amber[800]!,
                        ),
                        const SizedBox(height: 24),

                        // Interactive action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _openInMaps,
                                icon: const Icon(Icons.map_outlined),
                                label: Text(isAr ? "فتح الخريطة" : "Open Map"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => _askRafiq(isAr),
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                                label: Text(isAr ? "اسأل رفيق" : "Ask Rafiq"),
                              ),
                            ),
                          ],
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

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String title,
    String body,
    Color accentColor,
  ) {
    final isAr = context.locale.languageCode == 'ar';
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
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

  void _showPickerOptions(BuildContext context, bool isAr) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('📸', style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 10),
            Text(
              isAr ? "التقاط أو اختيار صورة" : "Capture or Pick Image",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: Text(isAr ? "الكاميرا" : "Camera"),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text(isAr ? "المعرض" : "Gallery"),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
