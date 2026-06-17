import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// معالج الأوامر الصوتية الذكي لرفيق
/// يدعم اللهجة المصرية (كلام بلدي) والإنجليزية
class VoiceCommandProcessor {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> handle(BuildContext context, String command) async {
    final text = command.toLowerCase().trim();
    final isAr = context.locale.languageCode == 'ar';

    // قاموس الكلمات المفتاحية الذكي (يدعم العامية المصرية والأجنبي)
    final Map<List<String>, String> navigationMap = {
      // الخريطة
      [
        'خريطة',
        'ماب',
        'الخريطه',
        'map',
        'الماب',
        'وريني الطريق',
        'الشبكة',
        'المحطات',
      ]: '/map',

      // الزحمة
      [
        'زحمة',
        'زحمه',
        'مزدحم',
        'توقعات',
        'crowd',
        'forecast',
        'الزحمة عاملة ايه',
        'المترو زحمة',
      ]: '/crowd_prediction',

      // التذاكر وحساب التكلفة
      [
        'تذكرة',
        'تذكره',
        'بكام',
        'أحسب',
        'احسب',
        'سعر',
        'fare',
        'ticket',
        'calculator',
        'التكلفة',
        'ادفع كام',
      ]: '/cost_calculator',

      // المفقودات
      [
        'مفقودات',
        'ضايع',
        'حاجة ضايعة',
        'لقيت',
        'lost',
        'found',
        'شنطة',
        'محفظة',
        'نسيت',
        'ضاع',
      ]: '/lost_found',

      // رفيق / المساعد الذكي
      ['رفيق', 'شات', 'ذكاء', 'كلم', 'chat', 'ai', 'assistant', 'بوت', 'اسأل']:
          '/ai_assistant',

      // الإنجازات
      [
        'نقط',
        'نقاط',
        'هدايا',
        'إنجازات',
        'points',
        'achievements',
        'level',
        'مستوايا',
        'كسبت',
        'جوايز',
      ]: '/achievements',

      // مخطط الرحلة
      [
        'مخطط',
        'رحلة',
        'اروح ازاي',
        'planner',
        'route',
        'trip',
        'ازاي اروح',
        'طريق',
      ]: '/route_planner',

      // تنبيهات الخطوط
      [
        'تنبيه',
        'اشعار',
        'alerts',
        'notifications',
        'حالة الخطوط',
        'الخط شغال',
        'متوقف',
        'عطل',
      ]: '/line_alerts',

      // أخبار
      ['اخبار', 'أخبار', 'news', 'المترو فيه ايه', 'جديد']: '/news',

      // إعدادات
      ['اعدادات', 'إعدادات', 'settings', 'لغة', 'مظهر', 'تغيير']: '/settings',

      // الكاميرا (بلاغات المفقودات والزحام)
      [
        'كاميرا',
        'كاميره',
        'camera',
        'صور',
        'تصوير',
        'افتح الكاميرا',
        'خد صورة',
      ]: '/lost_found',

      // وضع المكفوفين
      [
        'مكفوفين',
        'كفيف',
        'blind',
        'عصا',
        'وضع المكفوفين',
        'شغل وضع المكفوفين',
        'مساعدة صوتية',
      ]: '/blind_assist',

      // أماكن الترفيه والسياحة
      [
        'ترفيه',
        'فسحة',
        'خروجة',
        'خروجه',
        'سياحة',
        'tourism',
        'attractions',
        'places',
        'فسحني',
        'مطعم',
        'مطاعم',
        'كافيه',
        'جوعان',
        'food',
        'restaurant',
      ]: '/tourism',
    };

    String? targetRoute;
    for (var entry in navigationMap.entries) {
      if (entry.key.any((keyword) => text.contains(keyword))) {
        targetRoute = entry.value;
        break;
      }
    }

    if (targetRoute != null) {
      // رد صوتي سريع عشان اليوزر يعرف إننا فهمناه
      final response = isAr
          ? 'تمام، هفتحلك الصفحة دي حالاً'
          : 'Sure, navigating there now';
      await _respond(response, isAr);

      if (context.mounted) {
        // نستخدم pushNamed لسهولة التنقل
        Navigator.of(context).pushNamed(targetRoute).catchError((e) {
          debugPrint('Navigation error: Route $targetRoute not found.');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isAr
                      ? 'عذراً، لم أجد هذه الصفحة في التطبيق'
                      : 'Sorry, page not found',
                ),
              ),
            );
          }
          return null;
        });
      }
    } else {
      // إذا لم يتم التعرف على الأمر
      final fallback = isAr
          ? 'مش فاهم قصدك بالظبط، ممكن تقولي "افتح الخريطة" أو "التذكرة بكام"؟'
          : 'I didn\'t quite catch that. Try "Open map" or "How much is the ticket?".';
      await _respond(fallback, isAr);
    }
  }

  static Future<void> _respond(String message, bool isAr) async {
    await _tts.setLanguage(isAr ? "ar-EG" : "en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(message);
  }
}
