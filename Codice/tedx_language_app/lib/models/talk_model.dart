// lib/models/talk_model.dart

import 'package:flutter/foundation.dart';

class Talk {
  final String id;
  final String title;
  final String url;
  final String description;
  final String speakers;

  Talk({
    required this.id,
    required this.title,
    required this.url,
    required this.description,
    required this.speakers,
  });

  factory Talk.fromJson(Map<String, dynamic> json) {
    return Talk(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'No Title',
      url: json['url'] ?? '',
      description: json['description'] ?? 'No Description',
      speakers: json['speakers'] ?? 'Unknown Speaker',
    );
  }
}