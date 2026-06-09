// import 'package:animate_do/animate_do.dart';
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:math';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:rafiq_metrro/core/theme/app_colors.dart';
// import 'package:shimmer/shimmer.dart';
// import '../../domain/entities/reward.dart';

// class LeaderboardView extends StatefulWidget {
//   final Reward reward;
//   const LeaderboardView({super.key, required this.reward});

//   @override
//   State<LeaderboardView> createState() => _LeaderboardViewState();
// }

// class _LeaderboardViewState extends State<LeaderboardView> {
//   List<Map<String, dynamic>> competitors = [];
//   bool isLoading = true;
//   String _timeFilter = 'weekly'; // daily, weekly, monthly
//   Timer? _liveUpdateTimer;
//   final Random _random = Random();
//   String _latestActivity = "";
//   bool _showActivityBanner = false;
//   bool _isAr = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchCompetitors();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _isAr = context.locale.languageCode == 'ar';
//   }

//   @override
//   void dispose() {
//     _liveUpdateTimer?.cancel();
//     super.dispose();
//   }

//   void _startLiveLeaderboardUpdates() {
//     _liveUpdateTimer?.cancel();
//     _liveUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
//       if (!mounted || isLoading || competitors.isEmpty) return;

//       final idx = _random.nextInt(competitors.length);
//       final competitorName = competitors[idx]['name'];
//       final additionalPoints = (1 + _random.nextInt(4)) * 50;

//       setState(() {
//         competitors[idx]['points'] = (competitors[idx]['points'] as int) + additionalPoints;
        
//         if (_random.nextBool()) {
//           competitors[idx]['cheers'] = (competitors[idx]['cheers'] as int) + 1;
//         }

//         _latestActivity = _isAr
//             ? "⚡ $competitorName أكمل رحلة مترو الآن وحصل على +$additionalPoints نقطة!"
//             : "⚡ $competitorName completed a metro ride and earned +$additionalPoints pts!";
//         _showActivityBanner = true;
//       });

//       Future.delayed(const Duration(seconds: 4), () {
//         if (mounted) {
//           setState(() {
//             _showActivityBanner = false;
//           });
//         }
//       });
//     });
//   }

//   void _changeTimeFilter(String filter) {
//     setState(() {
//       _timeFilter = filter;
//       final multiplier = filter == 'daily' ? 0.15 : filter == 'weekly' ? 1.0 : 4.5;
//       for (var competitor in competitors) {
//         final int hash = competitor['name'].hashCode.abs();
//         competitor['points'] = (300 + (hash % 1800) * multiplier).round();
//       }
//     });
//   }

//   Future<void> _fetchCompetitors() async {
//     if (!mounted) return;
//     setState(() {
//       isLoading = true;
//     });

//     // Seed Egyptian competitors as fallback/base
//     final List<Map<String, dynamic>> basePool = [
//       {'name': 'سلمى فريد', 'points': 9200, 'avatar': '👧'},
//       {'name': 'أحمد حسن', 'points': 8400, 'avatar': '👨'},
//       {'name': 'عمر خالد', 'points': 7800, 'avatar': '👦'},
//       {'name': 'منى ياسر', 'points': 7100, 'avatar': '👩'},
//       {'name': 'كريم شوقي', 'points': 6500, 'avatar': '🧑'},
//       {'name': 'ياسين علي', 'points': 5900, 'avatar': '👨'},
//       {'name': 'هدى محمود', 'points': 4800, 'avatar': '👧'},
//       {'name': 'نادر سيف', 'points': 3200, 'avatar': '👨'},
//       {'name': 'هالة صدقي', 'points': 1500, 'avatar': '👩'},
//       {'name': 'باسم كمال', 'points': 800, 'avatar': '🧑'},
//       {'name': 'دنيا وائل', 'points': 150, 'avatar': '👧'},
//     ];

//     try {
//       // Query unique active senders from Supabase messages table
//       final response = await Supabase.instance.client
//           .from('messages')
//           .select('sender')
//           .order('created_at', ascending: false)
//           .limit(100);

//       final Set<String> uniqueSenders = {};
//       if (response != null && response is List) {
//         for (var item in response) {
//           final sender = item['sender'];
//           if (sender != null && sender.toString().trim().isNotEmpty) {
//             uniqueSenders.add(sender.toString().trim());
//           }
//         }
//       }

//       final List<Map<String, dynamic>> dynamicCompetitors = [];
//       final avatars = ['👨', '👩', '🧑', '👧', '👦', '😎', '🚇', '🚀'];

//       for (var sender in uniqueSenders) {
//         final int nameHash = sender.hashCode.abs();
//         final int points = 500 + (nameHash % 9000); // between 500 and 9500
//         final String avatar = avatars[nameHash % avatars.length];

//         dynamicCompetitors.add({
//           'name': sender,
//           'points': points,
//           'avatar': avatar,
//           'cheers': 0,
//         });
//       }

