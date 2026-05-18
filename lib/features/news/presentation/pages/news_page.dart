import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/news_bloc.dart';
import '../widgets/news_card_widget.dart';
import 'article_webview_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models for offline metro-specific tabs
// ─────────────────────────────────────────────────────────────────────────────
class _MetroAlert {
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String line;     // 'line1' / 'line2' / 'line3' / 'all'
  final String date;
  final _AlertType type;
  const _MetroAlert({
    required this.titleAr, required this.titleEn,
    required this.bodyAr, required this.bodyEn,
    required this.line, required this.date, required this.type,
  });
}

enum _AlertType { closure, maintenance, delay }

// ── Realistic curated data ────────────────────────────────────────────────────
const _closures = <_MetroAlert>[
  _MetroAlert(
    titleAr: 'إغلاق مؤقت لمحطة الشهداء',
    titleEn: 'Al Shohada Station Temporary Closure',
    bodyAr: 'تُغلق محطة الشهداء من 12 إلى 14 مايو 2025 لأعمال تطويرية. يُرجى الاستفادة من محطة أتابا كبديل.',
    bodyEn: 'Al Shohada station will be closed May 12–14, 2025 for development works. Use Ataba as an alternative.',
    line: 'line2', date: '12 مايو 2025', type: _AlertType.closure,
  ),
  _MetroAlert(
    titleAr: 'تعليق الخط الثالث بين نور وعدلي منصور (ليلاً)',
    titleEn: 'Line 3 Suspended: Nour–Adly Mansour (Night)',
    bodyAr: 'يتوقف الخط الثالث بين محطتي نور وعدلي منصور يومياً من 11 مساءً حتى 5 صباحاً لأعمال السكك.',
    bodyEn: 'Line 3 suspended between Nour and Adly Mansour daily from 11 PM to 5 AM for track works.',
    line: 'line3', date: '20 أبريل 2025', type: _AlertType.closure,
  ),
  _MetroAlert(
    titleAr: 'إغلاق مؤقت لمحطة المرج الجديدة',
    titleEn: 'El Marg El Gedida Station Closure',
    bodyAr: 'محطة المرج الجديدة ستُغلق لمدة ثلاثة أيام لتركيب بوابات تذاكر جديدة.',
    bodyEn: 'El Marg El Gedida will be closed for 3 days for new ticket gate installation.',
    line: 'line1', date: '5 مايو 2025', type: _AlertType.closure,
  ),
];

const _maintenance = <_MetroAlert>[
  _MetroAlert(
    titleAr: 'صيانة شاملة للخط الأول (عطلة نهاية الأسبوع)',
    titleEn: 'Line 1 Comprehensive Maintenance (Weekend)',
    bodyAr: 'سيخضع الخط الأول لصيانة شاملة للسكك والكهرباء خلال نهايات الأسبوع من 1 إلى 30 مايو.',
    bodyEn: 'Line 1 will undergo full track and electrical maintenance on weekends during May 1–30.',
    line: 'line1', date: '1 مايو 2025', type: _AlertType.maintenance,
  ),
  _MetroAlert(
    titleAr: 'تحديث منظومة الإشارات في الخط الثاني',
    titleEn: 'Line 2 Signaling System Upgrade',
    bodyAr: 'جارٍ تحديث منظومة الإشارات الذكية في الخط الثاني مما سيحسّن الدقة والانتظام.',
    bodyEn: 'Smart signaling system upgrade on Line 2 underway — will improve punctuality.',
    line: 'line2', date: '15 أبريل 2025', type: _AlertType.maintenance,
  ),
  _MetroAlert(
    titleAr: 'تجديد عربات الخط الثالث',
    titleEn: 'Line 3 Carriage Renovation',
    bodyAr: 'تجري صيانة دورية شاملة لعربات الخط الثالث تشمل التكييف والمقاعد والإضاءة.',
    bodyEn: 'Comprehensive periodic maintenance of Line 3 carriages covering AC, seats, and lighting.',
    line: 'line3', date: '10 مايو 2025', type: _AlertType.maintenance,
  ),
  _MetroAlert(
    titleAr: 'صيانة الرصيف في محطة جمال عبد الناصر',
    titleEn: 'Platform Maintenance — Gamal Abd El Nasser',
    bodyAr: 'أعمال تطوير الرصيف في محطة جمال عبد الناصر تستمر حتى نهاية الشهر.',
    bodyEn: 'Platform development at Gamal Abd El Nasser station continues until end of month.',
    line: 'line2', date: '3 مايو 2025', type: _AlertType.maintenance,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main NewsPage
// ─────────────────────────────────────────────────────────────────────────────
class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NewsBloc>()..add(FetchNews(countryCode: 'eg')),
      child: const _NewsTabView(),
    );
  }
}

class _NewsTabView extends StatefulWidget {
  const _NewsTabView();
  @override
  State<_NewsTabView> createState() => _NewsTabViewState();
}

class _NewsTabViewState extends State<_NewsTabView> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedCountry = 'eg';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 56),
              title: Text(
                "📰 Metro News".tr(),
                style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0D47A1)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: 0.06,
                    child: Icon(Icons.train_rounded, size: 160, color: Colors.white),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(icon: const Icon(Icons.newspaper_rounded, size: 18), text: "News".tr()),
                Tab(icon: const Icon(Icons.lock_rounded, size: 18), text: "Closures".tr()),
                Tab(icon: const Icon(Icons.build_rounded, size: 18), text: "Maintenance".tr()),
                Tab(icon: const Icon(Icons.public_rounded, size: 18), text: "World".tr()),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _EgNewsTab(
              countryCode: _selectedCountry == 'eg' ? 'eg' : 'eg',
              isAr: isAr,
            ),
            _MetroAlertsTab(alerts: _closures, isAr: isAr),
            _MetroAlertsTab(alerts: _maintenance, isAr: isAr),
            _WorldNewsTab(isAr: isAr),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 & 4 – Real news via NewsBloc
