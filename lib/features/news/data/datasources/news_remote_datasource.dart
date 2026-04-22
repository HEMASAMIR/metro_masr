import 'package:dio/dio.dart';
import '../models/news_article_model.dart';

abstract class NewsRemoteDataSource {
  Future<List<NewsArticleModel>> getTopHeadlines(String countryCode);
}

class NewsRemoteDataSourceImpl implements NewsRemoteDataSource {
  final Dio dio;

  NewsRemoteDataSourceImpl({required this.dio});

  static const String _baseUrl = 'https://newsapi.org/v2';
  static const String _apiKey = 'YOUR_API_KEY';

  @override
  Future<List<NewsArticleModel>> getTopHeadlines(String countryCode) async {
    try {
      final response = await dio.get(
        '$_baseUrl/top-headlines',
        queryParameters: {
          'country': countryCode,
          'apiKey': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final List articles = response.data['articles'];
        return articles.map((e) => NewsArticleModel.fromJson(e)).toList();
      } else {
        return _getMockArticles();
      }
    } catch (e) {
      // Fallback with mock data for local testing / graduation project demo when API Key is missing or rate limited
      return _getMockArticles();
    }
  }

  List<NewsArticleModel> _getMockArticles() {
    return [
      NewsArticleModel(
        title: "تطوير ضخم في الخط الثالث للمترو يربط جميع أنحاء العاصمة",
        description: "شهدت القاهرة اليوم افتتاح محطات جديدة للخط الثالث للمترو لتسهيل حركة المرور وتقليل التكدسات بنسبة كبيرة في المناطق المزدحمة...",
        url: "https://news.google.com",
        imageUrl: "https://images.unsplash.com/photo-1598284687824-34ad61112bc9?q=80&w=1000",
        publishedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        sourceName: "أخبار اليوم",
      ),
      NewsArticleModel(
        title: "تراجع أسعار الذهب عالمياً وسط استقرار الأسواق المحلية",
        description: "سجلت أسعار الذهب انخفاضاً طفيفاً اليوم في البورصات العالمية في حين استمر الاستقرار في السوق المصري بفضل الإجراءات الأخيرة للمركزي.",
        url: "https://news.google.com",
        imageUrl: "https://images.unsplash.com/photo-1610375461246-83df859d849d?q=80&w=1000",
        publishedAt: DateTime.now().subtract(const Duration(hours: 1)),
        sourceName: "الاقتصادية",
      ),
      NewsArticleModel(
        title: "النادي الأهلي يتوج ببطولة القارة",
        description: "في مباراة مثيرة، حقق النادي الأهلي فوزاً مستحقاً ليحصد اللقب القاري وسط احتفالات جماهيرية واسعة في كل أنحاء الجمهورية.",
        url: "https://news.google.com",
        imageUrl: "https://images.unsplash.com/photo-1518605368461-1ee71ee1b145?q=80&w=1000",
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        sourceName: "يلا كورة",
      ),
      NewsArticleModel(
        title: "اكتشاف أثري جديد في منطقة سقارة",
        description: "أعلنت وزارة السياحة والآثار عن اكتشاف مقبرة تعود للأسرة الفرعونية القديمة تحوي كنوزاً ومقتنيات ذهبية نادرة جدا.",
        url: "https://news.google.com",
        imageUrl: "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=1000",
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
        sourceName: "اليوم السابع",
      ),
      NewsArticleModel(
        title: "تحديثات تقنية جديدة في عالم الذكاء الاصطناعي تقدمها جوجل",
        description: "شركات التكنولوجيا الكبرى تعلن عن خدمات جديدة تعتمد بشكل كلي على الذكاء الاصطناعي لتسهيل مهام المستخدمين اليومية وتوفير وقتهم.",
        url: "https://news.google.com",
        imageUrl: "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?q=80&w=1000",
        publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
        sourceName: "بوابة التقنية",
      )
    ];
  }
}
