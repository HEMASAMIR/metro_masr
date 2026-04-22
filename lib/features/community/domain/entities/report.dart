import 'package:equatable/equatable.dart';

class Report extends Equatable {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime timestamp;
  final bool isSynced;
  final String category; // 'issue', 'overcrowd', 'harassment', 'other'

  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.timestamp,
    this.isSynced = false,
    this.category = 'issue',
  });

  Report copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? timestamp,
    bool? isSynced,
    String? category,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [id, title, description, location, timestamp, isSynced, category];
}
