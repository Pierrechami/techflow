import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../services/database_service.dart';

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

  /// Tous les tags uniques des articles (triés)
  List<String> get _allTags {
    final set = <String>{};
    for (final a in _articles) {
      set.addAll(a.tags);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Articles filtrés par les tags sélectionnés (vide = tout afficher)
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

  bool get _hasCurrentArticle =>
      _filteredArticles.isNotEmpty &&
      _topCardIndex != null &&
      _topCardIndex! < _filteredArticles.length;

  Article? get _currentArticle =>
      _hasCurrentArticle ? _filteredArticles[_topCardIndex!] : null;

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

  Widget _buildFavoritesTab() {
    final iconColor = _isDarkMode ? Colors.grey[500]! : Colors.grey[400]!;
    final textColor = _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: iconColor),
          const SizedBox(height: 16),
          Text(
            'Vos articles favoris apparaîtront ici',
            style: TextStyle(fontSize: 16, color: textColor),
            textAlign: TextAlign.center,
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
          Row(
            children: [
              const Spacer(),
              _buildFilterButton(),
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
                            allowedSwipeDirection: const AllowedSwipeDirection.only(
                              left: true,
                              right: true,
                            ),
                            maxAngle: 12,
                            threshold: 50,
                            scale: 0.92,
                            padding: EdgeInsets.zero,
                            duration: const Duration(milliseconds: 250),
                            isLoop: false,
                            numberOfCardsDisplayed: filtered.length.clamp(1, 3),
                            onSwipe: _onSwipe,
                            onEnd: _onEnd,
                            cardBuilder: (context, index, horizontalPercent, verticalPercent) {
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

  Widget _buildArticleCard(Article article) {
    final snippet = article.snippet ?? 'Pas de description disponible.';
    final dateStr = DateFormat('dd MMM yyyy', 'fr_FR').format(article.publishedAt);

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
            // Ligne : date de publication + bouton dark mode
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                    onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
                    icon: Icon(
                      _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 22,
                      color: badgeTextColor,
                    ),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            // Titre
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
            // Snippet scrollable avec tabulation avant le premier mot
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  snippet,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.55,
                    color: snippetColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Auteur à gauche ; Tags + Source à droite
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'By ${article.author ?? 'Unknown'}',
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
                              label: Text(tag, style: const TextStyle(fontSize: 13)),
                              backgroundColor: Colors.teal.withOpacity(_isDarkMode ? 0.25 : 0.12),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          onTap: () => _swiperController.swipe(CardSwiperDirection.left),
        ),
        const SizedBox(width: 40),
        _buildCircularActionButton(
          icon: Icons.check_rounded,
          color: _SwipeColors.likeHalo,
          onTap: () => _swiperController.swipe(CardSwiperDirection.right),
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
              spreadRadius: 0,
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
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.06),
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
                onTap: () => setState(() => _selectedTab = 1),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    color: _isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
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
                  : (_isDarkMode ? Colors.grey[400]! : Colors.grey[700]!),
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
    // TODO: si direction == right, enregistrer l'article en favori
    return true;
  }

  void _onEnd() {
    setState(() {
      _topCardIndex = null;
    });
  }

  void _showFilterSheet(BuildContext context) {
    final isDark = _isDarkMode;
    final bgColor = isDark ? _SwipeColors.cardBgDark : Colors.white;
    final surfaceColor = isDark ? _SwipeColors.headerBadgeBgDark : Colors.grey[100]!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterSheetContent(
        allTags: _allTags,
        initialSelected: Set<String>.from(_selectedFilterTags),
        backgroundColor: bgColor,
        surfaceColor: surfaceColor,
        isDarkMode: isDark,
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

/// Contenu du bottom sheet de filtre par tags
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
    final hintColor = widget.isDarkMode ? Colors.grey[500]! : Colors.grey[600]!;
    final borderColor = widget.isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  prefixIcon: Icon(Icons.search_rounded, color: hintColor),
                  filled: true,
                  fillColor: widget.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                          style: TextStyle(color: hintColor, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                horizontal: 16,
                                vertical: 12,
                              ),
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
                    onPressed: () {
                      setState(() => _selected.clear());
                    },
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
