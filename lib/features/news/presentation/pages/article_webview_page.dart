import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/news_article.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';

class ArticleWebViewPage extends StatefulWidget {
  final NewsArticle article;

  const ArticleWebViewPage({super.key, required this.article});

  @override
  State<ArticleWebViewPage> createState() => _ArticleWebViewPageState();
}

class _ArticleWebViewPageState extends State<ArticleWebViewPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _loadingProgress = progress / 100.0;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _loadingProgress = 1.0;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.article.url));
    } else {
      _isLoading = false;
      _loadingProgress = 1.0;
    }
  }

  String _getHostName(String urlStr) {
    try {
      final uri = Uri.parse(urlStr);
      return uri.host;
    } catch (_) {
      return "Secure Link";
    }
  }

  @override
  Widget build(BuildContext context) {
    final host = _getHostName(widget.article.url);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.green,
                size: 16,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article.sourceName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        color: Colors.green.shade600,
                        size: 10,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          host,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, size: 22),
            onPressed: () async {
              final uri = Uri.parse(widget.article.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            tooltip: "Open in external browser",
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: _loadingProgress < 1.0
              ? LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3.0,
                )
              : const SizedBox(height: 3.0),
        ),
      ),
      body: kIsWeb || _controller == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.language_rounded, size: 64, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Cannot display web page directly',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please open this link in your standard external browser to read the full article securely.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded),
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
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: 15,
                        itemBuilder: (context, index) {
                          return Shimmer.fromColors(
                            baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                            highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                            child: Container(
                              height: index == 0 ? 30 : 14,
                              width: index == 0
                                  ? double.infinity
                                  : (index % 3 == 0
                                      ? MediaQuery.of(context).size.width * 0.7
                                      : double.infinity),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade900 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: _controller != null
          ? Container(
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    onPressed: () async {
                      if (await _controller!.canGoBack()) {
                        await _controller!.goBack();
                      }
                    },
                    tooltip: "Go Back",
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    onPressed: () async {
                      if (await _controller!.canGoForward()) {
                        await _controller!.goForward();
                      }
                    },
                    tooltip: "Go Forward",
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    onPressed: () {
                      _controller!.reload();
                    },
                    tooltip: "Reload Page",
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 20),
                    onPressed: () async {
                      final uri = Uri.parse(widget.article.url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    tooltip: "Share Link",
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
