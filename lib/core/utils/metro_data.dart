import '../../features/metro/domain/entities/station.dart';

/// Cairo Metro official data.
/// Ticket prices effective 27 March 2026 (Ministry of Transport decree):
///   ≤ 9  stations → 10 EGP
///   ≤ 16 stations → 12 EGP
///   ≤ 23 stations → 15 EGP
///   ≤ 39 stations → 20 EGP
class MetroData {
  // ─── 2026 Pricing ─────────────────────────────────────────────────────────
  static int calculateTicketPrice(int stationCount) {
    if (stationCount <= 9) return 10;
    if (stationCount <= 16) return 12;
    if (stationCount <= 23) return 15;
    return 20;
  }

  // ─── All Stations ──────────────────────────────────────────────────────────
  static final Map<String, Station> stations = {
    // ════════════════════════════════════════════════════════════════════
    // LINE 1 — RED   Helwan ↔ El Marg El Gedida   (35 stations)
    // ════════════════════════════════════════════════════════════════════
    'l1_helwan': const Station(
      id: 'l1_helwan', nameEn: 'Helwan', nameAr: 'حلوان', line: 1,
      latitude: 29.8489, longitude: 31.3341,
      connectedTo: ['l1_ain_helwan']),

    'l1_ain_helwan': const Station(
      id: 'l1_ain_helwan', nameEn: 'Ain Helwan', nameAr: 'عين حلوان', line: 1,
      latitude: 29.8594, longitude: 31.3320,
      connectedTo: ['l1_helwan', 'l1_helwan_uni']),

    'l1_helwan_uni': const Station(
      id: 'l1_helwan_uni', nameEn: 'Helwan University', nameAr: 'جامعة حلوان', line: 1,
      latitude: 29.8675, longitude: 31.3283,
      connectedTo: ['l1_ain_helwan', 'l1_wadi_hof']),

    'l1_wadi_hof': const Station(
      id: 'l1_wadi_hof', nameEn: 'Wadi Hof', nameAr: 'وادي حوف', line: 1,
      latitude: 29.8870, longitude: 31.3210,
      connectedTo: ['l1_helwan_uni', 'l1_hadayek_helwan']),

    'l1_hadayek_helwan': const Station(
      id: 'l1_hadayek_helwan', nameEn: 'Hadayek Helwan', nameAr: 'حدائق حلوان', line: 1,
      latitude: 29.9003, longitude: 31.3140,
      connectedTo: ['l1_wadi_hof', 'l1_el_maasara']),

    'l1_el_maasara': const Station(
      id: 'l1_el_maasara', nameEn: 'El Maasara', nameAr: 'المعصرة', line: 1,
      latitude: 29.9130, longitude: 31.3070,
      connectedTo: ['l1_hadayek_helwan', 'l1_tora_asmant']),

    'l1_tora_asmant': const Station(
      id: 'l1_tora_asmant', nameEn: 'Tora El Asmant', nameAr: 'طرة الاسمنت', line: 1,
      latitude: 29.9260, longitude: 31.2990,
      connectedTo: ['l1_el_maasara', 'l1_kozzika']),

    'l1_kozzika': const Station(
      id: 'l1_kozzika', nameEn: 'Kozzika', nameAr: 'كوتسيكا', line: 1,
      latitude: 29.9390, longitude: 31.2910,
      connectedTo: ['l1_tora_asmant', 'l1_tora_balad']),

    'l1_tora_balad': const Station(
      id: 'l1_tora_balad', nameEn: 'Tora El Balad', nameAr: 'طرة البلد', line: 1,
      latitude: 29.9520, longitude: 31.2830,
      connectedTo: ['l1_kozzika', 'l1_sakanat_maadi']),

    'l1_sakanat_maadi': const Station(
      id: 'l1_sakanat_maadi', nameEn: 'Sakanat El Maadi', nameAr: 'سكن المعادي', line: 1,
      latitude: 29.9650, longitude: 31.2750,
      connectedTo: ['l1_tora_balad', 'l1_maadi']),

    'l1_maadi': const Station(
      id: 'l1_maadi', nameEn: 'El Maadi', nameAr: 'المعادي', line: 1,
      latitude: 29.9603, longitude: 31.2581,
      connectedTo: ['l1_sakanat_maadi', 'l1_hadayek_maadi']),

    'l1_hadayek_maadi': const Station(
      id: 'l1_hadayek_maadi', nameEn: 'Hadayek El Maadi', nameAr: 'حدائق المعادي', line: 1,
      latitude: 29.9720, longitude: 31.2540,
      connectedTo: ['l1_maadi', 'l1_hadaba_wosta']),

    'l1_hadaba_wosta': const Station(
      id: 'l1_hadaba_wosta', nameEn: 'El Hadaba El Wosta', nameAr: 'الحضبة الوسطى', line: 1,
      latitude: 29.9820, longitude: 31.2480,
      connectedTo: ['l1_hadayek_maadi', 'l1_dar_salam']),

    'l1_dar_salam': const Station(
      id: 'l1_dar_salam', nameEn: 'Dar Es Salam', nameAr: 'دار السلام', line: 1,
      latitude: 29.9930, longitude: 31.2430,
      connectedTo: ['l1_hadaba_wosta', 'l1_el_zahraa']),

    'l1_el_zahraa': const Station(
      id: 'l1_el_zahraa', nameEn: 'El Zahraa', nameAr: 'الزهراء', line: 1,
      latitude: 30.0020, longitude: 31.2380,
      connectedTo: ['l1_dar_salam', 'l1_mar_girgis']),

    'l1_mar_girgis': const Station(
      id: 'l1_mar_girgis', nameEn: 'Mar Girgis', nameAr: 'مار جرجس', line: 1,
      latitude: 30.0100, longitude: 31.2340,
      connectedTo: ['l1_el_zahraa', 'l1_malek_saleh']),

    'l1_malek_saleh': const Station(
      id: 'l1_malek_saleh', nameEn: 'El Malek El Saleh', nameAr: 'الملك الصالح', line: 1,
      latitude: 30.0200, longitude: 31.2340,
      connectedTo: ['l1_mar_girgis', 'l1_sayeda_zeinab']),

    'l1_sayeda_zeinab': const Station(
      id: 'l1_sayeda_zeinab', nameEn: 'Al Sayeda Zeinab', nameAr: 'السيدة زينب', line: 1,
      latitude: 30.0300, longitude: 31.2360,
      connectedTo: ['l1_malek_saleh', 'l1_saad_zaghloul']),

    'l1_saad_zaghloul': const Station(
      id: 'l1_saad_zaghloul', nameEn: 'Saad Zaghloul', nameAr: 'سعد زغلول', line: 1,
      latitude: 30.0370, longitude: 31.2360,
      connectedTo: ['l1_sayeda_zeinab', 'l1_sadat']),

    // ── TRANSFER L1 ↔ L2 ──
    'l1_sadat': const Station(
      id: 'l1_sadat', nameEn: 'Sadat', nameAr: 'السادات', line: 1,
      latitude: 30.0444, longitude: 31.2357,
      isTransfer: true,
      connectedTo: ['l1_saad_zaghloul', 'l1_nasser', 'l2_sadat'],
      facilities: ['atm', 'wc', 'elevator', 'police_station'],
      exits: [
        {'ar': 'مخرج مجمع التحرير', 'en': 'Mogamma El Tahrir Exit'},
        {'ar': 'مخرج الجامعة الأمريكية', 'en': 'AUC Exit'},
        {'ar': 'مخرج شارع طلعت حرب', 'en': 'Talaat Harb St. Exit'},
        {'ar': 'مخرج المتحف المصري', 'en': 'Egyptian Museum Exit'},
      ]),

    // ── TRANSFER L1 ↔ L3 ──
    'l1_nasser': const Station(
      id: 'l1_nasser', nameEn: 'Gamal Abd El Nasser', nameAr: 'جمال عبد الناصر', line: 1,
      latitude: 30.0528, longitude: 31.2394,
      isTransfer: true,
      connectedTo: ['l1_sadat', 'l1_shohadaa', 'l3_nasser'],
      facilities: ['atm', 'wc', 'elevator'],
      exits: [
        {'ar': 'مخرج شارع رمسيس', 'en': 'Ramses St. Exit'},
        {'ar': 'مخرج ماسبيرو', 'en': 'Maspero Exit'},
      ]),

    // ── TRANSFER L1 ↔ L2 ──
    'l1_shohadaa': const Station(
      id: 'l1_shohadaa', nameEn: 'Al Shohadaa', nameAr: 'الشهداء', line: 1,
      latitude: 30.0614, longitude: 31.2464,
      isTransfer: true,
      connectedTo: ['l1_nasser', 'l1_ghamra', 'l2_shohadaa'],
      facilities: ['atm', 'wc', 'elevator', 'ticket_office'],
      exits: [
        {'ar': 'مخرج محطة مصر (القطارات)', 'en': 'Ramses Station Exit'},
        {'ar': 'مخرج شارع رمسيس', 'en': 'Ramses Street Exit'},
        {'ar': 'مخرج موقف أحمد حلمي', 'en': 'Ahmed Helmy Bus Station Exit'},
      ]),

    'l1_ghamra': const Station(
      id: 'l1_ghamra', nameEn: 'Ghamra', nameAr: 'غمرة', line: 1,
      latitude: 30.0670, longitude: 31.2600,
      connectedTo: ['l1_shohadaa', 'l1_demerdash']),

    'l1_demerdash': const Station(
      id: 'l1_demerdash', nameEn: 'El Demerdash', nameAr: 'الدمرداش', line: 1,
      latitude: 30.0730, longitude: 31.2720,
      connectedTo: ['l1_ghamra', 'l1_manshiet_sadr']),

    'l1_manshiet_sadr': const Station(
      id: 'l1_manshiet_sadr', nameEn: 'Manshiet El Sadr', nameAr: 'منشية الصدر', line: 1,
      latitude: 30.0780, longitude: 31.2800,
      connectedTo: ['l1_demerdash', 'l1_kobri_qobba']),

    'l1_kobri_qobba': const Station(
      id: 'l1_kobri_qobba', nameEn: 'Kobri El Qobba', nameAr: 'كوبري القبة', line: 1,
      latitude: 30.0870, longitude: 31.2900,
      connectedTo: ['l1_manshiet_sadr', 'l1_hammamat_qobba']),

    'l1_hammamat_qobba': const Station(
      id: 'l1_hammamat_qobba', nameEn: 'Hammamat El Qobba', nameAr: 'حمامات القبة', line: 1,
      latitude: 30.0920, longitude: 31.2980,
      connectedTo: ['l1_kobri_qobba', 'l1_saray_qobba']),

    'l1_saray_qobba': const Station(
      id: 'l1_saray_qobba', nameEn: 'Saray El Qobba', nameAr: 'سراي القبة', line: 1,
      latitude: 30.0990, longitude: 31.3060,
      connectedTo: ['l1_hammamat_qobba', 'l1_hadayek_zaitoun']),

    'l1_hadayek_zaitoun': const Station(
      id: 'l1_hadayek_zaitoun', nameEn: 'Hadayek El Zaitoun', nameAr: 'حدائق الزيتون', line: 1,
      latitude: 30.1080, longitude: 31.3130,
      connectedTo: ['l1_saray_qobba', 'l1_helmeyet_zeitoun']),

    'l1_helmeyet_zeitoun': const Station(
      id: 'l1_helmeyet_zeitoun', nameEn: 'Helmeyet El Zeitoun', nameAr: 'حلمية الزيتون', line: 1,
      latitude: 30.1170, longitude: 31.3210,
      connectedTo: ['l1_hadayek_zaitoun', 'l1_matareyya']),

    'l1_matareyya': const Station(
      id: 'l1_matareyya', nameEn: 'El Matareyya', nameAr: 'المطرية', line: 1,
      latitude: 30.1260, longitude: 31.3210,
      connectedTo: ['l1_helmeyet_zeitoun', 'l1_ain_shams']),

    'l1_ain_shams': const Station(
      id: 'l1_ain_shams', nameEn: 'Ain Shams', nameAr: 'عين شمس', line: 1,
      latitude: 30.1330, longitude: 31.3280,
      connectedTo: ['l1_matareyya', 'l1_ezbet_nakhl']),

    'l1_ezbet_nakhl': const Station(
      id: 'l1_ezbet_nakhl', nameEn: 'Ezbet El Nakhl', nameAr: 'عزبة النخل', line: 1,
      latitude: 30.1420, longitude: 31.3350,
      connectedTo: ['l1_ain_shams', 'l1_el_marg']),

    'l1_el_marg': const Station(
      id: 'l1_el_marg', nameEn: 'El Marg', nameAr: 'المرج', line: 1,
      latitude: 30.1517, longitude: 31.3353,
      connectedTo: ['l1_ezbet_nakhl', 'l1_el_marg_gedida']),

    'l1_el_marg_gedida': const Station(
      id: 'l1_el_marg_gedida', nameEn: 'El Marg El Gedida', nameAr: 'المرج الجديدة', line: 1,
      latitude: 30.1630, longitude: 31.3380,
      connectedTo: ['l1_el_marg']),

    // ════════════════════════════════════════════════════════════════════
    // LINE 2 — YELLOW   Shubra El-Kheima ↔ El Mounib   (19 stations)
    // ════════════════════════════════════════════════════════════════════
    'l2_shubra': const Station(
      id: 'l2_shubra', nameEn: 'Shubra El-Kheima', nameAr: 'شبرا الخيمة', line: 2,
      latitude: 30.1225, longitude: 31.2450,
      connectedTo: ['l2_kolleyet_zeraah']),

    'l2_kolleyet_zeraah': const Station(
      id: 'l2_kolleyet_zeraah', nameEn: 'Kolleyet El Zeraah', nameAr: 'كلية الزراعة', line: 2,
      latitude: 30.1100, longitude: 31.2440,
      connectedTo: ['l2_shubra', 'l2_khalafawy']),

    'l2_khalafawy': const Station(
      id: 'l2_khalafawy', nameEn: 'Khalafawy', nameAr: 'خلفاوي', line: 2,
      latitude: 30.0980, longitude: 31.2430,
      connectedTo: ['l2_kolleyet_zeraah', 'l2_st_teresa']),

    'l2_st_teresa': const Station(
      id: 'l2_st_teresa', nameEn: 'St. Teresa', nameAr: 'سانت تيريزا', line: 2,
      latitude: 30.0860, longitude: 31.2450,
      connectedTo: ['l2_khalafawy', 'l2_rod_el_farag']),

    'l2_rod_el_farag': const Station(
      id: 'l2_rod_el_farag', nameEn: 'Rod El Farag', nameAr: 'روض الفرج', line: 2,
      latitude: 30.0740, longitude: 31.2440,
      connectedTo: ['l2_st_teresa', 'l2_masarra']),

    'l2_masarra': const Station(
      id: 'l2_masarra', nameEn: 'El Masarra', nameAr: 'المسرة', line: 2,
      latitude: 30.0670, longitude: 31.2450,
      connectedTo: ['l2_rod_el_farag', 'l2_shohadaa']),

    // ── TRANSFER L2 ↔ L1 ──
    'l2_shohadaa': const Station(
      id: 'l2_shohadaa', nameEn: 'Al Shohadaa', nameAr: 'الشهداء', line: 2,
      latitude: 30.0614, longitude: 31.2464,
      isTransfer: true,
      connectedTo: ['l2_masarra', 'l2_attaba', 'l1_shohadaa'],
      facilities: ['atm', 'wc', 'elevator', 'ticket_office'],
      exits: [
        {'ar': 'مخرج محطة مصر (القطارات)', 'en': 'Ramses Station Exit'},
        {'ar': 'مخرج شارع رمسيس', 'en': 'Ramses Street Exit'},
      ]),

    // ── TRANSFER L2 ↔ L3 ──
    'l2_attaba': const Station(
      id: 'l2_attaba', nameEn: 'Attaba', nameAr: 'العتبة', line: 2,
      latitude: 30.0519, longitude: 31.2461,
      isTransfer: true,
      connectedTo: ['l2_shohadaa', 'l2_mohamed_naguib', 'l3_attaba'],
      facilities: ['atm', 'wc', 'ticket_office'],
      exits: [
        {'ar': 'مخرج سوق العتبة', 'en': 'Attaba Market Exit'},
        {'ar': 'مخرج شارع الجيش', 'en': 'El Geish St. Exit'},
        {'ar': 'مخرج المسرح القومي', 'en': 'National Theater Exit'},
      ]),

    'l2_mohamed_naguib': const Station(
      id: 'l2_mohamed_naguib', nameEn: 'Mohamed Naguib', nameAr: 'محمد نجيب', line: 2,
      latitude: 30.0458, longitude: 31.2433,
      connectedTo: ['l2_attaba', 'l2_sadat']),

    // ── TRANSFER L2 ↔ L1 ──
    'l2_sadat': const Station(
      id: 'l2_sadat', nameEn: 'Sadat', nameAr: 'السادات', line: 2,
      latitude: 30.0444, longitude: 31.2357,
      isTransfer: true,
      connectedTo: ['l2_mohamed_naguib', 'l2_opera', 'l1_sadat'],
      facilities: ['atm', 'wc', 'elevator', 'police_station'],
      exits: [
        {'ar': 'مخرج مجمع التحرير', 'en': 'Mogamma El Tahrir Exit'},
        {'ar': 'مخرج الجامعة الأمريكية', 'en': 'AUC Exit'},
        {'ar': 'مخرج شارع طلعت حرب', 'en': 'Talaat Harb St. Exit'},
        {'ar': 'مخرج المتحف المصري', 'en': 'Egyptian Museum Exit'},
      ]),

    'l2_opera': const Station(
      id: 'l2_opera', nameEn: 'Opera', nameAr: 'الأوبرا', line: 2,
      latitude: 30.0419, longitude: 31.2264,
      connectedTo: ['l2_sadat', 'l2_dokki']),

    'l2_dokki': const Station(
      id: 'l2_dokki', nameEn: 'Dokki', nameAr: 'الدقي', line: 2,
      latitude: 30.0383, longitude: 31.2120,
      connectedTo: ['l2_opera', 'l2_bohooth']),

    'l2_bohooth': const Station(
      id: 'l2_bohooth', nameEn: 'El Bohooth', nameAr: 'البحوث', line: 2,
      latitude: 30.0310, longitude: 31.2050,
      connectedTo: ['l2_dokki', 'l2_cairo_uni']),

    // ── TRANSFER L2 ↔ L3 ──
    'l2_cairo_uni': const Station(
      id: 'l2_cairo_uni', nameEn: 'Cairo University', nameAr: 'جامعة القاهرة', line: 2,
      latitude: 30.0264, longitude: 31.2014,
      isTransfer: true,
      connectedTo: ['l2_bohooth', 'l2_faisal', 'l3_cairo_uni'],
      facilities: ['atm', 'wc', 'elevator'],
      exits: [
        {'ar': 'مخرج جامعة القاهرة', 'en': 'Cairo University Exit'},
        {'ar': 'مخرج شارع الجيزة', 'en': 'Giza St. Exit'},
      ]),

    'l2_faisal': const Station(
      id: 'l2_faisal', nameEn: 'Faisal', nameAr: 'فيصل', line: 2,
      latitude: 30.0150, longitude: 31.2140,
      connectedTo: ['l2_cairo_uni', 'l2_giza']),

    'l2_giza': const Station(
      id: 'l2_giza', nameEn: 'Giza', nameAr: 'الجيزة', line: 2,
      latitude: 30.0075, longitude: 31.2083,
      connectedTo: ['l2_faisal', 'l2_omm_masryeen']),

    'l2_omm_masryeen': const Station(
      id: 'l2_omm_masryeen', nameEn: 'Omm El Masryeen', nameAr: 'أم المصريين', line: 2,
      latitude: 29.9980, longitude: 31.2130,
      connectedTo: ['l2_giza', 'l2_sakiat_mekky']),

    'l2_sakiat_mekky': const Station(
      id: 'l2_sakiat_mekky', nameEn: 'Sakiat Mekky', nameAr: 'ساقية مكي', line: 2,
      latitude: 29.9900, longitude: 31.2130,
      connectedTo: ['l2_omm_masryeen', 'l2_mounib']),

    'l2_mounib': const Station(
      id: 'l2_mounib', nameEn: 'El Mounib', nameAr: 'المنيب', line: 2,
      latitude: 29.9814, longitude: 31.2131,
      connectedTo: ['l2_sakiat_mekky']),

    // ════════════════════════════════════════════════════════════════════
    // LINE 3 — GREEN   Adly Mansour ↔ Cairo University   (25 stations)
    // ════════════════════════════════════════════════════════════════════
    'l3_adly_mansour': const Station(
      id: 'l3_adly_mansour', nameEn: 'Adly Mansour', nameAr: 'عدلي منصور', line: 3,
      latitude: 30.1458, longitude: 31.4239,
      connectedTo: ['l3_haykestep']),

    'l3_haykestep': const Station(
      id: 'l3_haykestep', nameEn: 'El Haykestep', nameAr: 'الهايكستب', line: 3,
      latitude: 30.1340, longitude: 31.4150,
      connectedTo: ['l3_adly_mansour', 'l3_omar_ibn_khattab']),

    'l3_omar_ibn_khattab': const Station(
      id: 'l3_omar_ibn_khattab', nameEn: 'Omar Ibn El Khattab', nameAr: 'عمر بن الخطاب', line: 3,
      latitude: 30.1250, longitude: 31.4020,
      connectedTo: ['l3_haykestep', 'l3_qobaa']),

    'l3_qobaa': const Station(
      id: 'l3_qobaa', nameEn: 'Qobaa', nameAr: 'قبة', line: 3,
      latitude: 30.1170, longitude: 31.3880,
      connectedTo: ['l3_omar_ibn_khattab', 'l3_hesham_barakat']),

    'l3_hesham_barakat': const Station(
      id: 'l3_hesham_barakat', nameEn: 'Hesham Barakat', nameAr: 'هشام بركات', line: 3,
      latitude: 30.1090, longitude: 31.3740,
      connectedTo: ['l3_qobaa', 'l3_el_nozha']),

    'l3_el_nozha': const Station(
      id: 'l3_el_nozha', nameEn: 'El Nozha', nameAr: 'النزهة', line: 3,
      latitude: 30.1020, longitude: 31.3600,
      connectedTo: ['l3_hesham_barakat', 'l3_nadi_shams']),

    'l3_nadi_shams': const Station(
      id: 'l3_nadi_shams', nameEn: 'Nadi El Shams', nameAr: 'نادي الشمس', line: 3,
      latitude: 30.0970, longitude: 31.3440,
      connectedTo: ['l3_el_nozha', 'l3_alf_maskan']),

    'l3_alf_maskan': const Station(
      id: 'l3_alf_maskan', nameEn: 'Alf Maskan', nameAr: 'ألف مسكن', line: 3,
      latitude: 30.0900, longitude: 31.3320,
      connectedTo: ['l3_nadi_shams', 'l3_el_ahram']),

    'l3_el_ahram': const Station(
      id: 'l3_el_ahram', nameEn: 'El Ahram', nameAr: 'الأهرام', line: 3,
      latitude: 30.0840, longitude: 31.3180,
      connectedTo: ['l3_alf_maskan', 'l3_koleyet_banat']),

    'l3_koleyet_banat': const Station(
      id: 'l3_koleyet_banat', nameEn: 'Koleyet El Banat', nameAr: 'كلية البنات', line: 3,
      latitude: 30.0780, longitude: 31.3050,
      connectedTo: ['l3_el_ahram', 'l3_cairo_stadium']),

    'l3_cairo_stadium': const Station(
      id: 'l3_cairo_stadium', nameEn: 'Cairo Stadium', nameAr: 'ستاد القاهرة', line: 3,
      latitude: 30.0730, longitude: 31.2960,
      connectedTo: ['l3_koleyet_banat', 'l3_ard_maared']),

    'l3_ard_maared': const Station(
      id: 'l3_ard_maared', nameEn: 'Ard El Maared', nameAr: 'أرض المعارض', line: 3,
      latitude: 30.0690, longitude: 31.2870,
      connectedTo: ['l3_cairo_stadium', 'l3_abbassia']),

    'l3_abbassia': const Station(
      id: 'l3_abbassia', nameEn: 'Abbassia', nameAr: 'العباسية', line: 3,
      latitude: 30.0633, longitude: 31.2858,
      connectedTo: ['l3_ard_maared', 'l3_abdou_basha']),

    'l3_abdou_basha': const Station(
      id: 'l3_abdou_basha', nameEn: 'Abdou Basha', nameAr: 'عبده باشا', line: 3,
      latitude: 30.0600, longitude: 31.2750,
      connectedTo: ['l3_abbassia', 'l3_el_geish']),

    'l3_el_geish': const Station(
      id: 'l3_el_geish', nameEn: 'El Geish', nameAr: 'الجيش', line: 3,
      latitude: 30.0560, longitude: 31.2650,
      connectedTo: ['l3_abdou_basha', 'l3_bab_shaaria']),

    'l3_bab_shaaria': const Station(
      id: 'l3_bab_shaaria', nameEn: 'Bab El Shaaria', nameAr: 'باب الشعرية', line: 3,
      latitude: 30.0530, longitude: 31.2540,
      connectedTo: ['l3_el_geish', 'l3_attaba']),

    // ── TRANSFER L3 ↔ L2 ──
    'l3_attaba': const Station(
      id: 'l3_attaba', nameEn: 'Attaba', nameAr: 'العتبة', line: 3,
      latitude: 30.0519, longitude: 31.2461,
      isTransfer: true,
      connectedTo: ['l3_bab_shaaria', 'l3_maspero', 'l2_attaba'],
      facilities: ['atm', 'wc', 'ticket_office'],
      exits: [
        {'ar': 'مخرج سوق العتبة', 'en': 'Attaba Market Exit'},
        {'ar': 'مخرج شارع الجيش', 'en': 'El Geish St. Exit'},
      ]),

    'l3_maspero': const Station(
      id: 'l3_maspero', nameEn: 'Maspero', nameAr: 'ماسبيرو', line: 3,
      latitude: 30.0536, longitude: 31.2331,
      connectedTo: ['l3_attaba', 'l3_nasser']),

    // ── TRANSFER L3 ↔ L1 ──
    'l3_nasser': const Station(
      id: 'l3_nasser', nameEn: 'Gamal Abd El Nasser', nameAr: 'جمال عبد الناصر', line: 3,
      latitude: 30.0528, longitude: 31.2394,
      isTransfer: true,
      connectedTo: ['l3_maspero', 'l3_kitkat', 'l1_nasser'],
      facilities: ['atm', 'wc', 'elevator'],
      exits: [
        {'ar': 'مخرج شارع رمسيس', 'en': 'Ramses St. Exit'},
        {'ar': 'مخرج ماسبيرو', 'en': 'Maspero Exit'},
      ]),

    'l3_kitkat': const Station(
      id: 'l3_kitkat', nameEn: 'Kit Kat', nameAr: 'كيت كات', line: 3,
      latitude: 30.0617, longitude: 31.2136,
      connectedTo: ['l3_nasser', 'l3_tawfikeya']),

    'l3_tawfikeya': const Station(
      id: 'l3_tawfikeya', nameEn: 'El Tawfikeya', nameAr: 'التوفيقية', line: 3,
      latitude: 30.0520, longitude: 31.2060,
      connectedTo: ['l3_kitkat', 'l3_wadi_el_nil']),

    'l3_wadi_el_nil': const Station(
      id: 'l3_wadi_el_nil', nameEn: 'Wadi El Nil', nameAr: 'وادي النيل', line: 3,
      latitude: 30.0440, longitude: 31.2050,
      connectedTo: ['l3_tawfikeya', 'l3_gameat_dewal']),

    'l3_gameat_dewal': const Station(
      id: 'l3_gameat_dewal', nameEn: 'Gameat El Dewal', nameAr: 'جامعة الدول العربية', line: 3,
      latitude: 30.0380, longitude: 31.2040,
      connectedTo: ['l3_wadi_el_nil', 'l3_bolak_dakrour']),

    'l3_bolak_dakrour': const Station(
      id: 'l3_bolak_dakrour', nameEn: 'Boulak El Dakrour', nameAr: 'بولاق الدكرور', line: 3,
      latitude: 30.0310, longitude: 31.1950,
      connectedTo: ['l3_gameat_dewal', 'l3_cairo_uni']),

    // ── TRANSFER L3 ↔ L2 ──
    'l3_cairo_uni': const Station(
      id: 'l3_cairo_uni', nameEn: 'Cairo University', nameAr: 'جامعة القاهرة', line: 3,
      latitude: 30.0264, longitude: 31.2014,
      isTransfer: true,
      connectedTo: ['l3_bolak_dakrour', 'l2_cairo_uni'],
      facilities: ['atm', 'wc', 'elevator'],
      exits: [
        {'ar': 'مخرج جامعة القاهرة', 'en': 'Cairo University Exit'},
        {'ar': 'مخرج شارع الجيزة', 'en': 'Giza St. Exit'},
      ]),
  };
}
