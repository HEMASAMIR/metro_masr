import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:rafiq_metrro/features/community/domain/entities/message.dart';
import 'package:rafiq_metrro/features/community/domain/entities/report.dart';
import 'package:rafiq_metrro/features/community/domain/entities/reward.dart';
import 'package:rafiq_metrro/features/community/domain/repositories/community_repository.dart';
import 'package:rafiq_metrro/core/utils/offline_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  // Simulated local offline storage
  final List<Report> _localReports = [];
  final List<Message> _localMessages = [];
  int _points = 0;
  int _trips = 0;

  @override
  Future<Either<Failure, void>> saveReport(Report report) async {
    // 1. Save offline first (offline-first philosophy)
    final reports = OfflineStorage.getReports();
    reports.insert(0, report.copyWith(isSynced: false)); // newest first
    await OfflineStorage.saveReports(reports);

    // 2. Try to sync with Supabase
    final map = {
      'id': report.id,
      'title': report.title,
      'description': report.description,
      'location': report.location,
      'timestamp': report.timestamp.toIso8601String(),
      'category': report.category,
      'reporterName': report.reporterName,
      'imageUrl': report.imageUrl,
    };

    try {
      await Supabase.instance.client.from('reports').insert(map);
      // Mark as synced locally
      final updatedReports = OfflineStorage.getReports();
      final idx = updatedReports.indexWhere((r) => r.id == report.id);
      if (idx != -1) {
        updatedReports[idx] = updatedReports[idx].copyWith(isSynced: true);
        await OfflineStorage.saveReports(updatedReports);
      }
    } catch (e) {
      // Fallback: Save to messages table with room_id = 'lost_and_found_reports'
      try {
        await Supabase.instance.client.from('messages').insert({
          'room_id': 'lost_and_found_reports',
          'sender': report.reporterName ?? 'Anonymous',
          'text': json.encode(map),
          'type': 'report',
          'created_at': report.timestamp.toIso8601String(),
        });
        // Mark as synced locally
        final updatedReports = OfflineStorage.getReports();
        final idx = updatedReports.indexWhere((r) => r.id == report.id);
        if (idx != -1) {
          updatedReports[idx] = updatedReports[idx].copyWith(isSynced: true);
          await OfflineStorage.saveReports(updatedReports);
        }
      } catch (e2) {
        // Keeps local-only (synced = false) so it can sync when online
        print("Supabase sync failed (offline mode): $e2");
      }
    }

    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Report>>> getReports() async {
    List<Report> reportsList = [];

    // Try to fetch from Supabase 'reports' table
    try {
      final data = await Supabase.instance.client
          .from('reports')
          .select()
          .order('timestamp', ascending: false);
      if (data != null && data is List) {
        reportsList = data.map((item) => Report(
          id: item['id']?.toString() ?? '',
          title: item['title']?.toString() ?? '',
          description: item['description']?.toString() ?? '',
          location: item['location']?.toString() ?? '',
          timestamp: DateTime.parse(item['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
          category: item['category']?.toString() ?? 'other',
          reporterName: item['reporterName']?.toString(),
          imageUrl: item['imageUrl']?.toString(),
          isSynced: true,
        )).toList();
      }
    } catch (e) {
      // Fallback: Fetch from Supabase 'messages' table
      try {
        final data = await Supabase.instance.client
            .from('messages')
            .select()
            .eq('room_id', 'lost_and_found_reports')
            .order('created_at', ascending: false);
        if (data != null && data is List) {
          for (var item in data) {
            try {
              final textContent = item['text']?.toString();
              if (textContent != null) {
                final Map<String, dynamic> map = json.decode(textContent);
                reportsList.add(Report(
                  id: map['id']?.toString() ?? item['id']?.toString() ?? '',
                  title: map['title']?.toString() ?? '',
                  description: map['description']?.toString() ?? '',
                  location: map['location']?.toString() ?? '',
                  timestamp: DateTime.parse(map['timestamp']?.toString() ?? item['created_at']?.toString() ?? DateTime.now().toIso8601String()),
                  category: map['category']?.toString() ?? 'other',
                  reporterName: map['reporterName']?.toString() ?? item['sender']?.toString(),
                  imageUrl: map['imageUrl']?.toString() ?? item['image_base64']?.toString(),
                  isSynced: true,
                ));
              }
            } catch (_) {}
          }
        }
      } catch (e2) {
        print("Supabase fetch failed: $e2");
      }
    }

    // Merge with unsynced local reports
    final localReports = OfflineStorage.getReports();
    for (var local in localReports) {
      if (!reportsList.any((r) => r.id == local.id)) {
        reportsList.insert(0, local);
      }
    }

    // Seed one starter item if completely empty to guide users
    if (reportsList.isEmpty) {
      final initial = Report(
        id: const Uuid().v4(),
        title: 'تم العثور على محفظة',
        description: 'لقيت محفظة سوداء عند محطة السادات، سلمتها لمكتب الأمن.',
        location: 'محطة السادات',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        category: 'Wallet',
        isSynced: false,
      );
      await saveReport(initial);
      reportsList.add(initial);
    }

    return Right(reportsList);
  }

  @override
  Future<Either<Failure, void>> sendMessage(Message message) async {
    // Save message locally. Real offline-first mesh would auto-send via Bluetooth here.
    _localMessages.add(message);

    // Simulate auto-reply for demo purposes
    Future.delayed(const Duration(seconds: 2), () {
      _localMessages.add(
        Message(
          id: const Uuid().v4(),
          senderId: 'bot_id',
          senderName: 'Passenger #394',
          content: 'شفت المترو الجاي، لسه واصل المحطة اللي فاتت.',
          timestamp: DateTime.now(),
          isSent: true,
        ),
      );
    });

    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages() async {
    return Right(_localMessages);
  }

  @override
  Future<Either<Failure, void>> addTripPoint() async {
    _points += 10; // 10 points per trip
    _trips += 1;
    return const Right(null);
  }

  @override
  Future<Either<Failure, Reward>> getRewardProfile() async {
    return Right(
      Reward(id: 'user_reward_1', currentPoints: _points, totalTrips: _trips),
    );
  }

  @override
  Future<Either<Failure, void>> deleteReport(String id) async {
    // 1. Remove from local offline storage
    final reports = OfflineStorage.getReports();
    reports.removeWhere((r) => r.id == id);
    await OfflineStorage.saveReports(reports);

    // 2. Try to delete from Supabase 'reports' table
    try {
      await Supabase.instance.client.from('reports').delete().eq('id', id);
    } catch (_) {}

    // 3. Try to delete from Supabase 'messages' table if saved as fallback
    try {
      await Supabase.instance.client.from('messages').delete().like('text', '%$id%');
    } catch (_) {}

    return const Right(null);
  }
}
