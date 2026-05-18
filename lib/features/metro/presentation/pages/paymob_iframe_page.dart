import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/paymob_service.dart';

class PaymobIframePage extends StatefulWidget {
  final String paymentToken;

  const PaymobIframePage({super.key, required this.paymentToken});

  @override
  State<PaymobIframePage> createState() => _PaymobIframePageState();
}

class _PaymobIframePageState extends State<PaymobIframePage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // The URL for Paymob Iframe
    final String url = 'https://accept.paymob.com/api/acceptance/iframes/${PaymobService.iframeId}?payment_token=${widget.paymentToken}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Paymob redirects to a specific callback URL upon success/failure
            // You should configure this callback URL in your Paymob dashboard
            if (request.url.contains('success=true')) {
              Navigator.pop(context, true); // Payment successful
              return NavigationDecision.prevent;
            } else if (request.url.contains('success=false')) {
              Navigator.pop(context, false); // Payment failed
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Payment - Paymob'.tr(), style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
