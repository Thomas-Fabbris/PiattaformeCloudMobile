// lib/services/cognito_service.dart

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/foundation.dart';

class CognitoService {
  static const String _userPoolId = 'us-east-1_23phXQhI9';
  static const String _clientId = '4of2tduh3vd88sappcjj7foh0g';

  static final CognitoUserPool _userPool = CognitoUserPool(
    _userPoolId,
    _clientId,
  );
  static final CognitoService _instance = CognitoService._internal();
  factory CognitoService() => _instance;
  CognitoService._internal();

  CognitoUserSession? _session;
  CognitoUser? _cognitoUser;

  /// Inizializza il servizio controllando se esiste una sessione valida.
  /// Restituisce 'true' se l'utente ha una sessione valida, altrimenti 'false'.
  Future<bool> initialize() async {
    final cognitoUser = await _userPool.getCurrentUser();
    if (cognitoUser == null) return false;

    try {
      _session = await cognitoUser.getSession();
      if (_session?.isValid() ?? false) {
        _cognitoUser = cognitoUser;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Errore durante l\'inizializzazione della sessione: $e');
      return false;
    }
  }

  /// Esegue il login di un utente.
  /// Restituisce 'true' in caso di successo, 'false' in caso di fallimento.
  Future<bool> signIn(String email, String password) async {
    _cognitoUser = CognitoUser(email, _userPool);
    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );

    try {
      _session = await _cognitoUser?.authenticateUser(authDetails);
      return _session?.isValid() ?? false;
    } on CognitoClientException catch (e) {
      debugPrint('Errore Cognito durante il login: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Errore sconosciuto durante il login: $e');
      return false;
    }
  }

  /// Esegue il logout dell'utente.
  /// Restituisce 'true' in caso di successo, 'false' in caso di fallimento.
  Future<bool> signOut() async {
    try {
      await _cognitoUser?.signOut();
      _session = null;
      _cognitoUser = null;
      return true;
    } catch (e) {
      debugPrint('Errore durante il logout: $e');
      return false;
    }
  }

  /// Recupera un attributo specifico dell'utente loggato.
  Future<String?> _getSpecificAttribute(String attributeName) async {
    if (_cognitoUser == null) {
      if (!await initialize()) return null;
    }

    try {
      final attributes = await _cognitoUser?.getUserAttributes();
      if (attributes == null) return null;

      for (final attribute in attributes) {
        if (attribute.getName()?.toLowerCase() == attributeName.toLowerCase()) {
          return attribute.getValue();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Errore nel recupero dell\'attributo $attributeName: $e');
      return null;
    }
  }

  /// Recupera l'email dell'utente corrente.
  Future<String?> getCurrentUserEmail() async {
    return await _getSpecificAttribute('email');
  }

  /// Recupera il nome ('name') dell'utente corrente.
  Future<String?> getCurrentUserName() async {
    return await _getSpecificAttribute('name');
  }

  /// Restituisce l'ID token della sessione corrente, o null se la sessione non è valida.
  Future<String?> getLatestAuthToken() async {
    if (_session == null || !(_session?.isValid() ?? false)) {
      if (!await initialize()) {
        return null;
      }
    }
    return _session?.getIdToken().getJwtToken();
  }
}
