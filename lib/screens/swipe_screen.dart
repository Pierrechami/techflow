import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../services/database_service.dart';
import 'article_detail_page.dart';
import 'auth/login_page.dart';

/// Couleurs light / dark
class _SwipeColors {
  static const backgroundLight = Color(0xFFF5F5F5);
  static const backgroundDark = Color(0xFF121212);
  static const headerBadgeBgLight = Color(0xFFE8E8E8);
  static const headerBadgeBgDark = Color(0xFF3A3A3A);
  static const cardBgLight = Colors.white;
  static const cardBgDark = Color(0xFF1E1E1E);
  static const likeHalo = Color(0xFF4CAF50);
  static const dislikeHalo = Color(0xFFE53935);
  static const pillActiveStart = Color(0xFFE53935);
  static const pillActiveEnd = Color(0xFFF06292);
  static const textSecondaryLight = Color(0xFF757575);
  static const textSecondaryDark = Color(0xFFB0B0B0);
}

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final DatabaseService _dbService = DatabaseService();
  final CardSwiperController _swiperController = CardSwiperController();

  List<Article> _articles = [];
  bool _isLoading = true;
  int? _topCardIndex = 0;
  int _selectedTab = 0;
  bool _isDarkMode = false;
  final Set<String> _selectedFilterTags = {};
  List<Article> _likedArticles = [];
  bool _isLoadingFavorites = false;

  List<String> get _allTags {
    final set = <String>{};
    for (final a in _articles) {
      set.addAll(a.tags);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Article> get _filteredArticles {
    if (_selectedFilterTags.isEmpty) return _articles;
    return _articles
        .where((a) => a.tags.any((t) => _selectedFilterTags.contains(t)))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    try {
      final data = await _dbService.fetchArticles();
      setState(() {
        _articles = data;
        _topCardIndex = data.isEmpty ? null : 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur Supabase: $e');
      setState(() {
        _isLoading = false;
        _topCardIndex = null;
      });
    }
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Déconnexion ────────────────────────────────────────────────────────────
  Future<void> _handleLogout(BuildContext context) async {
    // 1. Boîte de dialogue de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Se déconnecter ?',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        content: Text(
          'Tu devras te reconnecter pour accéder à TechFlow.',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          // Bouton Annuler
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
              side: BorderSide(
                color: _isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
            ),
          ),
          // Bouton Se déconnecter
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _SwipeColors.dislikeHalo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 2. Déconnexion Supabase
    try {
      await Supabase.instance.client.auth.signOut();

      // 3. AuthGate écoute onAuthStateChange et redirige automatiquement.
      //    Si pour une raison quelconque la redirection auto ne se déclenche
      //    pas (ex: SwipeScreen monté hors du tree AuthGate), on force
      //    la navigation en nettoyant toute la pile.
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const LoginPage(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ),
          (route) => false, // supprime toute la pile
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Erreur lors de la déconnexion.',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: _SwipeColors.dislikeHalo,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  bool get _hasCurrentArticle =>
      _filteredArticles.isNotEmpty &&
      _topCardIndex != null &&
      _topCardIndex! < _filteredArticles.length;

  Color get _backgroundColor =>
      _isDarkMode ? _SwipeColors.backgroundDark : _SwipeColors.backgroundLight;
  Color get _cardBg =>
      _isDarkMode ? _SwipeColors.cardBgDark : _SwipeColors.cardBgLight;
  Color get _headerBadgeBg =>
      _isDarkMode ? _SwipeColors.headerBadgeBgDark : _SwipeColors.headerBadgeBgLight;
  Color get _textSecondary =>
      _isDarkMode ? _SwipeColors.textSecondaryDark : _SwipeColors.textSecondaryLight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: _selectedTab == 1
            ? _buildFavoritesTab()
            : _buildSwipeTab(),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Future<void> _loadLikedArticles() async {
    setState(() => _isLoadingFavorites = true);
    try {
      final data = await _dbService.fetchLikedArticles();
      setState(() => _likedArticles = data);
    } catch (e) {
      debugPrint('Erreur favoris: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFavorites = false);
    }
  }

  Future<void> _removeLike(Article article) async {
    await _dbService.removeLike(article.url);
    setState(() => _likedArticles.removeWhere((a) => a.url == article.url));
  }

  Widget _buildFavoritesTab() {
    final iconColor = _isDarkMode ? Colors.grey[500]! : Colors.grey[400]!;
    final textColor = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final titleColor = _isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              _buildLogoutButton(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Mes favoris',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(width: 10),
              if (_likedArticles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _SwipeColors.pillActiveStart,
                        _SwipeColors.pillActiveEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_likedArticles.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingFavorites
                ? Center(
                    child: CircularProgressIndicator(
                      color: _isDarkMode
                          ? Colors.grey[400]
                          : _SwipeColors.pillActiveStart,
                    ),
                  )
                : _likedArticles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border, size: 64, color: iconColor),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun article liké pour le moment.',
                              style: TextStyle(fontSize: 16, color: textColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Swipe à droite pour en sauvegarder !',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _likedArticles.length,
                        itemBuilder: (context, index) =>
                            _buildFavoriteCard(_likedArticles[index]),
                      ),
          ),
        ],
      ),
    );
  }

  void _showAiSummary(BuildContext context, Article article) {
    final bgColor = _isDarkMode ? _SwipeColors.cardBgDark : Colors.white;
    final titleColor = _isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    final textColor = _isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF9C95FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Résumé IA',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    height: 1.3,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  child: Text(
                    article.snippet ?? 'Aucun résumé disponible pour cet article.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.65,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF8B80FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openArticle(article.url);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text(
                        'Lire l\'article complet',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Article article) {
    final dateStr =
        DateFormat('dd MMM yyyy', 'fr_FR').format(article.publishedAt);
    final titleColor = _isDarkMode ? Colors.white : Colors.black87;
    final snippetColor = _isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;
    final tagBg = Colors.teal.withOpacity(_isDarkMode ? 0.25 : 0.12);
    final tagFg = _isDarkMode ? Colors.teal.shade200 : Colors.teal.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Titre + boutons (Lire | IA | ❤) ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              // Bouton Lire → ouvre la page détail
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, animation, __) => ArticleDetailPage(
                      article: article,
                      isDarkMode: _isDarkMode,
                    ),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.article_rounded,
                    color: _isDarkMode
                        ? Colors.teal.shade300
                        : Colors.teal.shade700,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton Résumer IA
              GestureDetector(
                onTap: () => _showAiSummary(context, article),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF6C63FF),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton unlike
              GestureDetector(
                onTap: () => _removeLike(article),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _SwipeColors.dislikeHalo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: _SwipeColors.dislikeHalo,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          // ── Snippet ───────────────────────────────────────────────────────
          if (article.snippet != null) ...[
            const SizedBox(height: 8),
            Text(
              article.snippet!,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: snippetColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // ── Date + tags ───────────────────────────────────────────────────
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: _textSecondary),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: article.tags
                      .take(3)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(fontSize: 11, color: tagFg),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeTab() {
    final textColor = _isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final iconColor = _isDarkMode ? Colors.grey[500]! : Colors.grey[400]!;
    final filtered = _filteredArticles;
    final hasCards = filtered.isNotEmpty &&
        _topCardIndex != null &&
        _topCardIndex! < filtered.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // ── Header : filtre + logout ──────────────────────────────────────
          Row(
            children: [
              const Spacer(),
              _buildFilterButton(),
              const SizedBox(width: 8),           // espacement entre les deux
              _buildLogoutButton(),               // ← nouveau bouton
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: _isDarkMode ? Colors.grey[400] : null,
                    ),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedFilterTags.isEmpty
                                  ? "Plus d'articles pour le moment !"
                                  : "Aucun article ne correspond aux tags sélectionnés.",
                              style: TextStyle(fontSize: 16, color: textColor),
                              textAlign: TextAlign.center,
                            ),
                            if (_selectedFilterTags.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => _showFilterSheet(context),
                                child: const Text('Modifier les filtres'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : (_topCardIndex == null || _topCardIndex! >= filtered.length)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.deck, size: 64, color: iconColor),
                                const SizedBox(height: 16),
                                Text(
                                  "Plus de cartes à swiper.",
                                  style: TextStyle(fontSize: 16, color: textColor),
                                ),
                              ],
                            ),
                          )
                        : CardSwiper(
                            controller: _swiperController,
                            cardsCount: filtered.length,
                            initialIndex: _topCardIndex!,
                            allowedSwipeDirection:
                                const AllowedSwipeDirection.only(
                              left: true,
                              right: true,
                            ),
                            maxAngle: 12,
                            threshold: 50,
                            scale: 0.92,
                            padding: EdgeInsets.zero,
                            duration: const Duration(milliseconds: 250),
                            isLoop: false,
                            numberOfCardsDisplayed:
                                filtered.length.clamp(1, 3),
                            onSwipe: _onSwipe,
                            onEnd: _onEnd,
                            cardBuilder: (context, index, hPct, vPct) {
                              final article = filtered[index];
                              return _buildArticleCard(article);
                            },
                          ),
          ),
          if (hasCards) ...[
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }

  // ── Bouton filtre (inchangé) ───────────────────────────────────────────────
  Widget _buildFilterButton() {
    final badgeTextColor = _isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;
    final filterBg = _isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100]!;
    return Material(
      color: filterBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showFilterSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 20, color: badgeTextColor),
              const SizedBox(width: 6),
              Text(
                'Filtre',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isDarkMode ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bouton déconnexion — même style que le filtre, icône seule ────────────
  Widget _buildLogoutButton() {
    final iconColor = _isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;
    final bgColor = _isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100]!;
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _handleLogout(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(Icons.logout_rounded, size: 20, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildArticleCard(Article article) {
    final dateStr =
        DateFormat('dd MMM yyyy', 'fr_FR').format(article.publishedAt);

    final titleColor = _isDarkMode ? Colors.white : Colors.black87;
    final snippetColor = _isDarkMode ? Colors.grey[300]! : Colors.grey[800]!;
    final badgeTextColor = _isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;

    return GestureDetector(
      onTap: () => _openArticle(article.url),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _headerBadgeBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Published: $dateStr',
                    style: TextStyle(
                      fontSize: 14,
                      color: badgeTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Material(
                  color: _headerBadgeBg,
                  borderRadius: BorderRadius.circular(16),
                  child: IconButton(
                    onPressed: () =>
                        setState(() => _isDarkMode = !_isDarkMode),
                    icon: Icon(
                      _isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 22,
                      color: badgeTextColor,
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(
                        minWidth: 40, minHeight: 40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              article.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: titleColor,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  article.snippet ?? 'Pas de description disponible.',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.55,
                    color: snippetColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'By ${article.author}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.end,
                      runAlignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 6,
                      children: article.tags
                          .take(5)
                          .map(
                            (tag) => Chip(
                              label: Text(tag,
                                  style: const TextStyle(fontSize: 13)),
                              backgroundColor: Colors.teal.withOpacity(
                                  _isDarkMode ? 0.25 : 0.12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Source : ${article.sourceName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircularActionButton(
          icon: Icons.close_rounded,
          color: _SwipeColors.dislikeHalo,
          onTap: () =>
              _swiperController.swipe(CardSwiperDirection.left),
        ),
        const SizedBox(width: 40),
        _buildCircularActionButton(
          icon: Icons.check_rounded,
          color: _SwipeColors.likeHalo,
          onTap: () =>
              _swiperController.swipe(CardSwiperDirection.right),
        ),
      ],
    );
  }

  Widget _buildCircularActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 12,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 36),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(_isDarkMode ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPillTab(
                label: 'Articles à swiper',
                isActive: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              const SizedBox(width: 12),
              _buildPillTab(
                label: 'Mes favoris',
                isActive: _selectedTab == 1,
                onTap: () {
                  setState(() => _selectedTab = 1);
                  _loadLikedArticles();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isActive
                ? const LinearGradient(
                    colors: [
                      _SwipeColors.pillActiveStart,
                      _SwipeColors.pillActiveEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: isActive
                ? null
                : Border.all(
                    color: _isDarkMode
                        ? Colors.grey[600]!
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? Colors.white
                  : (_isDarkMode
                      ? Colors.grey[400]!
                      : Colors.grey[700]!),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    setState(() {
      _topCardIndex = currentIndex;
    });
    if (direction == CardSwiperDirection.right) {
      final article = _filteredArticles[previousIndex];
      await _dbService.saveLike(article.url);
    }
    return true;
  }

  void _onEnd() {
    setState(() {
      _topCardIndex = null;
    });
  }

  void _showFilterSheet(BuildContext context) {
    final bgColor =
        _isDarkMode ? _SwipeColors.cardBgDark : Colors.white;
    final surfaceColor = _isDarkMode
        ? _SwipeColors.headerBadgeBgDark
        : Colors.grey[100]!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterSheetContent(
        allTags: _allTags,
        initialSelected: Set<String>.from(_selectedFilterTags),
        backgroundColor: bgColor,
        surfaceColor: surfaceColor,
        isDarkMode: _isDarkMode,
        onApply: (selected) {
          setState(() {
            _selectedFilterTags
              ..clear()
              ..addAll(selected);
            _topCardIndex = _filteredArticles.isEmpty ? null : 0;
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

// ─── Bottom sheet de filtre (inchangé) ────────────────────────────────────────
class _FilterSheetContent extends StatefulWidget {
  const _FilterSheetContent({
    required this.allTags,
    required this.initialSelected,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.isDarkMode,
    required this.onApply,
  });

  final List<String> allTags;
  final Set<String> initialSelected;
  final Color backgroundColor;
  final Color surfaceColor;
  final bool isDarkMode;
  final void Function(Set<String> selected) onApply;

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  late Set<String> _selected;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<String> get _filteredTags {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.allTags;
    return widget.allTags.where((t) => t.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final hintColor =
        widget.isDarkMode ? Colors.grey[500]! : Colors.grey[600]!;
    final borderColor =
        widget.isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Filtrer par tags',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher un tag...',
                  hintStyle: TextStyle(color: hintColor),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: hintColor),
                  filled: true,
                  fillColor: widget.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredTags.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Aucun tag ne correspond à la recherche.',
                          style:
                              TextStyle(color: hintColor, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: _filteredTags.length,
                      itemBuilder: (context, index) {
                        final tag = _filteredTags[index];
                        final isSelected = _selected.contains(tag);
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(tag);
                                } else {
                                  _selected.add(tag);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                    color: isSelected
                                        ? _SwipeColors.pillActiveStart
                                        : hintColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _selected.clear()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: hintColor,
                      side: BorderSide(color: borderColor),
                    ),
                    child: const Text('Réinitialiser'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => widget.onApply(_selected),
                      style: FilledButton.styleFrom(
                        backgroundColor: _SwipeColors.pillActiveStart,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}