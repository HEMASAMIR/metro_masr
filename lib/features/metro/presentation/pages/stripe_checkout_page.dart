import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

class StripeCheckoutPage extends StatefulWidget {
  final String sessionUrl;

  const StripeCheckoutPage({super.key, required this.sessionUrl});

  @override
  State<StripeCheckoutPage> createState() => _StripeCheckoutPageState();
}

class _StripeCheckoutPageState extends State<StripeCheckoutPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

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
            // Detect Stripe success / cancel redirect URLs
            if (request.url.startsWith('https://success.rafiqmetro.com')) {
              Navigator.pop(context, true); // Stripe Payment successful
              return NavigationDecision.prevent;
            } else if (request.url.startsWith('https://cancel.rafiqmetro.com')) {
              Navigator.pop(context, false); // Stripe Payment cancelled
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.sessionUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Checkout - Stripe'.tr(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
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
