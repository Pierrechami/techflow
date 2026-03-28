import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';

class ArticleDetailPage extends StatelessWidget {
  final Article article;
  final bool isDarkMode;

  const ArticleDetailPage({
    super.key,
    required this.article,
    required this.isDarkMode,
  });

  static const _accentColor = Color(0xFF6C63FF);

  Color get _bg =>
      isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
  Color get _cardBg =>
      isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _titleColor => isDarkMode ? Colors.white : Colors.black87;
  Color get _textSecondary =>
      isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF757575);
  Color get _badgeBg =>
      isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFE8E8E8);

  Future<void> _openUrl() async {
    final uri = Uri.parse(article.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd MMMM yyyy', 'fr_FR').format(article.publishedAt);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildMeta(dateStr),
                    const SizedBox(height: 20),
                    Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: _titleColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildAuthor(),
                    const SizedBox(height: 20),
                    if (article.tags.isNotEmpty) ...[
                      _buildTags(),
                      const SizedBox(height: 24),
                    ],
                    Divider(color: _badgeBg),
                    const SizedBox(height: 20),
                    _buildContent(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildCTA(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Material(
            color: _badgeBg,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: _titleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Article',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _titleColor,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFF06292)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'TechFlow',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(String dateStr) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _badge(
          icon: Icons.source_rounded,
          label: article.sourceName,
        ),
        _badge(
          icon: Icons.calendar_today_rounded,
          label: dateStr,
        ),
      ],
    );
  }

  Widget _badge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _badgeBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthor() {
    final initial =
        (article.author?.isNotEmpty == true ? article.author! : 'A')
            .substring(0, 1)
            .toUpperCase();
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _accentColor.withOpacity(0.15),
          child: Text(
            initial,
            style: const TextStyle(
              color: _accentColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.author ?? 'Auteur inconnu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _titleColor,
              ),
            ),
            Text(
              'Auteur',
              style: TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: article.tags
          .map(
            (tag) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.teal.withOpacity(isDarkMode ? 0.4 : 0.2),
                ),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.teal.shade200
                      : Colors.teal.shade700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildContent() {
    final content = article.content ?? '<p>Aucun contenu disponible pour cet article.</p>';
    final textColor = isDarkMode ? const Color(0xFFD0D0D0) : const Color(0xFF333333);
    final codeBackground = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);
    final codeBorder = isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFDDDDDD);
    final linkColor = isDarkMode ? const Color(0xFF9C95FF) : const Color(0xFF6C63FF);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: constraints.maxWidth,
              child: Html(
                data: content,
                onLinkTap: (url, _, __) async {
                  if (url == null) return;
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                style: {
                  'body': Style(
                    margin: Margins.all(22),
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(16),
                    lineHeight: LineHeight(1.75),
                    color: textColor,
                  ),
                  'h1': Style(
                    fontSize: FontSize(22),
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    margin: Margins.only(top: 24, bottom: 12),
                  ),
                  'h2': Style(
                    fontSize: FontSize(19),
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    margin: Margins.only(top: 20, bottom: 10),
                  ),
                  'h3': Style(
                    fontSize: FontSize(17),
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    margin: Margins.only(top: 16, bottom: 8),
                  ),
                  'p': Style(
                    margin: Margins.only(bottom: 14),
                    color: textColor,
                  ),
                  'a': Style(
                    color: linkColor,
                    textDecoration: TextDecoration.underline,
                    textDecorationColor: linkColor,
                  ),
                  'code': Style(
                    backgroundColor: codeBackground,
                    color: isDarkMode
                        ? const Color(0xFFFF7B9C)
                        : const Color(0xFFD6336C),
                    fontFamily: 'monospace',
                    fontSize: FontSize(14),
                    padding: HtmlPaddings.symmetric(horizontal: 5, vertical: 2),
                  ),
                  'pre': Style(
                    backgroundColor: codeBackground,
                    padding: HtmlPaddings.all(16),
                    margin: Margins.symmetric(vertical: 12),
                    display: Display.block,
                  ),
                  'blockquote': Style(
                    border: Border(
                      left: BorderSide(
                        color: const Color(0xFF6C63FF),
                        width: 3,
                      ),
                    ),
                    padding: HtmlPaddings.only(left: 16),
                    margin: Margins.symmetric(vertical: 12),
                    color: _textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  'ul': Style(margin: Margins.only(bottom: 14)),
                  'ol': Style(margin: Margins.only(bottom: 14)),
                  'li': Style(
                    margin: Margins.only(bottom: 6),
                    color: textColor,
                  ),
                  'img': Style(
                    width: Width(constraints.maxWidth - 44),
                    height: Height.auto(),
                  ),
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCTA() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF8B80FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _openUrl,
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            label: Text(
              'Lire sur ${article.sourceName}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
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
    );
  }
}
