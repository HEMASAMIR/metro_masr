import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/connectivity_service.dart';
import '../../../../core/utils/gemini_ai_service.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/utils/ad_service.dart';

class AiTriviaChallengePage extends StatefulWidget {
  const AiTriviaChallengePage({super.key});

  @override
  State<AiTriviaChallengePage> createState() => _AiTriviaChallengePageState();
}

class _AiTriviaChallengePageState extends State<AiTriviaChallengePage> {
  int _score = 0;
  int _lives = 3;
  int _currentIndex = 0;
  int _highScore = 0;
  bool _isLoading = false;
  bool _answered = false;
  int? _selectedOption;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  List<Map<String, dynamic>> _questions = [];

  // Curated questions database (50 questions covering history, facts, and Egyptian metro humor)
  final List<Map<String, dynamic>> _offlineQuestions = [
    {
      "questionAr": "ما هي الجملة السحرية التي تقال لفتح ممر في زحمة المترو عند الباب؟",
      "questionEn": "What is the magic phrase used to open a path near the door in a crowded metro?",
      "optionsAr": ["لو سمحت وسع", "والله العظيم لتنزل!", "معلش يا جماعة الباب المحطة الجاية", "أنا مستعجل جداً"],
      "optionsEn": ["Excuse me, move", "By God you are getting off!", "Sorry guys, I need the door next station", "I am in a huge hurry"],
      "answerIndex": 2,
      "explanationAr": "هذه الجملة كفيلة بجعل الركاب يتحركون تلقائياً لفتح ممر لك وكأنها تعويذة سحرية!",
      "explanationEn": "This phrase automatically signals others to clear a path for you as if it were a magic spell!"
    },
    {
      "questionAr": "أي من هذه المحطات سميت على اسم أول رئيس لجمهورية مصر العربية؟",
      "questionEn": "Which of these stations is named after the first President of Egypt?",
      "optionsAr": ["محطة أنور السادات", "محطة محمد نجيب", "محطة جمال عبد الناصر", "محطة حسني مبارك"],
      "optionsEn": ["Anwar El Sadat", "Mohamed Naguib", "Gamal Abdel Nasser", "Hosni Mubarak"],
      "answerIndex": 1,
      "explanationAr": "محطة محمد نجيب بالخط الثاني سميت تخليداً لذكرى أول رئيس لمصر بعد ثورة 1952.",
      "explanationEn": "Mohamed Naguib station on Line 2 is named in memory of Egypt's first president after the 1952 revolution."
    },
    {
      "questionAr": "أين تجد 'خزنة الأمان الأبدية' لحفظ تذكرة المترو أثناء الرحلة عند المواطن المصري؟",
      "questionEn": "Where is the 'eternal safety vault' for keeping the metro ticket during the trip for Egyptians?",
      "optionsAr": ["في المحفظة الجلدية", "تحت اللسان", "في جيب البنطلون الخلفي", "في اليد طوال الوقت"],
      "optionsEn": ["In the leather wallet", "Under the tongue", "In the back pocket", "In the hand the entire time"],
      "answerIndex": 1,
      "explanationAr": "تحت اللسان هي المكان الأكثر أماناً وموثوقية لحماية التذكرة من التلف أو الضياع وسط الزحام المصري الممتع!",
      "explanationEn": "Under the tongue is the ultimate secure spot to save the ticket from getting lost in the crowd!"
    },
    {
      "questionAr": "كم عدد خطوط مترو أنفاق القاهرة العاملة حالياً بالكامل؟",
      "questionEn": "How many Cairo Metro lines are currently fully operational?",
      "optionsAr": ["خطين", "3 خطوط", "4 خطوط", "5 خطوط"],
      "optionsEn": ["2 Lines", "3 Lines", "4 Lines", "5 Lines"],
      "answerIndex": 1,
      "explanationAr": "يعمل حالياً ثلاثة خطوط كاملة، مع بدء مراحل التشغيل التجريبي والإنشاء للخطوط الأخرى.",
      "explanationEn": "Currently three lines are fully operational, with others under construction or trial phases."
    },
    {
      "questionAr": "ماذا يحدث إذا دخل رجل بالخطأ عربة السيدات في المترو؟",
      "questionEn": "What happens if a man accidentally enters the ladies' carriage on the metro?",
      "optionsAr": ["يتم ترحيبه بالورود والقهوة", "يسمع 'زفة بلدي' من الراكبات ويفر هارباً", "يعاقب بغرامة مالية فورية", "يتم نقله لعربة القيادة"],
      "optionsEn": ["Welcomed with flowers and coffee", "Gets a public 'Zaffa' scolding and runs away", "Gets an immediate cash fine", "Moved to the driver's cabin"],
      "answerIndex": 1,
      "explanationAr": "الدخول لعربة السيدات خطأ فادح ينتج عنه زفة بلدي وتنبيه جماعي حاد يجعله يندم على اليوم الذي ركب فيه المترو!",
      "explanationEn": "Entering the ladies' carriage is a huge mistake that triggers collective warnings and scolding!"
    },
    {
      "questionAr": "أي محطة تعتبر أكبر محطة مترو تبادلية في أفريقيا والشرق الأوسط؟",
      "questionEn": "Which station is the largest metro interchange hub in Africa and the Middle East?",
      "optionsAr": ["محطة الشهداء", "محطة السادات", "محطة عدلي منصور", "محطة العتبة"],
      "optionsEn": ["Al Shohadaa", "Sadat", "Adly Mansour", "Attaba"],
      "answerIndex": 2,
      "explanationAr": "محطة عدلي منصور بالخط الثالث هي محطة تبادلية عملاقة تضم المترو، القطار الكهربائي LRT، السوبرجيت، والأوتوبيس الترددي.",
      "explanationEn": "Adly Mansour on Line 3 is a mega transport hub linking Metro, LRT, Superjet, and BRT buses."
    },
    {
      "questionAr": "ما هو المنتج الأكثر مبيعاً وشهرة داخل عربات المترو من الباعة الجائلين؟",
      "questionEn": "What is the most famous product sold inside metro carriages by street vendors?",
      "optionsAr": ["ساعات رولكس الذكية", "الشرابات والمناديل ومنظم السلوك", "روايات عالمية مترجمة", "وجبات كشري ساخنة"],
      "optionsEn": ["Smart Rolex watches", "Socks, tissues, and wire organizers", "Translated global novels", "Hot Koshary meals"],
      "answerIndex": 1,
      "explanationAr": "الباعة الجائلين يقدمون تشكيلة أسطورية من الجوارب والمناديل بأسعار خيالية لا تقبل المنافسة!",
      "explanationEn": "Street vendors offer an legendary selection of socks and tissues at unbeatable prices!"
    },
    {
      "questionAr": "ماذا كان الاسم السابق لمحطة 'الشهداء' بالخط الأول والثاني؟",
      "questionEn": "What was the previous name of 'Al Shohadaa' station on Lines 1 and 2?",
      "optionsAr": ["مبارك", "رمسيس", "مصر", "جمال عبد الناصر"],
      "optionsEn": ["Mubarak", "Ramses", "Misr", "Gamal Abdel Nasser"],
      "answerIndex": 0,
      "explanationAr": "كانت تسمى محطة 'مبارك' وتغير اسمها إلى 'الشهداء' بعد ثورة 25 يناير 2011 تخليداً للشهداء.",
      "explanationEn": "It was named 'Mubarak' and renamed to 'Al Shohadaa' after the January 25, 2011 revolution."
    },
    {
      "questionAr": "عندما ترى قطار المترو على وشك الإغلاق وتبدأ بالجري السريع جداً، ما هو القانون غير المكتوب؟",
      "questionEn": "When you run to catch the metro as the doors close, what is the unwritten law?",
      "optionsAr": ["أن تنجح دائماً في اللحاق به", "أن يغلق الباب على حقيبتك أو يدك وتكمل الجري", "أن ينتظرك السائق بأدب", "أن يصفق لك الركاب"],
      "optionsEn": ["You always succeed in entering smoothly", "The doors trap your bag or arm, and you keep running", "The driver politely waits for you", "Passengers applaud your speed"],
      "answerIndex": 1,
      "explanationAr": "إغلاق الباب على الحقيبة هو المشهد الكلاسيكي المعتاد في اللحظات الأخيرة المليئة بالأدرينالين!",
      "explanationEn": "Having the door clamp shut on your backpack is the classic, adrenaline-pumping metro finale!"
    },
    {
      "questionAr": "أي محطة يجب أن تنزل بها لزيارة جامع الأزهر الشريف وخان الخليلي؟",
      "questionEn": "Which station should you exit to visit Al-Azhar Mosque and Khan El-Khalili?",
      "optionsAr": ["محطة العتبة", "محطة باب الشعرية", "محطة الجيش", "محطة الأوبرا"],
      "optionsEn": ["Attaba", "Bab El Shaariya", "El Geish", "Opera"],
      "answerIndex": 1,
      "explanationAr": "محطة باب الشعرية بالخط الثالث هي الأقرب والأنسب للوصول مباشرة لخان الخليلي والأزهر الشريف.",
      "explanationEn": "Bab El Shaariya station on Line 3 is the closest and most convenient for reaching Al-Azhar and Khan El-Khalili."
    },
    {
      "questionAr": "ما هو السلوك الرسمي المعتمد للوقوف على السلم الكهربائي في محطات المترو المزدحمة؟",
      "questionEn": "What is the correct etiquette for standing on the escalator in crowded stations?",
      "optionsAr": ["الوقوف في جهة اليمين وترك اليسار للمستعجلين", "الوقوف في المنتصف لتعطيل الجميع", "الجلوس على الدرج والاسترخاء", "الصعود بعكس الاتجاه كنوع من الرياضة"],
      "optionsEn": ["Stand on the right and leave the left for people walking", "Stand in the middle to block everyone", "Sit on the stairs and relax", "Walk in the opposite direction for cardio"],
      "answerIndex": 0,
      "explanationAr": "الوقوف يميناً وترك اليسار لمن يجرون للحاق بالقطار هو قانون الذوق العام في المترو!",
      "explanationEn": "Standing on the right and leaving the left for those running to catch the train is the basic rule of courtesy!"
    },
    {
      "questionAr": "محطة 'أنور السادات' تقع مباشرة أسفل أي معلم شهير في القاهرة؟",
      "questionEn": "Which famous Cairo landmark is Sadat station located directly beneath?",
      "optionsAr": ["برج القاهرة", "ميدان التحرير", "قلعة صلاح الدين", "حديقة الأزهر"],
      "optionsEn": ["Cairo Tower", "Tahrir Square", "Salah Al-Din Citadel", "Al-Azhar Park"],
      "answerIndex": 1,
      "explanationAr": "محطة السادات تقع في قلب ميدان التحرير التاريخي، وتعتبر محطة تبادلية هامة جداً بين الخطين الأول والثاني.",
      "explanationEn": "Sadat station lies right beneath the historic Tahrir Square and serves as a major interchange between Lines 1 & 2."
    },
    {
      "questionAr": "إذا سمعت بائعاً يقول 'الـ 3 بـ 10 جنيه والـ 7 بـ 20'، فماذا يبيع غالباً؟",
      "questionEn": "If you hear a vendor calling '3 for 10 EGP and 7 for 20', what is he likely selling?",
      "optionsAr": ["سماعات بلوتوث", "شرابات (جوارب) قطن مصري", "شواحن هواتف ذكية", "تذاكر مترو مستعملة"],
      "optionsEn": ["Bluetooth earpieces", "Egyptian cotton socks", "Smart phone chargers", "Used metro tickets"],
      "answerIndex": 1,
      "explanationAr": "هذه هي المعادلة الرياضية والنداء الأشهر لبيع الجوارب في عربات المترو!",
      "explanationEn": "This is the most famous math equation and sales pitch for selling socks on the train!"
    },
    {
      "questionAr": "ما هي أعمق محطة مترو أنفاق نفقية بالكامل في شبكة مترو القاهرة؟",
      "questionEn": "What is the deepest fully underground station in the Cairo Metro network?",
      "optionsAr": ["محطة العتبة", "محطة هليوبوليس", "محطة السادات", "محطة ألف مسكن"],
      "optionsEn": ["Attaba", "Heliopolis", "Sadat", "Alf Maskan"],
      "answerIndex": 1,
      "explanationAr": "محطة هليوبوليس بالخط الثالث تعتبر من أكبر وأعمق المحطات النفقية في الشرق الأوسط بمساحة تزيد عن 10 آلاف متر مربع.",
      "explanationEn": "Heliopolis station on Line 3 is one of the largest and deepest underground stations in the Middle East."
    },
    {
      "questionAr": "ما هو التصرف التلقائي للمواطن عندما تعلن سماعة المترو 'عطل فني مؤقت والقطار سيتوقف قليلًا'؟",
      "questionEn": "What is the default reaction when the speaker announces 'a temporary technical failure and the train will stop'?",
      "optionsAr": ["تنهيدة جماعية موحدة مع جملة 'يا مسهل الحال يا رب'", "النزول فوراً والمشي على القضبان", "الاتصال بوزير النقل مباشرة", "النوم الفوري على المقعد"],
      "optionsEn": ["A unified collective sigh saying 'Ya Mesahel El Hal'", "Exiting immediately to walk on the tracks", "Calling the Minister of Transportation", "Sleeping instantly on the seat"],
      "answerIndex": 0,
      "explanationAr": "التنهيدة الجماعية والدعاء بالفرج هي رد الفعل المصري الدافئ والصبور لمواجهة الأعطال المفاجئة!",
      "explanationEn": "A collective sigh and a soft prayer is the warm and patient Egyptian way of facing sudden delays!"
    },
    {
      "questionAr": "في أي عام تم افتتاح الخط الأول لمترو القاهرة (حلوان - المرج)؟",
      "questionEn": "In which year was Cairo Metro Line 1 (Helwan - El Marg) opened?",
      "optionsAr": ["1980", "1987", "1995", "2000"],
      "optionsEn": ["1980", "1987", "1995", "2000"],
      "answerIndex": 1,
      "explanationAr": "تم افتتاح المرحلة الأولى من الخط الأول في عام 1987 ليكون الأول من نوعه في أفريقيا والشرق الأوسط.",
      "explanationEn": "The first phase of Line 1 opened in 1987, making it the first of its kind in Africa and the Middle East."
    },
    {
      "questionAr": "ما هي 'زقة القدر الكبرى' في قاموس مترو القاهرة؟",
      "questionEn": "What is 'The Great Shove of Destiny' in the Cairo Metro dictionary?",
      "optionsAr": ["زقة لتلحق الباب قبل الإغلاق", "الدفع البشري التلقائي الذي يدخلك العربة دون أن تحرك قدميك في محطة العتبة", "زق صديقك ليمزح معك", "دفع عربة المترو المعطلة"],
      "optionsEn": ["A push to catch the door before closing", "The human wave that pushes you into the train without moving your feet at Attaba", "Pushing your friend as a joke", "Pushing a broken metro carriage"],
      "answerIndex": 1,
      "explanationAr": "في المحطات المزدحمة كالعتبة والشهداء، تيار البشر كفيل بحملك لداخل القطار بدون أي مجهود عضلي منك!",
      "explanationEn": "In highly congested stations like Attaba, the human wave carries you right in without any physical effort!"
    },
    {
      "questionAr": "أي محطة تخدم منطقة المتحف المصري الكبير (GEM) بشكل مباشر في المستقبل؟",
      "questionEn": "Which station will serve the Grand Egyptian Museum (GEM) directly in the future?",
      "optionsAr": ["محطة الأهرام", "محطة حدائق الأهرام", "محطة الرماية", "محطة المتحف الكبير (الخط الرابع)"],
      "optionsEn": ["Al Ahram", "Hadayek El Ahram", "El Remayah", "Grand Egyptian Museum (Line 4)"],
      "answerIndex": 3,
      "explanationAr": "محطة المتحف الكبير على الخط الرابع قيد الإنشاء ستخدم ملايين السياح لزيارة المتحف الكبير والأهرامات.",
      "explanationEn": "The Grand Egyptian Museum station on the upcoming Line 4 will serve tourists visiting the museum and Pyramids."
    },
    {
      "questionAr": "ما هي الجملة التي تعني أن الشخص الذي خلفك يريد النزول في المحطة القادمة؟",
      "questionEn": "What is the phrase used to ask if the person in front is getting off next station?",
      "optionsAr": ["نازل يا كابتن؟", "وسع من فضلك", "هل المحطة القادمة هي محطتك؟", "أنا مغادر الآن"],
      "optionsEn": ["Getting off, captain?", "Step aside please", "Is the next station yours?", "I am leaving now"],
      "answerIndex": 0,
      "explanationAr": "سؤال 'نازل يا كابتن؟' هو الإشارة الرسمية للاستعداد لتبادل الأماكن قبل فتح الأبواب!",
      "explanationEn": "Asking 'Nazel ya captain?' is the official cue to prepare to swap spots before the doors open!"
    },
    {
      "questionAr": "محطة مترو 'مار جرجس' تقع مباشرة في أي منطقة تاريخية؟",
      "questionEn": "Where is the Mar Girgis metro station located historically?",
      "optionsAr": ["مصر القديمة (مجمع الأديان)", "مصر الجديدة", "المعادي", "شبرا الخيمة"],
      "optionsEn": ["Old Cairo (Coptic Cairo)", "Heliopolis", "Maadi", "Shubra El Kheima"],
      "answerIndex": 0,
      "explanationAr": "تقع محطة مار جرجس في قلب مجمع الأديان بمصر القديمة بجوار الكنيسة المعلقة والمتحف القبطي ومعبد بن عزرا.",
      "explanationEn": "Mar Girgis station is located in the heart of Coptic Cairo, next to the Hanging Church and the Coptic Museum."
    },
    {
      "questionAr": "ما هو سر سرعة اختفاء تذكرة المترو بمجرد شرائها من شباك التذاكر؟",
      "questionEn": "What is the secret of the quick disappearance of a metro ticket right after buying it?",
      "optionsAr": ["السحر الأسود", "توضع في جيب سري مجهول لا يتذكره أحد إلا أمام البوابة", "تطير مع الهواء", "تذوب من حرارة اليد"],
      "optionsEn": ["Black magic", "Placed in a secret pocket you only forget until reaching the gates", "Flies away with the wind", "Melts from hand temperature"],
      "answerIndex": 1,
      "explanationAr": "لحظة الوقوف أمام ماكينة العبور هي اللحظة التاريخية للبحث عن التذكرة الضائعة في كل الجيوب!",
      "explanationEn": "The moment you stand before the turnstile is the official search-party moment for your lost ticket!"
    },
    {
      "questionAr": "أي محطة تقع أسفل ميدان التحرير وتربط الخط الأول والثاني؟",
      "questionEn": "Which station lies directly under Tahrir Square, connecting Lines 1 & 2?",
      "optionsAr": ["محطة السادات", "محطة الشهداء", "محطة العتبة", "محطة الأوبرا"],
      "optionsEn": ["Sadat", "Al Shohadaa", "Attaba", "Opera"],
      "answerIndex": 0,
      "explanationAr": "محطة أنور السادات تقع في قلب ميدان التحرير التاريخي، وتعتبر محطة تبادلية بالغة الأهمية.",
      "explanationEn": "Anwar Sadat station lies beneath Tahrir Square, linking Line 1 and Line 2."
    },
    {
      "questionAr": "أشهر شخصية تقابلها في محطة المترو وتقوم بتوجيه الجميع للماكينات الصحيحة هي:",
      "questionEn": "The most famous person you meet at the gates instructing everyone is:",
      "optionsAr": ["وزير النقل", "عم صلاح بائع التذاكر", "رجل الأمن الذي يصرخ 'التذكرة في اليمين والشنطة على السير'", "سائق المترو"],
      "optionsEn": ["The Minister of Transport", "Uncle Salah the ticket guy", "The guard shouting 'Ticket on the right, bag on the belt'", "The train driver"],
      "answerIndex": 2,
      "explanationAr": "العبارة الإرشادية الأشهر عند بوابات الدخول لتنظيم حركة المرور البشري!",
      "explanationEn": "The most famous instructional guide at the gates to keep the human flow moving!"
    },
    {
      "questionAr": "من هو الشخص الذي سميت باسمه محطة 'أحمد عرابي' بالخط الأول؟",
      "questionEn": "Who is Ahmed Orabi station on Line 1 named after?",
      "optionsAr": ["شاعر مصري شهير", "قائد الثورة العرابية ضد الخديوي توفيق", "أول مهندس للمترو", "رئيس وزراء سابق"],
      "optionsEn": ["A famous Egyptian poet", "Leader of the Orabi Revolt against Khedive Tewfik", "The first metro engineer", "A former prime minister"],
      "answerIndex": 1,
      "explanationAr": "سميت المحطة تخليداً لاسم الزعيم العسكري أحمد عرابي صاحب الوقفة الشهيرة أمام قصر عابدين.",
      "explanationEn": "The station is named in memory of military leader Ahmed Orabi, famous for standing up to the Khedive."
    },
    {
      "questionAr": "ما هو الشيء الذي يحذر الجميع من لمسه أو الوقوف بجانبه على رصيف المترو؟",
      "questionEn": "What are you warned not to cross or stand on while waiting on the platform?",
      "optionsAr": ["صندوق القمامة", "الخط الأصفر التحذيري على حافة الرصيف", "لوحة الإعلانات", "أعمدة الإنارة"],
      "optionsEn": ["The trash bin", "The yellow warning line on the edge of the platform", "The billboard", "The light poles"],
      "answerIndex": 1,
      "explanationAr": "الخط الأصفر هو الحد الفاصل بين الأمان وجاذبية الهواء عند قدوم القطار بسرعة!",
      "explanationEn": "The yellow line is the thin line between safety and the heavy wind of the incoming train!"
    },
    {
      "questionAr": "محطة مترو 'الأوبرا' تخرجك مباشرة بجوار أي دار فنون عريقة؟",
      "questionEn": "Opera station drops you right next to which famous arts center?",
      "optionsAr": ["دار الأوبرا المصرية بالجزيرة", "مسرح البالون", "مسرح الطليعة", "سينما رادوبيس"],
      "optionsEn": ["The Cairo Opera House on Gezira", "The Balloon Theater", "The Avant-Garde Theater", "Radobis Cinema"],
      "answerIndex": 0,
      "explanationAr": "المحطة تقع بجوار دار الأوبرا المصرية العريقة ومتحف الفن الحديث.",
      "explanationEn": "The station is located right next to the historic Cairo Opera House and Museum of Modern Art."
    },
    {
      "questionAr": "لماذا يعتبر الجري خلف قطار المترو رياضة شعبية في القاهرة؟",
      "questionEn": "Why is running after the metro considered a popular sport in Cairo?",
      "optionsAr": ["لأن القطار القادم سيصل بعد ساعة كاملة", "لأن الجميع يعشق التحدي واللياقة البدنية", "لأن الباب سيغلق وهناك 3 ثوانٍ متبقية فقط", "لعدم وجود صالات رياضية بالمنطقة"],
      "optionsEn": ["Because the next train takes an hour to arrive", "Because everyone loves challenge and fitness", "Because the doors are closing and you have 3 seconds left", "Because there are no gyms nearby"],
      "answerIndex": 2,
      "explanationAr": "الجري الانتحاري في الثواني الأخيرة يمنح الراكب شعوراً بالإنجاز الأسطوري عند النجاح بالدخول!",
      "explanationEn": "Running in the last few seconds gives commuters a sense of epic accomplishment when they slip in!"
    },
    {
      "questionAr": "أي محطة سميت باسم زعيم ثورة 1919 التاريخية؟",
      "questionEn": "Which station is named after the leader of the historic 1919 revolution?",
      "optionsAr": ["محطة سعد زغلول", "محطة مصطفى كامل", "محطة محمد فريد", "محطة جمال عبد الناصر"],
      "optionsEn": ["Saad Zaghloul", "Mustafa Kamel", "Mohamed Farid", "Gamal Abdel Nasser"],
      "answerIndex": 0,
      "explanationAr": "سميت المحطة تخليداً لاسم الزعيم سعد زغلول قائد ثورة 1919 التاريخية للمطالبة بالاستقلال.",
      "explanationEn": "The station is named after Saad Zaghloul, the leader of the historic 1919 Egyptian Revolution."
    },
    {
      "questionAr": "ما هي أسرع وسيلة لمعرفة أن القطار قد وصل للرصيف بدون النظر للقضبان؟",
      "questionEn": "What is the fastest way to know the train arrived without looking at the tracks?",
      "optionsAr": ["سماع صوت الهواء المضغوط واهتزاز الأرض وهجوم الركاب نحو الباب", "الاتصال بخدمة العملاء", "النظر في الساعة", "سماع زقزقة العصافير"],
      "optionsEn": ["Compressed air sound, ground vibration, and sudden passenger movement", "Calling customer support", "Looking at your watch", "Hearing birds chirping"],
      "answerIndex": 0,
      "explanationAr": "الاهتزاز الأرضي وحالة الاستنفار العام للركاب هما المؤشر الطبيعي لوصول القطار!",
      "explanationEn": "The vibration under your feet and the sudden movement of passengers are the organic train arrival signals!"
    },
    {
      "questionAr": "ما هي المحطة التبادلية التي تربط بين الخطين الثاني والثالث وتعتبر مركزاً تجارياً ضخماً؟",
      "questionEn": "Which interchange station connects Lines 2 & 3 and is a major commercial hub?",
      "optionsAr": ["محطة العتبة", "محطة ناصر", "محطة السادات", "محطة الشهداء"],
      "optionsEn": ["Attaba", "Nasser", "Sadat", "Al Shohadaa"],
      "answerIndex": 0,
      "explanationAr": "محطة العتبة هي نقطة التلاقي الشهيرة بين الخط الثاني والخط الثالث وتخدم منطقة تجارية عريقة.",
      "explanationEn": "Attaba station connects Line 2 and Line 3, and serves one of Cairo's oldest commercial markets."
    },
    {
      "questionAr": "ما هي الفئة الأكثر رعباً في المترو بالنسبة للشخص الذي نسى شراء التذكرة؟",
      "questionEn": "Who is the most feared person on the metro for a passenger who forgot to buy a ticket?",
      "optionsAr": ["ركاب الدرجة الأولى", "موظفو شباك التذاكر", "مشرفو المحطة وكاميرات المراقبة", "مفتش التذاكر (الكمسري) عند بوابات الخروج"],
      "optionsEn": ["First class passengers", "Ticket counter staff", "Station supervisors & CCTV", "The Ticket Inspector (Komsary) at the exit gates"],
      "answerIndex": 3,
      "explanationAr": "الكمسري الواقف عند الماكينات يمتلك عيون الصقر لكشف المخالفين وتغريمهم فوراً!",
      "explanationEn": "The inspector standing at the turnstiles has hawk-eyes for spotting ticketless passengers!"
    },
    {
      "questionAr": "محطة 'باب الشعرية' بالخط الثالث سميت نسبة إلى:",
      "questionEn": "Bab El Shaariya station on Line 3 was named after:",
      "optionsAr": ["أكلة الشعرية باللبن الشهيرة", "طائفة عسكرية من البربر تسمى 'بنو الشعرية' استقرت هناك قديماً", "سوق لبيع الشعر والنثر", "مصنع نسيج قديم"],
      "optionsEn": ["The famous Egyptian sweet noodle dish", "A Berber military faction called 'Banu Shaariya' who settled there", "A market for poetry and books", "An old textile factory"],
      "answerIndex": 1,
      "explanationAr": "تنسب التسمية لطائفة من البربر كانوا يؤلفون حامية عسكرية استقرت هناك في عهد الفاطميين.",
      "explanationEn": "It is named after Banu Shaariya, a Berber military faction that settled there during the Fatimid era."
    },
    {
      "questionAr": "ماذا تعني إشارة الرأس الخفيفة من بعيد لشخص يبحث عن مقعد خالي في عربة المترو؟",
      "questionEn": "What does a slight head nod from a distance mean for someone looking for a seat?",
      "optionsAr": ["الترحيب الحار والتعارف", "التنبيه بأن المقعد محجوز لصديق نازل المحطة الجاية", "التحدي في مبارزة صامتة", "طلب المساعدة المالية"],
      "optionsEn": ["Warm greeting and friendship", "Signaling that the seat is saved for a friend getting off next", "A challenge in a silent duel", "Asking for financial help"],
      "answerIndex": 1,
      "explanationAr": "حجز المقاعد الصامت بلغة الجسد هو جزء من إتيكيت المترو غير الرسمي في أوقات الزحام!",
      "explanationEn": "Reserving seats silently with body language is part of the unofficial metro etiquette during rush hours!"
    },
    {
      "questionAr": "أي محطة تتيح لك الانتقال مباشرة إلى جامعة عين شمس العريقة؟",
      "questionEn": "Which station lets you walk directly into the historic Ain Shams University?",
      "optionsAr": ["محطة جامعة القاهرة", "محطة الدمرداش", "محطة العباسية", "محطة منشية الصدر"],
      "optionsEn": ["Cairo University", "El Demerdash", "Abbassia", "Manshiet El Sadr"],
      "answerIndex": 3,
      "explanationAr": "محطة منشية الصدر بالخط الأول تقع أمام البوابة الرئيسية للحرم الجامعي لجامعة عين شمس.",
      "explanationEn": "Manshiet El Sadr station on Line 1 exits directly in front of the main gates of Ain Shams University."
    },
    {
      "questionAr": "ما هي المقولة الشعبية لوصف حالة الازدحام الشديد داخل عربة المترو في الصباح؟",
      "questionEn": "What is the popular Egyptian saying for describing the extreme crowd in the morning?",
      "optionsAr": ["فسحة مريحة للجميع", "مفيش مكان لقدم (على قلب بعض)", "صالة ألعاب رياضية مجانية", "هدوء ما قبل العاصفة"],
      "optionsEn": ["A comfortable cruise", "No place to step (on each other's hearts)", "A free gym workout", "The calm before the storm"],
      "answerIndex": 1,
      "explanationAr": "تعبير شعبي يدل على قمة الالتحام البشري في رحلة الذهاب للعمل الصباحية!",
      "explanationEn": "A classic Egyptian idiom indicating maximum physical compression on the morning commute!"
    },
    {
      "questionAr": "من هو الشخص الذي سميت باسمه محطة 'جمال عبد الناصر' بالخط الأول والثالث؟",
      "questionEn": "Who is Gamal Abdel Nasser station named after?",
      "optionsAr": ["ثاني رئيس لجمهورية مصر العربية وقائد ثورة يوليو", "عالم فيزياء مصري", "فنان تشكيلي عريق", "أول مدير لمترو الأنفاق"],
      "optionsEn": ["Second president of Egypt and leader of July 23 Revolution", "An Egyptian physicist", "A legendary visual artist", "The first director of the metro"],
      "answerIndex": 0,
      "explanationAr": "سميت المحطة تكريماً للزعيم الراحل جمال عبد الناصر قائد ثورة 23 يوليو 1952.",
      "explanationEn": "The station is named in honor of the late president Gamal Abdel Nasser, leader of the 1952 Revolution."
    },
    {
      "questionAr": "عندما تشتري تذكرة بـ 8 جنيهات وتركب بها 20 محطة، ماذا يسمى هذا في عرف المترو؟",
      "questionEn": "Buying a ticket for 8 EGP and riding 20 stations is called:",
      "optionsAr": ["مغامرة اقتصادية قد تنتهي بغرامة فورية", "ذكاء خارق وعبقرية", "تبرع كريم للمترو", "رحلة سياحية مجانية"],
      "optionsEn": ["An economic risk that ends with a fine at the exit", "Pure genius and intelligence", "A generous donation to the metro", "A free tourist cruise"],
      "answerIndex": 0,
      "explanationAr": "تجاوز عدد المحطات المسموح به في لون التذكرة يعرضك لغرامة فورية عند الخروج!",
      "explanationEn": "Exceeding the allowed number of stations for your ticket tier triggers a fine at the turnstile!"
    },
    {
      "questionAr": "أي محطة بالخط الأول هي الأقرب لـ حديقة الفسطاط التاريخية ومتحف الحضارة (NMEC)؟",
      "questionEn": "Which station on Line 1 is closest to Fustat Park and the Museum of Egyptian Civilization?",
      "optionsAr": ["محطة الملك الصالح", "محطة مار جرجس", "محطة الزهراء", "محطة دار السلام"],
      "optionsEn": ["El-Malek El-Saleh", "Mar Girgis", "El-Zahraa", "Dar El-Salam"],
      "answerIndex": 2,
      "explanationAr": "محطة الزهراء بالخط الأول هي الأقرب لمتحف الحضارة ومنها تستقل مواصلة بسيطة للوصول.",
      "explanationEn": "El-Zahraa station on Line 1 is the nearest point to reach the Museum of Civilization (NMEC)."
    },
    {
      "questionAr": "ما هو الاختراع العبقري الذي يحمله الركاب لتفادي حرارة الصيف الشديدة داخل المحطات العلوية؟",
      "questionEn": "What ingenious DIY tool do passengers use to survive summer heat in above-ground stations?",
      "optionsAr": ["مكيف هواء محمول", "المروحة الورقية المصنوعة من غلاف كشكول أو كرتونة", "مظلة شمسية ملونة", "ثلج جاف"],
      "optionsEn": ["Portable air conditioner", "A paper fan made from a notebook cover or cardboard", "A colorful umbrella", "Dry ice pack"],
      "answerIndex": 1,
      "explanationAr": "المروحة الورقية اليدوية هي منقذ الركاب الرسمي في الصيف الحار ومثال حي على الابتكار الشعبي!",
      "explanationEn": "A homemade paper fan is the official savior during Cairo's hot summer months!"
    },
    {
      "questionAr": "محطة 'شبرا الخيمة' تقع في أي محافظة من محافظات مصر؟",
      "questionEn": "In which Egyptian governorate is Shubra El-Kheima station located?",
      "optionsAr": ["محافظة القاهرة", "محافظة الجيزة", "محافظة القليوبية", "محافظة حلوان"],
      "optionsEn": ["Cairo Governorate", "Giza Governorate", "Qalyubia Governorate", "Helwan Governorate"],
      "answerIndex": 2,
      "explanationAr": "شبرا الخيمة هي محطة نهاية الخط الثاني وتقع جغرافياً وإدارياً في محافظة القليوبية لتخدم سكانها.",
      "explanationEn": "Shubra El-Kheima is the terminal of Line 2 and lies inside the Qalyubia Governorate."
    },
    {
      "questionAr": "ما هو الصوت المميز الذي يصدره الركاب للتعبير عن الضيق عند تأخر المترو لأكثر من 5 دقائق؟",
      "questionEn": "What sound do passengers make collectively to express frustration when the train is late?",
      "optionsAr": ["الغناء الجماعي", "الدردشة السياسية والتصفيق", "النفخ والتصفير والنظر المشترك في الساعات", "النوم على الرصيف"],
      "optionsEn": ["Singing in harmony", "Political debates and clapping", "Sighing, whistling, and staring at watches together", "Sleeping on the platform floor"],
      "answerIndex": 2,
      "explanationAr": "طقس جماعي يعبر عن نفاد الصبر والاستعداد للهجوم بمجرد فتح الأبواب!",
      "explanationEn": "A group ritual signaling total impatience and prepare-to-board state!"
    },
    {
      "questionAr": "ما هو الاسم الآخر للخط الأول لمترو أنفاق القاهرة؟",
      "questionEn": "What is the other name of Cairo Metro Line 1?",
      "optionsAr": ["الخط الفرنسي", "الخط الإقليمي (حلوان - المرج)", "الخط الياباني", "الخط السريع"],
      "optionsEn": ["The French Line", "The Regional Line (Helwan - El Marg)", "The Japanese Line", "The Express Line"],
      "answerIndex": 1,
      "explanationAr": "يسمى بالخط الإقليمي أو الخط الأول وهو الخط الأطول والأقدم الذي يربط جنوب القاهرة بشمالها.",
      "explanationEn": "Known as the Regional Line, it is the longest and oldest line connecting Cairo's South and North."
    },
    {
      "questionAr": "ما هي الرياضة التي يمارسها الركاب للدخول لـ عربة المترو المزدحمة في محطة السادات؟",
      "questionEn": "What sport do passengers practice to enter a crowded carriage at Sadat station?",
      "optionsAr": ["كرة القدم", "رياضة الاختراق والضغط بالأكتاف (الركام البشري)", "السباحة الحرة", "الجمباز الإيقاعي"],
      "optionsEn": ["Football", "Shoulder-shoving and compact body-slipping", "Freestyle swimming", "Rhythmic gymnastics"],
      "answerIndex": 1,
      "explanationAr": "تتطلب مهارة فائقة في التوازن والدفع اللطيف دون التسبب في مشاحنات!",
      "explanationEn": "Requires extreme balance and a gentle push to fit in without starting any arguments!"
    },
    {
      "questionAr": "محطة 'الدقي' بالخط الثاني سميت نسبة إلى:",
      "questionEn": "Dokki station on Line 2 was named after:",
      "optionsAr": ["عائلة الدقي التي قطنت المنطقة قديماً وتعود لأصول ريفية", "دوران المترو واهتزازه هناك", "صوت دقات الساعات القديمة", "مصنع طحين ودقيق قديم"],
      "optionsEn": ["The El-Dokki family who inhabited the area historically", "The shaking of the train there", "The ticking sound of old clocks", "An old flour mill"],
      "answerIndex": 0,
      "explanationAr": "تنسب لعائلة الدقي التي سكنت المنطقة منذ القدم وجاءت من محافظة القليوبية.",
      "explanationEn": "It is named after the El-Dokki family who inhabited the region in old times."
    },
    {
      "questionAr": "ما هي أشهر عدوى غير مباشرة يتبادلها ركاب المترو المزدحم في الشتاء؟",
      "questionEn": "What is the most common indirect gift shared by winter commuters on the metro?",
      "optionsAr": ["تذاكر مجانية", "أقلام ومفكرات صغيرة", "الزكام ونزلات البرد بالعدوى المباشرة", "علب حلوى المولد"],
      "optionsEn": ["Free tickets", "Mini notebooks and pens", "Flu and cold viruses shared through the air", "Mawlid sweet boxes"],
      "answerIndex": 2,
      "explanationAr": "التهوية المشتركة في الشتاء تضمن توزيعاً عادلاً للفيروسات بين الركاب!",
      "explanationEn": "Shared ventilation in winter guarantees an even distribution of flu bugs among riders!"
    },
    {
      "questionAr": "أي محطة تتيح لك الوصول مباشرة لـ قصر البارون إمبان الأسطوري بمصر الجديدة؟",
      "questionEn": "Which station drops you closest to the legendary Baron Empain Palace in Heliopolis?",
      "optionsAr": ["محطة الأهرام", "محطة كلية البنات", "محطة هارون", "محطة هليوبوليس"],
      "optionsEn": ["Al Ahram", "Koleyet El Banat", "Haroun", "Heliopolis"],
      "answerIndex": 0,
      "explanationAr": "محطة الأهرام بالخط الثالث هي الأقرب لقصر البارون التاريخي ذو الطراز الهندي الفريد.",
      "explanationEn": "Al Ahram station on Line 3 is the closest to the historic, Indian-style Baron Palace."
    },
    {
      "questionAr": "ماذا يفعل الراكب الذكي لتجنب فوات محطته عندما ينام أثناء رحلة المترو الطويلة؟",
      "questionEn": "How does a smart commuter avoid missing their stop while sleeping on a long ride?",
      "optionsAr": ["يعلق لافتة مكتوب عليها 'أيقظوني في المعادي'", "يضبط منبه الهاتف بصوت مرتفع جداً", "يعتمد على حاسة السمع الباطنية والاستيقاظ التلقائي قبل محطته بدقيقة", "يطلب من السائق إيقاظه"],
      "optionsEn": ["Wears a sign saying 'Wake me up at Maadi'", "Sets an incredibly loud phone alarm", "Relies on subconscious hearing to wake up exactly 1 minute before the stop", "Asks the driver to wake him up"],
      "answerIndex": 2,
      "explanationAr": "ساعة بيولوجية عجيبة يمتلكها راكب المترو تجعله يستيقظ فور سماع اسم محطته السابقة!",
      "explanationEn": "An amazing biological clock that wakes the sleeping commuter right when their stop is called!"
    },
    {
      "questionAr": "محطة 'شبرا' الشهيرة تعني باللغة القبطية القديمة:",
      "questionEn": "The famous name 'Shubra' translates in Coptic to:",
      "optionsAr": ["العزبة أو القرية", "النهر العظيم", "أرض الذهب", "السوق الكبير"],
      "optionsEn": ["The village or farm", "The great river", "The land of gold", "The big market"],
      "answerIndex": 0,
      "explanationAr": "كلمة شبرا أصلها قبطي 'شبرو' وتعني القرية أو العزبة، وهناك قرى كثيرة في مصر تبدأ بها.",
      "explanationEn": "Shubra comes from the Coptic word 'Shobro', meaning a village or hamlet."
    },
    {
      "questionAr": "ما هي الجملة التي ينهي بها البائع جولته في عربة المترو عندما لا يشتري منه أحد؟",
      "questionEn": "What phrase does a street vendor end his tour with when no one buys anything?",
      "optionsAr": ["شكراً لكم جميعاً", "سأعود غداً بمنتجات أفضل", "أنا ماشي يا جماعة وربنا يسامحكم بقى!", "سأشتكيكم للإدارة"],
      "optionsEn": ["Thank you all", "I will return tomorrow with better stuff", "I am leaving now, and may God forgive you all!", "I will report you to management"],
      "answerIndex": 2,
      "explanationAr": "الابتزاز العاطفي الفكاهي الأخير لعل أحداً يشعر بالذنب ويشتري جوارب!",
      "explanationEn": "The ultimate funny guilt-trip to make someone buy some socks!"
    },
    {
      "questionAr": "محطة 'الكيت كات' بالخط الثالث تقع بجوار أي نهر تاريخي شهير؟",
      "questionEn": "Kit Kat station on Line 3 lies adjacent to which historic body of water?",
      "optionsAr": ["نهر النيل (فرع رشيد)", "نهر النيل (فرع دمياط)", "نهر النيل الرئيسي (مباشرة على ضفاف جزيرة الزمالك)", "بحر يوسف"],
      "optionsEn": ["River Nile (Rosetta branch)", "River Nile (Damietta branch)", "Main River Nile (facing Zamalek island)", "Bahr Youssef"],
      "answerIndex": 2,
      "explanationAr": "محطة الكيت كات تقع مباشرة على ضفاف النيل وتعتبر محطة تفرع هامة للخط الثالث شمالاً وجنوباً.",
      "explanationEn": "Kit Kat station sits right on the Nile bank, acting as a crucial split point for Line 3."
    }
  ];

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
    _loadHighScore();
    _startNewGame();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('rafiq_trivia_highscore') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('rafiq_trivia_highscore', _score);
      setState(() {
        _highScore = _score;
      });
    }
  }

  Future<void> _startNewGame() async {
    setState(() {
      _score = 0;
      _lives = 3;
      _currentIndex = 0;
      _answered = false;
      _selectedOption = null;
      _isLoading = false;
    });

    // Shuffle and load a round of 15 questions from the 50 curated ones
    final shuffled = List<Map<String, dynamic>>.from(_offlineQuestions)..shuffle();
    setState(() {
      _questions = shuffled.take(15).toList();
    });
  }

  void _handleOptionTap(int index) {
    if (_answered) return;

    final question = _questions[_currentIndex];
    final correctIndex = question['answerIndex'];

    setState(() {
      _answered = true;
      _selectedOption = index;
      if (index == correctIndex) {
        _score += 10;
      } else {
        _lives -= 1;
      }
    });

    if (_lives <= 0 || _currentIndex == _questions.length - 1) {
      _saveHighScore();
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      _answered = false;
      _selectedOption = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(isAr ? "تحدي رفيق للأسئلة 🎮" : "Rafiq Trivia Challenge 🎮"),
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

                      // Top stats bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${isAr ? "النقاط" : "Score"}: $_score',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                          ),
                          Row(
                            children: List.generate(3, (idx) {
                              return Icon(
                                idx < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: Colors.redAccent,
                              );
                            }),
                          ),
                          Text(
                            '${isAr ? "أعلى نقاط" : "Best"}: $_highScore',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_isLoading)
                        _buildLoadingSpinner(isAr)
                      else if (_questions.isEmpty)
                        _buildNoQuestions(isAr)
                      else if (_lives <= 0 || _currentIndex >= _questions.length)
                        _buildGameOverScreen(isAr)
                      else
                        _buildQuestionScreen(isAr),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_bannerAd != null && _isAdLoaded)
            SafeArea(
              top: false,
              child: Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                ),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionScreen(bool isAr) {
    final question = _questions[_currentIndex];
    final qText = (isAr ? question['questionAr'] : question['questionEn']) ?? '';
    final options = List<String>.from(isAr ? question['optionsAr'] : question['optionsEn']);
    final correctIndex = question['answerIndex'];
    final explanation = (isAr ? question['explanationAr'] : question['explanationEn']) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question Progress
        Text(
          '${isAr ? "السؤال" : "Question"} ${_currentIndex + 1} / ${_questions.length}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 12),

        // Question Text Card
        Card(
          elevation: 0,
          color: AppColors.primary.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              qText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Options List
        ...List.generate(options.length, (idx) {
          Color borderCol = Colors.grey.withOpacity(0.25);
          Color fillCol = Theme.of(context).cardColor;
          IconData? trailingIcon;

          if (_answered) {
            if (idx == correctIndex) {
              borderCol = Colors.green;
              fillCol = Colors.green.withOpacity(0.12);
              trailingIcon = Icons.check_circle_rounded;
            } else if (idx == _selectedOption) {
              borderCol = Colors.redAccent;
              fillCol = Colors.red.withOpacity(0.12);
              trailingIcon = Icons.cancel_rounded;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () => _handleOptionTap(idx),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: fillCol,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _answered && idx == correctIndex ? Colors.green : AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + idx),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _answered && idx == correctIndex ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        options[idx],
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    if (trailingIcon != null)
                      Icon(trailingIcon, color: idx == correctIndex ? Colors.green : Colors.redAccent),
                  ],
                ),
              ),
            ),
          );
        }),

        // Explanation & Next Button
        if (_answered)
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Colors.amber.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.amber, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? "💡 معلومة رفيق التاريخية:" : "💡 Rafiq's Insight:",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          explanation,
                          style: const TextStyle(fontSize: 12.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Next or Finish Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (_lives <= 0 || _currentIndex == _questions.length - 1) {
                      setState(() {
                        _currentIndex = _questions.length; // Triggers game over screen
                      });
                    } else {
                      _nextQuestion();
                    }
                  },
                  child: Text(
                    _currentIndex == _questions.length - 1
                        ? (isAr ? "عرض النتيجة 🏁" : "Show Results 🏁")
                        : (isAr ? "السؤال التالي ➡️" : "Next Question ➡️"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _onPlayAgainPressed() {
    AdService.showInterstitialAd(() {
      _startNewGame();
    });
  }

  Widget _buildGameOverScreen(bool isAr) {
    final won = _lives > 0;
    return ZoomIn(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Text(
              won ? '🏆' : '💀',
              style: const TextStyle(fontSize: 72),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            won 
                ? (isAr ? "عاش يا بطل! كملت التحدي" : "Awesome! Challenge Completed")
                : (isAr ? "حظ أوفر المرة الجاية!" : "Game Over! Better luck next time"),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${isAr ? "مجموع النقاط" : "Your Score"}: $_score',
            style: const TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (_score >= _highScore && _score > 0) ...[
            const SizedBox(height: 8),
            Text(
              isAr ? "🔥 رقم قياسي جديد! 🔥" : "🔥 New High Score! 🔥",
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _onPlayAgainPressed,
            icon: const Icon(Icons.replay_rounded),
            label: Text(
              isAr ? "العب تاني 🎮" : "Play Again 🎮",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSpinner(bool isAr) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          Text(isAr ? "جاري تحضير أسئلة المترو الذكية..." : "Preparing smart trivia questions..."),
        ],
      ),
    );
  }

  Widget _buildNoQuestions(bool isAr) {
    return Center(
      child: Text(isAr ? "مفيش أسئلة حالياً. جرب تعيد اللعبة!" : "No questions available. Try restarting!"),
    );
  }
}
