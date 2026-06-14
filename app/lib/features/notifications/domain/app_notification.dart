import 'package:flutter/foundation.dart';

/// An in-app notification received over the user's notify channel.
@immutable
class AppNotification {
  const AppNotification({
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory AppNotification.fromJson(
    Map<String, dynamic> json,
    DateTime fallback,
  ) {
    final created = json['created_at'];
    return AppNotification(
      category: json['category'] as String? ?? 'rewards',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: created == null
          ? fallback
          : (DateTime.tryParse(created.toString()) ?? fallback),
    );
  }

  final String category;
  final String title;
  final String body;
  final DateTime createdAt;
}
