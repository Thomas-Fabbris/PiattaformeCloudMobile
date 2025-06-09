// lib/providers/talk_provider.dart

import 'package:flutter/material.dart';
import '../models/talk_model.dart';
import '../services/api_service.dart';

class TalkProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Talk> _talks = [];
  bool _isLoading = false;
  String? _error;

  List<Talk> get talks => _talks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTalks(String tag) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _talks = await _apiService.getTalksByTag(tag);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}