// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/talk_model.dart';
import 'cognito_service.dart';

class ApiService {
  // URL per l'API principale (quella dei talk)
  //static const String _baseUrl = 'https://codqpgmjda.execute-api.us-east-1.amazonaws.com/default';
  static const String _baseUrl = 'https://n1989l0z49.execute-api.us-east-1.amazonaws.com/default/';
  // URL specifico per la ricerca per titolo (se diverso, altrimenti usa _baseUrl)
  static const String _searchByTitleUrl = 'https://n2v2k9ng51.execute-api.us-east-1.amazonaws.com/default/Get_Talks_By_Title'; // <--- VERIFICA CHE QUESTO SIA L'URL CORRETTO

  final CognitoService _cognitoService = CognitoService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _cognitoService.getLatestAuthToken();
    if (token == null) {
      throw Exception('User not authenticated. Token is null.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': token,
    };
  }

  // Metodo per ottenere la lista iniziale dei talk per tag (rimane invariato)
  Future<List<Talk>> getTalksByTag(String tag) async {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/Get_Talks_By_Tag'), // Assumi che questo sia l'endpoint per i tag
      headers: headers,
      body: json.encode({'tag': tag, 'doc_per_page': 10, 'page': 1}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> talksJson = json.decode(response.body);
      return talksJson.map((json) => Talk.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load talks: ${response.body}');
    }
  }

  // --- NUOVO METODO: PER OTTENERE TALK PER TITOLO ---
  Future<List<Talk>> getTalksByTitle(String title) async {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse(_searchByTitleUrl), // Usa l'URL della tua lambda Get_Talks_By_Title
      headers: headers,
      body: json.encode({'title': title, 'doc_per_page': 10, 'page': 1}), // Invia il titolo nella body
    );

    if (response.statusCode == 200) {
      final List<dynamic> talksJson = json.decode(response.body);
      return talksJson.map((json) => Talk.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load talks by title: ${response.body}');
    }
  }

  // Metodo per ottenere i video consigliati "Watch Next" (rimane invariato)
  Future<List<Talk>> getWatchNext(String talkId) async {
    final watchNextApiUrl = 'https://8jl68jy4vf.execute-api.us-east-1.amazonaws.com/default/Get_Watch_Next_By_Id';
    
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(watchNextApiUrl),
      headers: headers,
      body: json.encode({'id': talkId}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> talksJson = responseData['relatedTalks'];
      return talksJson.map((json) => Talk.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load watch next talks');
    }
  }
}