// ─────────────────────────────────────────────────────────────────────────────
class _EgNewsTab extends StatelessWidget {
  final String countryCode;
  final bool isAr;
  const _EgNewsTab({required this.countryCode, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewsBloc, NewsState>(
      builder: (context, state) {
        if (state is NewsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is NewsError) {
          return _ErrorView(message: state.message, countryCode: countryCode, isAr: isAr);
        }
        if (state is NewsLoaded) {
          if (state.articles.isEmpty) {
            return Center(child: Text("No news available".tr(),
                style: const TextStyle(fontWeight: FontWeight.bold)));
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: state.articles.length,
            itemBuilder: (ctx, i) {
              final article = state.articles[i];
              return FadeInUp(
                delay: Duration(milliseconds: i * 50),
                child: NewsCardWidget(
                  index: i, article: article,
                  onTap: () => Navigator.push(ctx,
                    MaterialPageRoute(builder: (_) => ArticleWebViewPage(article: article))),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _WorldNewsTab extends StatelessWidget {
  final bool isAr;
  const _WorldNewsTab({required this.isAr});
  @override
  Widget build(BuildContext context) {
    // Trigger world news fetch
    context.read<NewsBloc>().add(FetchNews(countryCode: 'us'));
    return _EgNewsTab(countryCode: 'us', isAr: isAr);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String countryCode;
  final bool isAr;
  const _ErrorView({required this.message, required this.countryCode, required this.isAr});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeIn(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 72, color: Colors.grey),
              const SizedBox(height: 16),
              Text("Could not load news".tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                icon: const Icon(Icons.refresh_rounded),
                label: Text("Retry".tr()),
                onPressed: () => context.read<NewsBloc>().add(FetchNews(countryCode: countryCode)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tabs 2 & 3 – Offline metro alerts (closures / maintenance)
// ─────────────────────────────────────────────────────────────────────────────
class _MetroAlertsTab extends StatefulWidget {
  final List<_MetroAlert> alerts;
  final bool isAr;
  const _MetroAlertsTab({required this.alerts, required this.isAr});

  @override
  State<_MetroAlertsTab> createState() => _MetroAlertsTabState();
}

class _MetroAlertsTabState extends State<_MetroAlertsTab> {
  String _filter = 'all';

  List<_MetroAlert> get _filtered => _filter == 'all'
      ? widget.alerts
      : widget.alerts.where((a) => a.line == _filter).toList();

  Color _lineColor(String line) => line == 'line1'
      ? AppColors.line1 : line == 'line2' ? AppColors.line2 : AppColors.line3;

  Color _typeColor(_AlertType t) =>
      t == _AlertType.closure ? Colors.red : t == _AlertType.maintenance ? Colors.blue : Colors.orange;

  IconData _typeIcon(_AlertType t) =>
      t == _AlertType.closure ? Icons.lock_rounded : t == _AlertType.maintenance ? Icons.build_rounded : Icons.warning_rounded;

  String _typeLabel(_AlertType t, bool isAr) =>
      t == _AlertType.closure
          ? ("Closure".tr())
          : t == _AlertType.maintenance
              ? ("Maintenance".tr())
              : ("Delay".tr());

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('all', "All".tr(), AppColors.primary),
                const SizedBox(width: 8),
                _chip('line1', "Line 1".tr(), AppColors.line1),
                const SizedBox(width: 8),
                _chip('line2', "Line 2".tr(), AppColors.line2),
                const SizedBox(width: 8),
                _chip('line3', "Line 3".tr(), AppColors.line3),
              ],
            ),
          ),
        ),

        if (_filtered.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green),
                  const SizedBox(height: 12),
                  Text("No alerts right now 🎉".tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              physics: const BouncingScrollPhysics(),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final alert = _filtered[i];
                final typeColor = _typeColor(alert.type);
                final lineCol = alert.line == 'all' ? AppColors.primary : _lineColor(alert.line);

                return FadeInUp(
                  delay: Duration(milliseconds: i * 60),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: typeColor.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(color: typeColor.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top colored bar
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(_typeIcon(alert.type), color: typeColor, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  // Type badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(_typeLabel(alert.type, isAr),
                                        style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 6),
                                  if (alert.line != 'all')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: lineCol.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(children: [
                                        Container(width: 8, height: 8,
                                          decoration: BoxDecoration(color: lineCol, shape: BoxShape.circle)),
                                        const SizedBox(width: 4),
                                        Text(
                                          alert.line == 'line1' ? ("L1".tr())
                                              : alert.line == 'line2' ? ("L2".tr())
                                              : ("L3".tr()),
                                          style: TextStyle(color: lineCol, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ]),
                                    ),
                                  const Spacer(),
                                  Row(children: [
                                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(alert.date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ]),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Title
                              Text(
                                isAr ? alert.titleAr : alert.titleEn,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.3),
                              ),
                              const SizedBox(height: 6),
                              // Body
                              Text(
                                isAr ? alert.bodyAr : alert.bodyEn,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _chip(String value, String label, Color color) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            )),
      ),
    );
  }
}
