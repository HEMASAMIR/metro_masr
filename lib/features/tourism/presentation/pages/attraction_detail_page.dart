import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/tourism_data.dart';

class AttractionDetailPage extends StatefulWidget {
  final TouristAttraction attraction;
  final String lang;
  final String stationName;

  const AttractionDetailPage({
    super.key,
    required this.attraction,
    required this.lang,
    required this.stationName,
  });

  @override
  State<AttractionDetailPage> createState() => _AttractionDetailPageState();
}

class _AttractionDetailPageState extends State<AttractionDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _heroScale;
  late Animation<double> _contentFade;

  // AI Chat
  final _chatCtrl = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  // Quick questions in 4 languages
  late List<String> _quickQuestions;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _heroScale = Tween<double>(begin: 1.1, end: 1.0).animate(
      CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut),
    );
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);

    _heroCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _contentCtrl.forward());

    _setupQuickQuestions();
    _addSystemMessage();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _contentCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  void _setupQuickQuestions() {
    final name = widget.attraction.name[widget.lang] ?? widget.attraction.name['en']!;
    _quickQuestions = {
      'ar': ['ما هي أبرز المعروضات؟', 'كيف أصل من المترو؟', 'هل يناسب الأطفال؟', 'ما هو أفضل وقت للزيارة؟'],
      'en': ['What are the highlights?', 'How to get there from metro?', 'Is it kid-friendly?', 'Best time to visit?'],
      'fr': ['Quels sont les points forts?', 'Comment y aller depuis le métro?', 'Convient aux enfants?', 'Meilleure heure de visite?'],
      'de': ['Was sind die Highlights?', 'Wie komme ich von der U-Bahn?', 'Kinderfreundlich?', 'Beste Besuchszeit?'],
    }[widget.lang] ?? ['What are the highlights?', 'How to get there?'];
  }

  void _addSystemMessage() {
    final name = widget.attraction.name[widget.lang] ?? widget.attraction.name['en']!;
    final greeting = {
      'ar': 'مرحباً! 👋 أنا رفيق الذكي، دليلك السياحي للـ $name. كيف أقدر أساعدك؟',
      'en': 'Hello! 👋 I\'m Rafiq AI, your smart guide for $name. How can I help you?',
      'fr': 'Bonjour! 👋 Je suis Rafiq AI, votre guide pour $name. Comment puis-je vous aider?',
      'de': 'Hallo! 👋 Ich bin Rafiq AI, Ihr Guide für $name. Wie kann ich Ihnen helfen?',
    }[widget.lang] ?? 'Hello! I\'m Rafiq AI, your guide for $name.';

    _messages.add(_ChatMessage(text: greeting, isUser: false));
  }

  String _generateAiResponse(String question) {
    final a = widget.attraction;
    final lang = widget.lang;
    final name = a.name[lang] ?? a.name['en']!;
    final desc = a.description[lang] ?? a.description['en']!;
    final q = question.toLowerCase();

    // Smart responses based on question keywords
    if (q.contains('كيف') || q.contains('وصول') || q.contains('how') || q.contains('get there') || q.contains('metro') || q.contains('محطة') || q.contains('comment') || q.contains('wie')) {
      return {
        'ar': '🚇 للوصول إلى $name:\n\n1. انزل في ${widget.stationName.isNotEmpty ? widget.stationName : "أقرب محطة"}\n2. امشي ${a.walkingMinutes} دقيقة\n3. ستجده على يمينك/يسارك\n\n💡 نصيحة: المترو أسرع وسيلة وأوفر من التاكسي في القاهرة!',
        'en': '🚇 To reach $name:\n\n1. Get off at ${widget.stationName.isNotEmpty ? widget.stationName : "the nearest station"}\n2. Walk ${a.walkingMinutes} minutes\n3. You\'ll find it on your right/left\n\n💡 Tip: Metro is faster and cheaper than taxis in Cairo!',
        'fr': '🚇 Pour atteindre $name:\n\n1. Descendez à ${widget.stationName.isNotEmpty ? widget.stationName : "la station la plus proche"}\n2. Marchez ${a.walkingMinutes} minutes\n\n💡 Conseil: Le métro est plus rapide et moins cher que les taxis!',
        'de': '🚇 Um $name zu erreichen:\n\n1. Steigen Sie an ${widget.stationName.isNotEmpty ? widget.stationName : "der nächsten Station"} aus\n2. Gehen Sie ${a.walkingMinutes} Minuten zu Fuß\n\n💡 Tipp: U-Bahn ist schneller und billiger als Taxis!',
      }[lang] ?? '';
    }

    if (q.contains('أطفال') || q.contains('عائلة') || q.contains('kid') || q.contains('child') || q.contains('family') || q.contains('enfant') || q.contains('kind')) {
      final catFamilyFriendly = [AttractionCategory.park, AttractionCategory.museum, AttractionCategory.entertainment];
      final isFamilyFriendly = catFamilyFriendly.contains(a.category);
      return {
        'ar': isFamilyFriendly
            ? '👨‍👩‍👧‍👦 نعم! $name مناسب جداً للعائلات والأطفال. ${a.isFree ? "الدخول مجاني" : "رسوم الدخول ${a.admissionEGP}"}.\n\n✅ ${a.openHours}'
            : '⚠️ $name أكثر ملاءمة للبالغين والمهتمين بالتراث. يمكن للأطفال الزيارة مع المرشد.',
        'en': isFamilyFriendly
            ? '👨‍👩‍👧‍👦 Yes! $name is very family-friendly. ${a.isFree ? "Free entry" : "Admission: ${a.admissionEGP}"}.\n\n✅ ${a.openHours}'
            : '⚠️ $name is better suited for adults interested in heritage. Children can visit with a guide.',
        'fr': isFamilyFriendly
            ? '👨‍👩‍👧‍👦 Oui! $name est très adapté aux familles. ${a.isFree ? "Entrée gratuite" : "Admission: ${a.admissionEGP}"}.'
            : '⚠️ $name est plus adapté aux adultes. Les enfants peuvent visiter avec un guide.',
        'de': isFamilyFriendly
            ? '👨‍👩‍👧‍👦 Ja! $name ist sehr familienfreundlich. ${a.isFree ? "Freier Eintritt" : "Eintritt: ${a.admissionEGP}"}.'
            : '⚠️ $name eignet sich besser für Erwachsene. Kinder können mit einem Führer besuchen.',
      }[lang] ?? '';
    }

    if (q.contains('وقت') || q.contains('توقيت') || q.contains('time') || q.contains('when') || q.contains('heure') || q.contains('wann') || q.contains('best')) {
      return {
        'ar': '⏰ أفضل وقت لزيارة $name:\n\n🌅 الصباح الباكر (9-11 صباحاً) للهدوء وأقل ازدحام\n☀️ تجنب أيام الجمعة والعطلات الرسمية\n\n🕐 ساعات العمل: ${a.openHours}\n💰 التذكرة: ${a.admissionEGP}',
        'en': '⏰ Best time to visit $name:\n\n🌅 Early morning (9-11 AM) for calm and fewer crowds\n☀️ Avoid Fridays and public holidays\n\n🕐 Hours: ${a.openHours}\n💰 Ticket: ${a.admissionEGP}',
        'fr': '⏰ Meilleure heure pour $name:\n\n🌅 Tôt le matin (9h-11h) pour le calme\n☀️ Évitez les vendredis et jours fériés\n\n🕐 Horaires: ${a.openHours}\n💰 Billet: ${a.admissionEGP}',
        'de': '⏰ Beste Besuchszeit für $name:\n\n🌅 Frühmorgens (9-11 Uhr) für Ruhe und weniger Menschenmassen\n☀️ Vermeiden Sie Freitage und Feiertage\n\n🕐 Öffnungszeiten: ${a.openHours}\n💰 Ticket: ${a.admissionEGP}',
      }[lang] ?? '';
    }

    if (q.contains('سعر') || q.contains('تذكرة') || q.contains('price') || q.contains('ticket') || q.contains('cost') || q.contains('prix') || q.contains('preis')) {
      return {
        'ar': '💰 تفاصيل الأسعار:\n\n${a.isFree ? "✅ الدخول مجاني تماماً!" : "🎟️ رسوم الدخول: ${a.admissionEGP}"}\n\n💡 نصيحة: احمل هويتك (طلاب لهم خصم في معظم المتاحف)\n📍 المسافة من المحطة: ${a.walkingMinutes} دقيقة مشياً',
        'en': '💰 Price details:\n\n${a.isFree ? "✅ Completely free entry!" : "🎟️ Admission: ${a.admissionEGP}"}\n\n💡 Tip: Carry your ID (students get discounts at most museums)\n📍 Distance: ${a.walkingMinutes} minute walk from station',
        'fr': '💰 Détails des prix:\n\n${a.isFree ? "✅ Entrée totalement gratuite!" : "🎟️ Admission: ${a.admissionEGP}"}\n\n💡 Conseil: Les étudiants ont des réductions dans la plupart des musées',
        'de': '💰 Preisdetails:\n\n${a.isFree ? "✅ Völlig kostenloser Eintritt!" : "🎟️ Eintritt: ${a.admissionEGP}"}\n\n💡 Tipp: Studenten erhalten in den meisten Museen Rabatte',
      }[lang] ?? '';
    }

    if (q.contains('highlights') || q.contains('أبرز') || q.contains('مميز') || q.contains('points forts') || q.contains('highlights')) {
      final tags = a.tags.join(' • ');
      return {
        'ar': '✨ أبرز ما يميز $name:\n\n$desc\n\n🏷️ الكلمات المفتاحية: $tags\n\n⭐ التقييم: ${a.rating}/5.0\n🕐 ساعات العمل: ${a.openHours}',
        'en': '✨ Highlights of $name:\n\n$desc\n\n🏷️ Key features: $tags\n\n⭐ Rating: ${a.rating}/5.0\n🕐 Hours: ${a.openHours}',
        'fr': '✨ Points forts de $name:\n\n$desc\n\n🏷️ Caractéristiques: $tags\n\n⭐ Note: ${a.rating}/5.0',
        'de': '✨ Highlights von $name:\n\n$desc\n\n🏷️ Merkmale: $tags\n\n⭐ Bewertung: ${a.rating}/5.0',
      }[lang] ?? '';
    }

    // Generic intelligent response
    return {
      'ar': '🤖 سؤال رائع عن $name!\n\n$desc\n\n📍 يقع على بُعد ${a.walkingMinutes} دقيقة من المحطة\n⏰ ${a.openHours}\n💰 ${a.admissionEGP}\n⭐ التقييم: ${a.rating}/5',
      'en': '🤖 Great question about $name!\n\n$desc\n\n📍 Located ${a.walkingMinutes} minutes from the station\n⏰ ${a.openHours}\n💰 ${a.admissionEGP}\n⭐ Rating: ${a.rating}/5',
      'fr': '🤖 Excellente question sur $name!\n\n$desc\n\n📍 À ${a.walkingMinutes} minutes de la station\n⏰ ${a.openHours}\n💰 ${a.admissionEGP}',
      'de': '🤖 Tolle Frage zu $name!\n\n$desc\n\n📍 ${a.walkingMinutes} Minuten von der Station\n⏰ ${a.openHours}\n💰 ${a.admissionEGP}',
    }[lang] ?? '';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
      _chatCtrl.clear();
    });

    // Simulate thinking delay
    final thinkMs = 600 + Random().nextInt(800);
    await Future.delayed(Duration(milliseconds: thinkMs));

    final response = _generateAiResponse(text);
    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: response, isUser: false));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attraction;
    final lang = widget.lang;
    final isAr = lang == 'ar';
    final name = a.name[lang] ?? a.name['en']!;
    final desc = a.description[lang] ?? a.description['en']!;
    final color = Color(TourismDatabase.categoryColor[a.category]!);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: CustomScrollView(
        slivers: [
          // ── Hero ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF0A0E27),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: AnimatedBuilder(
                animation: _heroScale,
                builder: (_, __) => Transform.scale(
                  scale: _heroScale.value,
                  child: _buildHero(a, color, name, isAr),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentFade,
              child: Column(
                children: [
                  // ── Name + rating ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                textAlign: isAr ? TextAlign.right : TextAlign.left,
                                style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    a.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (widget.stationName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.train_rounded, color: AppColors.primary, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.stationName} • ${a.walkingMinutes} ${isAr ? 'دقيقة مشياً' : 'min walk'}',
                                style: const TextStyle(color: Color(0xFF8899CC), fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Quick info cards ──────────────────────────────────────
                  _buildQuickInfoRow(a, color, isAr, lang),

                  // ── Description ───────────────────────────────────────────
                  _buildSection(
                    icon: '📖',
                    title: isAr ? 'عن المكان' : 'About',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        desc,
                        textAlign: isAr ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(
                          color: Color(0xFF8899CC), fontSize: 14, height: 1.8),
                      ),
                    ),
                  ),

                  // ── Tags ─────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Wrap(
                      spacing: 8,
                      children: a.tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text('#$t', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                      )).toList(),
                    ),
                  ),

                  // ── AI Chat ─────────────────────────────────────────────
                  _buildSection(
                    icon: '🤖',
                    title: isAr ? 'اسأل رفيق الذكي' : 'Ask Rafiq AI',
                    child: _buildAiChat(isAr, color),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(TouristAttraction a, Color color, String name, bool isAr) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.4), const Color(0xFF0A0E27)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Big emoji background
          Positioned(
            right: -20, top: -20,
            child: Text(a.emoji, style: TextStyle(
              fontSize: 180,
              color: Colors.white.withOpacity(0.06),
            )),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(a.emoji, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${TourismDatabase.categoryEmoji[a.category]} ${TourismDatabase.categoryLabel[a.category]?['en'] ?? ''}',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoRow(TouristAttraction a, Color color, bool isAr, String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1530),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2D5A)),
      ),
      child: Row(
        children: [
          _quickInfoItem(Icons.access_time_rounded, a.openHours.length > 15 ? a.openHours.substring(0, 15) + '…' : a.openHours, Colors.purple, isAr ? 'ساعات' : 'Hours'),
          _divider(),
          _quickInfoItem(
            a.isFree ? Icons.check_circle_rounded : Icons.paid_rounded,
            a.isFree ? (isAr ? 'مجاني' : 'Free') : a.admissionEGP,
            a.isFree ? Colors.green : Colors.orange,
            isAr ? 'التذكرة' : 'Ticket',
          ),
          _divider(),
          _quickInfoItem(Icons.directions_walk_rounded, '${a.walkingMinutes} min', Colors.blue, isAr ? 'مشياً' : 'Walk'),
        ],
      ),
    );
  }

  Widget _quickInfoItem(IconData icon, String value, Color color, String label) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(color: Color(0xFF556080), fontSize: 10)),
      ],
    ),
  );

  Widget _divider() => Container(width: 1, height: 40, color: const Color(0xFF1E2D5A), margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _buildSection({required String icon, required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildAiChat(bool isAr, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1530),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2D5A)),
      ),
      child: Column(
        children: [
          // Messages
          SizedBox(
            height: 280,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildChatBubble(_messages[i], isAr);
              },
            ),
          ),

          // Quick questions
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickQuestions.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _sendMessage(_quickQuestions[i]),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    _quickQuestions[i],
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: isAr ? 'اسأل عن المكان...' : 'Ask about this place...',
                      hintStyle: const TextStyle(color: Color(0xFF556080), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1A2A6C).withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_chatCtrl.text),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage msg, bool isAr) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF1A56DB),
              child: Text('🤖', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF1A56DB).withOpacity(0.3)
                    : const Color(0xFF1A2A6C).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12).copyWith(
                  bottomRight: isUser ? const Radius.circular(2) : null,
                  bottomLeft: isUser ? null : const Radius.circular(2),
                ),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFF1A56DB).withOpacity(0.4)
                      : const Color(0xFF1E2D5A),
                ),
              ),
              child: Text(
                msg.text,
                textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF1A56DB),
              child: Icon(Icons.person, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF1A56DB),
            child: Text('🤖', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A6C).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E2D5A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _TypingDot(delay: Duration(milliseconds: i * 200))),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

// Animated typing dots
class _TypingDot extends StatefulWidget {
  final Duration delay;
  const _TypingDot({required this.delay});
  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 6, height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3 + 0.7 * _ctrl.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
