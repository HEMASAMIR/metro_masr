import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/news_article.dart';

class ArticleWebViewPage extends StatefulWidget {
  final NewsArticle article;

  const ArticleWebViewPage({super.key, required this.article});

  @override
  State<ArticleWebViewPage> createState() => _ArticleWebViewPageState();
}

class _ArticleWebViewPageState extends State<ArticleWebViewPage> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.article.url));
    } else {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.sourceName),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final uri = Uri.parse(widget.article.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (widget.article.imageUrl != null)
            Hero(
              tag: widget.article.url,
              child: Image.network(
                widget.article.imageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          Expanded(
            child: kIsWeb || _controller == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.web, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Cannot display web page directly inside browser', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Read Full Article'),
                          onPressed: () async {
                            final uri = Uri.parse(widget.article.url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      WebViewWidget(controller: _controller!),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
