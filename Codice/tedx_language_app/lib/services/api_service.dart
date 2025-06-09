// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/talk_model.dart';
import 'cognito_service.dart';

class ApiService {
  // URL per l'API principale (quella dei talk)
  static const String _baseUrl = 'https://codqpgmjda.execute-api.us-east-1.amazonaws.com/default';
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

  // Metodo per ottenere la lista iniziale dei talk
  Future<List<Talk>> getTalksByTag(String tag) async {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/Get_Talks_By_ID'),
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

  // Metodo per ottenere i video consigliati "Watch Next"
  Future<List<Talk>> getWatchNext(String talkId) async {
    // URL completo della tua seconda API
    final watchNextApiUrl = 'https://8jl68jy4vf.execute-api.us-east-1.amazonaws.com/default/Get_Watch_Next_By_Id';
    
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(watchNextApiUrl),
      headers: headers,
      body: json.encode({'id': talkId}),
    );

    if (response.statusCode == 200) {
      // Decodifichiamo la risposta come un oggetto Map
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      // Estraiamo la lista di talk dalla chiave 'relatedTalks'
      final List<dynamic> talksJson = responseData['relatedTalks'];
      
      // Convertiamo la lista in oggetti Talk
      return talksJson.map((json) => Talk.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load watch next talks');
    }
  }
}