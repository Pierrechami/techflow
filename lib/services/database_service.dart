import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  Future<List<Article>> fetchArticles() async {
    final response = await _supabase
        .from('articles')
        .select()
        .order('published_at', ascending: false)
        .limit(20);

    return (response as List).map((json) => Article.fromJson(json)).toList();
  }

  Future<void> saveLike(String articleUrl) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('likes').upsert(
      {
        'user_id': userId,
        'article_url': articleUrl,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,article_url',
      ignoreDuplicates: true,
    );
  }

  Future<void> removeLike(String articleUrl) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('likes')
        .delete()
        .eq('user_id', userId)
        .eq('article_url', articleUrl);
  }

  Future<List<Article>> fetchLikedArticles() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final likes = await _supabase
        .from('likes')
        .select('article_url')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if ((likes as List).isEmpty) return [];

    final urls = likes.map((l) => l['article_url'] as String).toList();

    final articles = await _supabase
        .from('articles')
        .select()
        .inFilter('url', urls);

    // Conserver l'ordre des likes (du plus récent au plus ancien)
    final articlesMap = {
      for (final json in articles as List) json['url'] as String: Article.fromJson(json)
    };
    return urls
        .where(articlesMap.containsKey)
        .map((url) => articlesMap[url]!)
        .toList();
  }
}