//       // Add basePool participants who are not in the dynamicCompetitors to ensure a rich list
//       for (var base in basePool) {
//         if (!uniqueSenders.contains(base['name'])) {
//           dynamicCompetitors.add({
//             ...base,
//             'cheers': 0,
//           });
//         }
//       }

//       if (mounted) {
//         setState(() {
//           competitors = dynamicCompetitors;
//           isLoading = false;
//         });
//         _startLiveLeaderboardUpdates();
//       }
//     } catch (e) {
//       debugPrint('Error fetching leaderboard competitors: $e');
//       // Fallback
//       if (mounted) {
//         setState(() {
//           competitors = basePool.map((e) => {...e, 'cheers': 0}).toList();
//           isLoading = false;
//         });
//         _startLiveLeaderboardUpdates();
//       }
//     }
//   }

//   void _cheerUser(int index) {
//     setState(() {
//       competitors[index]['points'] = (competitors[index]['points'] as int) + 10;
//       competitors[index]['cheers'] = (competitors[index]['cheers'] as int) + 1;
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           _isAr
//               ? 'أرسلت تحية ودعم لـ ${competitors[index]['name']}! 🎉 (+10 نقاط)'
//               : 'Sent cheers to ${competitors[index]['name']}! 🎉 (+10 pts)',
//         ),
//         duration: const Duration(seconds: 1),
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: AppColors.accent,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isAr = context.locale.languageCode == 'ar';
//     final userPoints = widget.reward.currentPoints;

//     // Create a copy of competitors and inject the current user
//     List<Map<String, dynamic>> finalPool = List.from(competitors);

//     final bool hasMe = finalPool.any((e) => e['isMe'] == true);
//     if (!hasMe) {
//       finalPool.add({
//         'name': "You".tr(),
//         'points': userPoints,
//         'avatar': '😎',
//         'isMe': true,
//         'cheers': 0,
//       });
//     } else {
//       final int meIndex = finalPool.indexWhere((e) => e['isMe'] == true);
//       finalPool[meIndex]['points'] = userPoints;
//     }

//     // Sort by points descending organically!
//     finalPool.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));

//     // Assign canonical ranks safely after sorting
//     for (int i = 0; i < finalPool.length; i++) {
//       finalPool[i]['rank'] = i + 1;
//     }

//     final topThree = finalPool.take(3).toList();
//     final others = finalPool.skip(3).toList();

//     // Dynamic Level Computation
//     int nextTarget = 1000;
//     String nextLevel = "Silver".tr();
//     if (userPoints >= 1000 && userPoints < 5000) {
//       nextTarget = 5000;
//       nextLevel = "Gold".tr();
//     } else if (userPoints >= 5000) {
//       nextTarget = 10000;
//       nextLevel = "Platinum".tr();
//     }
//     final pointsNeeded = nextTarget > userPoints ? nextTarget - userPoints : 0;

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: RefreshIndicator(
//         onRefresh: _fetchCompetitors,
//         color: AppColors.accent,
//         child: Stack(
//           children: [
//             isLoading
//                 ? _buildShimmerLoading()
//                 : SingleChildScrollView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     child: Column(
//                       children: [
//                         // ── Podium ──────────────────────────────────────────────
//                         Container(
//                           padding: const EdgeInsets.only(top: 40, bottom: 20),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                             ),
//                             borderRadius: const BorderRadius.only(
//                               bottomLeft: Radius.circular(40),
//                               bottomRight: Radius.circular(40),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               if (topThree.length > 1) _buildPodiumUser(topThree[1], 2, 100, const Color(0xFFC0C0C0)), // Silver
//                               if (topThree.isNotEmpty) _buildPodiumUser(topThree[0], 1, 140, const Color(0xFFFFD700), isFirst: true), // Gold
//                               if (topThree.length > 2) _buildPodiumUser(topThree[2], 3, 80, const Color(0xFFCD7F32)), // Bronze
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 16),

//                         // ── Time Filter Tabs ────────────────────────────────────
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
//                           child: Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Theme.of(context).cardColor,
//                               borderRadius: BorderRadius.circular(16),
//                               border: Border.all(color: Colors.grey.withOpacity(0.12)),
//                             ),
//                             child: Row(
//                               children: ['daily', 'weekly', 'monthly'].map((filter) {
//                                 final active = _timeFilter == filter;
//                                 final label = filter == 'daily'
//                                     ? "Daily".tr()
//                                     : filter == 'weekly'
//                                         ? "Weekly".tr()
//                                         : "Monthly".tr();
//                                 return Expanded(
//                                   child: GestureDetector(
//                                     onTap: () => _changeTimeFilter(filter),
//                                     child: AnimatedContainer(
//                                       duration: const Duration(milliseconds: 250),
//                                       padding: const EdgeInsets.symmetric(vertical: 8),
//                                       decoration: BoxDecoration(
//                                         color: active ? AppColors.primary : Colors.transparent,
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: Text(
//                                         label,
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: active ? Colors.white : AppColors.textSecondary,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               }).toList(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),

