// import 'dart:async';
// import 'dart:convert';
// import 'package:animate_do/animate_do.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/utils/gamification_service.dart';
// import '../../../../core/utils/paymob_service.dart';
// import 'paymob_iframe_page.dart';
// import 'stripe_checkout_page.dart';

// class NfcWalletPage extends StatefulWidget {
//   const NfcWalletPage({super.key});

//   @override
//   State<NfcWalletPage> createState() => _NfcWalletPageState();
// }

// class _NfcWalletPageState extends State<NfcWalletPage> with SingleTickerProviderStateMixin {
//   double _balance = 75.0;
//   String _cardNumber = "5078 • 2910 • 8847 • 3921";
//   bool _isScanning = false;
//   bool _hasScanned = true;
//   bool _isInitializingPayment = false;
//   late AnimationController _waveController;
//   late SharedPreferences _prefs;
//   List<Map<String, dynamic>> _travelLogs = [];

//   @override
//   void initState() {
//     super.initState();
//     _waveController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     );
//     _loadWalletData();
//   }

//   @override
//   void dispose() {
//     _waveController.dispose();
//     super.dispose();
//   }

//   // ── LOAD PERSISTENT DATA FROM LOCAL STORAGE ──
//   Future<void> _loadWalletData() async {
//     _prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _balance = _prefs.getDouble('smart_card_balance') ?? 75.0;
//       _cardNumber = _prefs.getString('smart_card_number') ?? "5078 • 2910 • 8847 • 3921";
      
//       final String? logsJson = _prefs.getString('smart_card_logs');
//       if (logsJson != null) {
//         final List<dynamic> decoded = json.decode(logsJson);
//         _travelLogs = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
//       } else {
//         // Initial mock travel logs if empty
//         _travelLogs = [
//           {
//             "from": "Sadat",
//             "fromAr": "السادات",
//             "to": "Attaba",
//             "toAr": "العتبة",
//             "cost": 8.0,
//             "date": "Today, 02:40 PM",
//             "dateAr": "اليوم، 02:40 م",
//             "type": "Ride",
//             "typeAr": "رحلة"
//           },
//           {
//             "from": "Shohadaa",
//             "fromAr": "الشهداء",
//             "to": "Heliopolis",
//             "toAr": "مصر الجديدة",
//             "cost": 15.0,
//             "date": "Yesterday, 09:15 AM",
//             "dateAr": "أمس، 09:15 ص",
//             "type": "Ride",
//             "typeAr": "رحلة"
//           }
//         ];
//         _saveWalletData();
//       }
//     });
//   }

//   // ── SAVE PERSISTENT DATA ──
//   Future<void> _saveWalletData() async {
//     await _prefs.setDouble('smart_card_balance', _balance);
//     await _prefs.setString('smart_card_number', _cardNumber);
//     await _prefs.setString('smart_card_logs', json.encode(_travelLogs));
//   }

//   void _startNfcScan() {
//     setState(() {
//       _isScanning = true;
//       _hasScanned = false;
//     });
//     _waveController.repeat();

//     Timer(const Duration(milliseconds: 2500), () {
//       if (!mounted) return;
//       HapticFeedback.heavyImpact();
//       _waveController.stop();
//       setState(() {
//         _isScanning = false;
//         _hasScanned = true;
//       });

//       GamificationService.unlockBadge(BadgeType.nfcPro);
//       GamificationService.recordNfcUse();

