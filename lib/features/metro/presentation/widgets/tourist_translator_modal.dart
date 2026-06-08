import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';
import '../../../../core/utils/speech_service.dart';
import '../../../../core/utils/voice_service.dart';

class TouristTranslatorModal extends StatefulWidget {
  const TouristTranslatorModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TouristTranslatorModal(),
    );
  }

  @override
  State<TouristTranslatorModal> createState() => _TouristTranslatorModalState();
}

class _TouristTranslatorModalState extends State<TouristTranslatorModal> {
  bool _isListening = false;
  String _spokenText = '';
  String _translatedText = '';

  // ── القاموس الكامل English → Arabic ──────────────────────────────────────
  static const Map<String, String> _dict = {
    // ══════════════════════════════════════════════════════════════════════
    //  1. محطات المترو – كيف أروح؟  (كل محطات الخطوط 1 و2 و3)
    // ══════════════════════════════════════════════════════════════════════

    // ── خط 1 ──
    'how do i get to helwan': 'اركب الخط الأول واتجه جنوباً حتى محطة حلوان',
    'i want to go to helwan': 'اركب الخط الأول – آخر محطة جنوباً هي حلوان',
    'which line goes to helwan': 'الخط الأول يوصلك لحلوان',

    'how do i get to ain helwan':
        'اركب الخط الأول باتجاه حلوان، انزل محطة عين حلوان',
    'i want to go to ain helwan': 'اركب الخط الأول – محطة عين حلوان',

    'how do i get to helwan university':
        'اركب الخط الأول، انزل محطة جامعة حلوان',
    'i want to go to helwan university': 'اركب الخط الأول – محطة جامعة حلوان',

    'how do i get to wadi hof': 'اركب الخط الأول، انزل محطة وادي حوف',
    'i want to go to wadi hof': 'اركب الخط الأول – محطة وادي حوف',

    'how do i get to hadayek helwan': 'اركب الخط الأول، انزل محطة حدائق حلوان',
    'i want to go to hadayek helwan': 'اركب الخط الأول – محطة حدائق حلوان',

    'how do i get to el masra': 'اركب الخط الأول، انزل محطة المعصرة',
    'i want to go to el masra': 'اركب الخط الأول – محطة المعصرة',

    'how do i get to tora el asmant': 'اركب الخط الأول، انزل محطة طرة الإسمنت',
    'i want to go to tora el asmant': 'اركب الخط الأول – محطة طرة الإسمنت',

    'how do i get to kozzika': 'اركب الخط الأول، انزل محطة كوزيكا',
    'i want to go to kozzika': 'اركب الخط الأول – محطة كوزيكا',

    'how do i get to tora el balad': 'اركب الخط الأول، انزل محطة طرة البلد',
    'i want to go to tora el balad': 'اركب الخط الأول – محطة طرة البلد',

    'how do i get to sakanat el maadi':
        'اركب الخط الأول، انزل محطة سكن المعادي',
    'i want to go to sakanat el maadi': 'اركب الخط الأول – محطة سكن المعادي',

    'how do i get to maadi': 'اركب الخط الأول، انزل محطة المعادي',
    'i want to go to maadi': 'اركب الخط الأول – محطة المعادي',

    'how do i get to hadayek el maadi':
        'اركب الخط الأول، انزل محطة حدائق المعادي',
    'i want to go to hadayek el maadi': 'اركب الخط الأول – محطة حدائق المعادي',

    'how do i get to dar el salam': 'اركب الخط الأول، انزل محطة دار السلام',
    'i want to go to dar el salam': 'اركب الخط الأول – محطة دار السلام',

    'how do i get to el basatin': 'اركب الخط الأول، انزل محطة البساتين',
    'i want to go to el basatin': 'اركب الخط الأول – محطة البساتين',

    'how do i get to ibn tulun': 'اركب الخط الأول، انزل محطة ابن طولون',
    'i want to go to ibn tulun': 'اركب الخط الأول – محطة ابن طولون',

    'how do i get to al fustat': 'اركب الخط الأول، انزل محطة الفسطاط',
    'i want to go to al fustat': 'اركب الخط الأول – محطة الفسطاط',

    'how do i get to mar girgis': 'اركب الخط الأول، انزل محطة مار جرجس',
    'i want to go to mar girgis':
        'اركب الخط الأول – محطة مار جرجس – قريبة من الكنيسة المعلقة',

    'how do i get to el malek el saleh':
        'اركب الخط الأول، انزل محطة الملك الصالح',
    'i want to go to el malek el saleh': 'اركب الخط الأول – محطة الملك الصالح',

    'how do i get to sayyida zeinab': 'اركب الخط الأول، انزل محطة السيدة زينب',
    'i want to go to sayyida zeinab': 'اركب الخط الأول – محطة السيدة زينب',

    'how do i get to saad zaghloul': 'اركب الخط الأول، انزل محطة سعد زغلول',
    'i want to go to saad zaghloul': 'اركب الخط الأول – محطة سعد زغلول',

    'how do i get to sadat':
        'اركب الخط الأول أو الثاني، انزل محطة السادات – في ميدان التحرير',
    'i want to go to sadat':
        'اركب الخط الأول أو الثاني – محطة السادات – التحرير',
    'which line goes to sadat': 'الخط الأول والثاني كلاهما يوقف في السادات',

    'how do i get to nasser': 'اركب الخط الأول، انزل محطة ناصر',
    'i want to go to nasser': 'اركب الخط الأول – محطة ناصر',

    'how do i get to orabi': 'اركب الخط الأول، انزل محطة عرابي',
    'i want to go to orabi': 'اركب الخط الأول – محطة عرابي',

    'how do i get to al shohadaa':
        'اركب الخط الأول أو الثاني، انزل محطة الشهداء',
    'i want to go to al shohadaa': 'اركب الخط الأول أو الثاني – محطة الشهداء',

    'how do i get to ghamra': 'اركب الخط الأول، انزل محطة غمرة',
    'i want to go to ghamra': 'اركب الخط الأول – محطة غمرة',

    'how do i get to el demerdash': 'اركب الخط الأول، انزل محطة الدمرداش',
    'i want to go to el demerdash': 'اركب الخط الأول – محطة الدمرداش',

    'how do i get to manshiet el sadr':
        'اركب الخط الأول، انزل محطة منشية الصدر',
    'i want to go to manshiet el sadr': 'اركب الخط الأول – محطة منشية الصدر',

    'how do i get to kobri el qobba': 'اركب الخط الأول، انزل محطة كوبري القبة',
    'i want to go to kobri el qobba': 'اركب الخط الأول – محطة كوبري القبة',

    'how do i get to hammamat el qobba':
        'اركب الخط الأول، انزل محطة حمامات القبة',
    'i want to go to hammamat el qobba': 'اركب الخط الأول – محطة حمامات القبة',

    'how do i get to saray el qobba': 'اركب الخط الأول، انزل محطة سراي القبة',
    'i want to go to saray el qobba': 'اركب الخط الأول – محطة سراي القبة',

    'how do i get to hadayek el zeitoun':
        'اركب الخط الأول، انزل محطة حدائق الزيتون',
    'i want to go to hadayek el zeitoun':
        'اركب الخط الأول – محطة حدائق الزيتون',

    'how do i get to zeitoun': 'اركب الخط الأول، انزل محطة الزيتون',
    'i want to go to zeitoun': 'اركب الخط الأول – محطة الزيتون',

    'how do i get to heliopolis': 'اركب الخط الأول، انزل محطة مصر الجديدة',
    'i want to go to heliopolis': 'اركب الخط الأول – محطة مصر الجديدة',

    'how do i get to misr el gedida': 'اركب الخط الأول، انزل محطة مصر الجديدة',
    'i want to go to misr el gedida': 'اركب الخط الأول – محطة مصر الجديدة',

    'how do i get to el nozha': 'اركب الخط الأول، انزل محطة النزهة',
    'i want to go to el nozha': 'اركب الخط الأول – محطة النزهة',

    'how do i get to ain shams': 'اركب الخط الأول، انزل محطة عين شمس',
    'i want to go to ain shams': 'اركب الخط الأول – محطة عين شمس',

    'how do i get to ezbet el nakhl': 'اركب الخط الأول، انزل محطة عزبة النخل',
    'i want to go to ezbet el nakhl': 'اركب الخط الأول – محطة عزبة النخل',

    'how do i get to el marg': 'اركب الخط الأول، انزل محطة المرج',
    'i want to go to el marg': 'اركب الخط الأول – محطة المرج',

    'how do i get to new el marg':
        'اركب الخط الأول، انزل محطة المرج الجديدة – آخر محطة شمالاً',
    'i want to go to new el marg':
        'اركب الخط الأول – آخر محطة شمالاً هي المرج الجديدة',

    // ── خط 2 ──
    'how do i get to shubra el kheima':
        'اركب الخط الثاني، انزل محطة شبرا الخيمة – آخر محطة شمالاً',
    'i want to go to shubra el kheima':
        'اركب الخط الثاني – آخر محطة شمالاً هي شبرا الخيمة',

    'how do i get to kolleyyet el zeraah':
        'اركب الخط الثاني، انزل محطة كلية الزراعة',
    'i want to go to kolleyyet el zeraah':
        'اركب الخط الثاني – محطة كلية الزراعة',

    'how do i get to shubra': 'اركب الخط الثاني، انزل محطة شبرا',
    'i want to go to shubra': 'اركب الخط الثاني – محطة شبرا',

    'how do i get to st teresa': 'اركب الخط الثاني، انزل محطة سانت تيريزا',
    'i want to go to st teresa': 'اركب الخط الثاني – محطة سانت تيريزا',

    'how do i get to rod el farag': 'اركب الخط الثاني، انزل محطة روض الفرج',
    'i want to go to rod el farag': 'اركب الخط الثاني – محطة روض الفرج',

    'how do i get to massara': 'اركب الخط الثاني، انزل محطة مسرة',
    'i want to go to massara': 'اركب الخط الثاني – محطة مسرة',

    'how do i get to cairo university':
        'اركب الخط الثاني، انزل محطة جامعة القاهرة',
    'i want to go to cairo university': 'اركب الخط الثاني – محطة جامعة القاهرة',
    'which line goes to cairo university': 'الخط الثاني – محطة جامعة القاهرة',

    'how do i get to faisal': 'اركب الخط الثاني، انزل محطة فيصل',
    'i want to go to faisal': 'اركب الخط الثاني – محطة فيصل',

    'how do i get to giza': 'اركب الخط الثاني، انزل محطة الجيزة',
    'i want to go to giza': 'اركب الخط الثاني – محطة الجيزة',
    'which line goes to giza': 'الخط الثاني يوصلك لمحطة الجيزة',

    'how do i get to omm el masryeen':
        'اركب الخط الثاني، انزل محطة أم المصريين',
    'i want to go to omm el masryeen': 'اركب الخط الثاني – محطة أم المصريين',

    'how do i get to sakiat mekki': 'اركب الخط الثاني، انزل محطة ساقية مكي',
    'i want to go to sakiat mekki': 'اركب الخط الثاني – محطة ساقية مكي',

    'how do i get to el mounib':
        'اركب الخط الثاني، انزل محطة المنيب – آخر محطة جنوباً',
    'i want to go to el mounib': 'اركب الخط الثاني – آخر محطة جنوباً هي المنيب',

    'how do i get to opera': 'اركب الخط الثاني، انزل محطة الأوبرا',
    'i want to go to opera': 'اركب الخط الثاني – محطة الأوبرا',
    'which line goes to opera': 'الخط الثاني – محطة الأوبرا',

    'how do i get to dokki': 'اركب الخط الثاني، انزل محطة الدقي',
    'i want to go to dokki': 'اركب الخط الثاني – محطة الدقي',

    'how do i get to bohoos': 'اركب الخط الثاني، انزل محطة البحوث',
    'i want to go to bohoos': 'اركب الخط الثاني – محطة البحوث',

    'how do i get to el behoos': 'اركب الخط الثاني، انزل محطة البحوث',
    'how do i get to tahrir':
        'اركب الخط الأول أو الثاني، انزل محطة السادات في ميدان التحرير',
    'i want to go to tahrir':
        'اركب الخط الأول أو الثاني – محطة السادات – التحرير',
    'i want to go to tahrir square': 'اركب الخط الأول أو الثاني – محطة السادات',

    // ── خط 3 ──
    'how do i get to adly mansour':
        'اركب الخط الثالث، انزل محطة عدلي منصور – آخر محطة شرقاً',
    'i want to go to adly mansour':
        'اركب الخط الثالث – آخر محطة شرقاً هي عدلي منصور',
    'which line goes to adly mansour': 'الخط الثالث – محطة عدلي منصور',

    'how do i get to el haykestep': 'اركب الخط الثالث، انزل محطة الهايكستب',
    'i want to go to el haykestep': 'اركب الخط الثالث – محطة الهايكستب',

    'how do i get to omar ibn el khattab':
        'اركب الخط الثالث، انزل محطة عمر بن الخطاب',
    'i want to go to omar ibn el khattab':
        'اركب الخط الثالث – محطة عمر بن الخطاب',

    'how do i get to qobaa': 'اركب الخط الثالث، انزل محطة قبة',
    'i want to go to qobaa': 'اركب الخط الثالث – محطة قبة',

    'how do i get to hesham barakat': 'اركب الخط الثالث، انزل محطة هشام بركات',
    'i want to go to hesham barakat': 'اركب الخط الثالث – محطة هشام بركات',

    'how do i get to el nozha line 3': 'اركب الخط الثالث، انزل محطة النزهة',
    'how do i get to nozha': 'اركب الخط الثالث، انزل محطة النزهة',
    'i want to go to nozha': 'اركب الخط الثالث – محطة النزهة',

    'how do i get to nadi el shams': 'اركب الخط الثالث، انزل محطة نادي الشمس',
    'i want to go to nadi el shams': 'اركب الخط الثالث – محطة نادي الشمس',

    'how do i get to alf maskan': 'اركب الخط الثالث، انزل محطة ألف مسكن',
    'i want to go to alf maskan': 'اركب الخط الثالث – محطة ألف مسكن',

    'how do i get to heliopolis line 3':
        'اركب الخط الثالث، انزل محطة مصر الجديدة',
    'how do i get to haroun': 'اركب الخط الثالث، انزل محطة هارون',
    'i want to go to haroun': 'اركب الخط الثالث – محطة هارون',

    'how do i get to al ahram': 'اركب الخط الثالث، انزل محطة الأهرام',
    'i want to go to al ahram station': 'اركب الخط الثالث – محطة الأهرام',

    'how do i get to al kalaah': 'اركب الخط الثالث، انزل محطة القلعة',
    'i want to go to al kalaah':
        'اركب الخط الثالث – محطة القلعة – قريبة من قلعة صلاح الدين',

    'how do i get to abbassia': 'اركب الخط الثالث، انزل محطة العباسية',
    'i want to go to abbassia': 'اركب الخط الثالث – محطة العباسية',

    'how do i get to abdou basha': 'اركب الخط الثالث، انزل محطة عبده باشا',
    'i want to go to abdou basha': 'اركب الخط الثالث – محطة عبده باشا',

    'how do i get to el geish': 'اركب الخط الثالث، انزل محطة الجيش',
    'i want to go to el geish': 'اركب الخط الثالث – محطة الجيش',

    'how do i get to bab el shaaria': 'اركب الخط الثالث، انزل محطة باب الشعرية',
    'i want to go to bab el shaaria': 'اركب الخط الثالث – محطة باب الشعرية',

    'how do i get to attaba': 'اركب الخط الثالث، انزل محطة العتبة',
    'i want to go to attaba': 'اركب الخط الثالث – محطة العتبة',

    'how do i get to naguib': 'اركب الخط الثالث، انزل محطة نجيب',
    'i want to go to naguib': 'اركب الخط الثالث – محطة نجيب',

    'how do i get to cairo stadium':
        'اركب الخط الثالث، انزل محطة استاد القاهرة',
    'i want to go to cairo stadium': 'اركب الخط الثالث – محطة استاد القاهرة',

    'how do i get to sport city': 'اركب الخط الثالث، انزل محطة مدينة الرياضة',
    'i want to go to sport city': 'اركب الخط الثالث – محطة مدينة الرياضة',

    'how do i get to fair grounds': 'اركب الخط الثالث، انزل محطة أرض المعارض',
    'i want to go to fair grounds': 'اركب الخط الثالث – محطة أرض المعارض',

    'how do i get to cairo international fair':
        'اركب الخط الثالث، انزل محطة أرض المعارض',

    'how do i get to gamal abdel nasser':
        'اركب الخط الثالث، انزل محطة جمال عبد الناصر',
    'i want to go to gamal abdel nasser station':
        'اركب الخط الثالث – محطة جمال عبد الناصر',

    'how do i get to maspero': 'اركب الخط الثالث، انزل محطة ماسبيرو',
    'i want to go to maspero': 'اركب الخط الثالث – محطة ماسبيرو',

    'how do i get to safaa hegazy': 'اركب الخط الثالث، انزل محطة صفاء حجازي',
    'i want to go to safaa hegazy': 'اركب الخط الثالث – محطة صفاء حجازي',

    'how do i get to kit kat': 'اركب الخط الثالث، انزل محطة كيت كات',
    'i want to go to kit kat': 'اركب الخط الثالث – محطة كيت كات',

    'how do i get to sudan': 'اركب الخط الثالث، انزل محطة السودان',
    'i want to go to sudan station': 'اركب الخط الثالث – محطة السودان',

    'how do i get to imbaba': 'اركب الخط الثالث، انزل محطة إمبابة',
    'i want to go to imbaba': 'اركب الخط الثالث – محطة إمبابة',

    'how do i get to el bohy': 'اركب الخط الثالث، انزل محطة البهي',
    'i want to go to el bohy': 'اركب الخط الثالث – محطة البهي',

    'how do i get to el qawmia': 'اركب الخط الثالث، انزل محطة القومية',
    'i want to go to el qawmia': 'اركب الخط الثالث – محطة القومية',

    'how do i get to ring road': 'اركب الخط الثالث، انزل محطة الطريق الدائري',
    'i want to go to ring road station':
        'اركب الخط الثالث – محطة الطريق الدائري',

    'how do i get to cairo airport':
        'اركب الخط الثالث حتى محطة عدلي منصور، ثم خذ وسيلة مواصلات للمطار',
    'i want to go to cairo airport':
        'اركب الخط الثالث لمحطة عدلي منصور، ثم تاكسي أو أوبر للمطار',
    'which line goes to the airport':
        'الخط الثالث أقرب خط – انزل عدلي منصور ثم تاكسي للمطار',

    // ══════════════════════════════════════════════════════════════════════
    //  2. معالم سياحية شهيرة
    // ══════════════════════════════════════════════════════════════════════
    'how do i get to the pyramids':
        'اركب الخط الثاني، انزل محطة الجيزة، ثم تاكسي أو توك توك للأهرامات',
    'i want to go to the pyramids':
        'اركب الخط الثاني – محطة الجيزة – ثم تاكسي للأهرامات',
    'how do i get to the sphinx':
        'اركب الخط الثاني لمحطة الجيزة، ثم تاكسي لأبو الهول',
    'i want to see the sphinx':
        'اركب الخط الثاني لمحطة الجيزة، ثم تاكسي لأبو الهول',

    'how do i get to the egyptian museum':
        'اركب الخط الأول أو الثاني، انزل محطة السادات، المتحف على ميدان التحرير مباشرةً',
    'i want to go to the egyptian museum':
        'اركب الخط الأول أو الثاني – محطة السادات – المتحف أمامك في التحرير',
    'where is the egyptian museum': 'في ميدان التحرير – محطة السادات',

    'how do i get to khan el khalili':
        'اركب الخط الثالث، انزل محطة العتبة أو الأزهر، ثم امشِ 10 دقائق',
    'i want to go to khan el khalili':
        'اركب الخط الثالث – محطة العتبة – ثم امشِ لخان الخليلي',
    'where is khan el khalili': 'قريب من محطة العتبة في الخط الثالث',

    'how do i get to al azhar mosque':
        'اركب الخط الثالث، انزل محطة العتبة، ثم امشِ 10 دقائق للأزهر',
    'i want to visit al azhar':
        'اركب الخط الثالث – محطة العتبة – ثم امشِ للأزهر',

    'how do i get to salah el din citadel':
        'اركب الخط الثالث، انزل محطة القلعة',
    'i want to go to the citadel':
        'اركب الخط الثالث – محطة القلعة – أمامك مباشرة',
    'where is saladin citadel': 'بجانب محطة القلعة في الخط الثالث',

    'how do i get to hanging church': 'اركب الخط الأول، انزل محطة مار جرجس',
    'i want to visit the hanging church':
        'اركب الخط الأول – محطة مار جرجس – الكنيسة المعلقة قريبة جداً',
    'where is the hanging church': 'بجانب محطة مار جرجس في الخط الأول',

    'how do i get to coptic cairo': 'اركب الخط الأول، انزل محطة مار جرجس',
    'i want to visit coptic cairo':
        'اركب الخط الأول – محطة مار جرجس – مصر القبطية',

    'how do i get to cairo tower':
        'اركب الخط الثاني، انزل محطة الأوبرا أو الدقي، ثم عبر كوبري الجامعة لبرج القاهرة',
    'i want to go to cairo tower':
        'اركب الخط الثاني – محطة الأوبرا – ثم تاكسي قصير لبرج القاهرة',

    'how do i get to al azhar park':
        'اركب الخط الثالث، انزل محطة القلعة، ثم امشِ لحديقة الأزهر',
    'i want to go to al azhar park':
        'اركب الخط الثالث – محطة القلعة – ثم امشِ لحديقة الأزهر',

    'how do i get to ramses square':
        'اركب الخط الأول أو الثاني، انزل محطة الشهداء',
    'i want to go to ramses square':
        'اركب الخط الأول أو الثاني – محطة الشهداء – ميدان رمسيس',
    'where is ramses station':
        'بجانب محطة المترو الشهداء في الخطين الأول والثاني',

    'how do i get to grand egyptian museum':
        'اركب الخط الثاني لمحطة الجيزة، ثم تاكسي للمتحف المصري الكبير بالأهرام',
    'i want to go to gem':
        'اركب الخط الثاني – محطة الجيزة – ثم تاكسي للمتحف المصري الكبير',

    'how do i get to downtown cairo':
        'اركب الخط الأول أو الثاني، انزل محطة السادات أو ناصر – وسط البلد',
    'i want to go to downtown':
        'اركب الخط الأول أو الثاني – محطة السادات أو ناصر',

    'how do i get to zamalek':
        'اركب الخط الثاني، انزل محطة الأوبرا أو الدقي، ثم تاكسي قصير للزمالك',
    'i want to go to zamalek':
        'اركب الخط الثاني – محطة الأوبرا – ثم تاكسي للزمالك',

    'how do i get to garden city':
        'اركب الخط الأول أو الثاني، انزل محطة السادات، ثم امشِ جنوباً لجاردن سيتي',
    'i want to go to garden city':
        'اركب الخط الأول أو الثاني – محطة السادات – ثم امشِ لجاردن سيتي',

    'how do i get to mohandessin':
        'اركب الخط الثاني، انزل محطة الدقي أو البحوث، ثم امشِ أو تاكسي للمهندسين',
    'i want to go to mohandessin':
        'اركب الخط الثاني – محطة الدقي – ثم امشِ للمهندسين',

    'how do i get to nasr city':
        'اركب الخط الثالث، انزل محطة مدينة الرياضة أو أرض المعارض',
    'i want to go to nasr city':
        'اركب الخط الثالث – محطة مدينة الرياضة أو أرض المعارض',

    'how do i get to new cairo':
        'اركب الخط الثالث لمحطة عدلي منصور، ثم تاكسي لمدينة القاهرة الجديدة',
    'i want to go to new cairo':
        'اركب الخط الثالث – محطة عدلي منصور – ثم تاكسي لمدينة القاهرة الجديدة',

    'how do i get to fifth settlement':
        'اركب الخط الثالث لمحطة عدلي منصور، ثم تاكسي للتجمع الخامس',
    'i want to go to fifth settlement':
        'اركب الخط الثالث – عدلي منصور – ثم تاكسي للتجمع الخامس',

    'how do i get to the nile':
        'اركب الخط الثاني، انزل محطة الأوبرا – النيل أمامك مباشرةً',
    'i want to see the nile':
        'اركب الخط الثاني – محطة الأوبرا – شاطئ النيل قريب',

    // ══════════════════════════════════════════════════════════════════════
    //  3. تذاكر وأسعار
    // ══════════════════════════════════════════════════════════════════════
    'how much is the ticket': 'سعر التذكرة من 8 إلى 15 جنيه حسب عدد المحطات',
    'how much does a ticket cost': 'التذكرة بين 8 و15 جنيه حسب المسافة',
    'i want to buy a ticket': 'أريد شراء تذكرة',
    'where can i buy a ticket': 'أين أشتري التذكرة؟',
    'where is the ticket machine': 'أين ماكينة التذاكر؟',
    'where is the ticket office': 'أين مكتب التذاكر؟',
    'do you have a day pass': 'هل يوجد تذكرة يومية؟',
    'do you have a weekly pass': 'هل يوجد اشتراك أسبوعي؟',
    'do you have a monthly pass': 'هل يوجد اشتراك شهري؟',
    'is there a discount for tourists': 'هل يوجد خصم للسياح؟',
    'is there a student discount': 'هل يوجد خصم طلابي؟',
    'can i pay by card': 'هل يمكنني الدفع بالبطاقة؟',
    'do you accept credit cards': 'هل تقبلون بطاقات الائتمان؟',
    'i only have dollars': 'معي دولارات فقط',
    'where can i exchange money': 'أين أصرف العملة؟',
    'the machine is not working': 'الماكينة لا تعمل',
    'i need change': 'أحتاج فكة',
    'i do not have exact change': 'ليس معي فكة بالضبط',

    // ══════════════════════════════════════════════════════════════════════
    //  4. داخل المحطة
    // ══════════════════════════════════════════════════════════════════════
    'where is the entrance': 'أين المدخل؟',
    'where is the exit': 'أين المخرج؟',
    'where is gate': 'أين البوابة؟',
    'which platform': 'أي رصيف؟',
    'which line should i take': 'أي خط أركب؟',
    'does this train go to': 'هل هذا القطار يذهب إلى؟',
    'where do i transfer': 'أين أغير الخط؟',
    'how many stops': 'كم محطة؟',
    'what is the next station': 'ما المحطة القادمة؟',
    'is this the right train': 'هل هذا القطار الصحيح؟',
    'i missed my stop': 'فاتتني المحطة',
    'i am lost': 'أنا تهت',
    'where is the women only car': 'أين عربة السيدات؟',
    'is there a women only section': 'هل يوجد قسم للسيدات فقط؟',
    'where is the first class car': 'أين العربة الدرجة الأولى؟',
    'which direction': 'أي اتجاه؟',
    'is this train going north': 'هل هذا القطار يتجه شمالاً؟',
    'is this train going south': 'هل هذا القطار يتجه جنوباً؟',
    'how long until the next train': 'كم دقيقة للقطار القادم؟',
    'when does the metro start': 'متى يبدأ المترو؟',
    'when does the metro close': 'متى يغلق المترو؟',
    'what time does the metro open': 'متى يفتح المترو؟',
    'what time does the metro close': 'متى يغلق المترو؟',
    'when is the last train': 'متى آخر قطار؟',
    'how long is the wait': 'كم وقت الانتظار؟',
    'is the metro running now': 'هل المترو يعمل الآن؟',
    'is there a delay': 'هل يوجد تأخير؟',
    'the train is crowded': 'القطار مزدحم',
    'can i sit here': 'هل يمكنني الجلوس هنا؟',
    'this seat is taken': 'هذا المقعد محجوز',
    'please move': 'أرجوك تحرك',
    'excuse me let me through': 'لو سمحت، أريد المرور',
    'can you hold the door': 'هل يمكنك الإمساك بالباب؟',

    // ══════════════════════════════════════════════════════════════════════
    //  5. مرافق وخدمات
    // ══════════════════════════════════════════════════════════════════════
    'where is the bathroom': 'أين الحمام؟',
    'where is the toilet': 'أين دورة المياه؟',
    'where is the elevator': 'أين المصعد؟',
    'where is the escalator': 'أين السلم المتحرك؟',
    'where is the wheelchair access': 'أين منفذ ذوي الاحتياجات الخاصة؟',
    'where is the information desk': 'أين مكتب الاستعلامات؟',
    'where is the lost and found': 'أين مكتب المفقودات؟',
    'where is the police': 'أين الشرطة؟',
    'where is the first aid': 'أين الإسعافات الأولية؟',
    'i need an ambulance': 'أحتاج إسعاف',
    'call the police': 'اتصل بالشرطة',
    'i need help': 'أحتاج مساعدة',
    'can you help me': 'هل يمكنك مساعدتي؟',
    'i have an emergency': 'لدي حالة طارئة',
    'is there wifi': 'هل يوجد واي فاي؟',
    'is there internet': 'هل يوجد إنترنت؟',
    'where can i charge my phone': 'أين أشحن هاتفي؟',
    'where is a water fountain': 'أين نافورة الماء؟',
    'where can i get water': 'أين أحصل على ماء؟',
    'where is a vending machine': 'أين ماكينة المشروبات؟',
    'where can i buy food': 'أين أشتري أكلاً؟',
    'where is a pharmacy': 'أين يوجد صيدلية؟',
    'where is a hospital': 'أين يوجد مستشفى؟',
    'where is an atm': 'أين يوجد صراف آلي؟',
    'where is a bank': 'أين يوجد بنك؟',

    // ══════════════════════════════════════════════════════════════════════
    //  6. الطوارئ والأمان
    // ══════════════════════════════════════════════════════════════════════
    'help': 'النجدة!',
    'fire': 'حريق!',
    'stop the train': 'أوقف القطار!',
    'someone is sick': 'هناك شخص مريض',
    'i feel sick': 'أنا أشعر بتعب',
    'i need a doctor': 'أحتاج طبيباً',
    'my bag is stolen': 'سرقوا شنطتي',
    'my wallet is stolen': 'سرقوا محفظتي',
    'my phone is stolen': 'سرقوا هاتفي',
    'i lost my passport': 'ضاع جواز سفري',
    'i lost my bag': 'ضاعت شنطتي',
    'i lost my ticket': 'ضاعت تذكرتي',
    'someone stole from me': 'سرقوا مني',
    'there is a suspicious person': 'هناك شخص مشبوه',
    'i need the police': 'أحتاج الشرطة',
    'where is the embassy': 'أين السفارة؟',
    'i need to contact my embassy': 'أريد الاتصال بسفارتي',
    'please call 123': 'اتصل بالرقم 123 من فضلك',

    // ══════════════════════════════════════════════════════════════════════
    //  7. التواصل والفهم
    // ══════════════════════════════════════════════════════════════════════
    'do you speak english': 'هل تتحدث الإنجليزية؟',
    'i do not speak arabic': 'لا أتحدث العربية',
    'please speak slowly': 'تكلم ببطء من فضلك',
    'can you repeat that': 'هل يمكنك التكرار؟',
    'i do not understand': 'لا أفهم',
    'please write it down': 'اكتبها من فضلك',
    'can you show me on the map': 'هل يمكنك أن تريني على الخريطة؟',
    'how do you spell that': 'كيف تُهجّأ؟',
    'what does that mean': 'ما معنى ذلك؟',
    'is there a translator': 'هل يوجد مترجم؟',
    'can you speak more slowly': 'هل يمكنك التكلم بشكل أبطأ؟',
    'i understand a little arabic': 'أفهم القليل من العربية',
    'i am learning arabic': 'أنا أتعلم العربية',

    // ══════════════════════════════════════════════════════════════════════
    //  8. مواصلات خارج المترو
    // ══════════════════════════════════════════════════════════════════════
    'i need a taxi': 'أحتاج تاكسي',
    'where can i find a taxi': 'أين أجد تاكسي؟',
    'how much to the pyramids by taxi': 'بكم التاكسي للأهرامات؟',
    'please use the meter': 'استخدم العداد من فضلك',
    'is this price fixed': 'هل السعر ثابت؟',
    'i want to use uber': 'أريد استخدام أوبر',
    'i want to use careem': 'أريد استخدام كريم',
    'where is the bus stop': 'أين موقف الأتوبيس؟',
    'which bus goes to': 'أي أتوبيس يذهب إلى؟',
    'where is the microbus': 'أين المايكروباص؟',
    'how far is it to walk': 'كم المسافة مشياً؟',
    'is it far': 'هل هو بعيد؟',
    'is it close': 'هل هو قريب؟',
    'how many minutes by taxi': 'كم دقيقة بالتاكسي؟',
    'where can i rent a bike': 'أين أستأجر دراجة؟',
    'i want to go back to my hotel': 'أريد العودة إلى فندقي',
    'take me to the nearest hotel': 'خذني لأقرب فندق',
    'take me to four seasons': 'خذني لفندق فور سيزونز',
    'take me to the marriott': 'خذني لفندق ماريوت',
    'take me to the hilton': 'خذني لفندق هيلتون',
    'take me to the intercontinental': 'خذني لفندق إنتركونتيننتال',

    // ══════════════════════════════════════════════════════════════════════
    //  9. طعام وشراب
    // ══════════════════════════════════════════════════════════════════════
    'i am hungry': 'أنا جائع',
    'i am thirsty': 'أنا عطشان',
    'where is a restaurant': 'أين يوجد مطعم؟',
    'where is a cafe': 'أين يوجد كافيه؟',
    'where is mcdonalds': 'أين ماكدونالدز؟',
    'where is kfc': 'أين كنتاكي؟',
    'i want egyptian food': 'أريد أكلاً مصرياً',
    'what is koshari': 'ما هو الكشري؟',
    'i want koshari': 'أريد كشري',
    'i want foul': 'أريد فول',
    'i want taamiya': 'أريد طعمية',
    'i want kofta': 'أريد كفتة',
    'i want shawarma': 'أريد شاورما',
    'where can i get juice': 'أين أحصل على عصير؟',
    'i want tea': 'أريد شاي',
    'i want coffee': 'أريد قهوة',
    'i want water': 'أريد ماء',
    'do you have vegetarian food': 'هل يوجد أكل نباتي؟',
    'i am allergic to nuts': 'عندي حساسية من المكسرات',
    'no spicy please': 'بدون حار من فضلك',
    'the bill please': 'الحساب من فضلك',
    'how much is this': 'بكم هذا؟',
    'is this halal': 'هل هذا حلال؟',

    // ══════════════════════════════════════════════════════════════════════
    //  10. تسوق
    // ══════════════════════════════════════════════════════════════════════
    'where is the nearest mall': 'أين أقرب مول؟',
    'where is mall of egypt': 'أين مول مصر؟',
    'where is city stars': 'أين سيتي ستارز؟',
    'where is cairo festival city': 'أين القاهرة فيستيفال سيتي؟',
    'i want to buy souvenirs': 'أريد شراء تذكارات',
    'where can i buy souvenirs': 'أين أشتري تذكارات؟',
    'is this authentic': 'هل هذا أصلي؟',
    'can you give me a discount': 'هل يمكنك إعطائي خصماً؟',
    'this is too expensive': 'هذا غالي جداً',
    'do you have a cheaper one': 'هل يوجد أرخص؟',
    'i will buy it': 'سأشتريه',
    'i do not want it': 'لا أريده',
    'can i try it': 'هل يمكنني تجربته؟',
    'do you have my size': 'هل عندك مقاسي؟',
    'what size is this': 'ما هو المقاس؟',
    'where is the fitting room': 'أين غرفة القياس؟',
    'can i return this': 'هل يمكنني إرجاعه؟',
    'i want a receipt': 'أريد إيصالاً',

    // ══════════════════════════════════════════════════════════════════════
    //  11. فندق وإقامة
    // ══════════════════════════════════════════════════════════════════════
    'where is my hotel': 'أين فندقي؟',
    'i have a reservation': 'لدي حجز',
    'my name is': 'اسمي',
    'i want to check in': 'أريد تسجيل الدخول',
    'i want to check out': 'أريد تسجيل الخروج',
    'what time is checkout': 'ما وقت تسجيل الخروج؟',
    'can i have a late checkout': 'هل يمكنني مغادرة متأخرة؟',
    'where is my room': 'أين غرفتي؟',
    'the key does not work': 'المفتاح لا يعمل',
    'i need more towels': 'أحتاج مناشف إضافية',
    'the air conditioning is broken': 'التكييف معطل',
    'there is no hot water': 'لا يوجد ماء ساخن',
    'can i get breakfast': 'هل يمكنني الحصول على إفطار؟',
    'what time is breakfast': 'ما وقت الإفطار؟',
    'is breakfast included': 'هل الإفطار مشمول؟',
    'i want a room with a nile view': 'أريد غرفة بإطلالة على النيل',
    'do you have a swimming pool': 'هل يوجد حمام سباحة؟',
    'where is the gym': 'أين الجيم؟',
    'where is the spa': 'أين السبا؟',

    // ══════════════════════════════════════════════════════════════════════
    //  12. صحة وطوارئ طبية
    // ══════════════════════════════════════════════════════════════════════
    'call an ambulance': 'اتصل بالإسعاف',
    'i have a headache': 'أنا عندي صداع',
    'i have a stomachache': 'أنا عندي ألم في المعدة',
    'i feel dizzy': 'أشعر بدوار',
    'i have a fever': 'أنا عندي حمى',
    'i am diabetic': 'أنا مصاب بالسكري',
    'i have a heart condition': 'عندي مشكلة في القلب',
    'i am allergic to penicillin': 'عندي حساسية من البنسلين',
    'i need insulin': 'أحتاج أنسولين',
    'where is the nearest hospital': 'أين أقرب مستشفى؟',
    'where is the nearest pharmacy': 'أين أقرب صيدلية؟',
    'i need pain killers': 'أحتاج مسكنات',
    'do you have aspirin': 'هل يوجد أسبرين؟',
    'i need bandages': 'أحتاج ضمادات',
    'i have been injured': 'أصبت بجرح',
    'i cannot breathe': 'لا أستطيع التنفس',
    'i am having a heart attack': 'أعاني من نوبة قلبية',

    // ══════════════════════════════════════════════════════════════════════
    //  13. الوقت والتواريخ
    // ══════════════════════════════════════════════════════════════════════
    'what time is it': 'كم الساعة؟',
    'what is today date': 'ما تاريخ اليوم؟',
    'what day is today': 'ما اليوم؟',
    'in the morning': 'في الصباح',
    'in the afternoon': 'بعد الظهر',
    'in the evening': 'في المساء',
    'at night': 'في الليل',
    'yesterday': 'أمس',
    'today': 'اليوم',
    'tomorrow': 'غداً',
    'how long does it take': 'كم يستغرق؟',
    'is it open now': 'هل هو مفتوح الآن؟',
    'what are the opening hours': 'ما ساعات العمل؟',
    'is it closed today': 'هل هو مغلق اليوم؟',
    'what time does it close': 'متى يغلق؟',
    'what time does it open': 'متى يفتح؟',

    // ══════════════════════════════════════════════════════════════════════
    //  14. الأرقام والكميات
    // ══════════════════════════════════════════════════════════════════════
    'one ticket please': 'تذكرة واحدة من فضلك',
    'two tickets please': 'تذكرتان من فضلك',
    'three tickets please': 'ثلاث تذاكر من فضلك',
    'how many stops is it': 'كم عدد المحطات؟',
    'it is two stops away': 'على بعد محطتين',
    'it is far': 'إنه بعيد',
    'it is close': 'إنه قريب',
    'it is about ten minutes': 'حوالي عشر دقائق',
    'it is about thirty minutes': 'حوالي ثلاثين دقيقة',
    'it costs fifty pounds': 'يكلف خمسين جنيهاً',
    'that is too much': 'هذا كثير جداً',
    'that is fine': 'هذا مناسب',

    // ══════════════════════════════════════════════════════════════════════
    //  15. تحيات وعبارات اجتماعية
    // ══════════════════════════════════════════════════════════════════════
    'hello': 'مرحباً',
    'hi': 'أهلاً',
    'good morning': 'صباح الخير',
    'good afternoon': 'مساء الخير',
    'good evening': 'مساء الخير',
    'good night': 'تصبح على خير',
    'goodbye': 'مع السلامة',
    'see you later': 'إلى اللقاء',
    'nice to meet you': 'يسعدني لقاؤك',
    'thank you': 'شكراً',
    'thank you very much': 'شكراً جزيلاً',
    'you are welcome': 'على الرحب والسعة',
    'excuse me': 'عفواً',
    'sorry': 'آسف',
    'i am sorry': 'أنا آسف',
    'please': 'من فضلك',
    'yes': 'نعم',
    'no': 'لا',
    'maybe': 'ربما',
    'i do not know': 'لا أعرف',
    'i understand': 'أفهم',
    'ok': 'حسناً',
    'no problem': 'لا مشكلة',
    'of course': 'بالطبع',
    'i am a tourist': 'أنا سائح',
    'i am visiting cairo': 'أنا أزور القاهرة',
    'this is my first time in egypt': 'هذه أول مرة لي في مصر',
    'i love egypt': 'أنا أحب مصر',
    'egypt is beautiful': 'مصر جميلة',
    'the people here are kind': 'الناس هنا طيبون',
    'i am from america': 'أنا من أمريكا',
    'i am from the uk': 'أنا من المملكة المتحدة',
    'i am from france': 'أنا من فرنسا',
    'i am from germany': 'أنا من ألمانيا',
    'i am from italy': 'أنا من إيطاليا',
    'i am from spain': 'أنا من إسبانيا',
    'i am from china': 'أنا من الصين',
    'i am from japan': 'أنا من اليابان',
    'i am from india': 'أنا من الهند',
    'i am from russia': 'أنا من روسيا',
    'i am from brazil': 'أنا من البرازيل',
    'i am from australia': 'أنا من أستراليا',
    'i am from canada': 'أنا من كندا',
    'i am from turkey': 'أنا من تركيا',
    'i am from saudi arabia': 'أنا من المملكة العربية السعودية',
    'i am from the uae': 'أنا من الإمارات',
    'my name is john': 'اسمي جون',
    'what is your name': 'ما اسمك؟',
    'how are you': 'كيف حالك؟',
    'i am fine': 'أنا بخير',
    'i am tired': 'أنا تعبان',
    'i am happy': 'أنا سعيد',
    'i am excited': 'أنا متحمس',

    // ══════════════════════════════════════════════════════════════════════
    //  16. أسئلة متنوعة عن القاهرة
    // ══════════════════════════════════════════════════════════════════════
    'is cairo safe': 'هل القاهرة آمنة؟',
    'what should i visit in cairo': 'ماذا أزور في القاهرة؟',
    'what is the best time to visit': 'ما أفضل وقت للزيارة؟',
    'how is the weather today': 'كيف الطقس اليوم؟',
    'is it hot': 'هل الجو حار؟',
    'what currency is used': 'ما العملة المستخدمة؟',
    'what language do egyptians speak': 'ما اللغة التي يتحدثها المصريون؟',
    'what is the religion here': 'ما الدين هنا؟',
    'is alcohol available': 'هل الكحول متاح؟',
    'what is the local sim card': 'ما شريحة الاتصال المحلية؟',
    'where can i buy a sim card': 'أين أشتري شريحة اتصال؟',
    'what is the country code for egypt': 'ما كود مصر الدولي؟',
    'is tipping expected': 'هل البقشيش متوقع؟',
    'how much should i tip': 'كم أعطي بقشيش؟',
    'what is baksheesh': 'ما هو البقشيش؟',
    'is bargaining normal': 'هل المساومة طبيعية؟',
    'can i take photos here': 'هل يمكنني التصوير هنا؟',
    'is photography allowed': 'هل التصوير مسموح؟',
    'what is the dress code': 'ما قواعد اللباس؟',
    'should i cover my head': 'هل يجب تغطية رأسي؟',
    'is it ok to wear shorts': 'هل يمكن ارتداء شورت؟',
    'where can i find a guide': 'أين أجد مرشداً سياحياً؟',
    'how do i get a visa': 'كيف أحصل على تأشيرة؟',
    'where is the nearest police station': 'أين أقرب مركز شرطة؟',
    'where is the tourist information center': 'أين مركز معلومات السياحة؟',
    'do you have a map': 'هل يوجد خريطة؟',
    'can i have a metro map': 'هل يمكنني الحصول على خريطة المترو؟',
    'is there a guided tour': 'هل يوجد جولة مرشدة؟',
    'how much is the tour': 'بكم الجولة السياحية؟',
    'i want to book a tour': 'أريد حجز جولة سياحية',
    'what are the famous foods': 'ما الأطعمة المشهورة؟',
    'what souvenirs should i buy': 'ما التذكارات التي أشتريها؟',
    'where can i buy papyrus': 'أين أشتري البردي؟',
    'where can i buy perfume': 'أين أشتري عطراً؟',
    'where can i buy gold': 'أين أشتري ذهباً؟',
    'what is the exchange rate': 'ما سعر الصرف؟',

    // ══════════════════════════════════════════════════════════════════════
    //  17. الإنترنت والتواصل
    // ══════════════════════════════════════════════════════════════════════
    'what is the wifi password': 'ما كلمة مرور الواي فاي؟',
    'is there free wifi': 'هل يوجد واي فاي مجاني؟',
    'my phone has no signal': 'هاتفي ليس له إشارة',
    'i need to make a call': 'أريد إجراء مكالمة',
    'can i use your phone': 'هل يمكنني استخدام هاتفك؟',
    'i need to charge my phone': 'أريد شحن هاتفي',
    'where is a power outlet': 'أين المنفذ الكهربائي؟',
    'my battery is dead': 'بطاريتي فارغة',
    'do you have a charger': 'هل لديك شاحن؟',
    'can you take a photo of me': 'هل يمكنك تصويري؟',
    'can i take a selfie with you': 'هل يمكنني أخذ سيلفي معك؟',

    // ══════════════════════════════════════════════════════════════════════
    //  18. احتياجات خاصة
    // ══════════════════════════════════════════════════════════════════════
    'i use a wheelchair': 'أستخدم كرسياً متحركاً',
    'i need wheelchair access': 'أحتاج منفذاً للكرسي المتحرك',
    'i am visually impaired': 'أنا ضعيف البصر',
    'i am hearing impaired': 'أنا ضعيف السمع',
    'i have a disability': 'لدي إعاقة',
    'i am traveling with children': 'أنا أسافر مع أطفال',
    'i have a baby': 'معي طفل رضيع',
    'is there a baby changing room': 'هل يوجد غرفة لتغيير الطفل؟',
    'i am pregnant': 'أنا حامل',
    'i need a seat': 'أحتاج مقعداً',
    'i am an elderly person': 'أنا كبير في السن',

    // ══════════════════════════════════════════════════════════════════════
    //  19. أسئلة عن رفيق والتطبيق
    // ══════════════════════════════════════════════════════════════════════
    'what is this app': 'ما هذا التطبيق؟',
    'how does the metro work': 'كيف يعمل المترو؟',
    'how many lines are there': 'كم عدد الخطوط؟',
    'how many stations are there': 'كم عدد المحطات؟',
    'what is the fastest route': 'ما أسرع طريق؟',
    'can you plan my route': 'هل يمكنك تخطيط مساري؟',
    'show me the metro map': 'أرني خريطة المترو',
    'what is the nearest station': 'ما أقرب محطة؟',
    'find nearest station': 'أوجد أقرب محطة',
    'how do i buy a ticket': 'كيف أشتري تذكرة؟',
    'is the metro safe': 'هل المترو آمن؟',
    'is the metro clean': 'هل المترو نظيف؟',
    'are there cameras in the metro': 'هل يوجد كاميرات في المترو؟',
    'is there security in the metro': 'هل يوجد أمن في المترو؟',

    // ══════════════════════════════════════════════════════════════════════
    //  20. عبارات مفيدة متفرقة
    // ══════════════════════════════════════════════════════════════════════
    'just a moment please': 'لحظة من فضلك',
    'wait here': 'انتظر هنا',
    'follow me': 'اتبعني',
    'go straight ahead': 'اكمل مستقيماً',
    'turn left': 'اتجه يساراً',
    'turn right': 'اتجه يميناً',
    'it is on the right': 'إنه على اليمين',
    'it is on the left': 'إنه على اليسار',
    'it is in front of you': 'إنه أمامك',
    'it is behind you': 'إنه خلفك',
    'it is upstairs': 'إنه في الطابق العلوي',
    'it is downstairs': 'إنه في الطابق السفلي',
    'take the first left': 'خذ أول يسار',
    'take the second right': 'خذ ثاني يمين',
    'at the traffic lights': 'عند إشارة المرور',
    'next to the mosque': 'بجانب المسجد',
    'across from the bank': 'أمام البنك مباشرةً',
    'keep going': 'استمر',
    'you have arrived': 'لقد وصلت',
    'this is the place': 'هذا هو المكان',
    'you are almost there': 'أنت على وشك الوصول',
    'it is a five minute walk': 'على بعد خمس دقائق مشياً',
    'it is a ten minute walk': 'على بعد عشر دقائق مشياً',
    'it is a twenty minute walk': 'على بعد عشرين دقيقة مشياً',
    'can i walk there': 'هل يمكنني الوصول مشياً؟',
    'is it safe to walk at night': 'هل المشي آمن في الليل؟',
    'i want to explore': 'أريد الاستكشاف',
    'i want to see the city': 'أريد رؤية المدينة',
    'what is that building': 'ما هذا المبنى؟',
    'how old is this': 'كم عمر هذا؟',
    'this is amazing': 'هذا مذهل!',
    'this is beautiful': 'هذا جميل!',
    'i love this place': 'أنا أحب هذا المكان',
    'i will come back': 'سأعود مرة أخرى',
    'i had a great time': 'قضيت وقتاً رائعاً',
    'egypt is wonderful': 'مصر رائعة!',
  };
  Future<void> _toggleListening() async {
    if (_isListening) {
      await SpeechService.stopListening();
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _spokenText = '';
      _translatedText = '';
    });

