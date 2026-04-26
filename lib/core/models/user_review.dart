import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A user-submitted review for a tourist attraction.
class UserReview {
  final String id;
  final String attractionId;
  final String userName;
  final double rating; // 1.0 – 5.0
  final String comment;
  final DateTime date;
  int helpfulCount;

  /// Answers to post-review questionnaire
  /// Keys: 'recommend', 'liked', 'easyToFind'
  final Map<String, dynamic> postAnswers;

  UserReview({
    required this.id,
    required this.attractionId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    this.helpfulCount = 0,
    this.postAnswers = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'attractionId': attractionId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'date': date.toIso8601String(),
        'helpfulCount': helpfulCount,
        'postAnswers': postAnswers,
      };

  factory UserReview.fromJson(Map<String, dynamic> j) => UserReview(
        id: j['id'] as String,
        attractionId: j['attractionId'] as String,
        userName: j['userName'] as String,
        rating: (j['rating'] as num).toDouble(),
        comment: j['comment'] as String,
        date: DateTime.parse(j['date'] as String),
        helpfulCount: (j['helpfulCount'] as int?) ?? 0,
        postAnswers: Map<String, dynamic>.from(j['postAnswers'] as Map? ?? {}),
      );
}

/// Handles persisting and retrieving user reviews via SharedPreferences.
class UserReviewService {
  static const _prefix = 'reviews_';

  static String _key(String attractionId) => '$_prefix$attractionId';

  /// Load all reviews for an attraction.
  static Future<List<UserReview>> getReviews(String attractionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(attractionId));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => UserReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Add a new review, returns updated list.
  static Future<List<UserReview>> addReview(UserReview review) async {
    final reviews = await getReviews(review.attractionId);
    reviews.insert(0, review);
    await _save(review.attractionId, reviews);
    return reviews;
  }

  /// Increment helpful count for a review.
  static Future<void> markHelpful(String attractionId, String reviewId) async {
    final reviews = await getReviews(attractionId);
    final idx = reviews.indexWhere((r) => r.id == reviewId);
    if (idx != -1) {
      reviews[idx].helpfulCount++;
      await _save(attractionId, reviews);
    }
  }

  /// Compute average rating.  Returns null if no reviews.
  static Future<double?> averageRating(String attractionId) async {
    final reviews = await getReviews(attractionId);
    if (reviews.isEmpty) return null;
    final sum = reviews.fold<double>(0, (acc, r) => acc + r.rating);
    return sum / reviews.length;
  }

  static Future<void> _save(
      String attractionId, List<UserReview> reviews) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key(attractionId), jsonEncode(reviews.map((r) => r.toJson()).toList()));
  }
}
