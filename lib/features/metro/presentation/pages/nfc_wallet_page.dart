import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/offline_storage.dart';

class NfcWalletPage extends StatefulWidget {
  const NfcWalletPage({super.key});

  @override
  State<NfcWalletPage> createState() => _NfcWalletPageState();
}

class _NfcWalletPageState extends State<NfcWalletPage> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _isSuccess = false;
  double _balance = 0.0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _balance = OfflineStorage.getBalance();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _isSuccess = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _isSuccess = true;
      });
    });
  }

  void _rechargeBalance(double amount) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(context.locale.languageCode == 'ar' ? 'تأكيد الدفع' : 'Confirm Payment', style: const TextStyle(color: Colors.black)),
        content: Text(context.locale.languageCode == 'ar' ? 'جاري سحب $amount ج.م من البطاقة البنكية...' : 'Withdrawing $amount EGP from Visa...', style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _balance += amount);
              OfflineStorage.setBalance(_balance);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.locale.languageCode == 'ar' ? 'تم الشحن بنجاح! 💸' : 'Recharge Successful! 💸'), 
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(context.locale.languageCode == 'ar' ? 'اخصم الآن' : 'Pay Now', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _buyTicket(String ticketName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(context.locale.languageCode == 'ar' ? 'تذكرة مسبقة الحجز' : 'Pre-booked Ticket', style: const TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 150, color: Colors.black87),
            const SizedBox(height: 16),
            Text(context.locale.languageCode == 'ar' ? 'تم حجز $ticketName' : 'Purchased $ticketName', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(context.locale.languageCode == 'ar' ? 'مرر الـ QR على ماكينة العبور الإلكترونية' : 'Scan this QR at the e-gate', style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(context), 
              child: Text(context.locale.languageCode == 'ar' ? 'حسناً' : 'Done', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        title: Text('nfc_wallet'.tr(), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NFC Graphic Header
            FadeInDown(
              child: Center(
                child: GestureDetector(
                  onTap: _isScanning ? null : _startScan,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isSuccess
                              ? AppColors.success.withValues(alpha: 0.2)
                              : (_isScanning
                                  ? AppColors.primary.withValues(alpha: 0.3 * _pulseController.value)
                                  : AppColors.surface.withValues(alpha: 0.1)),
                          border: Border.all(
                            color: _isSuccess
                                ? AppColors.success
                                : (_isScanning ? AppColors.primary : AppColors.surface),
                            width: 3,
                          ),
                          boxShadow: [
                            if (_isScanning)
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5 * _pulseController.value),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isSuccess ? Icons.check_circle : Icons.contactless_outlined,
                            size: 60,
                            color: _isSuccess ? AppColors.success : Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeInDown(
              child: Text(
                _isSuccess ? (isAr ? 'تم قراءة الكارت!' : 'Card Read!') : (isAr ? 'مرر الكارت للقراءة' : 'Scan Card'),
                textAlign: TextAlign.center,
                style: TextStyle(color: _isSuccess ? AppColors.success : Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 30),

            // Balance Details
            FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.line3]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ]
                ),
                child: Column(
                  children: [
                    Text(isAr ? 'رصيد المترو المتاح' : 'Available Metro Balance', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text('$_balance EGP', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRechargeBtn('50', isAr),
                        _buildRechargeBtn('100', isAr),
                        _buildRechargeBtn('200', isAr),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Pre-booked Tickets
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Text(isAr ? 'شراء تذاكر مسبقة (QR)' : 'Pre-book QR Tickets', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: _buildTicketCard('تذكرة 9 محطات (10 ج.م)', '10 EGP Ticket', Icons.looks_one, () => _buyTicket(isAr ? 'تذكرة 10 ج.م' : '10 EGP Ticket')),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildTicketCard('تذكرة 16 محطة (12 ج.م)', '12 EGP Ticket', Icons.looks_two, () => _buyTicket(isAr ? 'تذكرة 12 ج.م' : '12 EGP Ticket')),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _buildTicketCard('تذكرة 23 محطة (15 ج.م)', '15 EGP Ticket', Icons.looks_3, () => _buyTicket(isAr ? 'تذكرة 15 ج.م' : '15 EGP Ticket')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRechargeBtn(String amount, bool isAr) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, 
        foregroundColor: AppColors.primary, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
      ),
      onPressed: () => _rechargeBalance(double.parse(amount)),
      child: Text('+$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildTicketCard(String titleAr, String titleEn, IconData icon, VoidCallback onTap) {
    final isAr = context.locale.languageCode == 'ar';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: AppColors.accent.withValues(alpha: 0.2), child: Icon(icon, color: AppColors.accent)),
            const SizedBox(width: 16),
            Expanded(child: Text(isAr ? titleAr : titleEn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
            const Icon(Icons.qr_code_scanner, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

