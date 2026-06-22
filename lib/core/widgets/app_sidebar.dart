import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

class AppSidebar extends StatelessWidget {
  final String currentPath;

  const AppSidebar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        'Dashboard',
        '/dashboard',
        Icons.dashboard_rounded,
        AppColors.primary,
      ),
      _NavItem('Users', '/users', Icons.people_alt_rounded, AppColors.primary),
      _NavItem(
        'Groups',
        '/groups',
        Icons.account_tree_rounded,
        const Color(0xFF7C3AED),
      ),
      _NavItem(
        'Events',
        '/events',
        Icons.event_note_rounded,
        const Color(0xFF2563EB),
      ),
      _NavItem(
        'Programs',
        '/programs',
        Icons.school_rounded,
        const Color(0xFF16A34A),
      ),
      _NavItem(
        'Attendance',
        '/attendance',
        Icons.fact_check_rounded,
        const Color(0xFF0F766E),
      ),
      _NavItem(
        'Notifications',
        '/notifications',
        Icons.notifications_rounded,
        const Color(0xFFF59E0B),
      ),
      _NavItem(
        'Content Pages',
        '/content-pages',
        Icons.article_rounded,
        const Color(0xFF7C3AED),
      ),
    ];

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),

          // 🔥 Logo / Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Bhakti Steps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 🔥 Nav items
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _SidebarTile(
                item: item,
                selected: currentPath == item.route,
                onTap: () => context.go(item.route),
              ),
            ),
          ),

          const Spacer(),

          // 🔥 Footer (optional)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'v1.0',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String route;
  final IconData icon;
  final Color color;

  _NavItem(this.label, this.route, this.icon, this.color);
}

class _SidebarTile extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: widget.selected
              ? item.color.withValues(alpha: 0.12)
              : hovering
              ? Colors.grey.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: widget.selected
                      ? item.color
                      : hovering
                      ? item.color
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: widget.selected
                          ? item.color
                          : const Color(0xFF334155),
                      fontWeight: widget.selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),

                // 🔥 Active indicator
                if (widget.selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
