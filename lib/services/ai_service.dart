import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  static const _model = 'claude-haiku-4-5-20251001';
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';

  /// Supprime les balises HTML d'un texte
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  Future<String> summarizeArticle({
    required String title,
    required String? content,
    required String? snippet,
  }) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('Clé API Anthropic manquante dans le fichier .env');
    }

   
    final rawText = content ?? snippet ?? '';
    final cleanText = _stripHtml(rawText);


    final truncated = cleanText.length > 3000
        ? '${cleanText.substring(0, 3000)}...'
        : cleanText;

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 350,
        'messages': [
          {
            'role': 'user',
            'content': '''Résume cet article technique en 3 à 5 phrases claires en français, accessibles à un développeur. Sois concis et va à l\'essentiel.

Titre : $title

Contenu : $truncated

Donne uniquement le résumé, sans introduction du style "Cet article parle de..." ni conclusion.''',
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['content'][0]['text'] as String;
    } else if (response.statusCode == 429) {
      throw Exception('Limite de requêtes atteinte. Réessaie dans quelques secondes.');
    } else if (response.statusCode == 401) {
      throw Exception('Clé API invalide. Vérifie ton fichier .env.');
    } else {
      final body = utf8.decode(response.bodyBytes);
      throw Exception('Erreur API (${response.statusCode}) : $body');
    }
  }
}
