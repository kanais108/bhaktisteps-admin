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

  List<Map<String, dynamic>> pages = [];
  bool loading = true;
  String? error;

  static const Color primary = Color(0xFF2563EB);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE5E7EB);
  static const Color purple = Color(0xFF7C3AED);
  static const Color accent = Color(0xFFF59E0B);
  static const Color green = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);

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
        pages = result
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
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

  Map<String, dynamic>? _findBySlug(String slug) {
    for (final page in pages) {
      if (page['slug']?.toString() == slug) return page;
    }
    return null;
  }

  List<Map<String, dynamic>> _childrenOf(String parentSlug) {
    final children = pages
        .where((page) => page['parentSlug']?.toString() == parentSlug)
        .toList();

    children.sort((a, b) {
      final aOrder = _asInt(a['sortOrder']);
      final bOrder = _asInt(b['sortOrder']);

      if (aOrder != bOrder) return aOrder.compareTo(bOrder);

      final aTitle = a['title']?.toString() ?? '';
      final bTitle = b['title']?.toString() ?? '';

      return aTitle.compareTo(bTitle);
    });

    return children;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _openEditor({
    required String slug,
    required String fallbackTitle,
    String? parentSlug,
    Map<String, dynamic>? existing,
    int? suggestedSortOrder,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ContentPageDialog(
        slug: slug,
        fallbackTitle: fallbackTitle,
        parentSlug: parentSlug,
        existing: existing,
        suggestedSortOrder: suggestedSortOrder,
        repository: repository,
      ),
    );

    if (saved == true) {
      await load();
    }
  }

  Future<void> _addPrayerSong() async {
    final children = _childrenOf('temple-songs-prayers');

    await _openEditor(
      slug: '',
      fallbackTitle: 'New Prayer / Song',
      parentSlug: 'temple-songs-prayers',
      suggestedSortOrder: children.length + 1,
    );
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

    final aboutUs = _findBySlug('about-us');
    final templeIndex = _findBySlug('temple-songs-prayers');
    final prayerSongs = _childrenOf('temple-songs-prayers');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
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
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Manage native app content for About Us and Temple Songs & Prayers.',
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
            sortOrder: _asInt(aboutUs?['sortOrder']),
            onEdit: () => _openEditor(
              slug: 'about-us',
              fallbackTitle: 'About Bhakti Steps',
              existing: aboutUs,
              suggestedSortOrder: 0,
            ),
          ),

          const SizedBox(height: 16),

          _ContentCard(
            title: 'Temple Songs & Prayers Index',
            subtitle:
                templeIndex?['subtitle']?.toString() ??
                'This is the landing page users see before selecting a prayer or song.',
            slug: 'temple-songs-prayers',
            icon: Icons.music_note_rounded,
            color: purple,
            isActive: templeIndex?['isActive'] == true,
            sortOrder: _asInt(templeIndex?['sortOrder']),
            onEdit: () => _openEditor(
              slug: 'temple-songs-prayers',
              fallbackTitle: 'Temple Songs & Prayers',
              existing: templeIndex,
              suggestedSortOrder: 0,
            ),
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.library_music_rounded,
                        color: accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prayer / Song Index',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add each prayer or song as a separate native app page.',
                            style: TextStyle(color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addPrayerSong,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Prayer / Song'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (prayerSongs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: accent.withOpacity(0.14)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.music_off_rounded, size: 44, color: accent),
                        SizedBox(height: 12),
                        Text(
                          'No prayers or songs yet',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Click “Add Prayer / Song” to create the first item in the native index.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textMuted),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final child in prayerSongs) ...[
                        _ChildContentRow(
                          page: child,
                          onEdit: () => _openEditor(
                            slug: child['slug']?.toString() ?? '',
                            fallbackTitle:
                                child['title']?.toString() ?? 'Prayer / Song',
                            parentSlug: 'temple-songs-prayers',
                            existing: child,
                            suggestedSortOrder: _asInt(child['sortOrder']),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
              ],
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
  final int sortOrder;
  final VoidCallback onEdit;

  const _ContentCard({
    required this.title,
    required this.subtitle,
    required this.slug,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.sortOrder,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
                    fontWeight: FontWeight.w900,
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
                          ? _ContentPagesPageState.green
                          : _ContentPagesPageState.danger,
                    ),
                    _MiniPill(
                      label: 'Order $sortOrder',
                      color: _ContentPagesPageState.textMuted,
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

class _ChildContentRow extends StatelessWidget {
  final Map<String, dynamic> page;
  final VoidCallback onEdit;

  const _ChildContentRow({required this.page, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final title = page['title']?.toString() ?? 'Untitled';
    final subtitle = page['subtitle']?.toString() ?? '';
    final slug = page['slug']?.toString() ?? '';
    final sortOrder = page['sortOrder']?.toString() ?? '0';
    final isActive = page['isActive'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ContentPagesPageState.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _ContentPagesPageState.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: _ContentPagesPageState.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$sortOrder. $title',
                  style: const TextStyle(
                    color: _ContentPagesPageState.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _ContentPagesPageState.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _MiniPill(
                      label: slug,
                      color: _ContentPagesPageState.purple,
                    ),
                    _MiniPill(
                      label: isActive ? 'Active' : 'Inactive',
                      color: isActive
                          ? _ContentPagesPageState.green
                          : _ContentPagesPageState.danger,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit'),
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
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ContentPageDialog extends StatefulWidget {
  final String slug;
  final String fallbackTitle;
  final String? parentSlug;
  final Map<String, dynamic>? existing;
  final int? suggestedSortOrder;
  final ContentPagesRepository repository;

  const _ContentPageDialog({
    required this.slug,
    required this.fallbackTitle,
    required this.parentSlug,
    required this.existing,
    required this.suggestedSortOrder,
    required this.repository,
  });

  @override
  State<_ContentPageDialog> createState() => _ContentPageDialogState();
}

class _ContentPageDialogState extends State<_ContentPageDialog> {
  late final TextEditingController slugController;
  late final TextEditingController titleController;
  late final TextEditingController subtitleController;
  late final TextEditingController heroImageController;
  late final TextEditingController sortOrderController;
  late final TextEditingController bodyController;

  bool isActive = true;
  bool saving = false;

  bool get isChild => widget.parentSlug != null;

  @override
  void initState() {
    super.initState();

    slugController = TextEditingController(
      text: widget.existing?['slug']?.toString() ?? widget.slug,
    );
    titleController = TextEditingController(
      text: widget.existing?['title']?.toString() ?? widget.fallbackTitle,
    );
    subtitleController = TextEditingController(
      text: widget.existing?['subtitle']?.toString() ?? '',
    );
    heroImageController = TextEditingController(
      text: widget.existing?['heroImageUrl']?.toString() ?? '',
    );
    sortOrderController = TextEditingController(
      text: (widget.existing?['sortOrder'] ?? widget.suggestedSortOrder ?? 0)
          .toString(),
    );
    bodyController = TextEditingController(
      text: widget.existing?['body']?.toString() ?? '',
    );
    isActive = widget.existing?['isActive'] == false ? false : true;
  }

  @override
  void dispose() {
    slugController.dispose();
    titleController.dispose();
    subtitleController.dispose();
    heroImageController.dispose();
    sortOrderController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> save() async {
    final title = titleController.text.trim();
    var slug = slugController.text.trim();

    if (slug.isEmpty) {
      slug = _slugify(title);
      slugController.text = slug;
    }

    if (slug.isEmpty || title.isEmpty || bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slug, title and body are required')),
      );
      return;
    }

    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(slug)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slug must use lowercase letters, numbers and hyphens'),
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await widget.repository.saveContentPage({
        'slug': slug,
        'parentSlug': widget.parentSlug,
        'title': title,
        'subtitle': subtitleController.text.trim(),
        'heroImageUrl': heroImageController.text.trim(),
        'sortOrder': int.tryParse(sortOrderController.text.trim()) ?? 0,
        'body': bodyController.text.trim(),
        'isActive': isActive,
      }, id: widget.existing?['id']?.toString());

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
      title: Text(
        isChild ? 'Edit Prayer / Song' : 'Edit ${widget.fallbackTitle}',
      ),
      content: SizedBox(
        width: 820,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: slugController,
                      readOnly: !isChild,
                      decoration: _decoration('Slug'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: sortOrderController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration('Sort Order'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: _decoration('Title'),
                onChanged: (value) {
                  if (isChild &&
                      widget.existing == null &&
                      slugController.text.trim().isEmpty) {
                    slugController.text = _slugify(value);
                  }
                },
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
                minLines: isChild ? 18 : 10,
                maxLines: 26,
                decoration: _decoration(
                  isChild ? 'Prayer / Song Body' : 'Body / Intro Text',
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: Text(
                  isChild
                      ? 'Inactive prayers will not appear in the mobile index.'
                      : 'Inactive pages will not be visible in the mobile app.',
                ),
                value: isActive,
                onChanged: (value) => setState(() => isActive = value),
              ),
              if (isChild)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _ContentPagesPageState.accent.withOpacity(0.14),
                    ),
                  ),
                  child: const Text(
                    'Tip: Create one prayer or song per item. The mobile app will show each item as a colorful card in the Temple Songs & Prayers index.',
                    style: TextStyle(
                      color: _ContentPagesPageState.textMuted,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
