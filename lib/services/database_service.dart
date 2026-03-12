import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  Future<List<Article>> fetchArticles() async {
    final response = await _supabase
        .from('articles')
        .select()
        .order('published_at', ascending: false)
        .limit(20); // On en prend 20 pour commencer

    return (response as List).map((json) => Article.fromJson(json)).toList();
  }
}