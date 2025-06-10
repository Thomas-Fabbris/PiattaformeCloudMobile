// lib/services/api_service.dart


import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/talk_model.dart';

import '../models/exercise_model.dart';

import 'cognito_service.dart';


class ApiService {

  // Un solo URL di base per tutta l'app, che punta alla tua API consolidata

  static const String _baseUrl = 'https://codqpgmjda.execute-api.us-east-1.amazonaws.com/default'; 


  final CognitoService _cognitoService = CognitoService();


  Future<Map<String, String>> _getHeaders() async {

    final token = await _cognitoService.getLatestAuthToken();

    if (token == null) {

      throw Exception('User not authenticated. Token is null.');

    }

    return {'Content-Type': 'application/json', 'Authorization': token};

  }


  /// Metodo per ottenere i talk della Homepage, filtrati per TAG

  Future<List<Talk>> getTalksByTag(String tag) async {

    final headers = await _getHeaders();

    

    // CORREZIONE: Usiamo un percorso chiaro e specifico

    final response = await http.post(

      Uri.parse('$_baseUrl/Get_Talks_By_ID'), 

      headers: headers,

      body: json.encode({'tag': tag}),

    );


    if (response.statusCode == 200) {

      final List<dynamic> talksJson = json.decode(response.body);

      return talksJson.map((json) => Talk.fromJson(json)).toList();

    } else {

      throw Exception('Failed to load talks by tag: ${response.body}');

    }

  }


  /// Metodo per la Ricerca per TITOLO

  Future<List<Talk>> getTalksByTitle(String title) async {

    final headers = await _getHeaders();

    

    // Usa il percorso specifico per la ricerca per titolo

    final response = await http.post(

      Uri.parse('$_baseUrl/Get_Talks_By_Title'), 

      headers: headers,

      body: json.encode({'title': title}),

    );


    if (response.statusCode == 200) {

      final List<dynamic> talksJson = json.decode(response.body);

      return talksJson.map((json) => Talk.fromJson(json)).toList();

    } else {

      throw Exception('Failed to load talks by title: ${response.body}');

    }

  }


  /// Metodo per gli ESERCIZI

  Future<List<Exercise>> getOrGenerateExercises(String talkId) async {
    final exercisesApiUrl = 'https://codqpgmjda.execute-api.us-east-1.amazonaws.com/default/Generate_Exercises_TedxLanguage';
    
    print("--- INIZIO CHIAMATA API ESERCIZI ---");
    print("URL Chiamato: $exercisesApiUrl");
    print("ID Inviato: $talkId");

    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse(exercisesApiUrl),
        headers: headers,
        body: json.encode({'talk_id': talkId}),
      );

      // --- STAMPIAMO LA RISPOSTA ESATTA DAL SERVER ---
      print("--- RISPOSTA RICEVUTA DAL SERVER ---");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("------------------------------------");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> exercisesJson = responseData['exercises'];
        return exercisesJson.map((json) => Exercise.fromJson(json)).toList();
      } else {
        // Lanciamo un errore che include lo status code per chiarezza
        throw Exception('Failed to load exercises. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("--- ERRORE DURANTE LA CHIAMATA API ---");
      print(e.toString());
      print("------------------------------------");
      rethrow; // Rilancia l'eccezione per farla vedere nella UI
    }
  }


  /// Metodo per i video "WATCH NEXT"

  Future<List<Talk>> getWatchNext(String talkId) async {

    // Usa il percorso specifico per i video consigliati

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