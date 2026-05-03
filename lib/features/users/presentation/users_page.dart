import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../data/users_repository.dart';
import 'widgets/user_edit_dialog.dart';
import 'widgets/user_form_dialog.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final searchController = TextEditingController();

  List<dynamic> users = [];
  bool loading = true;
  String? errorMessage;

  String? selectedRole;
  bool? selectedActive;

  int currentPage = 1;
  int pageSize = 10;
  int totalUsers = 0;

  late final UsersRepository repo;

  @override
  void initState() {
    super.initState();
    repo = UsersRepository(ApiClient(authStorage: AuthStorage()));
    loadUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadUsers({String? search}) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await repo.fetchUsers(
        search: search,
        page: currentPage,
        limit: pageSize,
        role: selectedRole,
        isActive: selectedActive,
      );

      if (!mounted) return;

      setState(() {
        users = List<dynamic>.from(result['data'] ?? []);
        totalUsers = result['total'] ?? 0;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = _extractError(e, fallback: 'Failed to load users');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load users';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> createUser() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const UserFormDialog(),
    );

    if (result == null) return;

    try {
      await repo.createUser(
        fullName: result['fullName']?.toString() ?? '',
        email: result['email']?.toString() ?? '',
        phone: result['phone']?.toString(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully')),
      );

      setState(() => currentPage = 1);
      await loadUsers(search: searchController.text);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractError(e, fallback: 'Failed to create user')),
        ),
      );
    }
  }

  Future<void> editUser(Map<String, dynamic> user) async {
    final currentRole = (user['role'] ?? 'USER').toString();

    try {
      final managers = await repo.fetchAssignableManagers(currentRole);

      if (!mounted) return;

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) =>
            UserEditDialog(user: user, assignableManagers: managers),
      );

      if (result == null) return;

      final selectedRoleResult = result['role']?.toString() ?? currentRole;
      final selectedManagerId = result['reportsToUserId']?.toString();
      final selectedIsActive = result['isActive'] == true;

      await repo.updateUserRole(
        userId: user['id'].toString(),
        role: selectedRoleResult,
      );

      final hierarchyManagers = await repo.fetchAssignableManagers(
        selectedRoleResult,
      );

      final managerStillValid = selectedManagerId == null
          ? true
          : hierarchyManagers.any(
              (m) => m['id'].toString() == selectedManagerId,
            );

      await repo.updateUserHierarchy(
        userId: user['id'].toString(),
        reportsToUserId: managerStillValid ? selectedManagerId : null,
        treeId: user['treeId']?.toString(),
      );

      await repo.updateUserStatus(
        userId: user['id'].toString(),
        isActive: selectedIsActive,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully')),
      );

      await loadUsers(search: searchController.text);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractError(e, fallback: 'Failed to update user')),
        ),
      );
    }
  }

  String _extractError(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) {
        return message.join(', ');
      }
      return message.toString();
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = totalUsers == 0 ? 1 : (totalUsers / pageSize).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Users',
          subtitle: 'Create users and manage role, hierarchy, and status.',
          action: ElevatedButton.icon(
            onPressed: createUser,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name or email...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onSubmitted: (value) {
                            setState(() => currentPage = 1);
                            loadUsers(search: value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() => currentPage = 1);
                          loadUsers(search: searchController.text);
                        },
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Search'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<String?>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All Roles'),
                          ),
                          DropdownMenuItem(
                            value: 'SUPER_ADMIN',
                            child: Text('Super Admin'),
                          ),
                          DropdownMenuItem(
                            value: 'CIRCLE_LEADER',
                            child: Text('Circle Leader'),
                          ),
                          DropdownMenuItem(
                            value: 'SECTOR_LEADER',
                            child: Text('Sector Leader'),
                          ),
                          DropdownMenuItem(
                            value: 'SERVANT_LEADER',
                            child: Text('Servant Leader'),
                          ),
                          DropdownMenuItem(value: 'USER', child: Text('User')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value;
                            currentPage = 1;
                          });
                          loadUsers(search: searchController.text);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<bool?>(
                        value: selectedActive,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: true, child: Text('Active')),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedActive = value;
                            currentPage = 1;
                          });
                          loadUsers(search: searchController.text);
                        },
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$totalUsers users',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Expanded(
                  child: loading
                      ? const LoadingState()
                      : users.isEmpty
                      ? const EmptyState(
                          title: 'No users found',
                          subtitle:
                              'Try a different search or create a new user.',
                        )
                      : ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = Map<String, dynamic>.from(
                              users[index] as Map,
                            );

                            final isActive = user['isActive'] == true;
                            final fullName = user['fullName']?.toString() ?? '';
                            final email = user['email']?.toString() ?? '';
                            final role = user['role']?.toString() ?? '-';

                            return _UserRow(
                              fullName: fullName,
                              email: email,
                              role: role,
                              isActive: isActive,
                              onEdit: () => editUser(user),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Page $currentPage of $totalPages',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Previous page',
                        onPressed: currentPage > 1
                            ? () {
                                setState(() => currentPage--);
                                loadUsers(search: searchController.text);
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      IconButton(
                        tooltip: 'Next page',
                        onPressed: (currentPage * pageSize) < totalUsers
                            ? () {
                                setState(() => currentPage++);
                                loadUsers(search: searchController.text);
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserRow extends StatefulWidget {
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final VoidCallback onEdit;

  const _UserRow({
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.onEdit,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final trimmedName = widget.fullName.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : '?';

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hovering
                ? AppColors.primary.withValues(alpha: 0.20)
                : Colors.black.withValues(alpha: 0.04),
          ),
          boxShadow: [
            BoxShadow(
              color: hovering
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.035),
              blurRadius: hovering ? 20 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.10),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(label: widget.role),
                      StatusChip(
                        label: widget.isActive ? 'Active' : 'Inactive',
                        color: widget.isActive
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