//       showModalBottomSheet(
//         context: context,
//         backgroundColor: Colors.transparent,
//         builder: (ctx) => Container(
//           padding: const EdgeInsets.all(24),
//           decoration: BoxDecoration(
//             color: Theme.of(context).cardColor,
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 48, height: 48,
//                 decoration: BoxDecoration(
//                   color: AppColors.success.withOpacity(0.12),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 30),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 "nfc_scan_success".tr(),
//                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "${"nfc_balance".tr()}: ${_balance.toStringAsFixed(1)} EGP",
//                 style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                   minimumSize: const Size(double.infinity, 50),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                 ),
//                 onPressed: () => Navigator.pop(ctx),
//                 child: Text("OK".tr()),
//               ),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   // ── 100% REAL RECHARGE DIALOG ──
//   void _showRechargeSheet() {
//     double selectedAmount = 100.0;
//     String selectedGateway = 'paymob'; // 'paymob' or 'stripe'
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           padding: EdgeInsets.only(
//             left: 24, right: 24, top: 24,
//             bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//           ),
//           decoration: BoxDecoration(
//             color: Theme.of(context).cardColor,
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: Container(
//                   width: 40, height: 4,
//                   decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 "nfc_recharge".tr(),
//                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Select amount and payment gateway to load funds".tr(),
//                 style: const TextStyle(color: Colors.grey, fontSize: 13),
//               ),
//               const SizedBox(height: 20),
//               // Package grid
//               Row(
//                 children: [50, 100, 200, 500].map((amt) {
//                   final isSelected = selectedAmount == amt.toDouble();
//                   return Expanded(
//                     child: GestureDetector(
//                       onTap: () => setModalState(() => selectedAmount = amt.toDouble()),
//                       child: Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 4),
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         decoration: BoxDecoration(
//                           color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.06),
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(
//                             color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.2),
//                             width: 1.2,
//                           ),
//                         ),
//                         child: Center(
//                           child: Text(
//                             "$amt",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 13,
//                               color: isSelected ? Colors.white : AppColors.primary,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 "Payment Method",
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
//               ),
//               const SizedBox(height: 12),
//               // 1. Paymob (Local Card / Wallet)
//               GestureDetector(
//                 onTap: () => setModalState(() => selectedGateway = 'paymob'),
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: selectedGateway == 'paymob'
//                         ? AppColors.primary.withOpacity(0.08)
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(
//                       color: selectedGateway == 'paymob'
//                           ? AppColors.primary
//                           : Colors.grey.withOpacity(0.2),
//                       width: 1.5,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: AppColors.primary.withOpacity(0.12),
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(Icons.payment_rounded, color: AppColors.primary),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               "Local Card / Wallets (Paymob)",
//                               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               "Visa, Mastercard, Vodafone Cash, Fawry",
//                               style: TextStyle(color: Colors.grey, fontSize: 11),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (selectedGateway == 'paymob')
//                         const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               // 2. Stripe (International / Global)
//               GestureDetector(
//                 onTap: () => setModalState(() => selectedGateway = 'stripe'),
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: selectedGateway == 'stripe'
//                         ? const Color(0xFF635BFF).withOpacity(0.08)
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(
//                       color: selectedGateway == 'stripe'
//                           ? const Color(0xFF635BFF)
//                           : Colors.grey.withOpacity(0.2),
//                       width: 1.5,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF635BFF).withOpacity(0.12),
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(Icons.language_rounded, color: Color(0xFF635BFF)),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               "International Cards (Stripe)",
//                               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               "Global Credit/Debit Cards, Apple Pay, Google Pay",
//                               style: TextStyle(color: Colors.grey, fontSize: 11),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (selectedGateway == 'stripe')
//                         const Icon(Icons.check_circle, color: Color(0xFF635BFF), size: 22),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 28),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: selectedGateway == 'paymob' ? AppColors.primary : const Color(0xFF635BFF),
//                   foregroundColor: Colors.white,
//                   minimumSize: const Size(double.infinity, 54),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                   elevation: 0,
//                 ),
//                 onPressed: () {
//                   Navigator.pop(ctx);
//                   if (selectedGateway == 'paymob') {
//                     _processRealPaymobPayment(selectedAmount);
//                   } else {
//                     _processRealStripePayment(selectedAmount);
//                   }
//                 },
//                 child: Text(
//                   "${"nfc_recharge".tr()} ($selectedAmount EGP)",
//                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ── INITIALIZE REAL PAYMOB GATEWAY CONNECTION ──
//   Future<void> _processRealPaymobPayment(double amount) async {
//     setState(() {
//       _isInitializingPayment = true;
//     });

//     try {
//       // 1. Get Payment token from Paymob API
//       final paymentToken = await PaymobService.getFinalPaymentToken(amount);

//       setState(() {
//         _isInitializingPayment = false;
//       });

//       if (!mounted) return;

//       // 2. Open Paymob WebView accept screen
//       final bool? paymentSuccess = await Navigator.push<bool>(
//         context,
//         MaterialPageRoute(
//           builder: (_) => PaymobIframePage(paymentToken: paymentToken),
//         ),
//       );

//       // 3. Handle result
//       if (paymentSuccess == true) {
//         HapticFeedback.heavyImpact();
//         setState(() {
//           _balance += amount;
//           _travelLogs.insert(0, {
//             "from": "Recharge",
//             "fromAr": "شحن رصيد",
//             "to": "",
//             "toAr": "",
//             "cost": -amount,
//             "date": "Just Now",
//             "dateAr": "الآن",
//             "type": "Payment",
//             "typeAr": "شحن"
//           });
//         });
//         await _saveWalletData();
//         _showPaymentSuccessAlert(amount);
//       } else {
//         _showPaymentFailedAlert("Payment canceled or rejected by card issuer.", amount);
//       }
//     } catch (e) {
//       setState(() {
//         _isInitializingPayment = false;
//       });
//       // Show elegant error popup
//       _showPaymentFailedAlert(
//         "Paymob Initialization Failed: ${e.toString().replaceAll("Exception:", "")}\n\n"
//         "Please check your network and make sure the Paymob keys in the dashboard are configured correctly.",
//         amount,
//       );
//     }
//   }

//   // ── INITIALIZE REAL STRIPE GATEWAY CONNECTION ──
//   Future<void> _processRealStripePayment(double amount) async {
//     setState(() {
//       _isInitializingPayment = true;
//     });

//     try {
//       // 1. Get Stripe checkout session URL
//       final sessionUrl = await StripeService.createCheckoutSession(amount);

//       setState(() {
//         _isInitializingPayment = false;
//       });

//       if (!mounted) return;

//       // 2. Open Stripe Checkout WebView
//       final bool? paymentSuccess = await Navigator.push<bool>(
//         context,
//         MaterialPageRoute(
//           builder: (_) => StripeCheckoutPage(sessionUrl: sessionUrl),
//         ),
//       );

//       // 3. Handle result
//       if (paymentSuccess == true) {
//         HapticFeedback.heavyImpact();
//         setState(() {
//           _balance += amount;
//           _travelLogs.insert(0, {
//             "from": "Recharge",
//             "fromAr": "شحن رصيد",
//             "to": "",
//             "toAr": "",
//             "cost": -amount,
//             "date": "Just Now",
//             "dateAr": "الآن",
//             "type": "Payment",
//             "typeAr": "شحن"
//           });
//         });
//         await _saveWalletData();
//         _showPaymentSuccessAlert(amount);
//       } else {
//         _showPaymentFailedAlert("Stripe payment canceled or incomplete.", amount);
//       }
//     } catch (e) {
//       setState(() {
//         _isInitializingPayment = false;
//       });
//       _showPaymentFailedAlert(
//         "Stripe Initialization Failed: ${e.toString().replaceAll("Exception:", "")}\n\n"
//         "Please check your network and make sure your Stripe Secret Key is configured correctly.",
//         amount,
//       );
//     }
//   }

//   void _showPaymentSuccessAlert(double amount) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
//               child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               "nfc_success_recharge".tr(),
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               "Recharge Amount: $amount EGP\nNew Balance: ${_balance.toStringAsFixed(1)} EGP",
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.grey, fontSize: 13),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.success,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                 minimumSize: const Size(120, 45),
//               ),
//               onPressed: () => Navigator.pop(ctx),
//               child: Text("Awesome".tr()),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   void _showPaymentFailedAlert(String error, double amount) {
//     final isAr = context.locale.languageCode == 'ar';
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Row(
//           children: [
//             const Icon(Icons.error_outline_rounded, color: AppColors.error),
//             const SizedBox(width: 10),
//             Text("Payment Failed".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
//           ],
//         ),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               error,
//               style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.amber.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.science_outlined, color: Colors.amber, size: 20),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       isAr 
//                         ? "أنت في وضع التجربة. يمكنك محاكاة عملية الشحن كاملة بضغطة زر!"
//                         : "You are in sandbox/demo mode. You can simulate the full flow!",
//                       style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: Text("OK".tr(), style: const TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primary,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//             ),
//             icon: const Icon(Icons.play_arrow_rounded, size: 18),
//             label: Text(
//               isAr ? "دفع تجريبي 🧪" : "Demo Recharge 🧪",
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//             onPressed: () {
//               Navigator.pop(ctx);
//               HapticFeedback.heavyImpact();
//               setState(() {
//                 _balance += amount;
//                 _travelLogs.insert(0, {
//                   "from": "Recharge",
//                   "fromAr": "شحن رصيد",
//                   "to": "",
//                   "toAr": "",
//                   "cost": -amount,
//                   "date": "Just Now",
//                   "dateAr": "الآن",
//                   "type": "Payment",
//                   "typeAr": "شحن"
//                 });
//               });
//               _saveWalletData();
//               _showPaymentSuccessAlert(amount);
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   void _simulateGateScan() {
//     if (_balance < 8.0) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text("Insufficient balance! Please recharge your card."),
//         backgroundColor: AppColors.error,
//         behavior: SnackBarBehavior.floating,
//       ));
//       return;
//     }

//     HapticFeedback.lightImpact();
//     setState(() {
//       _balance -= 8.0;
//       _travelLogs.insert(0, {
//         "from": "Ramses",
//         "fromAr": "رمسيس",
//         "to": "Sadat",
//         "toAr": "السادات",
//         "cost": 8.0,
//         "date": "Just Now",
//         "dateAr": "الآن",
//         "type": "Ride",
//         "typeAr": "رحلة"
//       });
//     });
//     _saveWalletData();

//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.directions_subway_rounded, color: AppColors.success, size: 54),
//             const SizedBox(height: 16),
//             Text(
//               "nfc_gate_entered".tr(),
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               "Deducted: 8.0 EGP\nNew Balance: ${_balance.toStringAsFixed(1)} EGP",
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.grey, fontSize: 13),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.success,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               onPressed: () => Navigator.pop(ctx),
//               child: const Text("Enjoy Ride"),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isAr = context.locale.languageCode == 'ar';

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("nfc_wallet".tr()),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.help_outline_rounded),
//             onPressed: () {
//               showDialog(
//                 context: context,
//                 builder: (ctx) => AlertDialog(
//                   title: const Text("Cairo Smart Card info"),
//                   content: const Text(
//                     "You can link your physical Cairo Metro smart card using your NFC receiver. "
//                     "Simply hold the card against the back of your phone to synchronize balance and recharge remotely.",
//                   ),
//                   actions: [
//                     TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Got it"))
//                   ],
//                 ),
//               );
//             },
//           )
//         ],
//       ),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ── PREMIUM METRO NFC CARD ──
//                 FadeInDown(
//                   child: AspectRatio(
//                     aspectRatio: 1.6,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(22),
//                         gradient: const LinearGradient(
//                           colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617)],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: AppColors.primary.withOpacity(0.25),
//                             blurRadius: 20,
//                             offset: const Offset(0, 8),
//                           )
//                         ],
//                         border: Border.all(color: Colors.white.withOpacity(0.08)),
//                       ),
//                       child: Stack(
//                         children: [
//                           // Radial highlights
//                           Positioned(
//                             right: -30, top: -30,
//                             child: Container(
//                               width: 140, height: 140,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: AppColors.primary.withOpacity(0.15),
//                               ),
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(22),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         const Text(
//                                           "RAFIQ METRO",
//                                           style: TextStyle(
//                                             color: Colors.white70,
//                                             fontSize: 10,
//                                             fontWeight: FontWeight.bold,
//                                             letterSpacing: 2,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 2),
//                                         Text(
//                                           isAr ? "كارت ذكي موحد" : "Unified Smart Card",
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     // NFC symbol
//                                     const Icon(Icons.nfc_rounded, color: Colors.white, size: 28),
//                                   ],
//                                 ),
//                                 const Spacer(),
//                                 // Chip and neon text
//                                 Row(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: [
//                                     // Glowing microchip
//                                     Container(
//                                       width: 38, height: 28,
//                                       decoration: BoxDecoration(
//                                         gradient: const LinearGradient(
//                                           colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
//                                         ),
//                                         borderRadius: BorderRadius.circular(6),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 16),
//                                     Text(
//                                       _cardNumber.length >= 10
//                                           ? "•••• •••• •••• ${_cardNumber.split(' • ').last}"
//                                           : _cardNumber,
//                                       style: const TextStyle(
//                                         color: Colors.white70,
//                                         fontFamily: 'monospace',
//                                         fontSize: 14,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 20),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           "nfc_balance".tr().toUpperCase(),
//                                           style: const TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 1),
//                                         ),
//                                         const SizedBox(height: 2),
//                                         Text(
//                                           "${_balance.toStringAsFixed(1)} EGP",
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 22,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                                       decoration: BoxDecoration(
//                                         color: AppColors.success.withOpacity(0.2),
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                       child: Row(
//                                         children: [
//                                           Container(
//                                             width: 6, height: 6,
//                                             decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
//                                           ),
//                                           const SizedBox(width: 6),
//                                           Text(
//                                             "nfc_card_active".tr(),
//                                             style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
//                                           ),
//                                         ],
//                                       ),
//                                     )
//                                   ],
//                                 )
//                               ],
//                             ),
//                           )
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 28),

//                 // ── INTERACTIVE CONTROLS ──
//                 FadeInUp(
//                   delay: const Duration(milliseconds: 150),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.primary,
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                             elevation: 0,
//                           ),
//                           icon: const Icon(Icons.add_card_rounded),
//                           label: Text("nfc_recharge".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
//                           onPressed: _showRechargeSheet,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: AppColors.primary,
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             side: const BorderSide(color: AppColors.primary, width: 1.5),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                           ),
//                           icon: const Icon(Icons.sensor_occupied_rounded),
//                           label: Text("nfc_simulate_gate".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
//                           onPressed: _simulateGateScan,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // ── NFC SCANNER WIDGET ──
//                 FadeInUp(
//                   delay: const Duration(milliseconds: 250),
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(22),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).cardColor,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: Colors.grey.withOpacity(0.15)),
//                     ),
//                     child: Column(
//                       children: [
//                         if (_isScanning) ...[
//                           AnimatedBuilder(
//                             animation: _waveController,
//                             builder: (context, child) => Container(
//                               width: 80, height: 80,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: AppColors.primary.withOpacity(0.15),
//                                 border: Border.all(
//                                   color: AppColors.primary.withOpacity(1 - _waveController.value),
//                                   width: 1 + 6 * _waveController.value,
//                                 ),
//                               ),
//                               child: const Icon(Icons.nfc_rounded, color: AppColors.primary, size: 38),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             "nfc_tap_instruction".tr(),
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
//                           ),
//                         ] else ...[
//                           const Icon(Icons.nfc_rounded, color: Colors.grey, size: 40),
//                           const SizedBox(height: 10),
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: AppColors.primary.withOpacity(0.1),
//                               foregroundColor: AppColors.primary,
//                               elevation: 0,
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             ),
//                             onPressed: _startNfcScan,
//                             child: Text("nfc_simulate_scan".tr()),
//                           )
//                         ]
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 28),

//                 // ── RECENT TRAVEL LEDGER ──
//                 FadeInUp(
//                   delay: const Duration(milliseconds: 350),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "nfc_recent_logs".tr(),
//                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
//                       ),
//                       const SizedBox(height: 12),
//                       ListView.separated(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         itemCount: _travelLogs.length,
//                         separatorBuilder: (_, __) => Divider(color: Colors.grey.withOpacity(0.12), height: 1),
//                         itemBuilder: (ctx, i) {
//                           final log = _travelLogs[i];
//                           final isRide = log["type"] == "Ride";
//                           final from = isAr ? log["fromAr"] : log["from"];
//                           final to = isAr ? log["toAr"] : log["to"];
//                           final title = isRide ? "$from ➔ $to" : from;
//                           final type = isAr ? log["typeAr"] : log["type"];
//                           final date = isAr ? log["dateAr"] : log["date"];

//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   width: 40, height: 40,
//                                   decoration: BoxDecoration(
//                                     color: isRide ? AppColors.primary.withOpacity(0.08) : AppColors.success.withOpacity(0.08),
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: Icon(
//                                     isRide ? Icons.directions_subway_rounded : Icons.add_card_rounded,
//                                     color: isRide ? AppColors.primary : AppColors.success,
//                                     size: 20,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 14),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         title,
//                                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         "$type · $date",
//                                         style: const TextStyle(color: Colors.grey, fontSize: 11),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 Text(
//                                   isRide ? "-${log["cost"].toStringAsFixed(0)} EGP" : "+${(-log["cost"]).toStringAsFixed(0)} EGP",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: isRide ? Colors.red[600] : AppColors.success,
//                                     fontSize: 14,
//                                   ),
//                                 )
//                               ],
//                             ),
//                           );
//                         },
//                       )
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           ),
//           // ── REAL PAYMOB INITIALIZING SPINNER OVERLAY ──
//           if (_isInitializingPayment)
//             Container(
//               color: Colors.black.withOpacity(0.65),
//               child: Center(
//                 child: FadeIn(
//                   child: Card(
//                     color: Theme.of(context).cardColor,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                     elevation: 12,
//                     child: Padding(
//                       padding: const EdgeInsets.all(32),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3.5),
//                           const SizedBox(height: 20),
//                           Text(
//                             "Securing Paymob connection...".tr(),
//                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             "Please wait, generating payment token".tr(),
//                             style: const TextStyle(color: Colors.grey, fontSize: 11),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
