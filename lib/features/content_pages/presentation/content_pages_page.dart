import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/widgets/loading_state.dart';
import '../data/content_pages_repository.dart';

class ContentPagesPage extends StatefulWidget {
  const ContentPagesPage({super.key});

  @override
  State<ContentPagesPage> createState() => _ContentPagesPageState();
}

class _ContentPagesPageState extends State<ContentPagesPage> {
  late final ContentPagesRepository repository;

  List<dynamic> pages = [];
  bool loading = true;
  String? error;

  static const Color primary = Color(0xFF2563EB);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    repository = ContentPagesRepository(ApiClient(authStorage: AuthStorage()));
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await repository.fetchContentPages();

      if (!mounted) return;

      setState(() {
        pages = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        error = 'Failed to load content pages';
        loading = false;
      });
    }
  }

  Map<String, dynamic>? _findPage(String slug) {
    for (final page in pages) {
      final map = Map<String, dynamic>.from(page as Map);
      if (map['slug'] == slug) return map;
    }
    return null;
  }

  Future<void> _openEditor({
    required String slug,
    required String fallbackTitle,
  }) async {
    final existing = _findPage(slug);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ContentPageDialog(
        slug: slug,
        fallbackTitle: fallbackTitle,
        existing: existing,
        repository: repository,
      ),
    );

    if (saved == true) {
      load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingState();

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final aboutUs = _findPage('about-us');
    final songs = _findPage('temple-songs-prayers');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content Pages',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Manage native app content for About Us and Temple Songs.',
                      style: TextStyle(color: textMuted),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ContentCard(
            title: 'About Us',
            subtitle:
                aboutUs?['subtitle']?.toString() ??
                'Introduce Bhakti Steps and your mission.',
            slug: 'about-us',
            icon: Icons.info_outline_rounded,
            color: primary,
            isActive: aboutUs?['isActive'] == true,
            updatedAt: aboutUs?['updatedAt']?.toString(),
            onEdit: () => _openEditor(
              slug: 'about-us',
              fallbackTitle: 'About Bhakti Steps',
            ),
          ),
          const SizedBox(height: 16),
          _ContentCard(
            title: 'Temple Songs & Prayers',
            subtitle:
                songs?['subtitle']?.toString() ??
                'Manage songs, prayers, and devotional text.',
            slug: 'temple-songs-prayers',
            icon: Icons.music_note_rounded,
            color: const Color(0xFF7C3AED),
            isActive: songs?['isActive'] == true,
            updatedAt: songs?['updatedAt']?.toString(),
            onEdit: () => _openEditor(
              slug: 'temple-songs-prayers',
              fallbackTitle: 'Temple Songs & Prayers',
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String slug;
  final IconData icon;
  final Color color;
  final bool isActive;
  final String? updatedAt;
  final VoidCallback onEdit;

  const _ContentCard({
    required this.title,
    required this.subtitle,
    required this.slug,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.updatedAt,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ContentPagesPageState.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ContentPagesPageState.textDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _ContentPagesPageState.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniPill(label: slug, color: color),
                    _MiniPill(
                      label: isActive ? 'Active' : 'Inactive',
                      color: isActive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ContentPageDialog extends StatefulWidget {
  final String slug;
  final String fallbackTitle;
  final Map<String, dynamic>? existing;
  final ContentPagesRepository repository;

  const _ContentPageDialog({
    required this.slug,
    required this.fallbackTitle,
    required this.existing,
    required this.repository,
  });

  @override
  State<_ContentPageDialog> createState() => _ContentPageDialogState();
}

class _ContentPageDialogState extends State<_ContentPageDialog> {
  late final TextEditingController titleController;
  late final TextEditingController subtitleController;
  late final TextEditingController heroImageController;
  late final TextEditingController bodyController;

  bool isActive = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.existing?['title']?.toString() ?? widget.fallbackTitle,
    );
    subtitleController = TextEditingController(
      text: widget.existing?['subtitle']?.toString() ?? '',
    );
    heroImageController = TextEditingController(
      text: widget.existing?['heroImageUrl']?.toString() ?? '',
    );
    bodyController = TextEditingController(
      text: widget.existing?['body']?.toString() ?? '',
    );
    isActive = widget.existing?['isActive'] == false ? false : true;
  }

  @override
  void dispose() {
    titleController.dispose();
    subtitleController.dispose();
    heroImageController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (titleController.text.trim().isEmpty ||
        bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and body are required')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await widget.repository.saveContentPage({
        'slug': widget.slug,
        'title': titleController.text.trim(),
        'subtitle': subtitleController.text.trim(),
        'heroImageUrl': heroImageController.text.trim(),
        'body': bodyController.text.trim(),
        'isActive': isActive,
      });

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save content')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.fallbackTitle}'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: _decoration('Title'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: subtitleController,
                decoration: _decoration('Subtitle'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: heroImageController,
                decoration: _decoration('Hero Image URL optional'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bodyController,
                minLines: 14,
                maxLines: 22,
                decoration: _decoration(
                  widget.slug == 'temple-songs-prayers'
                      ? 'Body. Use # Heading for each song/prayer section.'
                      : 'Body',
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: (value) => setState(() => isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: saving ? null : save,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
