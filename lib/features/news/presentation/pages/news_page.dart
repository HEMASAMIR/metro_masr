import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/news_bloc.dart';
import '../widgets/news_card_widget.dart';
import 'article_webview_page.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<NewsBloc>()..add(FetchNews(countryCode: 'eg')),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأخبار العاجلة', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
        ),
        body: const NewsView(),
      ),
    );
  }
}

class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  String _selectedCountry = 'eg';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  title: 'أخبار مصر',
                  isActive: _selectedCountry == 'eg',
                  onTap: () {
                    setState(() => _selectedCountry = 'eg');
                    context.read<NewsBloc>().add(FetchNews(countryCode: 'eg'));
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTabButton(
                  title: 'العالم',
                  isActive: _selectedCountry == 'us',
                  onTap: () {
                    setState(() => _selectedCountry = 'us');
                    context.read<NewsBloc>().add(FetchNews(countryCode: 'us'));
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<NewsBloc, NewsState>(
            builder: (context, state) {
              if (state is NewsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is NewsError) {
                return Center(
                  child: FadeIn(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('حدث خطأ: ${state.message}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<NewsBloc>().add(FetchNews(countryCode: _selectedCountry));
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is NewsLoaded) {
                if (state.articles.isEmpty) {
                  return const Center(child: Text('لا توجد أخبار متاحة حالياً.', style: TextStyle(fontWeight: FontWeight.bold)));
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: state.articles.length,
                  itemBuilder: (context, index) {
                    final article = state.articles[index];
                    return NewsCardWidget(
                      index: index,
                      article: article,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleWebViewPage(article: article),
                          ),
                        );
                      },
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({required String title, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