//                     // ── Today's Challenge Banner ────────────────────────────
//                     FadeInUp(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 20),
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: AppColors.accent.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: AppColors.accent.withOpacity(0.3)),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.flash_on, color: AppColors.accent, size: 28),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       isAr
//                                           ? 'ينقصك $pointsNeeded نقطة لتصل للدرجة $nextLevel 🚀'
//                                           : '$pointsNeeded points to reach $nextLevel 🚀',
//                                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // ── List ────────────────────────────────────────────────
//                     ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                       itemCount: others.length,
//                       itemBuilder: (context, index) {
//                         final user = others[index];
//                         final isMe = user['isMe'] == true;
//                         // Find this user's index in the main competitors list for cheering
//                         final int mainIndex = competitors.indexWhere((e) => e['name'] == user['name']);

//                         return FadeInUp(
//                           delay: Duration(milliseconds: 50 * index),
//                           child: Container(
//                             margin: const EdgeInsets.only(bottom: 12),
//                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                             decoration: BoxDecoration(
//                               color: isMe ? AppColors.accent.withOpacity(0.15) : Theme.of(context).cardColor,
//                               borderRadius: BorderRadius.circular(16),
//                               border: isMe ? Border.all(color: AppColors.accent) : null,
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.04),
//                                   blurRadius: 8,
//                                   offset: const Offset(0, 4),
//                                 ),
//                               ],
//                             ),
//                             child: Row(
//                               children: [
//                                 Text(
//                                   '#${user['rank']}',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                     color: isMe ? AppColors.accent : AppColors.textSecondary,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 16),
//                                 CircleAvatar(
//                                   backgroundColor: Colors.grey.withOpacity(0.1),
//                                   child: Text(user['avatar'] as String, style: const TextStyle(fontSize: 20)),
//                                 ),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         user['name'] as String,
//                                         style: TextStyle(
//                                           fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                       if (user['cheers'] != null && (user['cheers'] as int) > 0)
//                                         Padding(
//                                           padding: const EdgeInsets.only(top: 2),
//                                           child: Text(
//                                             isAr 
//                                                 ? '💖 تلقى ${user['cheers']} دعم' 
//                                                 : '💖 Received ${user['cheers']} cheers',
//                                             style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                                 if (!isMe && mainIndex != -1)
//                                   IconButton(
//                                     icon: const Icon(Icons.favorite_border_rounded, color: AppColors.accent, size: 22),
//                                     onPressed: () => _cheerUser(mainIndex),
//                                     tooltip: isAr ? 'أرسل دعم' : 'Send Cheers',
//                                   ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   '${user['points']} نقطة',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: isMe ? AppColors.accent : AppColors.primary,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                     const SizedBox(height: 110),
//                   ],
//                 ),
//               ),
//             if (_showActivityBanner && _latestActivity.isNotEmpty)
//               Positioned(
//                 top: 24,
//                 left: 20,
//                 right: 20,
//                 child: FadeInDown(
//                   duration: const Duration(milliseconds: 400),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: AppColors.accent,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppColors.accent.withOpacity(0.35),
//                           blurRadius: 12,
//                           offset: const Offset(0, 6),
//                         )
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Text(
//                             _latestActivity,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildShimmerLoading() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // Podium Shimmer
//           Shimmer.fromColors(
//             baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
//             highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
//             child: Container(
//               height: 220,
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(40),
//                   bottomRight: Radius.circular(40),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 40),
//           // List Shimmer
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             itemCount: 6,
//             itemBuilder: (ctx, i) => Shimmer.fromColors(
//               baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
//               highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
//               child: Container(
//                 margin: const EdgeInsets.only(bottom: 16),
//                 height: 70,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPodiumUser(Map<String, dynamic> user, int rank, double height, Color medalColor, {bool isFirst = false}) {
//     return FadeInUp(
//       delay: Duration(milliseconds: 100 * rank),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           if (isFirst)
//             const Padding(
//               padding: EdgeInsets.only(bottom: 8.0),
//               child: Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 40),
//             ),
//           CircleAvatar(
//             radius: isFirst ? 36 : 28,
//             backgroundColor: medalColor,
//             child: CircleAvatar(
//               radius: isFirst ? 32 : 25,
//               backgroundColor: Colors.white,
//               child: Text(user['avatar'], style: TextStyle(fontSize: isFirst ? 32 : 24)),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             user['name'],
//             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           Text(
//             '${user['points']}',
//             style: const TextStyle(color: Colors.white70, fontSize: 12),
//           ),
//           const SizedBox(height: 12),
//           Container(
//             width: 80,
//             height: height,
//             decoration: BoxDecoration(
//               color: medalColor.withOpacity(0.9),
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(12),
//                 topRight: Radius.circular(12),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   blurRadius: 10,
//                   offset: const Offset(0, -4),
//                 ),
//               ],
//             ),
//             child: Center(
//               child: Text(
//                 '$rank',
//                 style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