    await SpeechService.startListening(
      localeId: 'en-US',
      onResult: (text) {
        if (!mounted) return;
        final spoken = text.toLowerCase().trim();

        // ابحث أولاً بـ exact match، لو مش لاقي جرب fuzzy
        String translation = _dict[spoken] ?? '';
        if (translation.isEmpty) {
          for (final entry in _dict.entries) {
            if (SpeechService.fuzzyMatch(spoken, entry.key)) {
              translation = entry.value;
              break;
            }
          }
        }

        setState(() {
          _spokenText = text;
          _translatedText = translation.isNotEmpty
              ? translation
              : '⚠️ مش عارف أترجم دي، جرب تاني';
          _isListening = false;
        });

        if (translation.isNotEmpty) {
          VoiceService.speak(translation, 'ar');
        }
      },
    );
  }

  @override
  void dispose() {
    SpeechService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'مساعد السياح 🌍',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اتكلم بالإنجليزي — هيترجمله للعربي ويتكلم',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // ── زرار الميك ───────────────────────────────────────────────────
          GestureDetector(
            onTap: _toggleListening,
            child: _isListening
                ? Pulse(infinite: true, child: _micButton())
                : _micButton(),
          ),
          const SizedBox(height: 12),
          Text(
            _isListening ? '🎙️ بيسمعك...' : 'اضغط للتكلم',
            style: TextStyle(
              color: _isListening ? Colors.red : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // ── النتيجة ──────────────────────────────────────────────────────
          if (_spokenText.isNotEmpty)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '"$_spokenText"',
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Icon(
                      Icons.arrow_downward_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _translatedText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // زرار إعادة النطق
                    if (!_translatedText.startsWith('⚠️'))
                      OutlinedButton.icon(
                        onPressed: () =>
                            VoiceService.speak(_translatedText, 'ar'),
                        icon: const Icon(Icons.volume_up_rounded, size: 18),
                        label: const Text('اسمع التعبير تاني'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            // hint examples
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'أمثلة:',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children:
                        const [
                              '"Where is the exit?"',
                              '"How much is the ticket?"',
                              '"I need help"',
                              '"Where is the bathroom?"',
                              '"Thank you"',
                              '"Excuse me"',
                            ]
                            .map(
                              (e) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.07,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _micButton() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isListening
            ? Colors.red.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.10),
        border: Border.all(
          color: _isListening
              ? Colors.red.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        _isListening ? Icons.mic : Icons.mic_none_rounded,
        size: 52,
        color: _isListening ? Colors.red : AppColors.primary,
      ),
    );
  }
}
